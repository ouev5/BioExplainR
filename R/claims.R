# Typed claim ledger and validation policy --------------------------------------

.claim_types <- c("statistical_fact", "statistical_interpretation", "biological_association",
                  "causal", "evidence_support", "design", "plot_mapping", "unknown")
.claim_origins <- c("local_template", "model", "user")

.claim_value_type <- function(value) {
  if (is.null(value)) return("none")
  if (is.logical(value)) "logical" else if (is.integer(value)) "integer" else
    if (is.numeric(value)) "number" else if (is.character(value)) "string" else "object"
}

.claim_evidence_refs <- function(cl) {
  v <- cl$evidence_refs %||% cl$evidence %||% cl$evidence_ids %||% cl$citations %||% cl$citation
  if (is.null(v)) return(character())
  if (is.list(v)) v <- unlist(v, use.names = FALSE)
  unique(as.character(v))
}

.claim_tokens <- function(cl) {
  tok <- cl$path_tokens %||% cl$fact_path_tokens
  if (!is.null(tok)) return(as.character(unlist(tok, use.names = FALSE)))
  ref <- cl$fact_path %||% cl$fact %||% cl$reference %||% cl$path
  if (is.null(ref) || length(ref) != 1L || !nzchar(as.character(ref))) return(character())
  ref <- sub("^facts\\$|^facts\\.", "", as.character(ref))
  strsplit(ref, "[.$]", fixed = FALSE)[[1]]
}

.claim_path <- function(tokens) paste(tokens, collapse = ".")

.claim_scope <- function(cl, ctx = NULL) {
  cl$scope %||% list()
}

.normalise_claims <- function(claims) {
  if (is.null(claims)) return(list())
  if (is.data.frame(claims)) return(lapply(seq_len(nrow(claims)), function(i) as.list(claims[i, , drop = FALSE])))
  if (!is.list(claims)) return(list(list(text = as.character(claims))))
  if (length(claims) && !is.null(names(claims)) && any(c("id", "text", "fact", "fact_path", "path_tokens", "claim_type") %in% names(claims)))
    return(list(claims))
  claims
}

#' Create a typed claim policy
#'
#' @param tolerance Numeric comparison tolerance.
#' @param require_evidence_types Claim types that require evidence references.
#' @return A \code{bio_claim_policy} object.
#' @export
bio_claim_policy <- function(tolerance = 1e-6,
                             require_evidence_types = c("biological_association", "causal", "evidence_support")) {
  if (!is.numeric(tolerance) || length(tolerance) != 1L || is.na(tolerance) ||
      !is.finite(tolerance) || tolerance < 0) stop("tolerance must be finite and non-negative.", call. = FALSE)
  structure(list(schema_version = .bio_schema_version, tolerance = tolerance,
                 require_evidence_types = intersect(require_evidence_types, .claim_types)),
            class = "bio_claim_policy")
}

#' Convert explanation claims to a typed ledger
#'
#' @param explanation A \code{bio_explanation}, or a context when claims are supplied.
#' @param claims Optional list/data.frame of atomic claims.
#' @param origin Default claim origin.
#' @return A \code{bio_claim_ledger}.
#' @export
bio_claim_ledger <- function(explanation, claims = NULL, origin = "model") {
  ctx <- if (inherits(explanation, "bio_explanation")) explanation$context else explanation
  if (!inherits(ctx, "bio_context")) stop("explanation must contain a bio_context.", call. = FALSE)
  if (!origin %in% .claim_origins) stop("Unknown claim origin.", call. = FALSE)
  from_model <- is.null(claims) && inherits(explanation, "bio_explanation") && !is.null(explanation$llm)
  if (is.null(claims) && inherits(explanation, "bio_explanation")) claims <- explanation$llm$claims
  raw <- .normalise_claims(claims)
  if (!length(raw)) {
    rows <- data.frame(id = character(), schema_version = character(), claim_type = character(),
                       text = character(), origin = character(), text_ref = character(),
                       context_id = character(), fact_path = character(), value_type = character(),
                       unit = character(), direction = character(), stringsAsFactors = FALSE)
    rows$value <- list(); rows$scope <- list(); rows$path_tokens <- list();
    rows$evidence_refs <- list(); rows$validation <- list()
    return(structure(list(schema_version = .bio_schema_version, context_id = ctx$context_id,
                          claims = rows, unmapped_prose = NA_real_, errors = character()),
                     class = "bio_claim_ledger"))
  }
  ids <- vapply(seq_along(raw), function(i) {
    cl <- raw[[i]]
    if (!is.list(cl)) cl <- list(text = as.character(cl))
    as.character(cl$id %||% paste0("claim_", i))[1]
  }, "")
  rows <- lapply(seq_along(raw), function(i) {
    cl <- raw[[i]]
    if (!is.list(cl)) cl <- list(text = as.character(cl))
    toks <- .claim_tokens(cl)
    typ <- as.character(cl$claim_type %||% cl$type %||% if (length(toks)) "statistical_fact" else "unknown")[1]
    if (!typ %in% .claim_types) typ <- "unknown"
    data.frame(id = ids[i], schema_version = as.character(cl$schema_version %||% .bio_schema_version)[1],
               claim_type = typ, text = as.character(cl$text %||% "")[1],
                origin = if (from_model) "model" else as.character(cl$origin %||% origin)[1],
               text_ref = as.character(cl$text_ref %||% "")[1],
               context_id = as.character(cl$context_id %||% ctx$context_id %||% NA_character_)[1],
               fact_path = .claim_path(toks), value_type = as.character(cl$value_type %||%
                 .claim_value_type(cl$value))[1], unit = as.character(cl$unit %||% NA_character_)[1],
               direction = as.character(cl$direction %||% NA_character_)[1],
               stringsAsFactors = FALSE)
  })
  tab <- do.call(rbind, rows)
  tab$value <- lapply(raw, function(cl) { if (!is.list(cl)) cl <- list(text = as.character(cl)); cl$value %||% NULL })
  tab$scope <- lapply(raw, function(cl) { if (!is.list(cl)) cl <- list(text = as.character(cl)); .claim_scope(cl, ctx) })
  tab$path_tokens <- lapply(raw, function(cl) { if (!is.list(cl)) cl <- list(text = as.character(cl)); .claim_tokens(cl) })
  tab$evidence_refs <- lapply(raw, function(cl) { if (!is.list(cl)) cl <- list(text = as.character(cl)); .claim_evidence_refs(cl) })
   tab$validation <- rep(list(NULL), length(raw))
  dup <- unique(ids[duplicated(ids)])
  errs <- character()
  if (anyNA(ids) || any(!nzchar(ids))) errs <- c(errs, "claim IDs must be non-empty")
  if (length(dup)) errs <- c(errs, paste0("duplicate claim id(s): ", paste(dup, collapse = ", ")))
  bad_origin <- which(!tab$origin %in% .claim_origins)
  if (length(bad_origin)) errs <- c(errs, paste0("invalid claim origin at row(s): ", paste(bad_origin, collapse = ", ")))
  structure(list(schema_version = .bio_schema_version, context_id = ctx$context_id,
                 claims = tab, unmapped_prose = if (inherits(explanation, "bio_explanation"))
                   if (length(explanation$llm)) NA_real_ else 0 else NA_real_, errors = errs),
            class = "bio_claim_ledger")
}

#' @export
print.bio_claim_ledger <- function(x, ...) {
  cat("<bio_claim_ledger> ", nrow(x$claims), " claims", if (length(x$errors)) " (invalid)" else "", "\n", sep = "")
  if (length(x$errors)) cat(paste("  -", x$errors), sep = "\n")
  invisible(x)
}

.ledger_fact_get <- function(ctx, tokens) {
  if (!length(tokens) || anyNA(tokens) || any(!nzchar(tokens))) return(list(found = FALSE))
  cur <- ctx$facts
  for (p in tokens) {
    index <- suppressWarnings(as.numeric(p))
    if (is.data.frame(cur) && grepl("^[1-9][0-9]*$", p) && is.finite(index) && index <= nrow(cur))
      cur <- as.list(cur[as.integer(p), , drop = FALSE])
    else if (is.list(cur) && !is.null(names(cur)) && p %in% names(cur)) cur <- cur[[p]]
    else if (grepl("^[1-9][0-9]*$", p) && is.finite(index) && index <= length(cur)) cur <- cur[[as.integer(p)]]
    else return(list(found = FALSE))
  }
  list(found = TRUE, value = cur)
}

.validation_status <- function(statuses) {
  if ("fail" %in% statuses) "fail" else if (!any(statuses == "pass")) "unverified" else
    if (any(statuses != "pass")) "partial" else "pass"
}

.typed_value_matches <- function(actual, want, value_type, tolerance) {
  if (length(actual) != 1L || length(want) != 1L || is.list(actual) || is.list(want) ||
      anyNA(actual) || anyNA(want)) return(FALSE)
  if (is.logical(actual)) return(is.logical(want) && value_type == "logical" && identical(actual, want))
  if (is.character(actual)) return(is.character(want) && value_type == "string" && identical(actual, want))
  if (!is.numeric(actual) || !is.finite(actual) || !value_type %in% c("integer", "number", "string")) return(FALSE)
  # Full-precision decimal strings are accepted only for numeric facts.
  if (!(is.numeric(want) || is.character(want))) return(FALSE)
  w <- suppressWarnings(as.numeric(want))
  if (!is.finite(w)) return(FALSE)
  if (is.integer(actual) || value_type == "integer") return(actual == w && w == floor(w))
  abs(actual - w) <= if (actual == 0) tolerance else abs(actual) * tolerance
}

.ledger_validate <- function(explanation, ledger, policy) {
  ctx <- explanation$context
  findings <- list()
  add <- function(id, check, status, detail, reference_scope = "full") {
    findings[[length(findings) + 1L]] <<- data.frame(claim = id, check = check, status = status,
      detail = detail, reference_scope = reference_scope, stringsAsFactors = FALSE)
  }
  if (length(ledger$errors)) for (e in ledger$errors) add("(ledger)", "schema", "fail", e)
  for (i in seq_len(nrow(ledger$claims))) {
    cl <- ledger$claims[i, , drop = FALSE]; id <- cl$id[[1]]; toks <- ledger$claims$path_tokens[[i]]
    if (!length(toks)) add(id, "fact_reference", "unverified", "claim has no safe fact path")
    else {
      got <- .ledger_fact_get(ctx, toks)
      if (!got$found && identical(toks[1], "top_features")) {
        topctx <- ctx; topctx$facts <- list(top_features = ctx$top_features)
        got <- .ledger_fact_get(topctx, toks)
      }
      if (!got$found) add(id, "fact_reference", "fail", paste0("unknown fact reference '", cl$fact_path[[1]], "'"))
      else if (!is.null(ledger$claims$value[[i]])) {
        want <- ledger$claims$value[[i]]; actual <- got$value
        ok <- .typed_value_matches(actual, want, cl$value_type[[1]], policy$tolerance)
        add(id, "value", if (ok) "pass" else "fail", if (ok) "typed value matches computed fact" else
          "value/type does not match a finite scalar fact", if (identical(toks[1], "top_features")) "preview" else "full")
      } else add(id, "fact_reference", "unverified", "fact exists but no value was supplied")
      if (got$found && !is.na(cl$unit[[1]])) {
        unit <- ctx$fact_descriptors[[cl$fact_path[[1]]]]$unit
        add(id, "unit", if (is.null(unit)) "unverified" else if (identical(unit, cl$unit[[1]])) "pass" else "fail",
            if (is.null(unit)) "reference unit is unknown" else "claim unit compared with descriptor")
      }
      if (got$found && !is.na(cl$direction[[1]])) {
        d <- tolower(cl$direction[[1]])
        want_sign <- if (d %in% c("up", "positive", "increase", "increased")) 1 else
          if (d %in% c("down", "negative", "decrease", "decreased")) -1 else NA_real_
        a <- got$value
        hint <- if (grepl("(^|[._])down($|[._])", cl$fact_path[[1]])) -1 else
          if (grepl("(^|[._])up($|[._])", cl$fact_path[[1]])) 1 else NA_real_
        s <- if (!is.na(hint)) hint else if (is.numeric(a) && length(a) == 1 && is.finite(a) && a != 0) sign(a) else NA_real_
        add(id, "direction", if (is.na(want_sign)) "fail" else if (is.na(s)) "unverified" else if (s == want_sign) "pass" else "fail",
            "direction compared with reference sign/count direction")
      }
    }
    typ <- cl$claim_type[[1]]
    if (typ == "unknown") add(id, "claim_type", "unverified", "claim type is unknown")
    if (typ %in% policy$require_evidence_types && !length(ledger$claims$evidence_refs[[i]]))
      add(id, "evidence_required", "unverified", paste0(typ, " claims require evidence references"))
    scope <- ledger$claims$scope[[i]]
    known <- function(s) is.list(s) && any(vapply(s, function(v) length(v) > 0 && any(!is.na(v) & !as.character(v) %in% c("", "unknown")), logical(1)))
    if (!known(scope) || !known(ctx$scope)) add(id, "scope", "unverified", "claim or context has no declared known scope")
    else if (length(.scope_mismatch(scope, ctx$scope))) add(id, "scope", "fail", "claim scope differs from context")
    else if (!all(names(scope) %in% names(ctx$scope))) add(id, "scope", "unverified", "context does not declare all claim scope fields")
    if (!is.na(cl$context_id[[1]]) && !is.null(ctx$context_id) && cl$context_id[[1]] != ctx$context_id)
      add(id, "context_id", "fail", "claim refers to a different context")
    if (typ == "causal") add(id, "causal_design", "unverified", "numeric agreement cannot establish a causal design or mechanism")
  }
  if (!length(findings)) add("(none)", "claims", "unverified", "no typed claims")
  do.call(rbind, findings)
}

#' Validate typed claims and attach their ledger to an explanation
#'
#' @param explanation A \code{bio_explanation}.
#' @param claims Optional typed claims.
#' @param policy A \code{bio_claim_policy}.
#' @param relations Optional independently recorded claim--evidence relations.
#' @return The explanation with \code{claim_ledger} and validation findings.
#' @export
bio_validate_claims <- function(explanation, claims = NULL, policy = bio_claim_policy(), relations = NULL) {
  stopifnot(inherits(explanation, "bio_explanation"))
  if (!inherits(policy, "bio_claim_policy")) stop("policy must be a bio_claim_policy.", call. = FALSE)
  ledger <- bio_claim_ledger(explanation, claims)
  typed <- .ledger_validate(explanation, ledger, policy)
  old <- bio_validate_explanation(explanation, claims = .normalise_claims(claims %||% explanation$llm$claims), tolerance = policy$tolerance)
  old$claim_ledger <- ledger
  old$validation$typed_findings <- typed
  support <- bio_validate_evidence_support(ledger, explanation$evidence, relations)
  old$validation$evidence_findings <- support$findings
  old$validation$legacy_status <- old$validation$status
  statuses <- typed$status
  if (any(lengths(ledger$claims$evidence_refs))) statuses <- c(statuses, support$findings$status)
  used <- old$validation$findings$check == "evidence_ids"
  statuses <- c(statuses, old$validation$findings$status[used])
  old$validation$status <- .validation_status(statuses)
  for (i in seq_len(nrow(ledger$claims))) ledger$claims$validation[[i]] <- typed[typed$claim == ledger$claims$id[i], , drop = FALSE]
  old$claim_ledger <- ledger
  old$validation$policy_version <- policy$schema_version
  old$validation$prose_status <- if (is.null(old$llm)) "not_run" else if (nrow(ledger$claims)) "partial" else "unverified"
  if (!is.null(old$llm) && old$validation$status == "pass") old$validation$status <- "partial"
  old
}
