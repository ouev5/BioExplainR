# Public real-data development analysis. Run from the repository root.
args <- commandArgs(trailingOnly = TRUE)
if (!length(args) || length(args) > 2L) stop("Supply a new output directory and optional --installed")
installed <- length(args) == 2L
if (installed && args[[2]] != "--installed") stop("Optional mode must be --installed")
out <- args[[1]]
if (dir.exists(out) || file.exists(out)) stop("Output exists; choose a new run directory")
required <- c("MultiAssayExperiment", "SummarizedExperiment", "jsonlite", "digest",
              if (installed) "BioExplainR" else "pkgload")
stopifnot(all(vapply(required, requireNamespace, logical(1), quietly = TRUE)))
stopifnot(as.character(utils::packageVersion("MultiAssayExperiment")) == "1.28.0")
if (installed) library(BioExplainR) else pkgload::load_all(".", quiet = TRUE)
dir.create(out, recursive = TRUE)
write_json <- function(x, name) jsonlite::write_json(x, file.path(out, name), pretty = TRUE,
  auto_unbox = TRUE, digits = 17, null = "null", na = "null", force = TRUE)
write_csv <- function(x, name) utils::write.csv(x, file.path(out, name), row.names = FALSE, na = "")
record <- function(path) list(path = path, bytes = unname(file.info(path)$size),
                             sha256 = digest::digest(file = path, algo = "sha256"))
started <- format(Sys.time(), tz = "UTC", usetz = TRUE)
protocol <- record("research/multiomics/PROTOCOL.md")
script <- record("research/multiomics/run_miniacc.R")
file.copy(protocol$path, file.path(out, "PROTOCOL.md"))
env <- new.env()
utils::data("miniACC", package = "MultiAssayExperiment", envir = env)
x <- env$miniACC
saveRDS(x, file.path(out, "input_miniACC.rds"), version = 3)
writeLines(capture.output(utils::packageDescription("MultiAssayExperiment")), file.path(out, "source_package.txt"))
writeLines(capture.output(tools::Rd2txt(utils:::.getHelpFile(utils::help("miniACC", package = "MultiAssayExperiment")))),
           file.path(out, "source_help.txt"))
write_json(S4Vectors::metadata(x), "source_metadata.json")
cd <- as.data.frame(SummarizedExperiment::colData(x))
sm <- as.data.frame(MultiAssayExperiment::sampleMap(x))
names(sm) <- c("modality", "biological_unit", "source_id")
sm[] <- lapply(sm, as.character)
write_csv(sm, "sample_map.csv")
stage <- as.character(cd$pathologic_stage)
group <- ifelse(stage %in% c("stage i", "stage ii"), "early",
                ifelse(stage %in% c("stage iii", "stage iv"), "late", NA_character_))
clinical <- data.frame(biological_unit = rownames(cd), stage = stage, group = group)
write_csv(clinical, "clinical_groups.csv")
experiments <- MultiAssayExperiment::experiments(x)
observed <- lapply(experiments, colnames)
alignment <- bio_validate_sample_map(sm, observed, primary_units = rownames(cd))
stopifnot(alignment$status == "pass")
write_csv(alignment$coverage, "modality_coverage.csv")
write_csv(alignment$pairwise, "pairwise_coverage.csv")
write_json(list(status = alignment$status, n_primary_units = alignment$n_primary_units,
  n_complete_units = alignment$n_complete_units, n_unmeasured_units = alignment$n_unmeasured_units,
  findings = alignment$findings), "alignment_summary.json")
mae_context <- bio_context(x, species = "Homo sapiens", tissue = "adrenal cortex",
                          scope = list(dataset_id = "TCGA-ACC-miniACC", sample_level = "patient"))
stopifnot(mae_context$facts$n_complete_units == alignment$n_complete_units,
          mae_context$facts$n_primary_units == nrow(cd))
get_matrix <- function(modality) {
  z <- experiments[[modality]]
  if (inherits(z, "SummarizedExperiment")) SummarizedExperiment::assay(z) else as.matrix(z)
}
rna <- get_matrix("RNASeq2GeneNorm"); protein <- get_matrix("RPPAArray")
stopifnot(all(is.finite(rna)), all(rna >= 0))
maps <- lapply(c("RNASeq2GeneNorm", "RPPAArray"), function(m) sm[sm$modality == m, ])
stopifnot(all(vapply(maps, function(m) !anyDuplicated(m$biological_unit), logical(1))))
units <- Reduce(intersect, lapply(maps, function(m) m$biological_unit))
units <- sort(intersect(units, clinical$biological_unit[!is.na(clinical$group)]))
genes <- sort(intersect(rownames(rna), rownames(protein)))
stopifnot(length(genes) > 0L, length(units) > 0L)
sample_cols <- lapply(maps, function(m) m$source_id[match(units, m$biological_unit)])
rna <- log2(rna[genes, sample_cols[[1]], drop = FALSE] + 1)
protein <- protein[genes, sample_cols[[2]], drop = FALSE]
colnames(rna) <- colnames(protein) <- units
groups <- clinical$group[match(units, clinical$biological_unit)]
inputs <- do.call(rbind, lapply(genes, function(g) data.frame(feature_id = g,
  biological_unit = units, group = groups, rna = as.numeric(rna[g, ]), protein = as.numeric(protein[g, ]))))
write_csv(inputs, "paired_measurements.csv")
results <- do.call(rbind, lapply(genes, function(g) {
  a <- rna[g, ]; b <- protein[g, ]; ok <- is.finite(a) & is.finite(b)
  early <- ok & groups == "early"; late <- ok & groups == "late"
  effect <- function(v) if (any(early) && any(late)) mean(v[late]) - mean(v[early]) else NA_real_
  pvalue <- function(v) if (sum(early) >= 3L && sum(late) >= 3L) {
    if (length(unique(v[ok])) == 1L) return(1)
    stats::wilcox.test(v[late], v[early], exact = FALSE, correct = TRUE)$p.value
  } else NA_real_
  ae <- effect(a); be <- effect(b)
  direction <- if (!is.finite(ae) || !is.finite(be) || ae == 0 || be == 0) "unverified" else
    if (sign(ae) == sign(be)) "same" else "opposite"
  data.frame(feature_id = g, n_early = sum(early), n_late = sum(late), n_excluded_nonfinite = sum(!ok),
             rna_effect = ae, protein_effect = be, rna_p = pvalue(a), protein_p = pvalue(b), direction = direction)
}))
results$rna_padj <- stats::p.adjust(results$rna_p, method = "BH")
results$protein_padj <- stats::p.adjust(results$protein_p, method = "BH")
write_csv(results, "feature_results.csv")
scope <- list(dataset_id = "TCGA-ACC-miniACC", comparison_id = "late_vs_early",
              species = "Homo sapiens", tissue = "adrenal cortex", sample_level = "patient")
design <- list(independent_unit = "patient", numerator = "late", denominator = "early",
               pairing = "RNA and protein measured in the same patients")
make_context <- function(modality) {
  values <- stats::setNames(as.list(results[[paste0(modality, "_effect")]]), genes)
  # Stable generated keys avoid ambiguity in scientific gene names containing dots.
  keys <- paste0("effect_", seq_along(genes)); names(values) <- keys
  descriptors <- stats::setNames(lapply(seq_along(genes), function(i) list(feature_id = genes[i],
    unit = if (modality == "rna") "log2_normalized_expression_plus_one" else "normalized_RPPA",
    source_path = keys[i], computation = "mean(late) - mean(early)", completeness = "complete")), keys)
  new_bio_context("generic", "miniACC_stage_comparison", "MultiAssayExperiment", "user_declared",
    facts = c(list(n_features = length(genes), n_paired_units = length(units),
                   n_early = sum(groups == "early"), n_late = sum(groups == "late")), values),
    scope = c(scope, list(modality = modality)), design = design, fact_descriptors = descriptors,
    top_features = results[, c("feature_id", "n_early", "n_late", paste0(modality, c("_effect", "_p", "_padj")))],
    metadata = list(species = "Homo sapiens", tissue = "adrenal cortex", contrast = "late vs early"),
    uncertainty = c("Exploratory stage association in a selected reduced TCGA dataset; no causal inference.",
                    "RNA/protein observations share patients; agreement is not independent validation.",
                    "Stage groups are not randomized; age, purity, subtype and other confounders are not adjusted."))
}
contexts <- list(rna = make_context("rna"), protein = make_context("protein"))
relations <- data.frame(id = paste0("pair_", seq_along(genes)), from = "rna", to = "protein",
  from_fact = paste0("effect_", seq_along(genes)), to_fact = paste0("effect_", seq_along(genes)),
  feature_id = genes, expected = "same")
project <- bio_project(c(list(cohort = mae_context), contexts),
  title = "TCGA-ACC: exploratory paired RNA/protein stage comparison",
  dependencies = list(rna = "cohort", protein = "cohort"), sample_map = sm, relations = relations)
# Retain the accessor-verified alignment, including unmeasured primary units.
project$sample_map <- alignment
project <- bio_explain_project(project)
write_csv(project$relation_validation$findings, "direction_findings.csv")
write_csv(relations, "relations.csv")
for (language in c("en", "zh")) {
  p <- bio_explain_project(project, language = language)
  text <- bio_report(p, file = file.path(out, paste0("report-", language, ".html")), language = language)
  stopifnot(!grepl("TCGA-[A-Z0-9]{2}-[A-Z0-9]{4}", text))
}
saveRDS(project, file.path(out, "project.rds"), version = 3)
write_json(lapply(contexts, function(ctx) ctx$facts), "facts.json")
payload <- bio_context_payload(mae_context, policy = bio_payload_policy(max_chars = 100000))
write_json(payload, "cohort_payload.json")
stopifnot(!grepl("TCGA-[A-Z0-9]{2}-[A-Z0-9]{4}", jsonlite::toJSON(payload, auto_unbox = TRUE)))
checks <- data.frame(case = character(), expected = character(), actual = character())
add <- function(case, expected, actual) checks <<- rbind(checks, data.frame(case, expected, actual))
add("observed_sample_map", "pass", alignment$status)
chosen <- which(results$direction %in% c("same", "opposite"))[1]
stopifnot(!is.na(chosen))
r <- relations[chosen, ]; r$expected <- results$direction[chosen]
p <- project; p$relations <- r
add("observed_direction", "pass", bio_validate_project_relations(p)$status)
r$expected <- if (r$expected == "same") "opposite" else "same"
add("injected_wrong_direction", "fail", bio_validate_project_relations(p, r)$status)
p$items$protein$design <- list(numerator = "early", denominator = "late")
add("injected_reversed_comparison", "fail", bio_validate_project_relations(p)$status)
p <- project; p$relations <- relations[chosen, ]; p$items$protein$scope$comparison_id <- NULL
z <- bio_validate_project_relations(p)
add("injected_missing_scope", "unverified", z$findings$status[z$findings$check == "direction"])
p <- project; p$relations <- relations[chosen, ]; p$items$protein$fact_descriptors[[p$relations$to_fact]]$feature_id <- "WRONG"
add("injected_wrong_feature", "fail", bio_validate_project_relations(p)$status)
write_csv(checks, "engineering_checks.csv")
stopifnot(all(checks$expected == checks$actual))
writeLines(capture.output(sessionInfo()), file.path(out, "sessionInfo.txt"))
write_csv(bio_dependency_provenance(c("BioExplainR", required, "S4Vectors")), "packages.csv")
summary <- list(dataset = "TCGA-ACC / miniACC", scope = "public real-data development case; no expert/test gold",
  n_primary_units = nrow(cd), n_modalities = length(experiments), n_paired_known_stage = length(units),
  n_early = sum(groups == "early"), n_late = sum(groups == "late"), n_common_features = length(genes),
  direction = as.list(table(factor(results$direction, levels = c("same", "opposite", "unverified")))),
  rna_bh_below_005 = sum(results$rna_padj < .05, na.rm = TRUE),
  protein_bh_below_005 = sum(results$protein_padj < .05, na.rm = TRUE),
  n_complete_all_modalities = alignment$n_complete_units, n_unmeasured_units = alignment$n_unmeasured_units,
  engineering_checks = nrow(checks), online_model_calls = 0L, expert_evaluation = "deferred_until_ready",
  user_study = "deferred_by_owner", protocol = protocol, script = script,
  package_mode = if (installed) "installed" else "source",
  package_version = as.character(utils::packageVersion("BioExplainR")),
  package_path = find.package("BioExplainR"),
  started_utc = started, finished_utc = format(Sys.time(), tz = "UTC", usetz = TRUE))
write_json(summary, "summary.json")
files <- list.files(out, full.names = TRUE)
records <- lapply(files, function(path) { r <- record(path); r$path <- basename(path); r })
write_json(list(manifest_version = "2.0", path_base = "run_directory", status = "pass", files = records,
                hash_policy = "SHA-256 of each output file, excluding manifest itself"), "manifest.json")
print(summary[1:13])
