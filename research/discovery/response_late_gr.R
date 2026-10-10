args <- commandArgs(TRUE); out <- args[1]
if (file.exists(file.path(out, "gr_late_results.csv"))) stop("Refusing to overwrite")
suppressPackageStartupMessages(library(limma))
jsonlite::write_json(list(frozen_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    phase = "exploratory temporal amendment after 2h candidate response results",
    script_sha256 = digest::digest(file = "research/discovery/response_late_gr.R", algo = "sha256"),
    amendment_sha256 = digest::digest(file = "research/discovery/RESPONSE_TIME_AMENDMENT.md", algo = "sha256")),
    file.path(out, "late_gr_freeze.json"), auto_unbox = TRUE, pretty = TRUE)
m <- readRDS("research/results/discovery_mechanism_fit_v4/model.rds"); X <- m$v$design
ann <- read.csv(file.path(out, "candidate_annotation.csv")); cvec <- setNames(rep(0, ncol(X)), colnames(X))
cvec["grouppost_DMSO"] <- 1; cvec["groupbaseline_DMSO"] <- -1
rows <- lapply(seq_len(nrow(ann)), function(i) {
    g <- ann$symbols[i]; j <- match(g, rownames(m$v$E))
    if (!is.na(j)) {
        vv <- drop(t(cvec) %*% solve(crossprod(X, X * m$v$weights[j, ])) %*% cvec)
        effect <- sum(m$fit$coefficients[j, ] * cvec); se <- sqrt(vv * m$fit$s2.post[j]); df <- m$fit$df.total[j]
        data.frame(feature_id = ann$feature_id[i], symbol = g, contrast = "DEX18h", status = "estimable", log2_effect = effect,
            se = se, df = df, ci_low = effect - qt(.975, df) * se, ci_high = effect + qt(.975, df) * se,
            pvalue = 2 * pt(-abs(effect/se), df), variance_post = m$fit$s2.post[j], unscaled_var = vv)
    } else data.frame(feature_id = ann$feature_id[i], symbol = g, contrast = "DEX18h", status = "filtered_or_unmapped_not_estimable",
        log2_effect = NA_real_, se = NA_real_, df = NA_real_, ci_low = NA_real_, ci_high = NA_real_, pvalue = NA_real_,
        variance_post = NA_real_, unscaled_var = NA_real_)
})
res <- do.call(rbind, rows); p <- res$pvalue; p[!is.finite(p)] <- 1; res$holm_12_tests <- p.adjust(p, "holm")
write.csv(res, file.path(out, "gr_late_results.csv"), row.names = FALSE, na = "")
print(res[, c("symbol", "log2_effect", "holm_12_tests")])
