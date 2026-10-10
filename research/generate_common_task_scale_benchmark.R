# Generate a reproducible, package-derived scale benchmark for the common-task
# protocol.  This is a protocol/serialization stress test, not new biological
# evidence or a model generalization study.
suppressPackageStartupMessages({
  library(BioExplainR)
  library(jsonlite)
})

root <- getwd()
out <- Sys.getenv("BIOEXPLAINR_SCALE_FACTS", file.path(root, "research/results/reference_facts_scale_480.json"))
dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)

facts <- list()
add_case <- function(prefix, index, values) {
  name <- sprintf("%s_%03d", prefix, index)
  stopifnot(length(values) == 4L, !is.null(names(values)), all(nzchar(names(values))))
  facts[[name]] <<- values
}

# Differential-expression contexts: use the package's own deterministic
# adapter to calculate the four target values from each generated table.
for (i in seq_len(30L)) {
  n <- 40L + i
  de <- data.frame(
    log2FoldChange = rep(c(2 + i / 100, -1.5 - i / 200, 0.2), length.out = n),
    padj = rep(c(0.001 + i / 100000, 0.02 + i / 100000, 0.8), length.out = n),
    row.names = paste0("gene", seq_len(n))
  )
  ctx <- bio_context(de, thresholds = list(padj = 0.05, lfc = 1))
  add_case("de", i, list(
    n_features = unname(ctx$facts$n_features),
    n_significant = unname(ctx$facts$n_significant),
    n_up = unname(ctx$facts$n_up),
    n_down = unname(ctx$facts$n_down)
  ))
}

# Enrichment-like tables: the enrichment adapter records term counts and the
# number passing the supplied adjusted-p threshold.
for (i in seq_len(20L)) {
  n <- 12L + i
  tab <- data.frame(
    ID = paste0("TERM", seq_len(n)),
    Description = paste("Term", seq_len(n)),
    GeneRatio = paste0((seq_len(n) %% 7L) + 1L, "/20"),
    Count = (seq_len(n) %% 7L) + 1L,
    p.adjust = ((seq_len(n) %% (5L + i %% 4L)) + 1L) / 100
  )
  ctx <- bio_context(tab, analysis_type = "enrichment_ora", thresholds = list(padj = 0.05))
  add_case("enrichment", i, list(
    n_terms = unname(ctx$facts$n_terms),
    n_significant = unname(ctx$facts$n_significant),
    enrichment_method = unname(ctx$facts$enrichment_method),
    significance_threshold = unname(ctx$facts$significance_threshold)
  ))
}

# PCA contexts: the target values are computed from each deterministic
# prcomp object and retain enough digits to expose premature rounding.
for (i in seq_len(20L)) {
  set.seed(1000L + i)
  x <- matrix(rnorm((8L + i %% 5L) * (12L + i)), nrow = 8L + i %% 5L)
  fit <- prcomp(x, center = TRUE, scale. = FALSE)
  ctx <- bio_context(fit)
  ve <- fit$sdev^2 / sum(fit$sdev^2)
  add_case("pca", i, list(
    n_observations = unname(ctx$facts$n_observations),
    n_variables = unname(ctx$facts$n_variables),
    variance_explained_1 = unname(ve[1]),
    variance_explained_2 = unname(ve[2])
  ))
}

# Single-cell objects: use real SCE construction when the optional dependency is
# available; otherwise the deterministic values still document the intended
# object contract and this script fails loudly rather than silently changing it.
if (!requireNamespace("SingleCellExperiment", quietly = TRUE) ||
    !requireNamespace("S4Vectors", quietly = TRUE)) {
  stop("The scale benchmark requires SingleCellExperiment and S4Vectors.", call. = FALSE)
}
for (i in seq_len(20L)) {
  n_features <- 25L + i
  n_cells <- 30L + i * 2L
  counts <- matrix((seq_len(n_features * n_cells) + i) %% 11L,
                   nrow = n_features, ncol = n_cells,
                   dimnames = list(paste0("g", seq_len(n_features)), paste0("c", seq_len(n_cells))))
  sce <- SingleCellExperiment::SingleCellExperiment(
    assays = list(counts = counts),
    colData = S4Vectors::DataFrame(sample_id = rep(paste0("s", seq_len(1L + i %% 3L)),
                                                   length.out = n_cells))
  )
  ctx <- bio_context(sce, sample_col = "sample_id")
  add_case("single_cell", i, list(
    n_cells = unname(ctx$facts$n_cells),
    n_features = unname(ctx$facts$n_features),
    n_samples = unname(ctx$facts$n_samples),
    assay_name = "counts"
  ))
}

# Cell-composition contexts: these exercise the sample-level composition
# adapter, including its explicit sample count and cluster count facts.
for (i in seq_len(15L)) {
  n_samples <- 4L + i %% 4L
  n_cells <- n_samples * (18L + i)
  md <- data.frame(
    sample = rep(paste0("sample", seq_len(n_samples)), each = 18L + i),
    cluster = rep(paste0("cluster", seq_len(2L + i %% 3L)), length.out = n_cells),
    group = rep(rep(c("control", "treated"), length.out = n_samples), each = 18L + i),
    stringsAsFactors = FALSE
  )
  cp <- bio_cell_proportions(md, sample_col = "sample", cluster_col = "cluster", group_col = "group")
  ctx <- bio_context(cp)
  add_case("cell_composition", i, list(
    n_samples = unname(ctx$facts$n_samples),
    n_clusters = unname(ctx$facts$n_clusters),
    n_cells_used = unname(ctx$facts$n_cells_used),
    analysis_type = "cell_composition"
  ))
}

# Generic/plot-like summaries: these are deliberately simple scalar contracts
# and cover the generic object and plotting metadata paths without requiring
# visual interpretation by the model.
for (i in seq_len(15L)) {
  n_rows <- 10L + i
  n_cols <- 3L + i %% 5L
  tab <- data.frame(matrix(seq_len(n_rows * n_cols), nrow = n_rows, ncol = n_cols))
  names(tab) <- paste0("value", seq_len(n_cols))
  ctx <- bio_context(tab, analysis_type = "generic")
  add_case("generic", i, list(
    n_rows = nrow(tab),
    n_columns = ncol(tab),
    first_column = names(tab)[1],
    analysis_type = unname(ctx$analysis_type)
  ))
}

stopifnot(length(facts) == 120L, sum(vapply(facts, length, integer(1))) == 480L)
write_json(facts, out, pretty = TRUE, auto_unbox = TRUE, digits = 15, null = "null")
manifest <- list(
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  purpose = "Protocol and serialization scale benchmark; not independent biological evidence.",
  n_cases = length(facts),
  n_facts = sum(vapply(facts, length, integer(1))),
  case_families = as.list(table(sub("_[0-9]+$", "", names(facts)))),
  facts_file = normalizePath(out, mustWork = FALSE),
  seed_policy = "PCA cases use seeds 1001 through 1020; other cases are deterministic.",
  package = "BioExplainR"
)
write_json(manifest, file.path(dirname(out), "reference_facts_scale_480_manifest.json"),
           pretty = TRUE, auto_unbox = TRUE)
cat(sprintf("Generated %d cases and %d target facts at %s\n", length(facts),
            sum(vapply(facts, length, integer(1))), out))
