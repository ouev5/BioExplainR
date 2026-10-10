# Explicit-claim validation ----------------------------------------------------------------------------

.vf <- function(claim, check, status, detail) {
  data.frame(claim = claim, check = check, status = status, detail = detail, stringsAsFactors = FALSE)
}

.fact_get <- function(facts, path) {
  path <- sub("^facts\\$|^facts\\.", "", path)
  parts <- strsplit(path, "[.$]")[[1]]
  cur <- facts
  for (p in parts) {
    if (is.data.frame(cur) && grepl("^[1-9][0-9]*$", p) && as.numeric(p) <= nrow(cur))
      cur <- as.list(cur[as.integer(p), , drop = FALSE])
    else if (!is.null(names(cur)) && p %in% names(cur)) cur <- cur[[p]]
    else if (grepl("^[1-9][0-9]*$", p) && as.numeric(p) <= length(cur)) cur <- cur[[as.integer(p)]]
    else return(list(found = FALSE))
  }
  list(found = TRUE, value = cur)
}

.claim_ids <- function(cl) {
  v <- cl$evidence %||% cl$evidence_ids %||% cl$citations %||% cl$citation
  as.character(unlist(v))
}

#' Validate explicit machine-checkable claims in an explanation
#'
#' Each claim is a list with \code{fact} (a path into \code{context$facts},
#' e.g. \code{"n_significant"} or \code{"per_cluster.0.n_up"}), optional
#' \code{value} (number), \code{direction} (\code{"up"}/\code{"down"}/
#' \code{"positive"}/\code{"negative"}) and \code{evidence} (evidence ids).
#' Free prose without explicit claims is reported as \code{"unverified"}, never
#' as passed. A passing validation only shows consistency with the computed
#' facts; it does not establish scientific correctness.
#' Paths such as \code{"top_features.1.log2fc"} refer to rows of the bounded
#' preview and check the stored preview values, which may have display rounding.
#'
#' @param explanation A \code{bio_explanation}.
#' @param claims List of claims; default uses \code{explanation$llm$claims}.
#' @param tolerance Relative numeric tolerance for nonzero facts, or absolute
#'   tolerance when the reference is exactly zero. Tiny p-values are not treated
#'   as equal to zero merely because they are below an absolute tolerance.
#' @return The explanation with a \code{validation} element
#'   (\code{status}, \code{findings}, \code{n_claims}).
#' @export
bio_validate_explanation <- function(explanation, claims = NULL, tolerance = 1e-6) {
  stopifnot(inherits(explanation, "bio_explanation"))
  facts <- explanation$context$facts
  claims <- claims %||% explanation$llm$claims
  if (is.data.frame(claims)) claims <- lapply(seq_len(nrow(claims)), function(i) as.list(claims[i, , drop = FALSE]))
  known <- if (length(explanation$evidence)) vapply(explanation$evidence, function(e) e$id, "") else character()
  f <- list()
  used <- as.character(unlist(explanation$llm$evidence_used))
  if (length(used)) {
    bad <- setdiff(used, known)
    f$used <- .vf("(evidence_used)", "evidence_ids", if (length(bad)) "fail" else "pass",
                  if (length(bad)) paste0("unknown evidence id(s): ", paste(bad, collapse = ", "),
                                          if (!length(known)) " (no evidence list was supplied)" else "")
                  else "all cited evidence ids were supplied")
  }
  if (!length(claims)) {
    f$none <- .vf("(none)", "claims", "unverified", "no explicit machine-checkable claims; prose is not verified")
  }
  for (i in seq_along(claims)) {
    cl <- claims[[i]]
    if (!is.list(cl)) cl <- list(text = as.character(cl))
    nm <- as.character(cl$id %||% paste0("claim_", i))[1L]
    ref <- cl$fact %||% cl$reference %||% cl$path
    checked <- FALSE
    if (!is.null(ref) && length(ref) == 1 && nzchar(ref)) {
      got <- if (grepl("^top_features[.$]", ref))
        .fact_get(list(top_features = explanation$context$top_features), as.character(ref)) else
        .fact_get(facts, as.character(ref))
      if (!got$found) {
        f[[length(f) + 1]] <- .vf(nm, "reference", "fail", paste0("unknown fact reference '", ref, "'"))
      } else {
        act <- got$value
        if (!is.null(cl$value)) {
          v <- suppressWarnings(as.numeric(unlist(cl$value)))
          a <- suppressWarnings(as.numeric(unlist(act)))
          if (length(v) != 1L || !is.finite(v) || length(a) != 1L || !is.finite(a)) {
            f[[length(f) + 1]] <- if (is.character(act) && length(act) == 1 && length(cl$value) == 1L && identical(as.character(cl$value), act))
              .vf(nm, "value", "pass", "value matches fact") else
              .vf(nm, "value", "fail", paste0("value is not comparable with fact '", ref, "'"))
          } else {
            limit <- if (a == 0) tolerance else tolerance * abs(a)
            ok <- abs(v - a) <= limit
            f[[length(f) + 1]] <- .vf(nm, "value", if (ok) "pass" else "fail",
              if (ok) paste0(ref, " = ", .fmt_num(a, 6)) else paste0("claimed ", .fmt_num(v, 6), " but ", ref, " = ", .fmt_num(a, 6)))
          }
          checked <- TRUE
        }
        if (!is.null(cl$direction)) {
          d <- tolower(as.character(cl$direction)[1])
          want <- if (d %in% c("up", "positive", "increase", "increased")) 1 else if (d %in% c("down", "negative", "decrease", "decreased")) -1 else NA
          a <- suppressWarnings(as.numeric(unlist(act)))
          hint <- if (grepl("(^|[._])down($|[._])", ref)) -1 else if (grepl("(^|[._])up($|[._])", ref)) 1 else NA
          if (is.na(want)) f[[length(f) + 1]] <- .vf(nm, "direction", "fail", paste0("unrecognised direction '", d, "'"))
          else if (!is.na(hint)) {
            ok <- hint == want
            f[[length(f) + 1]] <- .vf(nm, "direction", if (ok) "pass" else "fail",
              paste0("fact '", ref, "' counts features going ", if (hint > 0) "up" else "down", "; claim says ", d))
          } else if (length(a) == 1 && !is.na(a) && a != 0) {
            ok <- sign(a) == want
            f[[length(f) + 1]] <- .vf(nm, "direction", if (ok) "pass" else "fail",
              paste0("fact '", ref, "' = ", .fmt_num(a, 6), " is ", if (a > 0) "positive" else "negative", "; claim says ", d))
          } else f[[length(f) + 1]] <- .vf(nm, "direction", "unverified", "fact has no sign to check direction against")
          checked <- TRUE
        }
        if (!checked) f[[length(f) + 1]] <- .vf(nm, "reference", "unverified", "fact reference exists, but no value or direction was checked")
        checked <- TRUE
      }
    } else {
      f[[length(f) + 1]] <- .vf(nm, "claim", "unverified", "claim has no fact reference; cannot be checked")
    }
    ids <- .claim_ids(cl)
    if (length(ids)) {
      bad <- setdiff(ids, known)
      f[[length(f) + 1]] <- .vf(nm, "citation", if (length(bad)) "fail" else "pass",
        if (length(bad)) paste0("citation(s) not in the supplied evidence: ", paste(bad, collapse = ", ")) else "citations are supplied evidence ids")
    }
  }
  fd <- do.call(rbind, unname(f))
  st <- if ("fail" %in% fd$status) "fail" else if (!any(fd$status == "pass")) "unverified"
        else if ("unverified" %in% fd$status) "partial" else "pass"
  explanation$validation <- list(
    status = st, findings = fd, n_claims = length(claims),
    note = "Consistency with computed facts only; this does not establish scientific correctness.")
  explanation
}
