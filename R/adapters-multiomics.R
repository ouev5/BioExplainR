# MultiAssayExperiment and SpatialExperiment adapters --------------------------

.adapt_multi_assay_experiment <- function(x, meta = list(), n_top = 10, ...) {
  if (!requireNamespace("MultiAssayExperiment", quietly = TRUE)) {
    ctx <- .adapt_generic(x, meta = meta)
    ctx$analysis_type <- "multi_assay"
    ctx$source_package <- "MultiAssayExperiment"
    ctx$source_status <- "verified_class"
    ctx$uncertainty <- c(ctx$uncertainty, "MultiAssayExperiment is not installed; assay/sample alignment was not inspected.")
    return(ctx)
  }
  en <- tryCatch(getExportedValue("MultiAssayExperiment", "experiments")(x), error = function(e) NULL)
  if (is.null(en)) stop("Could not read MultiAssayExperiment experiments.", call. = FALSE)
  names_en <- names(en) %||% paste0("assay", seq_along(en))
  contexts <- lapply(seq_along(en), function(i) tryCatch(bio_context(en[[i]], n_top = n_top), error = function(e) NULL))
  names(contexts) <- names_en
  child <- lapply(seq_along(en), function(i) {
    z <- contexts[[i]]
    if (is.null(z)) list(name = names_en[i], class = class(en[[i]]), error = "context_failed")
    else list(name = names_en[i], context_id = z$context_id, analysis_type = z$analysis_type,
               source_class = z$source_class, facts_hash = z$facts_hash, facts = z$facts)
  })
  cd <- tryCatch(as.data.frame(SummarizedExperiment::colData(x), stringsAsFactors = FALSE), error = function(e) NULL)
  sm <- tryCatch(as.data.frame(getExportedValue("MultiAssayExperiment", "sampleMap")(x), stringsAsFactors = FALSE), error = function(e) NULL)
  alignment <- if (!is.null(sm)) {
    names(sm)[names(sm) == "assay"] <- "modality"
    names(sm)[names(sm) == "primary"] <- "biological_unit"
    names(sm)[names(sm) == "colname"] <- "source_id"
    if (all(c("modality", "source_id", "biological_unit") %in% names(sm))) bio_sample_map(sm) else NULL
  } else NULL
  observed <- stats::setNames(lapply(en, colnames), names_en)
   alignment_check <- if (is.null(alignment)) NULL else bio_validate_sample_map(alignment, observed,
                                                                              primary_units = rownames(cd))
  facts <- list(n_modalities = length(en), modalities = names_en,
                child_contexts = child, sample_map_rows = if (is.null(sm)) NA_integer_ else nrow(sm),
                sample_map_columns = if (is.null(sm)) NULL else names(sm),
                 n_primary_units = if (is.null(cd)) NA_integer_ else nrow(cd),
                  alignment_status = if (is.null(alignment_check)) "unverified" else alignment_check$status,
                  modality_coverage = alignment_check$coverage,
                  pairwise_coverage = alignment_check$pairwise,
                  n_complete_units = alignment_check$n_complete_units,
                  n_unmeasured_units = alignment_check$n_unmeasured_units)
  unc <- c("Each modality retains a separate context; a joint context does not make modalities independently replicated.",
           if (is.null(sm)) "No sampleMap was available, so cross-modality alignment is unknown." else NULL,
           if (!is.null(alignment) && length(alignment$duplicate_keys)) "Duplicate modality/source mappings require review." else NULL)
  new_bio_context("multi_assay", class(x), "MultiAssayExperiment", "verified_class",
                  facts = facts, metadata = meta, uncertainty = unc,
                   modalities = contexts, provenance = list(sample_map = sm, alignment = alignment_check))
}

.adapt_spatial_experiment <- function(x, meta = list(), n_top = 10, ...) {
  if (!requireNamespace("SpatialExperiment", quietly = TRUE)) {
    ctx <- .adapt_generic(x, meta = meta); ctx$analysis_type <- "spatial";
    ctx$source_package <- "SpatialExperiment"; ctx$source_status <- "verified_class"
    ctx$uncertainty <- c(ctx$uncertainty, "SpatialExperiment is not installed; spatial accessors were not inspected.")
    return(ctx)
  }
  coords <- tryCatch(getExportedValue("SpatialExperiment", "spatialCoords")(x), error = function(e) NULL)
  cd <- tryCatch(as.data.frame(SummarizedExperiment::colData(x), stringsAsFactors = FALSE), error = function(e) NULL)
  img <- tryCatch(getExportedValue("SpatialExperiment", "imgData")(x), error = function(e) NULL)
  cn <- if (is.null(coords)) character() else colnames(coords)
  facts <- list(n_spots = ncol(x), n_features = nrow(x), assays = SummarizedExperiment::assayNames(x),
                coordinate_columns = cn, coordinate_units = attr(coords, "units") %||% NA_character_,
                coordinate_missing = if (is.null(coords)) NA_integer_ else sum(!stats::complete.cases(coords)),
                 coordinate_ranges = if (is.null(coords)) NULL else lapply(seq_len(ncol(coords)), function(i) {
                   v <- coords[, i]; if (any(is.finite(v))) range(v[is.finite(v)]) else c(NA_real_, NA_real_)
                 }),
                 has_image_metadata = !is.null(img) && nrow(img) > 0, colData_columns = if (is.null(cd)) NULL else names(cd))
  section <- if (!is.null(cd)) .find_col(cd, c("section_id", "section", "sample", "sample_id", "donor")) else NULL
  facts$section_column <- section
  facts$n_sections <- if (is.null(section)) NA_integer_ else length(unique(.clean_id(cd[[section]])))
  unc <- c("Spatial coordinates describe spot/cell locations; they do not by themselves define tissue coverage or biological replication.",
           if (is.null(coords)) "No spatial coordinates were available." else NULL,
           if (is.null(attr(coords, "units"))) "Coordinate units were not declared." else NULL,
            if (!facts$has_image_metadata) "No image metadata was available; image layers are not checkable.")
  new_bio_context("spatial", class(x), "SpatialExperiment", "verified_class", facts = facts,
                  metadata = meta, uncertainty = unc,
                  provenance = list(spatial_accessor = "SpatialExperiment::spatialCoords",
                                    image_metadata = !is.null(img)))
}
