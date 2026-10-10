# Explicit sample and feature alignment contracts --------------------------------

.sample_map_required <- c("modality", "source_id", "biological_unit")

#' Create and validate a cross-modality sample map
#'
#' @param map Data frame with one row per modality-to-source mapping.
#' @param modality,source_id,biological_unit Optional column names when the
#'   input uses non-standard names.
#' @param allow_technical_replicates Whether repeated source IDs are allowed
#'   when their replicate_role is technical.
#' @return A \code{bio_sample_map} object.
#' @export
bio_sample_map <- function(map, modality = "modality", source_id = "source_id",
                           biological_unit = "biological_unit", allow_technical_replicates = TRUE) {
  if (!is.data.frame(map)) stop("map must be a data.frame.", call. = FALSE)
  if (!is.logical(allow_technical_replicates) || length(allow_technical_replicates) != 1L || is.na(allow_technical_replicates))
    stop("allow_technical_replicates must be TRUE or FALSE.", call. = FALSE)
  cols <- c(modality, source_id, biological_unit)
  if (any(!cols %in% names(map))) stop("sample map is missing required columns: ",
    paste(setdiff(cols, names(map)), collapse = ", "), call. = FALSE)
  out <- map
  names(out)[match(cols, names(out))] <- .sample_map_required
  if (anyNA(out$modality) || any(!nzchar(as.character(out$modality))) ||
      anyNA(out$source_id) || any(!nzchar(as.character(out$source_id))))
    stop("sample map modality and source_id must be non-missing.", call. = FALSE)
  if (anyNA(out$biological_unit) || any(!nzchar(as.character(out$biological_unit))))
    stop("sample map biological_unit must be non-missing.", call. = FALSE)
  if (!"replicate_role" %in% names(out)) out$replicate_role <- "biological"
  out$replicate_role <- as.character(out$replicate_role)
  valid_roles <- c("biological", "technical", "unknown")
  if (any(!out$replicate_role %in% valid_roles)) stop("replicate_role has unknown values.", call. = FALSE)
  key <- paste(out$modality, out$source_id, sep = "\r")
  duplicates <- unique(key[duplicated(key)])
  if (length(duplicates)) {
    is_technical <- tapply(out$replicate_role, key, function(x) all(x == "technical"))
    same_unit <- tapply(as.character(out$biological_unit), key, function(x) length(unique(x)) == 1L)
    bad <- duplicates[!is_technical[duplicates] | !same_unit[duplicates]]
    if (!allow_technical_replicates || length(bad))
      stop("duplicate modality/source_id mappings are ambiguous.", call. = FALSE)
  }
  ambiguous <- if (length(duplicates)) {
    technical <- tapply(out$replicate_role, key, function(x) all(x == "technical"))
    duplicates[!vapply(duplicates, function(k) isTRUE(technical[[k]]), logical(1))]
  } else character()
  structure(list(map = out, duplicate_keys = duplicates, ambiguous_duplicate_keys = ambiguous,
                 matched_units = unique(out$biological_unit),
                 missing_modalities = character(), exclusions = data.frame()),
            class = "bio_sample_map")
}

#' Validate two modality tables against an explicit sample map
#'
#' @param map A \code{bio_sample_map} or data frame.
#' @param observed Optional named list of IDs observed in each modality.
#' @param primary_units Optional complete set of biological unit IDs, including
#'   units without any measured modality. IDs remain in the local alignment only.
#' @return A sample alignment result with findings.
#' @export
bio_validate_sample_map <- function(map, observed = NULL, primary_units = NULL) {
  sm <- bio_sample_map(if (inherits(map, "bio_sample_map")) map$map else map)
  f <- data.frame(check = character(), status = character(), detail = character(), stringsAsFactors = FALSE)
  add <- function(check, status, detail) f <<- rbind(f, data.frame(check = check, status = status, detail = detail, stringsAsFactors = FALSE))
  add("required_columns", "pass", "modality, source_id and biological_unit are present")
  if (length(sm$ambiguous_duplicate_keys)) add("duplicate_mapping", "fail", paste(sm$ambiguous_duplicate_keys, collapse = ", "))
  else if (length(sm$duplicate_keys)) add("duplicate_mapping", "pass", "technical replicate mappings are explicitly marked")
  else add("duplicate_mapping", "pass", "no ambiguous modality/source mappings")
  if (!is.null(observed)) {
    if (!is.list(observed) || is.null(names(observed)) || anyNA(names(observed)) ||
        any(!nzchar(names(observed))) || anyDuplicated(names(observed)))
      stop("observed must be a uniquely named list.", call. = FALSE)
    if (any(vapply(observed, function(x) !is.atomic(x) || anyNA(x) ||
                   any(!nzchar(as.character(x))) || anyDuplicated(x) > 0L, logical(1))))
      stop("observed IDs must be unique and non-missing within each modality.", call. = FALSE)
    for (m in union(names(observed), unique(as.character(sm$map$modality)))) {
      present <- unique(as.character(observed[[m]]))
      mapped <- unique(as.character(sm$map$source_id[sm$map$modality == m]))
      add(paste0("observed_", m), if (setequal(present, mapped)) "pass" else "partial",
          paste0("observed=", length(present), "; mapped=", length(mapped),
                 "; missing=", length(setdiff(present, mapped)), "; extra=", length(setdiff(mapped, present))))
    }
  }
  units <- if (is.null(primary_units)) unique(as.character(sm$map$biological_unit)) else as.character(primary_units)
  if (anyNA(units) || any(!nzchar(units)) || anyDuplicated(units))
    stop("primary_units must be unique and non-missing.", call. = FALSE)
  outside <- setdiff(as.character(sm$map$biological_unit), units)
  if (length(outside)) add("primary_membership", "fail", paste(length(outside), "mapped units are absent from primary_units"))
  modalities <- union(unique(as.character(sm$map$modality)), names(observed))
  present <- stats::setNames(lapply(modalities, function(m) {
    rows <- sm$map$modality == m
    if (!is.null(observed)) rows <- rows & sm$map$source_id %in% observed[[m]]
    intersect(units, as.character(sm$map$biological_unit[rows]))
  }), modalities)
  coverage <- data.frame(modality = modalities,
                         n_units = as.integer(lengths(present)),
                         n_missing = as.integer(length(units) - lengths(present)),
                         stringsAsFactors = FALSE)
  pairs <- data.frame(from = character(), to = character(), n_shared = integer(),
                      n_from_only = integer(), n_to_only = integer(), stringsAsFactors = FALSE)
  if (length(modalities) > 1L) for (ij in utils::combn(modalities, 2, simplify = FALSE)) {
    a <- present[[ij[1]]]; b <- present[[ij[2]]]
    pairs <- rbind(pairs, data.frame(from = ij[1], to = ij[2], n_shared = length(intersect(a, b)),
                                    n_from_only = length(setdiff(a, b)), n_to_only = length(setdiff(b, a))))
  }
  complete <- if (length(present)) Reduce(intersect, present) else character()
  unmeasured <- setdiff(units, unique(unlist(present, use.names = FALSE)))
  structure(list(status = if (any(f$status == "fail")) "fail" else if (any(f$status == "partial")) "partial" else "pass",
                 map = sm, findings = f, coverage = coverage, pairwise = pairs,
                 n_primary_units = length(units), n_complete_units = length(complete),
                 n_unmeasured_units = length(unmeasured),
                 coverage_basis = if (is.null(observed)) "declared_map" else "observed_ids",
                 complete_units = complete, unmeasured_units = unmeasured), class = "bio_sample_alignment")
}

#' @export
print.bio_sample_map <- function(x, ...) {
  cat("<bio_sample_map> ", nrow(x$map), " mappings; ", length(x$matched_units), " biological units\n", sep = "")
  invisible(x)
}
