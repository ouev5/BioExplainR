# Paper revision: real-source rechecks and controlled failure cases, no model calls.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L || file.exists(args[1])) stop("Supply a new output directory")
pkgload::load_all(".", quiet = TRUE)
out <- args[1]
dir.create(out, recursive = TRUE)
write_csv <- function(x, name) utils::write.csv(x, file.path(out, name), row.names = FALSE, na = "")
write_json <- function(x, name) jsonlite::write_json(x, file.path(out, name), auto_unbox = TRUE,
  pretty = TRUE, digits = 17, null = "null", na = "null")
checks <- data.frame(case = character(), source = character(), purpose = character(), expected = character(), actual = character())
add <- function(case, source, purpose, expected, actual) {
  checks <<- rbind(checks, data.frame(case, source, purpose, expected, actual))
}
started <- format(Sys.time(), tz = "UTC", usetz = TRUE)
x <- readRDS("research/cache/real_objects.rds")
thresholds <- expand.grid(padj = c(.01, .05, .1), lfc = c(0, 1, 2))
threshold_rows <- do.call(rbind, lapply(seq_len(nrow(thresholds)), function(i) {
  a <- thresholds$padj[i]; b <- thresholds$lfc[i]
  ctx <- bio_context(x$res, thresholds = list(padj = a, lfc = b))
  tab <- x$tab
  sig <- !is.na(tab$padj) & tab$padj < a & !is.na(tab$log2FoldChange) & abs(tab$log2FoldChange) > b
  expected <- c(n_features = nrow(tab), n_significant = sum(sig),
    n_up = sum(sig & tab$log2FoldChange > 0), n_down = sum(sig & tab$log2FoldChange < 0),
    n_na_padj = sum(is.na(tab$padj)))
  actual <- unlist(ctx$facts[names(expected)])
  data.frame(padj = a, lfc = b, fact = names(expected), expected = expected, actual = actual,
             pass = as.numeric(expected) == as.numeric(actual), row.names = NULL)
}))
write_csv(threshold_rows, "airway_threshold_checks.csv")
add("airway_nine_thresholds", "airway stored DESeqResults", "full-table counts / 45 numeric facts", "pass",
    if (all(threshold_rows$pass)) "pass" else "fail")
write_csv(data.frame(feature_id = rownames(x$tab), x$tab), "airway_de.csv")
write_csv(data.frame(sample_code = seq_len(nrow(x$fit$x)), x$fit$x[, 1:2],
                    treatment = x$metadata$dex, donor_code = match(x$metadata$cell, unique(x$metadata$cell))), "airway_pca.csv")
write_csv(data.frame(component = seq_along(x$fit$sdev), variance = x$fit$sdev^2 / sum(x$fit$sdev^2)), "airway_variance.csv")
write_csv(x$ora[, c("ID", "Description", "GeneRatio", "Count", "p.adjust")], "airway_ora.csv")
emb <- SingleCellExperiment::reducedDim(x$sce, "UMAP")
md <- as.data.frame(SummarizedExperiment::colData(x$sce))
write_csv(data.frame(UMAP1 = emb[, 1], UMAP2 = emb[, 2], md[, c("nCount_RNA", "nFeature_RNA", "percent.mt", "mito_qc")]), "pbmc_embedding_qc.csv")
sce <- bio_context(x$sce, sample_col = "sample_id")
add("pbmc_independent_unit", "PBMC3k stored SCE", "2700 cells remain one donor", "pass",
    if (sce$facts$n_cells == 2700 && sce$facts$n_samples == 1) "pass" else "fail")
plot <- bio_plot_pca(x$expression, metadata = x$metadata, group = "dex", n_top_features = 500)
add("airway_correct_pca", "airway stored VST", "source and generated coordinates", "pass", bio_cross_check(plot, x$expression)$status)
bad <- plot; bad$data$PC1[1] <- bad$data$PC1[1] + 5
add("airway_injected_pca_coordinate", "airway controlled mutation", "detect coordinate drift", "fail", bio_cross_check(bad, x$expression)$status)
bad <- plot + ggplot2::labs(x = "PC1 (99.9%)")
add("airway_injected_pca_label", "airway controlled mutation", "detect wrong variance label", "fail", bio_cross_check(bad, x$expression)$status)
raw <- data.frame(log2FoldChange = c(2, -2, .2), pvalue = c(.001, .01, .8))
ctx <- bio_context(raw)
add("raw_p_not_adjusted", "hand-computable fixture", "raw-only state is not adjusted significance", "pass",
    if (is.null(ctx$facts$n_significant) || is.na(ctx$facts$n_significant)) "pass" else "fail")
ctx <- bio_context(x$res)
failed <- tryCatch({ bio_context_payload(ctx, policy = bio_payload_policy(max_chars = 20)); FALSE }, error = function(e) TRUE)
add("payload_budget_rejects", "airway stored DESeqResults", "complete facts fail explicitly when over budget", "pass", if (failed) "pass" else "fail")
map <- data.frame(modality = c("rna", "rna", "protein"), source_id = c("r1", "r2", "p1"), biological_unit = c("u1", "u2", "u1"))
a <- bio_validate_sample_map(map, list(rna = c("r1", "r2"), protein = "p1"), primary_units = c("u1", "u2", "u3"))
add("valid_map_incomplete_coverage", "hand-computable fixture", "valid map with 1 complete / 1 unmeasured of 3", "pass",
    if (a$status == "pass" && a$n_complete_units == 1 && a$n_unmeasured_units == 1) "pass" else "fail")
a <- bio_validate_sample_map(map, list(rna = c("r1", "r2", "r3"), protein = "p1"))
add("missing_observed_mapping", "hand-computable fixture", "observed-but-unmapped sample is partial", "partial", a$status)
map$biological_unit[2] <- "u4"
a <- bio_validate_sample_map(map, primary_units = c("u1", "u2", "u3"))
add("mapped_unit_outside_cohort", "hand-computable fixture", "reject mapping outside complete denominator", "fail", a$status)
p <- readRDS("research/results/miniacc_installed_review/project.rds")
r <- p$relations[1, , drop = FALSE]
tab <- utils::read.csv("research/results/miniacc_installed_review/feature_results.csv")
r$expected <- tab$direction[match(r$feature_id, tab$feature_id)]
add("miniacc_observed_relation", "miniACC stored project", "explicit effect relation matches observed sign", "pass", bio_validate_project_relations(p, r)$status)
r$expected <- if (r$expected == "same") "opposite" else "same"
add("miniacc_wrong_relation", "miniACC controlled mutation", "reject incorrect relation", "fail", bio_validate_project_relations(p, r)$status)
r$expected <- tab$direction[match(r$feature_id, tab$feature_id)]
p$items$protein$design$numerator <- "early"; p$items$protein$design$denominator <- "late"
add("miniacc_reversed_comparison", "miniACC controlled mutation", "reject reversed numerator / denominator", "fail", bio_validate_project_relations(p, r)$status)
p <- readRDS("research/results/miniacc_installed_review/project.rds")
p$items$protein$scope$comparison_id <- NULL
z <- bio_validate_project_relations(p, r)
add("miniacc_missing_comparison_scope", "miniACC controlled mutation", "missing scientific scope remains unverified", "unverified", z$findings$status[z$findings$check == "direction"])
input <- list(language = "zh", use_llm = FALSE)
p <- readRDS("research/results/miniacc_installed_review/project.rds")
ans <- BioExplainR:::.bio_app_explain(p, input, config = bio_config("local"))
add("workbench_project_dispatch", "miniACC stored project", "workbench preserves project and coverage", "pass",
    if (inherits(ans, "bio_project") && ans$sample_map$n_complete_units == 43) "pass" else "fail")
bio_report(ans, file = file.path(out, "miniacc_workbench_report.html"), language = "zh")
write_csv(checks, "scenario_checks.csv")
stopifnot(all(checks$expected == checks$actual))
writeLines(capture.output(sessionInfo()), file.path(out, "sessionInfo.txt"))
write_json(list(status = "pass", package_version = as.character(utils::packageVersion("BioExplainR")),
  scenarios = nrow(checks), passed = sum(checks$expected == checks$actual), airway_numeric_facts = nrow(threshold_rows),
  scope = "Development scenarios; saved public objects rechecked, controlled mutations explicitly labelled",
  online_model_calls = 0, started_utc = started, finished_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)), "summary.json")
files <- list.files(out, full.names = TRUE)
write_json(list(files = lapply(files, function(f) list(path = basename(f), bytes = unname(file.info(f)$size),
  sha256 = digest::digest(file = f, algo = "sha256")))), "manifest.json")
print(checks)
