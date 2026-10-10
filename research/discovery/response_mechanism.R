# Exact gene-weighted covariance for candidate GR perturbation contrasts.
args <- commandArgs(TRUE); stopifnot(length(args) == 1L)
out <- args[1]
if (file.exists(file.path(out, "gr_candidate_results.csv"))) stop("Refusing to overwrite GR tests")
suppressPackageStartupMessages(library(limma))
ann <- read.csv(file.path(out, "candidate_annotation.csv"), stringsAsFactors = FALSE)
model_path <- "research/results/discovery_mechanism_fit_v4/model.rds"
jsonlite::write_json(list(frozen_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    stage = "before extracting selected candidates from existing GR fit",
    model_sha256 = digest::digest(file = model_path, algo = "sha256"),
    script_sha256 = digest::digest(file = "research/discovery/response_mechanism.R", algo = "sha256"),
    annotations_sha256 = digest::digest(file = file.path(out, "candidate_annotation.csv"), algo = "sha256")),
    file.path(out, "gr_analysis_freeze.json"), auto_unbox = TRUE, pretty = TRUE)
m <- readRDS(model_path); X <- m$v$design
kk <- c("DEX", "KH103", "MIF", "Cort113"); C <- m$contrasts[, kk, drop = FALSE]
rr <- list(); raw <- list(); covariance <- list()
for (i in seq_len(nrow(ann))) {
    g <- ann$symbols[i]
    estimable <- !grepl("\\|", g) && g %in% rownames(m$v$E)
    for (k in kk) {
        if (estimable) {
            j <- match(g, rownames(m$v$E)); w <- m$v$weights[j, ]
            inverse <- solve(crossprod(X, X * w)); cvec <- C[, k]
            unscaled_var <- drop(t(cvec) %*% inverse %*% cvec)
            variance <- m$fit$s2.post[j]; df <- m$fit$df.total[j]
            effect <- drop(m$fit$coefficients[j, ] %*% cvec)
            se <- sqrt(unscaled_var * variance); p <- 2 * pt(-abs(effect / se), df)
            r <- data.frame(feature_id = ann$feature_id[i], symbol = g, contrast = k, status = "estimable",
                log2_effect = effect, se = se, df = df, ci_low = effect - qt(.975, df) * se,
                ci_high = effect + qt(.975, df) * se, pvalue = p, unscaled_var = unscaled_var, variance_post = variance)
        } else r <- data.frame(feature_id = ann$feature_id[i], symbol = g, contrast = k,
            status = "filtered_or_unmapped_not_estimable", log2_effect = NA_real_, se = NA_real_, df = NA_real_,
            ci_low = NA_real_, ci_high = NA_real_, pvalue = NA_real_, unscaled_var = NA_real_, variance_post = NA_real_)
        rr[[length(rr) + 1L]] <- r
    }
    if (estimable) {
        j <- match(g, rownames(m$v$E))
        raw[[length(raw) + 1L]] <- data.frame(feature_id = ann$feature_id[i], symbol = g,
            sample = m$map$sample, logCPM = m$v$E[j, ], weight = m$v$weights[j, ])
    }
}
res <- do.call(rbind, rr); p <- res$pvalue; p[!is.finite(p)] <- 1
res$holm_all_tests <- p.adjust(p, "holm")
write.csv(res, file.path(out, "gr_candidate_results.csv"), row.names = FALSE, na = "")
write.csv(do.call(rbind, raw), file.path(out, "gr_candidate_measurements.csv"), row.names = FALSE)
write.csv(data.frame(sample = m$map$sample, X, check.names = FALSE), file.path(out, "gr_design_matrix.csv"), row.names = FALSE)
write.csv(data.frame(coefficient = rownames(C), C, check.names = FALSE), file.path(out, "gr_contrasts.csv"), row.names = FALSE)
print(res[, c("symbol", "contrast", "status", "log2_effect", "holm_all_tests")])
