# Manuscript integration of saved biological results through actual package APIs.
# This is a reproducible application, not a new statistical fit or held-out benchmark.
args <- commandArgs(TRUE)
out <- if (length(args)) args[1] else "research/results/package_discovery_workflow_v1"
if (dir.exists(out)) stop("Refusing to overwrite workflow results")
pkgload::load_all(".", quiet = TRUE)
dir.create(out, recursive = TRUE)
read <- function(path) read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
paths <- c(
  response = "research/results/discovery_stable_response_v1/response_full_results.csv",
  interactions = "research/results/discovery_genome_v2/genome_screen.csv",
  adult = "research/results/discovery_set_validation_v1/tpm_results.csv",
  intracellular = "research/results/discovery_set_validation_v1/unselected_protein/results.csv",
  secretome = "research/results/discovery_secretome_v1/candidate_results.csv",
  epithelial = "research/results/discovery_epithelial_protein_v1/complete/candidate_results.csv")
jsonlite::write_json(list(
  utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  inputs = lapply(paths, function(p) list(path = p, sha256 = digest::digest(file = p, algo = "sha256"))),
  source_sha256 = digest::digest(file = "research/paper_cn_revision/package_discovery_workflow.R", algo = "sha256"),
  scope = "Saved statistical outputs; actual package context/claim/report application; no new biological sample or statistical fit",
  package_version = as.character(packageVersion("BioExplainR")), online_model_calls = 0L),
  file.path(out, "input_manifest.json"), auto_unbox = TRUE, pretty = TRUE)
items <- list()
checks <- list()
claims <- list()
add <- function(name, r, ids, effects, p, padj, dataset, tissue, unit, n, scale, limitation, lfc = 0) {
  table <- data.frame(gene = ids, log2FoldChange = effects, pvalue = p, padj = padj)
  ctx <- bio_context(table, analysis_type = "differential_expression",
    source_package = "Saved upstream statistical results; declared effect scale",
    species = "Homo sapiens", tissue = tissue, contrast = name,
    design = list(unit_type = unit, independent_units = n),
    scope = list(dataset_id = dataset, comparison_id = name, sample_level = unit),
    thresholds = list(padj = .05, lfc = lfc), p_adjust_method = NULL, language = "zh")
  expected <- sum(is.finite(effects) & padj < .05 & abs(effects) > lfc)
  stopifnot(ctx$facts$n_features == nrow(r), ctx$facts$n_significant == expected)
  ctx$facts$endpoint_scale <- scale
  ctx$facts$study_limitations <- limitation
  ctx$uncertainty <- c(ctx$uncertainty, limitation,
    "Package adapter uses a generic effect column; effect is interpreted only in the declared scale. Missing effects are not zero responses.")
  ex <- bio_explain(ctx, use_llm = FALSE, language = "zh")
  for (field in c("n_features", "n_significant", "n_up", "n_down")) {
    cl <- list(id = paste(name, field, sep = ":"), claim_type = "statistical_fact",
      fact = field, value = ctx$facts[[field]], scope = ctx$scope, origin = "user")
    correct <- bio_validate_claims(ex, claims = list(cl))
    stopifnot(correct$validation$status == "pass")
    claims[[length(claims) + 1L]] <<- data.frame(context = name, challenge = field,
      expected = "pass", observed = correct$validation$status, value = as.character(cl$value))
  }
  for (kind in c("wrong_count", "wrong_dataset", "unsupported_causality")) {
    cl <- list(id = paste(name, kind, sep = ":"), claim_type = "statistical_fact",
      fact = "n_significant", value = ctx$facts$n_significant, scope = ctx$scope, origin = "user")
    if (kind == "wrong_count") cl$value <- cl$value + 1L
    if (kind == "wrong_dataset") cl$scope$dataset_id <- "incorrect_source"
    if (kind == "unsupported_causality") cl$claim_type <- "causal"
    result <- bio_validate_claims(ex, claims = list(cl))
    expected_status <- if (kind == "unsupported_causality") "partial" else "fail"
    stopifnot(result$validation$status == expected_status)
    if (kind == "unsupported_causality") stopifnot(any(
      result$validation$typed_findings$check == "causal_design" &
      result$validation$typed_findings$status == "unverified"))
    claims[[length(claims) + 1L]] <<- data.frame(context = name, challenge = kind,
      expected = expected_status, observed = result$validation$status, value = as.character(cl$value))
  }
  items[[name]] <<- ctx
  checks[[name]] <<- data.frame(context = name, dataset = dataset, rows = nrow(r),
    estimable = sum(is.finite(effects)), significant = expected,
    up = ctx$facts$n_up, down = ctx$facts$n_down, effect_threshold = lfc,
    unit = unit, declared_units = n, scale = scale)
}
r <- read(paths[["response"]])
for (k in unique(r$contrast)) {
  d <- r[r$contrast == k, ]
  add(k, d, d$feature_id, d$log2FoldChange, d$pvalue, d$response_pooled_BH,
    "GSE146017", "airway smooth muscle", "donor", 4L, "DESeq2 log2FC",
    "Four backgrounds share four donors; 109636 pooled tests per model. These contexts do not reproduce the composite54-gene filter or establish equivalence.", lfc = .5)
}
r <- read(paths[["interactions"]])
add("genome_interactions", r, paste(r$feature_id, r$contrast, sep = ":"),
  r$log2FoldChange, r$pvalue, r$pooled_BH, "GSE146017", "airway smooth muscle",
  "donor", 4L, "DESeq2 interaction log2FC", "82227-test family; zero significant interactions does not establish no modulation.")
r <- read(paths[["adult"]]); r <- r[r$family == "primary_54", ]
add("adult_primary54", r, r$feature_id, r$effect, r$pvalue, r$holm,
  "GSE130715", "adult airway smooth muscle", "paired donor", 6L,
  "Within-donor log2(TPM+1) difference", "Post-result expansion; exact Holm54 not confirmed. TPM/count models share six donors; no circadian or causal endpoint.")
r <- read(paths[["intracellular"]])
add("HTPC_intracellular112", r, paste(r$feature_id, r$time_h, sep = ":"),
  r$effect, r$pvalue, r$holm112, "PXD033514/PXD033534", "testicular peritubular cells",
  "date-labelled paired culture source", 7L, "Mean paired log2LFQ difference",
  "Seven raw labels versus six published adult donors; extra-label age/QC unresolved. Two timepoints and technical replicates do not add independent donors; not ASM.")
r <- read(paths[["secretome"]])
add("HTPC_secretome112", r, paste(r$feature_id, r$time_h, sep = ":"),
  r$effect, r$pvalue, r$holm112, "PXD033504", "testicular peritubular cells",
  "date-labelled paired culture source", NA_integer_, "Supernatant log2LFQ difference",
  "Six/eight date labels at24/72h, not additive; effective paired n is candidate-specific. FBN2 published subset not confirmed;24h source discrepancy. Relative abundance is not secretion rate.")
r <- read(paths[["epithelial"]])
for (family in unique(r$family)) {
  d <- r[r$family == family, ]; a <- d$dataset[1] == "A549"
  add(family, d, paste(d$feature_id, d$contrast, sep = ":"), d$effect, d$pvalue, d$holm,
    if (a) "PXD063431" else "PXD029135", if (a) "A549 cancer epithelial cell line" else "bronchial epithelium",
    if (a) "culture well" else "paired clinical individual", if (a) 8L else 10L,
    if (a) "Median-centered log2 intensity difference" else "Supplied normalized export units",
    if (a) "Four wells per group are not donors; independent experimental batches unverified. Welch, not suffix pairing. Exact Holm56 not confirmed; not ASM."
    else "Clinical before/after ICS, not controlled GC/vehicle; no fold conversion. All-member protein identity correction made after first results; MAOA excluded. Effective paired n depends on contrast; not ASM.")
}
project <- bio_project(items, title = "BioExplainR：公开数据发现与跨来源追踪",
  metadata = list(scope = "Actual source-loaded package, saved upstream fits; no new biological cohort",
    online_model_calls = 0L, independent_units_policy = "Never add units across contexts",
    candidate_selection = "Frozen by research scripts; not autonomous LLM discovery"))
project <- bio_explain_project(project, use_llm = FALSE, language = "zh")
saveRDS(project, file.path(out, "discovery_project.rds"))
bio_report(project, file = file.path(out, "BioExplainR-discovery-zh.html"), language = "zh")
bio_report(project, file = file.path(out, "BioExplainR-discovery-en.html"), language = "en")
# The generic report's compact fact display truncates long strings. Preserve the
# complete study-specific qualifications and actual typed-check results visibly.
escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}
details <- paste0("<section><h2>Complete study scope / 完整研究范围</h2>",
  paste(vapply(names(items), function(k) paste0("<h3>", escape(k), "</h3><p>",
    escape(items[[k]]$facts$endpoint_scale), "</p><p>",
    escape(items[[k]]$facts$study_limitations), "</p>"), ""), collapse = ""),
  "<h2>Typed claim checks / 声明核对</h2><p>Controlled application checks, not held-out performance.</p><table>",
  "<tr><th>Context</th><th>Challenge</th><th>Expected</th><th>Observed</th></tr>",
  paste(vapply(claims, function(r) paste0("<tr>",
    paste0("<td>", escape(as.character(r[1, c("context", "challenge", "expected", "observed")])), "</td>", collapse = ""),
    "</tr>"), ""), collapse = ""), "</table></section>")
for (language in c("zh", "en")) {
  path <- file.path(out, paste0("BioExplainR-discovery-", language, ".html"))
  text <- paste(readLines(path, warn = FALSE), collapse = "\n")
  writeLines(sub("</body>", paste0(details, "</body>"), text, fixed = TRUE), path)
}
write.csv(do.call(rbind, checks), file.path(out, "context_checks.csv"), row.names = FALSE, na = "")
write.csv(do.call(rbind, claims), file.path(out, "claim_checks.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(out, "sessionInfo.txt"))
jsonlite::write_json(list(status = "pass", contexts = length(items),
  claims_checked = length(claims), rows = sum(vapply(checks, function(x) x$rows, integer(1))),
  package_version = as.character(packageVersion("BioExplainR")), online_model_calls = 0L,
  interpretation = "Application/controlled consistency demonstration, not independent performance or new fitted biology"),
  file.path(out, "run.json"), auto_unbox = TRUE, pretty = TRUE)
cat("Actual package integration and typed-claim checks completed\n")
