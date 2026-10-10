# Run a version-aware compatibility matrix over the installed upstream objects.
# Missing package versions are recorded as not_installed; this script never
# labels an uninstalled version as compatible and never claims a full matrix.
suppressPackageStartupMessages(library(BioExplainR))
library(jsonlite)
`%||%` <- function(x, y) if (is.null(x)) y else x
dir.create("research/results/compatibility_matrix", recursive = TRUE, showWarnings = FALSE)
targets <- list(
  list(package = "DESeq2", version_slot = "installed", object = "DESeqResults", check = function(d) bio_context(d$res)),
  list(package = "limma", version_slot = "installed", object = "MArrayLM", check = function(d) bio_context(d$limma_fit, coefficient = "dextrt")),
  list(package = "edgeR", version_slot = "installed", object = "TopTags", check = function(d) bio_context(d$edger_top)),
  list(package = "SummarizedExperiment", version_slot = "installed", object = "RangedSummarizedExperiment", check = function(d) bio_context(d$airway)),
  list(package = "SingleCellExperiment", version_slot = "installed", object = "SingleCellExperiment", check = function(d) bio_context(d$sce)),
  list(package = "SeuratObject", version_slot = "installed", object = "Seurat", check = function(d) bio_context(d$seurat)),
  list(package = "ggplot2", version_slot = "installed", object = "ggplot", check = function(d) bio_context(d$pca)),
  list(package = "uwot", version_slot = "installed", object = "UMAP", check = function(d) bio_context(d$embedding))
)
d <- readRDS("research/cache/real_objects.rds")
saved <- if (file.exists("research/results/compatibility.json")) {
  read_json("research/results/compatibility.json", simplifyVector = FALSE)
} else list()
rows <- lapply(targets, function(target) {
  installed <- requireNamespace(target$package, quietly = TRUE)
  version <- if (installed) as.character(packageVersion(target$package)) else NA_character_
  result <- if (!installed) NULL else if (target$package %in% names(saved)) saved[[target$package]] else {
    tryCatch(target$check(d), error = function(e) e)
  }
  saved_result <- target$package %in% names(saved)
  result_status <- if (!installed) "not_installed" else if (saved_result) {
    if (identical(result$status, "verified_class")) "pass" else "fail"
  } else if (inherits(result, "error")) "fail" else "pass"
  data.frame(package = target$package, version_slot = target$version_slot, installed = installed,
             version = version, object = target$object,
             status = result_status,
             detail = if (!installed) "package unavailable" else if (saved_result) "saved deterministic compatibility result" else if (inherits(result, "error")) conditionMessage(result) else result$analysis_type %||% "context_created",
             stringsAsFactors = FALSE)
})
matrix <- do.call(rbind, rows)
write.csv(matrix, "research/results/compatibility_matrix/compatibility_matrix.csv", row.names = FALSE)
write_json(list(date_utc = format(Sys.time(), tz = "UTC", usetz = TRUE), scope = "installed packages only; not a full upstream version matrix",
                rows = matrix), "research/results/compatibility_matrix/compatibility_matrix.json", pretty = TRUE, auto_unbox = TRUE)
print(matrix)
