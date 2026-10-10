# Candidate follow-up contexts preserve endpoint, scope, unit and negative findings.
pkgload::load_all(".", quiet = TRUE)
out <- "research/results/discovery_context_v1"
donor_out <- "research/results/discovery_donors_v1"
if (file.exists(file.path(out, "followup_project_v2.rds"))) stop("Refusing to overwrite report workflow")
model <- read.csv(file.path(out, "model_results.csv"))
donors <- read.csv(file.path(donor_out, "results.csv"))
candidate <- bio_context(read.csv("research/results/discovery_sparcl1_v1/candidate.csv"), analysis_type = "generic",
    species = "Homo sapiens", tissue = "airway smooth muscle")
candidate$scope$dataset_id <- "GSE52778"
candidate$design <- list(independent_units = 4L, unit_type = "paired donor", numerator = "dex", denominator = "untreated")
candidate$facts$novelty <- "SPARCL1 glucocorticoid response was reported in Himes 2014 Table 1 and Kan 2019 Table 3."
factorial <- bio_context(model, analysis_type = "generic", species = "Homo sapiens", tissue = "airway smooth muscle")
factorial$scope$dataset_id <- "GSE146017"
factorial$scope$sample_level <- "donor_blocked_library"
factorial$design <- list(independent_units = 4L, libraries = 31L, unit_type = "donor",
    formula = "~ donor + kd * bud * tnf", numerator = "BUD response with modifier", denominator = "BUD response without modifier")
factorial$facts$interaction_results <- model[model$symbol == "SPARCL1" & !is.na(model$holm_candidate_interactions), ]
factorial$facts$interaction_supported <- FALSE
factorial$uncertainties <- c(factorial$uncertainties,
    "All three pre-specified interactions failed Holm correction; non-significance is not equivalence.",
    "SPARCL1 baseMean is low (8.175); count model and donor sensitivity use distinct estimators.",
    "Three named donor cell lines overlap GSE94335; contexts cannot be pooled as independent donors.")
replication <- bio_context(donors, analysis_type = "generic", species = "Homo sapiens", tissue = "airway smooth muscle")
replication$scope$dataset_id <- "GSE94335"
replication$scope$sample_level <- "paired_donor"
replication$design <- list(independent_units = 16L, libraries = 32L, non_asthma = 7L, fatal_asthma = 9L,
    unit_type = "donor", numerator = "BUD 100 nM 24 h", denominator = "vehicle",
    pairing_source = "Original Supplement Table E1 Cell Line; GEO donor field is a library ID")
replication$facts$endpoint_unit <- "within-donor difference in log2(sum transcript TPM + 1)"
replication$facts$candidate_tests <- donors
replication$facts$positive_donors <- 16L
replication$facts$group_difference_supported <- FALSE
replication$uncertainties <- c(replication$uncertainties,
    "Two published TPM libraries lack verifiable pairing and were excluded before candidate testing; all raw data retained.",
    "Gene-specific response is not protein function, clinical steroid sensitivity or a first biological discovery.",
    "Dataset overlap and unresolved airway aliases prohibit adding independent sample sizes across studies.")
# Generic report tables display scalar facts; nested statistical tables are retained
# locally but abbreviated in HTML. Expose every scientific endpoint as a scalar.
for (name in c("candidate", "factorial", "replication")) {
    ctx <- get(name)
    ctx$facts$dataset_id <- ctx$scope$dataset_id
    ctx$facts$independent_units <- ctx$design$independent_units
    ctx$facts$unit_type <- ctx$design$unit_type
    ctx$facts$uncertainties <- paste(ctx$uncertainties, collapse = " | ")
    assign(name, ctx)
}
for (i in which(model$symbol == "SPARCL1" & !is.na(model$holm_candidate_interactions))) {
    r <- model[i, ]
    for (field in c("log2FoldChange", "ci_low", "ci_high", "pvalue", "holm_candidate_interactions"))
        factorial$facts[[paste(r$contrast, field, sep = "_")]] <- r[[field]]
}
for (i in seq_len(nrow(donors))) {
    r <- donors[i, ]
    for (field in c("effect", "ci_low", "ci_high", "pvalue", "permutation_p", "holm_three_tests"))
        replication$facts[[paste(r$contrast, field, sep = "_")]] <- r[[field]]
}
replication$facts$pairing_source <- replication$design$pairing_source
# Candidate prioritization is a question dependency, not shared measurement input.
# Do not label external expression as a computational derivative of airway.
factorial$facts$hypothesis_origin <- "Fixed airway candidate; expression data are GSE146017"
replication$facts$hypothesis_origin <- "Fixed airway candidate; expression data are GSE94335"
project <- bio_project(list(candidate = candidate, factorial = factorial, donor_response = replication))
project <- bio_explain_project(project, use_llm = FALSE, language = "zh")
saveRDS(list(candidate = candidate, factorial = factorial, donor_response = replication), file.path(out, "followup_contexts_v2.rds"))
saveRDS(project, file.path(out, "followup_project_v2.rds"))
bio_report(project, file = file.path(out, "followup_report_zh_v2.html"), language = "zh")
bio_report(project, file = file.path(out, "followup_report_en_v2.html"), language = "en")
jsonlite::write_json(list(status = "pass", contexts = 3L, online_model_calls = 0L,
    package_version = as.character(packageVersion("BioExplainR")),
    scope = "Actual offline candidate-to-follow-up project, with null interactions and non-additive donor units"),
    file.path(out, "report_workflow_v2.json"), pretty = TRUE, auto_unbox = TRUE)
cat("Follow-up project and bilingual reports generated\n")
