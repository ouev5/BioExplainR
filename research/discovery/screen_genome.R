# Exploratory pooled-FDR screen with alternative normalization and donor diagnostics.
args <- commandArgs(TRUE)
stopifnot(length(args) == 1L)
out <- normalizePath(args[1], mustWork = TRUE)
if (file.exists(file.path(out, "genome_screen.csv"))) stop("Refusing to overwrite screen")
suppressPackageStartupMessages({library(DESeq2); library(edgeR); library(limma)})
write_csv <- function(x, name) write.csv(x, file.path(out, name), row.names = FALSE, na = "")
write_json <- function(x, name) jsonlite::write_json(x, file.path(out, name), auto_unbox = TRUE,
    pretty = TRUE, digits = NA, na = "null", null = "null")
frozen <- jsonlite::fromJSON(file.path(out, "analysis_freeze.json"))$files
for (i in seq_len(nrow(frozen))) stopifnot(digest::digest(file = frozen$path[i], algo = "sha256") == frozen$sha256[i])
src <- "research/results/discovery_context_v1"
dds <- readRDS(file.path(src, "model.rds"))
md <- read.csv(file.path(src, "samples.csv"), stringsAsFactors = FALSE)
md$donor <- factor(md$donor); md$kd <- factor(md$kd, levels = c("NT", "KD"))
md$bud <- factor(md$bud, levels = c("no", "yes")); md$tnf <- factor(md$tnf, levels = c("no", "yes"))
rownames(md) <- md$sample
stopifnot(identical(colnames(dds), md$sample), nrow(md) == 31L, nlevels(md$donor) == 4L)
definitions <- list(bud_NT_noTNF = "bud_yes_vs_no", bud_NT_TNF = c("bud_yes_vs_no", "budyes.tnfyes"),
    bud_KD_noTNF = c("bud_yes_vs_no", "kdKD.budyes"),
    bud_KD_TNF = c("bud_yes_vs_no", "kdKD.budyes", "budyes.tnfyes", "kdKD.budyes.tnfyes"),
    bud_tnf_NT = "budyes.tnfyes", bud_kd_noTNF = "kdKD.budyes", three_way = "kdKD.budyes.tnfyes")
interactions <- c("bud_tnf_NT", "bud_kd_noTNF", "three_way")
de <- do.call(rbind, lapply(names(definitions), function(k) {
    v <- setNames(rep(0, length(resultsNames(dds))), resultsNames(dds)); v[definitions[[k]]] <- 1
    r <- as.data.frame(results(dds, contrast = v, independentFiltering = FALSE, cooksCutoff = TRUE))
    data.frame(feature_id = rownames(r), contrast = k, r,
        ci_low = r$log2FoldChange - qnorm(.975) * r$lfcSE,
        ci_high = r$log2FoldChange + qnorm(.975) * r$lfcSE, row.names = NULL)
}))
idx <- de$contrast %in% interactions
de$pooled_BH <- NA_real_; p <- de$pvalue[idx]; p[!is.finite(p)] <- 1
de$pooled_BH[idx] <- p.adjust(p, "BH")
write_csv(de, "deseq2_all_contrasts.csv")
design <- model.matrix(~ donor + kd * bud * tnf, md)
stopifnot(qr(design)$rank == ncol(design))
write_csv(data.frame(sample = md$sample, design, check.names = FALSE), "design_matrix.csv")
cc <- matrix(0, ncol(design), length(definitions), dimnames = list(colnames(design), names(definitions)))
cc["budyes", ] <- as.integer(grepl("^bud_[NK]", names(definitions)))
cc["budyes:tnfyes", c("bud_NT_TNF", "bud_KD_TNF", "bud_tnf_NT")] <- 1
cc["kdKD:budyes", c("bud_KD_noTNF", "bud_KD_TNF", "bud_kd_noTNF")] <- 1
cc["kdKD:budyes:tnfyes", c("bud_KD_TNF", "three_way")] <- 1
fit_voom <- function(ct, metadata) {
    metadata$donor <- droplevels(metadata$donor)
    mm <- model.matrix(~ donor + kd * bud * tnf, metadata)
    stopifnot(qr(mm)$rank == ncol(mm))
    y <- DGEList(ct)
    keep <- filterByExpr(y, design = mm)
    y <- calcNormFactors(y[keep, , keep.lib.sizes = FALSE])
    vv <- voom(y, mm, plot = FALSE)
    csub <- cc[colnames(mm), , drop = FALSE]
    fit <- eBayes(contrasts.fit(lmFit(vv, mm), csub))
    rr <- do.call(rbind, lapply(colnames(cc), function(k) {
        se <- fit$stdev.unscaled[, k] * sqrt(fit$s2.post)
        data.frame(feature_id = rownames(fit), contrast = k, log2_effect = fit$coefficients[, k],
            se = se, pvalue = fit$p.value[, k],
            ci_low = fit$coefficients[, k] - qt(.975, fit$df.total) * se,
            ci_high = fit$coefficients[, k] + qt(.975, fit$df.total) * se, row.names = NULL)
    }))
    ii <- rr$contrast %in% interactions; rr$pooled_BH <- NA_real_
    rr$pooled_BH[ii] <- p.adjust(rr$pvalue[ii], "BH")
    list(results = rr, model = fit, voom = vv, normalization = y$samples, kept = keep)
}
counts <- counts(dds)
alt <- fit_voom(counts, md)
write_csv(alt$results, "voom_all_contrasts.csv")
write_csv(data.frame(sample = rownames(alt$normalization), alt$normalization), "tmm_normalization.csv")
saveRDS(alt, file.path(out, "alternative_model.rds"))
logcounts <- log2(counts(dds, normalized = TRUE) + 1)
effects <- list()
for (d in levels(md$donor)) {
    value <- function(k, b, t) {
        i <- which(md$donor == d & md$kd == k & md$bud == b & md$tnf == t)
        if (length(i) != 1) return(rep(NA_real_, nrow(logcounts)))
        logcounts[, i]
    }
    v <- list(bud_NT_noTNF = value("NT", "yes", "no") - value("NT", "no", "no"),
        bud_NT_TNF = value("NT", "yes", "yes") - value("NT", "no", "yes"),
        bud_KD_noTNF = value("KD", "yes", "no") - value("KD", "no", "no"),
        bud_KD_TNF = value("KD", "yes", "yes") - value("KD", "no", "yes"))
    v$bud_tnf_NT <- v$bud_NT_TNF - v$bud_NT_noTNF
    v$bud_kd_noTNF <- v$bud_KD_noTNF - v$bud_NT_noTNF
    v$three_way <- v$bud_KD_TNF - v$bud_KD_noTNF - v$bud_NT_TNF + v$bud_NT_noTNF
    effects[[d]] <- do.call(rbind, lapply(names(v), function(k)
        data.frame(feature_id = rownames(logcounts), donor = d, contrast = k, effect = v[[k]])))
}
effects <- do.call(rbind, effects)
write_csv(effects, "all_donor_effects.csv")
screen <- de[idx, c("feature_id", "contrast", "baseMean", "log2FoldChange", "lfcSE", "pvalue", "pooled_BH", "ci_low", "ci_high")]
ar <- alt$results[alt$results$contrast %in% interactions, ]
names(ar)[3:ncol(ar)] <- paste0("voom_", names(ar)[3:ncol(ar)])
screen <- merge(screen, ar, by = c("feature_id", "contrast"), all.x = TRUE, sort = FALSE)
dk <- paste(effects$feature_id, effects$contrast)
ds <- split(seq_len(nrow(effects)), dk)
counts_d <- vapply(ds, function(i) sum(is.finite(effects$effect[i])), integer(1))
pos <- vapply(ds, function(i) sum(effects$effect[i] > 0, na.rm = TRUE), integer(1))
neg <- vapply(ds, function(i) sum(effects$effect[i] < 0, na.rm = TRUE), integer(1))
keys <- paste(screen$feature_id, screen$contrast)
screen$n_donors <- unname(counts_d[keys]); screen$positive_donors <- unname(pos[keys]); screen$negative_donors <- unname(neg[keys])
screen$eligible_DESeq2 <- is.finite(screen$pooled_BH) & screen$pooled_BH < .05 & screen$baseMean >= 10 & abs(screen$log2FoldChange) >= .5
screen$robust_voom <- is.finite(screen$voom_pooled_BH) & screen$voom_pooled_BH < .05 & sign(screen$log2FoldChange) == sign(screen$voom_log2_effect)
screen$donor_direction_consistent <- screen$n_donors >= 3 & ifelse(screen$log2FoldChange > 0,
    screen$positive_donors == screen$n_donors, screen$negative_donors == screen$n_donors)
screen$priority_pass <- screen$eligible_DESeq2 & screen$robust_voom & screen$donor_direction_consistent
screen <- screen[order(screen$pooled_BH, -abs(screen$log2FoldChange), screen$feature_id, na.last = TRUE), ]
write_csv(screen, "genome_screen.csv")
candidates <- head(screen[screen$priority_pass, ], 12L)
write_csv(candidates, "frozen_candidates.csv")
write_csv(de[de$feature_id %in% candidates$feature_id, ], "candidate_simple_effects.csv")
write_csv(effects[effects$feature_id %in% candidates$feature_id, ], "candidate_donor_effects.csv")
write_json(list(frozen_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    phase = "after fixed exploratory ranking, before external gene TPM or tests",
    candidates = candidates,
    candidate_file_sha256 = digest::digest(file = file.path(out, "frozen_candidates.csv"), algo = "sha256")), "candidate_freeze.json")
loo <- list()
for (d in levels(md$donor)) {
    use <- md$donor != d
    fit <- fit_voom(counts[, use], md[use, ])
    r <- fit$results[fit$results$feature_id %in% candidates$feature_id, ]; r$excluded_donor <- rep(d, nrow(r))
    loo[[d]] <- r
}
write_csv(do.call(rbind, loo), "candidate_leave_one_donor_out.csv")
summary <- do.call(rbind, lapply(interactions, function(k) {
    r <- screen[screen$contrast == k, ]
    data.frame(contrast = k, tested_genes = nrow(r), pooled_BH_significant = sum(r$pooled_BH < .05),
        effect_abundance_pass = sum(r$eligible_DESeq2), two_model_pass = sum(r$eligible_DESeq2 & r$robust_voom),
        priority_pass = sum(r$priority_pass))
}))
write_csv(summary, "screen_summary.csv")
write_json(list(status = "completed", independent_donors = 4L, libraries = 31L,
    retained_genes = nrow(dds), pooled_test_family = sum(idx), selected_rows = nrow(candidates),
    selected_genes = length(unique(candidates$feature_id)), summary = summary,
    finished_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)), "screen_run.json")
writeLines(capture.output(sessionInfo()), file.path(out, "sessionInfo.txt"))
print(summary); print(candidates[, c("feature_id", "contrast", "log2FoldChange", "pooled_BH", "voom_log2_effect", "voom_pooled_BH", "n_donors")])
