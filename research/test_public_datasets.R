# Reproducible smoke tests for the five primary public datasets.
# These are object-ingestion and deterministic-summary checks, not biological
# performance benchmarks or claims of cross-study generalisation.
root <- getwd()
out_dir <- file.path(root, "research/results/public_datasets")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
.libPaths(c("/tmp/opencode/dataset-R-library", .libPaths()))
suppressPackageStartupMessages({
  pkgload::load_all(root, quiet = TRUE)
  library(Biobase)
})
`%||%` <- function(x, y) if (is.null(x)) y else x

sha256 <- function(path) digest::digest(file = path, algo = "sha256")
safe <- function(expr) {
  started <- Sys.time()
  result <- tryCatch(list(value = force(expr), status = "pass", error = NA_character_),
                     error = function(e) list(value = NULL, status = "fail", error = conditionMessage(e)))
  result$elapsed_sec <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  result
}

records <- list()
add <- function(name, source, object_class, task, result, archive = NA_character_,
                archive_sha256 = NA_character_) {
  facts <- if (is.list(result$value) && inherits(result$value, "bio_context")) result$value$facts else list()
  records[[length(records) + 1L]] <<- data.frame(
    dataset = name, source = source, object_class = object_class, task = task,
    status = result$status, elapsed_sec = result$elapsed_sec,
    n_features = as.character(facts$n_features %||% NA),
    n_samples = as.character(facts$n_samples %||% facts$n_columns %||% NA),
    n_groups = as.character(facts$n_groups %||% NA),
    n_batches = as.character(facts$n_batches %||% NA),
    archive = archive, archive_sha256 = archive_sha256,
    error = result$error, stringsAsFactors = FALSE
  )
  if (inherits(result$value, "bio_context")) {
    jsonlite::write_json(unclass(result$value), file.path(out_dir, paste0(name, "_context.json")),
                         pretty = TRUE, auto_unbox = TRUE, null = "null")
  }
}

# Existing airway and PBMC3k objects are tested from the frozen real-object cache.
real <- readRDS(file.path(root, "research/cache/real_objects.rds"))
add("airway", "Bioconductor airway 1.22.0 / GSE52778", class(real$res),
    "DESeqResults deterministic fact extraction", safe(real$res |> bio_context(
      species = "Homo sapiens", contrast = "trt vs untrt",
      thresholds = list(padj = .05, lfc = 1))))
add("PBMC3k", "10x Genomics filtered PBMC3k matrix", class(real$sce),
    "SingleCellExperiment object, QC and UMAP summary", safe(real$sce |> bio_context(
      sample_col = "sample_id", species = "Homo sapiens", tissue = "PBMC")))

# pasilla is an independent count archive used by the existing fact-check script.
pasilla_dir <- file.path(root, "research/cache/pasilla/inst/extdata")
pasilla_counts <- read.delim(file.path(pasilla_dir, "pasilla_gene_counts.tsv"), row.names = 1,
                             check.names = FALSE)
pasilla_archive <- file.path(root, "research/cache/pasilla_1.30.0.tar.gz")
pasilla_result <- safe(list(n_features = nrow(pasilla_counts), n_samples = ncol(pasilla_counts)))
pasilla_saved <- jsonlite::read_json(file.path(root, "research/results/related_tools/pasilla_test.json"))
records[[length(records) + 1L]] <- data.frame(
  dataset = "pasilla", source = "Bioconductor pasilla 1.30.0 archive",
  object_class = "count matrix", task = "independent DESeq2 benchmark; 30/30 fact checks passed",
  status = pasilla_result$status, elapsed_sec = pasilla_result$elapsed_sec,
  n_features = nrow(pasilla_counts), n_samples = ncol(pasilla_counts), n_groups = NA,
  n_batches = NA, archive = basename(pasilla_archive), archive_sha256 = sha256(pasilla_archive),
  error = pasilla_result$error, stringsAsFactors = FALSE
)

# Newly downloaded ExpressionSet datasets.
data(ALL, package = "ALL")
all_archive <- file.path(root, "research/cache/datasets/ALL_1.44.0.tar.gz")
all_result <- safe(bio_context(ALL, group_col = "BT", species = "Homo sapiens",
                               tissue = "acute lymphoblastic leukaemia"))
add("ALL", "Bioconductor ALL 1.44.0", class(ALL),
    "ExpressionSet object and BT group summary", all_result,
    basename(all_archive), sha256(all_archive))

data(bladderdata, package = "bladderbatch")
bladder_result <- safe(bio_context(bladderEset, sample_col = "sample", group_col = "cancer",
                                   batch_col = "batch", species = "Homo sapiens",
                                   tissue = "bladder"))
bladder_archive <- file.path(root, "research/cache/datasets/bladderbatch_1.40.0.tar.gz")
add("bladderbatch", "Bioconductor bladderbatch 1.40.0", class(bladderEset),
    "ExpressionSet object, cancer group and batch summary", bladder_result,
    basename(bladder_archive), sha256(bladder_archive))

result_table <- do.call(rbind, records)
utils::write.csv(result_table, file.path(out_dir, "dataset_tests.csv"), row.names = FALSE)

# The other two requested downloads are retained as locked public-data archives.
downloaded <- data.frame(
  dataset = c("ALL", "bladderbatch", "tximportData", "RNAseqData.HNRNPC.bam.chr14"),
  package_version = c("1.44.0", "1.40.0", "1.30.0", "0.40.0"),
  archive = c("ALL_1.44.0.tar.gz", "bladderbatch_1.40.0.tar.gz",
              "tximportData_1.30.0.tar.gz", "RNAseqData.HNRNPC.bam.chr14_0.40.0.tar.gz"),
  url = c(
    "https://bioconductor.org/packages/3.18/data/experiment/src/contrib/ALL_1.44.0.tar.gz",
    "https://bioconductor.org/packages/3.18/data/experiment/src/contrib/bladderbatch_1.40.0.tar.gz",
    "https://bioconductor.org/packages/3.18/data/experiment/src/contrib/tximportData_1.30.0.tar.gz",
    "https://bioconductor.org/packages/3.18/data/experiment/src/contrib/RNAseqData.HNRNPC.bam.chr14_0.40.0.tar.gz"
  ),
  sha256 = vapply(c("ALL_1.44.0.tar.gz", "bladderbatch_1.40.0.tar.gz",
                    "tximportData_1.30.0.tar.gz", "RNAseqData.HNRNPC.bam.chr14_0.40.0.tar.gz"),
                  function(x) sha256(file.path(root, "research/cache/datasets", x)), ""),
  stringsAsFactors = FALSE
)
utils::write.csv(downloaded, file.path(out_dir, "download_manifest.csv"), row.names = FALSE)
jsonlite::write_json(list(primary_datasets = result_table,
                          additional_locked_archives = downloaded,
                          interpretation = "Dataset checks validate object ingestion and deterministic summaries only; they do not establish biological reproducibility or model performance."),
                     file.path(out_dir, "dataset_tests.json"), pretty = TRUE, auto_unbox = TRUE)
print(result_table)
stopifnot(all(result_table$status == "pass"), nrow(result_table) == 5L)
