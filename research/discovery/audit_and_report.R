# Independent R recomputation and BioExplainR object-to-report workflow.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Supply an existing discovery run directory")
out <- args[1]
if (file.exists(file.path(out, "r_audit.json"))) stop("Audit output already exists")
pkgload::load_all(".", quiet = TRUE)
measurements <- read.csv(file.path(out, "gene_measurements.csv"))
results <- read.csv(file.path(out, "validation_results.csv"))
candidate <- read.csv(file.path(out, "candidate.csv"))
control <- measurements$value[measurements$group == "untreated"]
audit <- lapply(seq_len(nrow(results)), function(i) {
  group <- if (results$role[i] == "primary") "dex24h" else "dex4h"
  treated <- measurements$value[measurements$group == group]
  test <- stats::t.test(treated, control, paired = FALSE, var.equal = FALSE)
  effect <- mean(treated) - mean(control)
  pooled <- c(treated, control)
  differences <- apply(utils::combn(seq_along(pooled), length(treated)), 2, function(ix) {
    mean(pooled[ix]) - mean(pooled[-ix])
  })
  perm <- mean(abs(differences) >= abs(effect) - 1e-12)
  actual <- c(effect = effect, pvalue = test$p.value, ci_low = test$conf.int[1],
              ci_high = test$conf.int[2], permutation_p = perm)
  expected <- unlist(results[i, names(actual)], use.names = TRUE)
  stopifnot(isTRUE(all.equal(actual, expected, tolerance = 1e-10)))
  data.frame(comparison = results$comparison[i], fact = names(actual),
             actual = actual, expected = expected, row.names = NULL)
})
checks <- do.call(rbind, audit)
stopifnot(isTRUE(all.equal(stats::p.adjust(results$pvalue, "holm"),
                         results$holm_two_timepoints, tolerance = 1e-10)))
write.csv(checks, file.path(out, "r_numeric_checks.csv"), row.names = FALSE)

# Each dataset retains its own scope, effect units and independent-unit meaning.
source_table <- read.csv("research/results/paper_cn_cases_v1/airway_de.csv", row.names = 1)
discovery <- bio_context(source_table, analysis_type = "differential_expression",
  species = "Homo sapiens", tissue = "airway smooth muscle", contrast = "trt vs untrt",
  thresholds = list(padj = .05, lfc = 1))
discovery$scope$dataset_id <- "GSE52778"
discovery$scope$comparison_id <- "dex_vs_untreated"
discovery$scope$sample_level <- "donor"
discovery$design <- list(numerator = "trt", denominator = "untrt", independent_units = 4L,
                         unit_type = "donor", formula = "~ cell + dex")
discovery$facts$candidate <- list(feature_id = candidate$feature_id, symbol = candidate$symbol,
                                 log2fc = candidate$log2FoldChange, padj = candidate$padj)
external <- bio_context(measurements, analysis_type = "generic",
  species = "Homo sapiens", tissue = "airway smooth muscle")
external$scope$dataset_id <- "GSE34313"
external$scope$comparison_id <- "dex24h_vs_untreated"
external$scope$sample_level <- "culture_replicate"
external$design <- list(numerator = "dex24h", denominator = "untreated",
                        n_treated = 3L, n_control = 4L, donor_count = 1L,
                        unit_type = "culture replicate in HASM1; not distinct donors")
external$facts$candidate_validation <- list(symbol = "SPARCL1", effect = results$effect[1],
  unit = "published processed-expression unit", pvalue = results$pvalue[1],
  ci_low = results$ci_low[1], ci_high = results$ci_high[1],
  permutation_p = results$permutation_p[1], supported = results$effect[1] > 0 && results$pvalue[1] < .05)
external$uncertainties <- c(external$uncertainties,
  "External experiment uses one HASM cell line; arrays are not independent donors.",
  "Processed expression units retained without re-normalization; no causal or clinical validation.",
  "Different GEO accessions do not alone establish absence of donor overlap.")
project <- bio_project(list(discovery = discovery, external_validation = external),
  dependencies = list(external_validation = "discovery"))
project <- bio_explain_project(project, use_llm = FALSE, language = "zh")
saveRDS(discovery, file.path(out, "discovery_context.rds"))
saveRDS(external, file.path(out, "external_context.rds"))
saveRDS(project, file.path(out, "project.rds"))
bio_report(project, file = file.path(out, "report_zh.html"), language = "zh")
bio_report(project, file = file.path(out, "report_en.html"), language = "en")
jsonlite::write_json(list(status = "pass", numeric_checks = nrow(checks), holm_checks = 2L,
  package_version = as.character(utils::packageVersion("BioExplainR")),
  independent_implementation = "R stats::t.test and combn vs Python SciPy and itertools",
  biological_validation_scope = "External single-cell-line experiment; no independent donor cohort",
  online_model_calls = 0L), file.path(out, "r_audit.json"), pretty = TRUE, auto_unbox = TRUE)
writeLines(capture.output(sessionInfo()), file.path(out, "sessionInfo.txt"))
files <- list.files(out, full.names = TRUE)
jsonlite::write_json(list(files = lapply(files, function(f) list(path = basename(f),
  bytes = unname(file.info(f)$size), sha256 = digest::digest(file = f, algo = "sha256")))),
  file.path(out, "manifest.json"), pretty = TRUE, auto_unbox = TRUE)
print(checks)
