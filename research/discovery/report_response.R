# Actual BioExplainR contexts from full statistical tables plus research figures.
args <- commandArgs(TRUE); out <- args[1]
if (file.exists(file.path(out, "bioexplainr_project_v2.rds"))) stop("Refusing to overwrite research report")
pkgload::load_all(".", quiet = TRUE)
genome <- "research/results/discovery_genome_v2"
de <- read.csv(file.path(out, "response_full_results.csv"))
ann <- read.csv(file.path(out, "candidate_annotation.csv"), stringsAsFactors = FALSE)
ann$display_symbol <- ifelse(nzchar(ann$symbols), ann$symbols, "LINC00607 [unmapped externally]")
ann$symbol <- ifelse(nzchar(ann$symbols), ann$symbols, "LINC00607")
selected <- read.csv(file.path(out, "frozen_candidates.csv"))
ext <- read.csv(file.path(out, "external_results.csv"), stringsAsFactors = FALSE)
gr <- read.csv(file.path(out, "gr_candidate_results.csv"), stringsAsFactors = FALSE)
late <- read.csv(file.path(out, "gr_late_results.csv"), stringsAsFactors = FALSE)
arrays <- read.csv(file.path(out, "asm_time_results.csv"), stringsAsFactors = FALSE)
time <- read.csv(file.path(out, "direct_temporal_results.csv"), stringsAsFactors = FALSE)
items <- list(); checks <- list()
contexts <- c("bud_NT_noTNF", "bud_NT_TNF", "bud_KD_noTNF", "bud_KD_TNF")
for (k in contexts) {
    r <- de[de$contrast == k, ]; table <- data.frame(gene = r$feature_id,
        log2FoldChange = r$log2FoldChange, pvalue = r$pvalue, padj = r$response_pooled_BH, baseMean = r$baseMean)
    ctx <- bio_context(table, analysis_type = "differential_expression", source_package = "DESeq2",
        species = "Homo sapiens", tissue = "airway smooth muscle", contrast = k,
        design = list(independent_units = 4L, libraries = 31L, unit_type = "donor", formula = "~ donor + kd * bud * tnf",
            numerator = "BUD", denominator = "vehicle"),
        scope = list(dataset_id = "GSE146017", sample_level = "donor_blocked_library", comparison_id = k),
        p_adjust_method = NULL, thresholds = list(padj = .05, lfc = .5), language = "zh")
    expected <- sum(is.finite(r$response_pooled_BH) & r$response_pooled_BH < .05 & abs(r$log2FoldChange) > .5)
    stopifnot(ctx$facts$n_features == nrow(r), ctx$facts$n_significant == expected)
    ctx$facts$multiple_testing_family <- "Four simple effects x 27,409 genes = 109,636 tests, pooled BH"
    ctx$facts$independent_units <- 4L
    ctx$uncertainty <- c(ctx$uncertainty, "Retained response is not equivalence across TNF/KD conditions; genome interactions failed pooled BH.")
    ctx$facts$scope_limitations <- paste(ctx$uncertainty, collapse = " | ")
    items[[k]] <- ctx
    checks[[k]] <- data.frame(context = k, input_rows = nrow(r), significant_computed = expected, significant_BioExplainR = ctx$facts$n_significant)
}
int <- read.csv(file.path(genome, "genome_screen.csv"))
ctx <- bio_context(data.frame(gene = paste(int$feature_id, int$contrast, sep = ":"),
    log2FoldChange = int$log2FoldChange, pvalue = int$pvalue, padj = int$pooled_BH),
    analysis_type = "differential_expression", source_package = "DESeq2",
    species = "Homo sapiens", tissue = "airway smooth muscle", contrast = "three genome-wide interactions",
    design = list(independent_units = 4L, unit_type = "donor", libraries = 31L), language = "zh")
stopifnot(ctx$facts$n_features == 82227L, ctx$facts$n_significant == 0L)
ctx$facts$tested_genes <- 27409L; ctx$facts$independent_units <- 4L; ctx$facts$interaction_tests <- 82227L
ctx$uncertainty <- c(ctx$uncertainty, "Zero significant interactions is not absence of biological modulation or equivalence.")
ctx$facts$scope_limitations <- paste(ctx$uncertainty, collapse = " | ")
items$genome_interactions <- ctx
for (kind in c("external", "GR", "ASM_time", "direct_time")) {
    r <- switch(kind, external = ext, GR = gr, ASM_time = arrays, direct_time = time)
    effect <- if (kind == "GR") r$log2_effect else r$effect
    padj <- if (kind %in% c("external", "GR")) r$holm_all_tests else r$holm_24_tests
    ctx <- bio_context(data.frame(gene = paste(r$feature_id, r$contrast, sep = ":"),
        log2FoldChange = effect, pvalue = r$pvalue, FWER = padj),
        analysis_type = "differential_expression", source_package = if (kind == "GR") "limma exact WLS" else "paired or Welch t",
        species = "Homo sapiens", tissue = if (kind == "GR") "A549 cancer epithelial cell line" else if (kind == "direct_time") "airway smooth muscle and A549 cancer epithelial cell line" else "airway smooth muscle",
        contrast = kind, design = list(unit_type = if (kind == "external") "paired donor" else "culture replicate"),
        language = "zh", notes = "Effect column is a declared log-scale difference; external TPM/arrays are not count-model log2FC.")
    ctx$facts$endpoint_scale <- switch(kind, external = "within-donor difference of log2(TPM+1)",
        GR = "weighted logCPM contrast, exact gene-specific covariance", ASM_time = "published processed array units", direct_time = "study-specific log-scale units")
    ctx$facts$dataset_id <- switch(kind, external = "GSE94335", GR = "GSE229084", ASM_time = "GSE34313", direct_time = "GSE34313 and GSE229084")
    if (kind == "direct_time") ctx$facts$unit_scope <- "Two experiments, one cell line per experiment; do not pool independent units"
    else ctx$facts$independent_units <- if (kind == "external") 13L else 1L
    ctx$facts$tests_in_family <- nrow(r)
    for (i in seq_len(nrow(r))) {
        prefix <- paste(ifelse(nzchar(r$symbol[i]), r$symbol[i], r$feature_id[i]), r$contrast[i], sep = "_")
        if (kind == "direct_time") prefix <- paste(prefix, r$study[i], sep = "_")
        for (field in c("status", "effect", "log2_effect", "ci_low", "ci_high", "pvalue", "holm_all_tests", "holm_24_tests", "holm_exact_all_tests"))
            if (field %in% names(r)) ctx$facts[[paste0(prefix, "_", field)]] <- r[[field]][i]
    }
    ctx$uncertainty <- c(ctx$uncertainty, switch(kind,
        external = "Three known overlapping lines excluded. No TNF/KD in external data; cannot replicate an interaction. TPM scale differs from RNA-seq log2FC.",
        GR = "Four A549 batches are not four independent human donors. Culture, time, drug and dose differ from ASM. Candidate × four contrasts Holm includes non-estimable genes.",
        ASM_time = "One HASM1 line, 3 treated/4 untreated cultures. Welch significance is exploratory; exact permutations cannot pass the 24-test Holm family.",
        direct_time = "Read after marginal results, exploratory amendment. Direct time differences do not establish circadian phase/amplitude or tissue-specific mechanism."))
    ctx$facts$scope_limitations <- paste(ctx$uncertainty, collapse = " | ")
    items[[kind]] <- ctx
}
project <- bio_project(items, title = "Context-retained steroid response and PER2 temporal divergence",
    metadata = list(analysis_status = "exploratory published-data reanalysis", selected_genes = 12L,
        retained_signature = 54L, hypothesis = "PER2 induction/repression depends on temporal/experimental context",
        overlap_policy = "Do not add 4 discovery donors, 13 external donors, old16 or single-line cultures as a new total"))
project <- bio_explain_project(project, use_llm = FALSE, language = "zh")
saveRDS(items, file.path(out, "bioexplainr_contexts_v2.rds")); saveRDS(project, file.path(out, "bioexplainr_project_v2.rds"))
bio_report(project, file.path(out, "BioExplainR-report-zh-v2.html"), language = "zh")
bio_report(project, file.path(out, "BioExplainR-report-en-v2.html"), language = "en")
write.csv(do.call(rbind, checks), file.path(out, "bioexplainr_fact_checks_v2.csv"), row.names = FALSE)
jsonlite::write_json(list(status = "pass", contexts = length(items), package_version = as.character(packageVersion("BioExplainR")),
    load_mode = "actual local source via pkgload", online_model_calls = 0L,
    full_table_fact_checks = length(checks) + 1L, source_sha256 = digest::digest(file = "DESCRIPTION", algo = "sha256")),
    file.path(out, "bioexplainr_workflow_v2.json"), pretty = TRUE, auto_unbox = TRUE)
writeLines(capture.output(sessionInfo()), file.path(out, "report_sessionInfo_v2.txt"))

# Initial figures/tables are already saved; v2 corrects report metadata only.
if (file.exists(file.path(out, "evidence_summary.csv"))) {
    cat("BioExplainR v2 reports generated with correct uncertainty field and mixed-study scope\n")
    quit(save = "no", status = 0)
}

# Compact evidence table: all frozen candidates, including failed measurements.
summary <- lapply(seq_len(nrow(ann)), function(i) {
    id <- ann$feature_id[i]; r <- de[de$feature_id == id, ]; e <- ext[ext$feature_id == id & ext$contrast == "all13_BUD_vs_vehicle", ]
    g <- gr[gr$feature_id == id & gr$contrast == "DEX", ]; a <- arrays[arrays$feature_id == id & arrays$contrast == "dex24h", ]
    data.frame(feature_id = id, symbol = ann$symbol[i],
        discovery_min_log2FC = min(r$log2FoldChange), discovery_max_log2FC = max(r$log2FoldChange),
        discovery_max_pooled_BH = max(r$response_pooled_BH),
        external_status = e$status, external_effect = e$effect, external_ci_low = e$ci_low, external_ci_high = e$ci_high,
        external_Holm = e$holm_all_tests, external_exact_Holm = e$holm_exact_all_tests,
        external_positive = e$positive_donors, external_negative = e$negative_donors,
        A549_DEX2h_effect = g$log2_effect, A549_DEX2h_Holm = g$holm_all_tests,
        ASM_DEX24h_effect = a$effect, ASM_DEX24h_Holm = a$holm_24_tests)
})
write.csv(do.call(rbind, summary), file.path(out, "evidence_summary.csv"), row.names = FALSE, na = "")

suppressPackageStartupMessages(library(ggplot2))
fig <- file.path(out, "figures"); dir.create(fig)
theme_set(theme_bw(base_size = 12))
save_plot <- function(p, name, width, height) {
    ggsave(file.path(fig, paste0(name, ".pdf")), p, width = width, height = height, device = grDevices::cairo_pdf)
    ggsave(file.path(fig, paste0(name, ".png")), p, width = width, height = height, dpi = 180)
}
rr <- de[de$feature_id %in% selected$feature_id, ]; rr$symbol <- ann$symbol[match(rr$feature_id, ann$feature_id)]
rr$symbol <- factor(rr$symbol, levels = rev(ann$symbol)); rr$contrast <- factor(rr$contrast, levels = contexts,
    labels = c("Control / no TNF", "Control / TNF", "CEBPD KD / no TNF", "CEBPD KD / TNF"))
p <- ggplot(rr, aes(contrast, symbol, fill = log2FoldChange)) + geom_tile(color = "white") +
    geom_text(aes(label = sprintf("%.2f", log2FoldChange)), size = 3.5) +
    scale_fill_gradient2(low = "#2574ad", mid = "white", high = "#ce5b43", midpoint = 0) +
    labs(title = "Fixed top12: retained BUD responses in four ASM contexts", x = NULL, y = NULL, fill = "DESeq2\nlog2FC",
        subtitle = "54 genes passed two-model pooled FDR, donor signs and leave-one-donor direction checks") +
    theme(axis.text.x = element_text(angle = 15, hjust = 1))
save_plot(p, "Figure_1_context_response", 10, 7)
ee <- ext[ext$contrast == "all13_BUD_vs_vehicle" & ext$status == "estimable", ]
ee$symbol <- factor(ee$symbol, levels = rev(ann$symbol))
p <- ggplot(ee, aes(effect, symbol)) + geom_vline(xintercept = 0, linetype = 2, color = "grey50") +
    geom_errorbarh(aes(xmin = ci_low, xmax = ci_high), height = .2) + geom_point(size = 3, color = "#226c7a") +
    labs(title = "External response: 13 paired donors, known overlaps excluded", subtitle = "11/12 frozen genes measurable; all11 pass t-test and exact-sign Holm (48-test family)",
        x = "Mean within-donor change in log2(TPM+1), 95% t CI", y = NULL)
save_plot(p, "Figure_2_external_donors", 10, 7)
measure <- read.csv(file.path(out, "external_gene_measurements.csv"))
focus <- c("PER2", "PER3", "ANGPTL2", "METTL7A", "FSTL3", "MAOA")
measure <- measure[measure$symbol %in% focus, ]; measure$treatment <- factor(measure$treatment, levels = c("vehicle", "BUD"))
p <- ggplot(measure, aes(treatment, log2_tpm_plus_one, group = donor, color = disease)) +
    geom_line(alpha = .7) + geom_point(size = 1.8) + facet_wrap(~symbol, scales = "free_y", ncol = 3) +
    scale_color_manual(values = c(fatal_asthma = "#bd5546", non_asthma = "#277995")) +
    labs(title = "Individual donor measurements for six biological leads", x = NULL, y = "log2(TPM+1)", color = "Donor origin")
save_plot(p, "Figure_3_paired_measurements", 10, 7)
per <- gr[gr$symbol == "PER2", ]; labels <- c("DEX" = "DEX 2h", "KH103" = "DEX x KH103", "MIF" = "DEX x MIF", "Cort113" = "DEX x Cort113")
per$label <- labels[per$contrast]
per <- rbind(data.frame(label = per$label, effect = per$log2_effect, low = per$ci_low, high = per$ci_high),
    data.frame(label = "DEX 18h", effect = late$log2_effect[late$symbol == "PER2"], low = late$ci_low[late$symbol == "PER2"], high = late$ci_high[late$symbol == "PER2"]),
    data.frame(label = "DEX 18h minus 2h", effect = time$effect[time$symbol == "PER2" & time$study == "A549"],
        low = time$ci_low[time$symbol == "PER2" & time$study == "A549"], high = time$ci_high[time$symbol == "PER2" & time$study == "A549"]))
per$label <- factor(per$label, levels = rev(per$label))
p <- ggplot(per, aes(effect, label)) + geom_vline(xintercept = 0, linetype = 2) +
    geom_errorbarh(aes(xmin = low, xmax = high), height = .2) + geom_point(size = 3, color = "#2a7180") +
    labs(title = "PER2: A549 short-term induction, GR perturbation and later decay",
        subtitle = "Exact gene-weighted WLS CIs; interaction = change in DEX response, not drug main effect",
        x = "Weighted logCPM contrast (95% CI)", y = NULL)
save_plot(p, "Figure_4_PER2_GR_time", 10, 5)
am <- read.csv(file.path(out, "asm_time_measurements.csv")); am <- am[am$symbol %in% c("PER2", "PER3"), ]
am$group <- factor(am$group, levels = c("untreated", "dex4h", "dex24h"))
p <- ggplot(am, aes(group, value)) + geom_point(position = position_jitter(width = .05, seed = 11), size = 2.5) +
    stat_summary(fun = mean, geom = "crossbar", width = .5, color = "#b55242") + facet_wrap(~symbol, scales = "free_y") +
    labs(title = "Late ASM repression of PER2 and PER3", subtitle = "GSE34313: one HASM1 line; three treated cultures per time, four untreated cultures",
        x = "Published time condition", y = "Published processed expression units")
save_plot(p, "Figure_5_clock_time_arrays", 10, 5)
cat("BioExplainR project, bilingual reports, complete evidence table and five PDF/PNG figures created\n")
