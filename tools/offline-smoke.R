# Installed-package smoke; the expected numbers are hand-computable.
library(BioExplainR)
args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args)) args[1] else tempfile("bioexplainr-smoke-")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
bio_configure("local")
ctx <- bio_context(data.frame(log2FoldChange = c(2, -2, 0.1), padj = c(.01, .02, .8)),
                   scope = list(comparison_id = "treated_vs_control"))
stopifnot(ctx$facts$n_significant == 2L, ctx$facts$n_up == 1L, ctx$facts$n_down == 1L)
ex <- bio_explain(ctx, use_llm = FALSE)
ex <- bio_validate_claims(ex, list(list(id = "fixture", fact = "n_significant", value = 2L,
                                      scope = ctx$scope)))
stopifnot(ex$validation$status == "pass", identical(ex$manifest$context_id, ctx$context_id), !ex$llm_meta$used)
project <- bio_explain_project(bio_project(list(result = ex)), use_llm = FALSE)
bio_report(project, file = file.path(out, "offline-report.html"))
stopifnot(file.exists(file.path(out, "offline-report.html")))
# New alignment and relation interfaces, verified with hand-computable inputs.
map <- data.frame(modality = c("rna", "rna", "protein", "protein"),
                  source_id = c("r1", "r2", "p2", "p3"), biological_unit = c("u1", "u2", "u2", "u3"))
alignment <- bio_validate_sample_map(map, list(rna = c("r1", "r2"), protein = c("p2", "p3")),
                                     primary_units = paste0("u", 1:4))
stopifnot(alignment$status == "pass", alignment$n_complete_units == 1L,
          alignment$n_unmeasured_units == 1L, alignment$pairwise$n_shared == 1L,
          all(alignment$coverage$n_missing == 2L))
make_effect <- function(value) new_bio_context("generic", "list", "fixture", "user_declared",
  facts = list("HLA.A" = value), scope = list(dataset_id = "fixture", comparison_id = "late_vs_early",
    species = "Homo sapiens", tissue = "adrenal", sample_level = "patient"),
  design = list(numerator = "late", denominator = "early"),
  fact_descriptors = list("HLA.A" = list(feature_id = "HLA.A")))
relation <- data.frame(id = "pair1", from = "rna", to = "protein", from_fact = "HLA.A",
                       to_fact = "HLA.A", feature_id = "HLA.A", expected = "opposite")
relation$from_tokens <- relation$to_tokens <- list("HLA.A")
p <- bio_project(list(rna = make_effect(2), protein = make_effect(-1)), sample_map = map, relations = relation)
stopifnot(bio_validate_project_relations(p)$status == "pass")
wrong <- relation; wrong$expected <- "same"
stopifnot(bio_validate_project_relations(p, wrong)$status == "fail")
p <- bio_explain_project(p, use_llm = FALSE)
report <- bio_report(p, file = file.path(out, "relation-report.html"))
stopifnot(grepl("Explicit cross-result direction checks", report, fixed = TRUE))
optional <- c("DESeq2", "SingleCellExperiment", "MultiAssayExperiment", "SpatialExperiment", "shiny", "ggplot2")
jsonlite::write_json(list(status = "pass", package_version = as.character(packageVersion("BioExplainR")),
  r_version = R.version.string, libraries = .libPaths(),
  optional_available = as.list(stats::setNames(vapply(optional, requireNamespace, logical(1), quietly = TRUE), optional)),
  alignment = list(status = alignment$status, n_complete_units = alignment$n_complete_units,
                   n_unmeasured_units = alignment$n_unmeasured_units),
  relation_status = p$relation_validation$status,
  purpose = "Installed-package engineering smoke including coverage and exact-token direction relations, not a scientific result"),
  file.path(out, "smoke.json"), pretty = TRUE, auto_unbox = TRUE)
cat("Installed package: context -> typed validation -> alignment/direction project -> HTML report passed\n")
