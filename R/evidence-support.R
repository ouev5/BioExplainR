# Claim-level evidence support relations ---------------------------------------

.relation_values <- c("supports", "contradicts", "definition_only", "irrelevant", "unknown")
.relation_roles <- c("definition", "annotation", "method", "dataset_support",
                     "experimental_support", "structural_computation")
.relation_origins <- c("rule", "model_proposed", "user_declared", "expert_reviewed")

.scope_value <- function(x, key) {
  if (is.null(x)) return(NULL)
  if (is.list(x)) return(x[[key]])
  NULL
}

.scope_mismatch <- function(claim_scope, evidence_scope) {
  keys <- intersect(names(claim_scope %||% list()), names(evidence_scope %||% list()))
  if (!length(keys)) return(character())
  bad <- vapply(keys, function(k) {
    a <- .scope_value(claim_scope, k); b <- .scope_value(evidence_scope, k)
    a <- as.character(a); b <- as.character(b)
    a <- a[!is.na(a) & !a %in% c("", "unknown")]
    b <- b[!is.na(b) & !b %in% c("", "unknown")]
    length(a) > 0 && length(b) > 0 && !any(a %in% b)
  }, logical(1))
  keys[bad]
}

#' Construct a claim-level evidence support relation
#'
#' @param claim Claim row/list or claim ID.
#' @param evidence A \code{bio_evidence} object or list.
#' @param relation Support category.
#' @param role Evidence role.
#' @param origin How the relation was proposed or reviewed.
#' @param detail Human-readable finding.
#' @param reviewed_at Review timestamp.
#' @param reviewer_id Optional pseudonymous reviewer identifier.
#' @param rubric_version Optional review rubric version.
#' @return A \code{bio_evidence_relation} object.
#' @export
bio_evidence_support <- function(claim, evidence, relation = c("supports", "contradicts", "definition_only", "irrelevant", "unknown"),
                                 role = NULL, origin = c("rule", "model_proposed", "user_declared", "expert_reviewed"),
                                 detail = NULL, reviewed_at = NULL, reviewer_id = NULL, rubric_version = NULL) {
  relation <- match.arg(relation); origin <- match.arg(origin)
  if (origin == "expert_reviewed" && any(vapply(list(reviewed_at, reviewer_id, rubric_version),
      function(v) is.null(v) || length(v) != 1L || is.na(v) || !nzchar(as.character(v)), logical(1))))
    stop("expert_reviewed requires reviewed_at, reviewer_id and rubric_version.", call. = FALSE)
  if (is.data.frame(claim) && nrow(claim)) {
    claim <- as.list(claim[1, , drop = FALSE])
    claim <- lapply(claim, function(x) if (is.list(x) && length(x) == 1L) x[[1L]] else x)
  }
  cid <- if (is.character(claim)) claim[1] else as.character(claim$id %||% claim$claim_id %||% "unknown")[1]
  evs <- if (inherits(evidence, "bio_evidence")) list(evidence) else evidence
  if (!is.list(evs) || !length(evs) || !all(vapply(evs, inherits, logical(1), what = "bio_evidence")))
    stop("evidence must contain bio_evidence objects.", call. = FALSE)
  if (!is.null(role) && !role %in% .relation_roles) stop("Unknown evidence role.", call. = FALSE)
  rows <- lapply(evs, function(ev) {
    mismatch <- .scope_mismatch(if (is.list(claim)) claim$scope else NULL, ev$scope)
    auto <- if (length(mismatch)) "scope mismatch: " else ""
    data.frame(claim_id = cid, evidence_id = ev$id, relation = relation,
               role = role %||% ev$role %||% NA_character_, origin = origin,
               status = if (length(mismatch)) "fail" else "recorded",
               detail = detail %||% paste0(auto, if (length(mismatch)) paste(mismatch, collapse = ", ") else "relation recorded"),
               reviewed_at = reviewed_at %||% NA_character_, reviewer_id = reviewer_id %||% NA_character_,
               rubric_version = rubric_version %||% NA_character_, content_hash = ev$content_hash %||% NA_character_,
               stringsAsFactors = FALSE)
  })
  structure(list(schema_version = .bio_schema_version, pairs = do.call(rbind, rows)),
            class = "bio_evidence_relation")
}

#' Validate evidence relations referenced by a typed ledger
#'
#' @param ledger A \code{bio_claim_ledger}.
#' @param evidence Evidence objects.
#' @param relations Optional relation table/list.
#' @return A relation validation result.
#' @export
bio_validate_evidence_support <- function(ledger, evidence, relations = NULL) {
  if (!inherits(ledger, "bio_claim_ledger")) stop("ledger must be a bio_claim_ledger.", call. = FALSE)
  evs <- if (inherits(evidence, "bio_evidence")) list(evidence) else evidence
  known <- if (length(evs)) vapply(evs, `[[`, "", "id") else character()
  rel <- if (is.null(relations)) data.frame() else if (inherits(relations, "bio_evidence_relation")) relations$pairs else as.data.frame(relations, stringsAsFactors = FALSE)
  need <- c("claim_id", "evidence_id", "relation", "role", "origin", "status")
  if (nrow(rel) && any(!need %in% names(rel))) stop("relations are missing required fields.", call. = FALSE)
  rows <- list()
  add <- function(claim, check, status, detail) rows[[length(rows) + 1L]] <<- data.frame(claim = claim, check = check,
    status = status, detail = detail, stringsAsFactors = FALSE)
  for (i in seq_len(nrow(ledger$claims))) {
    refs <- ledger$claims$evidence_refs[[i]]
    if (!length(refs)) next
    missing <- setdiff(refs, known)
    if (length(missing)) add(ledger$claims$id[i], "evidence_ids", "fail", paste("unknown evidence:", paste(missing, collapse = ", ")))
    else {
      for (id in refs) {
        hit <- if (nrow(rel)) rel[rel$claim_id == ledger$claims$id[i] & rel$evidence_id == id, , drop = FALSE] else rel
        if (!nrow(hit)) add(ledger$claims$id[i], "support_relation", "unverified", paste("no claim-level relation for", id))
        else {
          ev <- evs[[match(id, known)]]
          typ <- ledger$claims$claim_type[i]
          mismatch <- .scope_mismatch(ledger$claims$scope[[i]], ev$scope)
          if (length(mismatch) || any(hit$status == "fail", na.rm = TRUE))
            add(ledger$claims$id[i], "support_relation", "fail", paste(id, "has a scope mismatch or failed relation"))
          else if (anyNA(hit[need]) || any(!hit$relation %in% .relation_values) || any(!hit$origin %in% .relation_origins))
            add(ledger$claims$id[i], "support_relation", "unverified", paste(id, "has incomplete/unknown relation fields"))
          else if (any(hit$relation %in% c("contradicts", "irrelevant")) ||
                   (typ %in% c("biological_association", "causal", "evidence_support") &&
                    any(hit$relation == "definition_only" | hit$role %in% c("definition", "method"))))
            add(ledger$claims$id[i], "support_relation", "fail", paste(id, "does not support this claim"))
          else if (any(hit$relation == "unknown") || !length(ev$scope) || !length(ledger$claims$scope[[i]]) ||
            !any(vapply(intersect(names(ev$scope), names(ledger$claims$scope[[i]])), function(k) {
              a <- as.character(ev$scope[[k]]); b <- as.character(ledger$claims$scope[[i]][[k]])
              any(a[!is.na(a) & !a %in% c("", "unknown")] %in% b[!is.na(b) & !b %in% c("", "unknown")])
            }, logical(1))))
            add(ledger$claims$id[i], "support_relation", "unverified", paste(id, "support or scope is unknown"))
          else if (any(hit$origin != "expert_reviewed"))
            add(ledger$claims$id[i], "support_relation", "partial", paste(id, "has non-expert proposed support"))
          else {
            review <- c("reviewed_at", "reviewer_id", "rubric_version")
            verified <- all(review %in% names(hit)) && !anyNA(hit[review]) && all(nzchar(as.matrix(hit[review]))) &&
              !is.null(ev$content_hash) && "content_hash" %in% names(hit) &&
              all(!is.na(hit$content_hash) & hit$content_hash == ev$content_hash)
            add(ledger$claims$id[i], "support_relation", if (verified) "pass" else "unverified",
                paste(id, if (verified) "has documented expert support" else "has incomplete review/content provenance"))
          }
        }
      }
    }
  }
  if (!length(rows)) add("(none)", "evidence", "unverified", "no evidence references were supplied")
   structure(list(status = .validation_status(vapply(rows, function(x) x$status, "")),
    findings = do.call(rbind, rows)), class = "bio_evidence_validation")
}
