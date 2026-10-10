# Explicit cross-result direction checks. No feature matching is inferred.

#' Check explicit direction relations between project facts
#'
#' Each relation checks two finite, scalar effects for a declared feature.
#' A pass verifies only the declared sign relationship, not biological support,
#' causality, statistical significance or independent replication. Missing scope,
#' feature annotation or comparison orientation remains unverified.
#'
#' @param project A \code{bio_project}.
#' @param relations Data frame with unique \code{id}, \code{from}, \code{to},
#'   \code{from_fact}, \code{to_fact}, \code{feature_id}, and \code{expected}
#'   (\code{"same"} or \code{"opposite"}). Fact paths use dot-separated names.
#'   Optional list columns \code{from_tokens}/\code{to_tokens} provide exact
#'   path tokens for keys containing dots.
#' @return A list with status and per-relation findings. Contexts must declare
#'   matching dataset_id, comparison_id, species, tissue and sample_level in
#'   scope, numerator/denominator in design, and feature_id in the descriptor
#'   of each referenced fact. Zero effects have an unverified direction.
#' @export
bio_validate_project_relations <- function(project, relations = project$relations) {
  if (!inherits(project, "bio_project")) stop("project must be a bio_project.", call. = FALSE)
  required <- c("id", "from", "to", "from_fact", "to_fact", "feature_id", "expected")
  if (!is.data.frame(relations) || !all(required %in% names(relations)))
    stop("relations must be a data.frame with columns: ", paste(required, collapse = ", "), call. = FALSE)
  if (any(vapply(relations[required], function(x) !is.atomic(x) || anyNA(x) ||
                 any(!nzchar(as.character(x))), logical(1))) || anyDuplicated(relations$id))
    stop("Relation fields must be non-missing and IDs unique.", call. = FALSE)
  if (any(!relations$expected %in% c("same", "opposite")))
    stop("expected must be same or opposite.", call. = FALSE)
  findings <- data.frame(id = character(), check = character(), status = character(),
                         detail = character(), stringsAsFactors = FALSE)
  add <- function(id, check, status, detail) {
    findings <<- rbind(findings, data.frame(id = id, check = check, status = status, detail = detail))
  }
  scalar_text <- function(x) is.character(x) && length(x) == 1L && !is.na(x) &&
    nzchar(x) && !tolower(x) %in% c("unknown", "unspecified")
  context <- function(name) {
    x <- project$items[[name]]
    if (inherits(x, "bio_explanation")) x$context else if (inherits(x, "bio_context")) x else NULL
  }
  for (i in seq_len(nrow(relations))) {
    r <- relations[i, , drop = FALSE]; id <- as.character(r$id)
    a <- context(as.character(r$from)); b <- context(as.character(r$to))
    if (is.null(a) || is.null(b) || r$from == r$to) {
      add(id, "contexts", "fail", "Two distinct project contexts are required")
      next
    }
    scope_ok <- TRUE
    for (field in c("dataset_id", "comparison_id", "species", "tissue", "sample_level")) {
      x <- a$scope[[field]]; y <- b$scope[[field]]
      status <- if (!scalar_text(x) || !scalar_text(y)) "unverified" else if (identical(x, y)) "pass" else "fail"
      add(id, paste0("scope_", field), status, if (status == "pass") "Recorded scope agrees" else "Missing or conflicting scope")
      scope_ok <- scope_ok && status == "pass"
    }
    for (field in c("numerator", "denominator")) {
      x <- if (is.list(a$design)) a$design[[field]] else NULL
      y <- if (is.list(b$design)) b$design[[field]] else NULL
      status <- if (!scalar_text(x) || !scalar_text(y)) "unverified" else if (identical(x, y)) "pass" else "fail"
      add(id, paste0("orientation_", field), status, if (status == "pass") "Recorded orientation agrees" else "Missing or conflicting orientation")
      scope_ok <- scope_ok && status == "pass"
    }
    if (is.list(a$design) && is.list(b$design) &&
        ((scalar_text(a$design$numerator) && identical(a$design$numerator, a$design$denominator)) ||
         (scalar_text(b$design$numerator) && identical(b$design$numerator, b$design$denominator)))) {
      add(id, "orientation_distinct", "fail", "Numerator and denominator must differ")
      scope_ok <- FALSE
    }
    tokens <- function(side) {
      column <- paste0(side, "_tokens")
      if (column %in% names(relations)) {
        v <- relations[[column]][[i]]
        if (!is.character(v) || !length(v) || anyNA(v) || any(!nzchar(v)))
          stop("Relation tokens must be non-empty character paths.", call. = FALSE)
        v
      } else strsplit(as.character(r[[paste0(side, "_fact")]]), ".", fixed = TRUE)[[1]]
    }
    at <- tokens("from"); bt <- tokens("to")
    af <- a$fact_descriptors[[paste(at, collapse = ".")]]$feature_id
    bf <- b$fact_descriptors[[paste(bt, collapse = ".")]]$feature_id
    feature_status <- if (!scalar_text(af) || !scalar_text(bf)) "unverified" else
      if (identical(af, as.character(r$feature_id)) && identical(bf, as.character(r$feature_id))) "pass" else "fail"
    add(id, "feature_identity", feature_status, "Feature identity uses explicit fact descriptors")
    x <- .ledger_fact_get(a, at); y <- .ledger_fact_get(b, bt)
    finite <- function(v) isTRUE(v$found) && is.numeric(v$value) && length(v$value) == 1L && is.finite(v$value)
    if (!finite(x) || !finite(y)) {
      add(id, "direction", "unverified", "Both effects must be finite numeric scalars")
    } else if (!scope_ok || feature_status != "pass") {
      add(id, "direction", "unverified", "Direction is not comparable without matching scope, orientation and feature")
    } else if (x$value == 0 || y$value == 0) {
      add(id, "direction", "unverified", "A zero effect has no positive or negative direction")
    } else {
      same <- sign(x$value) == sign(y$value)
      add(id, "direction", if (same == (r$expected == "same")) "pass" else "fail",
          if (same) "Effects have the same sign" else "Effects have opposite signs")
    }
  }
  list(status = .validation_status(findings$status), findings = findings,
       scope = "Explicit sign relations only; no significance, causality or independent-evidence assessment")
}
