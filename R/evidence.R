# Evidence and provenance ------------------------------------------------------------

#' Create, register and list user-supplied evidence
#'
#' Evidence objects record traceable sources (literature, database entries,
#' method documentation) that the user has checked. They are passed to the
#' model as the \emph{only} citable sources and appear in reports. Version 0.1
#' does not query databases unless asked: see \code{\link{bio_fetch_evidence}}
#' (explicit retrieval) and \code{\link{bio_register_evidence_provider}}.
#'
#' @param source Source name, e.g. \code{"PubMed"}, \code{"GO"},
#'   \code{"Reactome"}, \code{"KEGG"}, \code{"UniProt"}, \code{"DOI"}.
#' @param id Identifier within the source (PMID, DOI, GO:0006954, ...).
#' @param title Title or term name.
#' @param claim The specific statement this evidence supports.
#' @param url Optional URL.
#' @param type \code{"literature"}, \code{"database"}, \code{"method"},
#'   \code{"software"} or \code{"other"}.
#' @param version Database release / version, if known.
#' @param accessed Access date.
#' @param note Free text.
#' @param content_type Content level, such as \code{"abstract"} or
#'   \code{"database_definition"}.
#' @param scope Known species, tissue, comparison and modality scope.
#' @param role Evidence role.
#' @param content Optional saved content or excerpt used to derive a hash.
#' @param content_hash Hash of the saved evidence content.
#' @return \code{bio_evidence()} returns a \code{bio_evidence} object.
#' @export
#' @examples
#' ev <- bio_evidence("GO", id = "GO:0006954", title = "inflammatory response",
#'                    claim = "IL6 is annotated to inflammatory response",
#'                    type = "database", version = "user-checked")
#' bio_evidence_register(ev)
#' bio_evidence_list()
#' bio_evidence_clear()
bio_evidence <- function(source, id = NULL, title = NULL, claim = NULL, url = NULL,
                         type = c("literature", "database", "method", "software", "other"),
                         version = NULL, accessed = Sys.Date(), note = NULL,
                         content_type = NULL, scope = list(), role = NULL,
                         content = NULL, content_hash = NULL) {
  type <- match.arg(type)
  stopifnot(is.character(source), length(source) == 1)
  key <- paste0(source, ":", id %||% title %||% "unnamed")
  if (is.null(content_hash) && !is.null(content)) content_hash <- .sha256(.canonical_json(content))
  structure(list(id = key, source = source, source_id = id, title = title, claim = claim,
                  url = url, type = type, version = version, accessed = as.character(accessed),
                  note = note, content_type = content_type, scope = scope %||% list(),
                  role = role, content = content, content_hash = content_hash,
                  supplied_by = "user"), class = "bio_evidence")
}

#' @rdname bio_evidence
#' @param ... \code{bio_evidence} objects.
#' @export
bio_evidence_register <- function(...) {
  evs <- list(...)
  if (length(evs) == 1 && is.list(evs[[1]]) && !inherits(evs[[1]], "bio_evidence")) evs <- evs[[1]]
  for (e in evs) {
    if (!inherits(e, "bio_evidence")) stop("Only bio_evidence objects can be registered.", call. = FALSE)
    .pkg_env$evidence[[e$id]] <- e
  }
  invisible(names(.pkg_env$evidence))
}

#' @rdname bio_evidence
#' @export
bio_evidence_list <- function() unname(.pkg_env$evidence)

#' @rdname bio_evidence
#' @export
bio_evidence_clear <- function() {
  .pkg_env$evidence <- list()
  invisible(TRUE)
}

#' @export
print.bio_evidence <- function(x, ...) {
  cat("<bio_evidence> ", x$id, " [", x$type, "]", if (!is.null(x$title)) paste0(" ", x$title), "\n", sep = "")
  if (!is.null(x$claim)) cat("  claim:", x$claim, "\n")
  if (!is.null(x$url)) cat("  url:", x$url, "\n")
  invisible(x)
}

#' Register an evidence lookup provider (extension point)
#'
#' Users or extension packages can register a function that takes a query and
#' returns a list of \code{\link{bio_evidence}} objects (for example wrapping a
#' local GO annotation package or an institutional API).
#' \code{bio_evidence_lookup()} calls it and validates the result. The public
#' sources of \code{\link{bio_fetch_evidence}} (\code{"europepmc"},
#' \code{"go"}, \code{"reactome"}, \code{"kegg"}, \code{"uniprot"}) are
#' resolved by name without registration; a request happens only when you call
#' \code{bio_evidence_lookup()}, and user-registered providers take precedence.
#'
#' @param name Provider name.
#' @param fn \code{function(query, ...)} returning a list of
#'   \code{bio_evidence}.
#' @param query Query passed to the provider (e.g. gene symbols).
#' @param provider Provider name.
#' @param register Also register returned evidence for the session.
#' @param ... Passed to the provider.
#' @return \code{bio_evidence_lookup()} returns a list of \code{bio_evidence}.
#' @export
#' @examples
#' bio_register_evidence_provider("my_table", function(query, ...) {
#'   lapply(query, function(g) bio_evidence("LocalTable", id = g, claim = "user curated"))
#' })
#' bio_evidence_lookup(c("IL6"), "my_table")
bio_register_evidence_provider <- function(name, fn) {
  stopifnot(is.function(fn))
  .pkg_env$evidence_providers[[name]] <- fn
  invisible(names(.pkg_env$evidence_providers))
}

#' @rdname bio_register_evidence_provider
#' @export
bio_evidence_lookup <- function(query, provider, register = FALSE, ...) {
  fn <- .pkg_env$evidence_providers[[provider]] %||% .live_provider(provider)
  if (is.null(fn)) {
    stop("No evidence provider '", provider, "'. Built-in live sources: ",
         paste(.live_sources, collapse = ", "), "; register others with ",
         "bio_register_evidence_provider().", call. = FALSE)
  }
  res <- fn(query, ...)
  if (inherits(res, "bio_evidence")) res <- list(res)
  ok <- vapply(res, inherits, logical(1), what = "bio_evidence")
  if (!all(ok)) stop("Provider must return bio_evidence objects.", call. = FALSE)
  if (register) bio_evidence_register(res)
  res
}

#' Package provenance for reports
#'
#' Reports versions and installation sources (CRAN, Bioconductor, GitHub,
#' local) for a set of packages, from installed package metadata.
#'
#' @param packages Character vector; default: attached + loaded non-base
#'   packages.
#' @return data.frame with \code{package}, \code{version}, \code{source}.
#' @export
#' @examples
#' bio_dependency_provenance(c("jsonlite", "httr2"))
bio_dependency_provenance <- function(packages = NULL) {
  packages <- packages %||% names(.session_versions()$packages)
  rows <- lapply(packages, function(p) {
    d <- tryCatch(utils::packageDescription(p), error = function(e) NULL, warning = function(w) NULL)
    if (!is.list(d) || is.null(d$Version)) return(data.frame(package = p, version = NA_character_, source = "not installed",
                                       stringsAsFactors = FALSE))
    src <- if (!is.null(d$RemoteType)) paste0(d$RemoteType, if (!is.null(d$RemoteRepo)) paste0(":", d$RemoteUsername, "/", d$RemoteRepo))
           else if (!is.null(d$biocViews) && is.null(d$Repository)) "Bioconductor"
           else if (!is.null(d$Repository)) d$Repository
           else if (!is.null(d$Priority) && d$Priority %in% c("base", "recommended")) paste0("R (", d$Priority, ")")
           else "local/unknown"
    data.frame(package = p, version = d$Version %||% NA_character_, source = src, stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}
