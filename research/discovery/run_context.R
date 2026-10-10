# Published factorial perturbation: full donor-blocked count model and donor sensitivity.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L)
out <- normalizePath(args[[1]], mustWork = TRUE)
if (file.exists(file.path(out, "model_results.csv"))) stop("Refusing to overwrite a prior fit")
suppressPackageStartupMessages(library(DESeq2))
stopifnot(requireNamespace("jsonlite", quietly = TRUE), requireNamespace("digest", quietly = TRUE))
write_csv <- function(x, name) write.csv(x, file.path(out, name), row.names = FALSE, na = "")
write_json <- function(x, name) jsonlite::write_json(x, file.path(out, name), auto_unbox = TRUE,
    pretty = TRUE, digits = NA, na = "null", null = "null")
freeze <- jsonlite::fromJSON(file.path(out, "frozen_protocol.json"))
stopifnot(digest::digest(file = "research/discovery/CONTEXT_PROTOCOL.md", algo = "sha256") == freeze$protocol$sha256)
raw <- read.delim(gzfile(file.path(out, "counts.txt.gz")), check.names = FALSE)
cat("Count input columns:\n"); print(names(raw))
meta_lines <- readLines(gzfile(file.path(out, "series_matrix.txt.gz")))
sample_lines <- meta_lines[grepl("^!Sample_", meta_lines)]
metadata_values <- lapply(sample_lines, function(x) scan(text = x, what = "", sep = "\t", quiet = TRUE))
cat("Sample titles and treatment/donor metadata:\n")
print(metadata_values[vapply(metadata_values, function(v) v[[1]] %in%
    c("!Sample_title", "!Sample_geo_accession", "!Sample_characteristics_ch1"), logical(1))])
# Design parsing is completed after inspecting metadata, without selecting expression outcomes.
if (!file.exists("research/discovery/context_design.R")) stop("Metadata acquired: design parser required")
source("research/discovery/context_design.R")
md <- parse_context_design(raw, metadata_values)
feature_id <- sub("\\.[0-9]+$", "", raw[[1]])
stopifnot(!anyDuplicated(feature_id), nrow(md) == 31L, length(unique(md$donor)) == 4L)
counts <- as.matrix(raw[, md$count_column, drop = FALSE])
stopifnot(is.numeric(counts), all(is.finite(counts)), all(counts >= 0), all(counts == round(counts)))
storage.mode(counts) <- "integer"
rownames(counts) <- feature_id; colnames(counts) <- md$sample
stopifnot(all(is.finite(counts)), all(counts >= 0), !anyDuplicated(md$sample))
rownames(md) <- md$sample
md$donor <- factor(md$donor); md$kd <- factor(md$kd, levels = c("NT", "KD"))
md$bud <- factor(md$bud, levels = c("no", "yes")); md$tnf <- factor(md$tnf, levels = c("no", "yes"))
design <- ~ donor + kd * bud * tnf
mm <- model.matrix(design, md)
stopifnot(qr(mm)$rank == ncol(mm))
write_json(list(recorded_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    phase = "after metadata parsing, before count fitting or candidate-result inspection",
    refinement = "metadata parser added and integer count validation enforced; scientific protocol unchanged",
    scripts = lapply(c("run_context.R", "context_design.R", "audit_context.py"), function(n)
        list(path = n, sha256 = digest::digest(file = file.path("research/discovery", n), algo = "sha256")))),
    "execution_code.json")
write_csv(md, "samples.csv")
write_csv(data.frame(sample = rownames(mm), mm, check.names = FALSE), "design_matrix.csv")
keep <- rowSums(counts) >= 10L
dds <- DESeqDataSetFromMatrix(counts[keep, ], md, design)
dds <- DESeq(dds, quiet = TRUE, minReplicatesForReplace = Inf)
cat("Coefficients:\n"); print(resultsNames(dds))
coefs <- resultsNames(dds)
contrast <- function(terms) {
    v <- setNames(rep(0, length(coefs)), coefs)
    stopifnot(all(terms %in% coefs)); v[terms] <- 1; v
}
definitions <- list(
    bud_NT_noTNF = c("bud_yes_vs_no"),
    bud_NT_TNF = c("bud_yes_vs_no", "budyes.tnfyes"),
    bud_KD_noTNF = c("bud_yes_vs_no", "kdKD.budyes"),
    bud_KD_TNF = c("bud_yes_vs_no", "kdKD.budyes", "budyes.tnfyes", "kdKD.budyes.tnfyes"),
    bud_tnf_NT = c("budyes.tnfyes"),
    bud_kd_noTNF = c("kdKD.budyes"),
    three_way = c("kdKD.budyes.tnfyes"),
    kd_baseline = c("kd_KD_vs_NT"))
genes <- c(SPARCL1 = "ENSG00000152583", CEBPD = "ENSG00000221869",
           FKBP5 = "ENSG00000096060", TSC22D3 = "ENSG00000157514")
stopifnot(all(genes %in% rownames(dds)))
all_res <- lapply(definitions, function(terms) results(dds, contrast = contrast(terms), alpha = .05))
model <- do.call(rbind, lapply(names(all_res), function(n) {
    r <- as.data.frame(all_res[[n]][genes, ])
    data.frame(symbol = names(genes), feature_id = genes, contrast = n, r,
               ci_low = r$log2FoldChange - qnorm(.975)*r$lfcSE,
               ci_high = r$log2FoldChange + qnorm(.975)*r$lfcSE, row.names = NULL)
}))
primary_names <- c("bud_tnf_NT", "bud_kd_noTNF", "three_way")
idx <- which(model$symbol == "SPARCL1" & model$contrast %in% primary_names)
model$holm_candidate_interactions <- NA_real_
model$holm_candidate_interactions[idx] <- p.adjust(model$pvalue[idx], "holm")
write_csv(model, "model_results.csv")
for (n in primary_names) write_csv(data.frame(feature_id = rownames(dds), as.data.frame(all_res[[n]])), paste0("genome_", n, ".csv"))
sf <- sizeFactors(dds); write_csv(data.frame(sample = names(sf), size_factor = sf), "size_factors.csv")
norm <- counts(dds, normalized = TRUE)[genes, , drop = FALSE]
long <- do.call(rbind, lapply(names(genes), function(g) data.frame(symbol = g, feature_id = genes[[g]],
    sample = md$sample, donor = md$donor, kd = md$kd, bud = md$bud, tnf = md$tnf,
    raw_count = counts[genes[[g]], md$sample], normalized_count = norm[genes[[g]], ],
    log2_count_plus_one = log2(norm[genes[[g]], ] + 1), row.names = NULL)))
write_csv(long, "gene_measurements.csv")
differences <- list()
for (g in names(genes)) for (d in levels(md$donor)) {
    x <- long[long$symbol == g & long$donor == d, ]
    value <- function(k, b, t) {
        v <- x$log2_count_plus_one[x$kd == k & x$bud == b & x$tnf == t]
        if (length(v) != 1) return(NA_real_); v
    }
    effects <- c(bud_NT_noTNF = value("NT", "yes", "no") - value("NT", "no", "no"),
                 bud_NT_TNF = value("NT", "yes", "yes") - value("NT", "no", "yes"),
                 bud_KD_noTNF = value("KD", "yes", "no") - value("KD", "no", "no"),
                 bud_KD_TNF = value("KD", "yes", "yes") - value("KD", "no", "yes"))
    effects <- c(effects, bud_tnf_NT = unname(effects["bud_NT_TNF"] - effects["bud_NT_noTNF"]),
                 bud_kd_noTNF = unname(effects["bud_KD_noTNF"] - effects["bud_NT_noTNF"]),
                 three_way = unname(effects["bud_KD_TNF"] - effects["bud_KD_noTNF"] - effects["bud_NT_TNF"] + effects["bud_NT_noTNF"]))
    differences[[length(differences)+1L]] <- data.frame(symbol = g, donor = d, contrast = names(effects), value = effects)
}
differences <- do.call(rbind, differences); write_csv(differences, "donor_effects.csv")
sensitivity <- do.call(rbind, lapply(split(differences, paste(differences$symbol, differences$contrast)), function(r) {
    x <- r$value[is.finite(r$value)]; n <- length(x); tt <- t.test(x)
    signs <- as.matrix(expand.grid(rep(list(c(-1, 1)), n)))
    perm <- rowMeans(sweep(signs, 2, x, "*"))
    data.frame(symbol = r$symbol[1], contrast = r$contrast[1], n_donors = n, mean = mean(x),
        ci_low = tt$conf.int[1], ci_high = tt$conf.int[2], pvalue = tt$p.value,
        sign_flip_p = mean(abs(perm) >= abs(mean(x)) - 1e-12), permutations = nrow(signs),
        positive_donors = sum(x > 0), negative_donors = sum(x < 0))
}))
sensitivity$holm_candidate_interactions <- NA_real_
idx <- which(sensitivity$symbol == "SPARCL1" & sensitivity$contrast %in% primary_names)
sensitivity$holm_candidate_interactions[idx] <- p.adjust(sensitivity$pvalue[idx], "holm")
write_csv(sensitivity, "donor_sensitivity.csv")
write_json(list(status = "completed", dataset = "GSE146017", independent_units = 4L, libraries = nrow(md),
    retained_features = sum(keep), original_features = nrow(counts), design = deparse(design),
    coefficients = coefs, primary_test = "SPARCL1 bud_tnf_NT", correction = "Holm across three candidate interactions",
    model = model[model$symbol == "SPARCL1", ], sensitivity = sensitivity[sensitivity$symbol == "SPARCL1", ],
    finished_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    versions = list(R = R.version.string, DESeq2 = as.character(packageVersion("DESeq2")))), "summary.json")
saveRDS(dds, file.path(out, "model.rds"))
capture.output(sessionInfo(), file = file.path(out, "sessionInfo.txt"))
print(model[model$symbol == "SPARCL1", ])
print(sensitivity[sensitivity$symbol == "SPARCL1", ])
