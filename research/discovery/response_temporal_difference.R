# Direct temporal contrasts avoid interpreting significance differences as interactions.
args <- commandArgs(TRUE); out <- args[1]
if (file.exists(file.path(out, "direct_temporal_results.csv"))) stop("Refusing to overwrite")
jsonlite::write_json(list(frozen_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    phase = "after marginal time effects; exploratory direct temporal comparisons for all fixed12 genes",
    tests = 24L, contrasts = c("ASM DEX24h minus DEX4h", "A549 DEX18h minus DEX2h"),
    script_sha256 = digest::digest(file = "research/discovery/response_temporal_difference.R", algo = "sha256")),
    file.path(out, "direct_temporal_freeze.json"), pretty = TRUE, auto_unbox = TRUE)
suppressPackageStartupMessages(library(limma))
m <- readRDS("research/results/discovery_mechanism_fit_v4/model.rds"); X <- m$v$design
ann <- read.csv(file.path(out, "candidate_annotation.csv")); arrays <- read.csv(file.path(out, "asm_time_measurements.csv"))
cc <- setNames(rep(0, ncol(X)), colnames(X)); cc["grouppost_DMSO"] <- 1; cc["grouppre_DMSO"] <- -1
rows <- list()
for (i in seq_len(nrow(ann))) for (study in c("ASM", "A549")) {
    g <- ann$symbols[i]; feature <- ann$feature_id[i]
    r <- data.frame(feature_id = feature, symbol = g, study = study,
        contrast = if (study == "ASM") "DEX24h_minus_DEX4h" else "DEX18h_minus_DEX2h",
        status = "not_estimable", effect = NA_real_, se = NA_real_, df = NA_real_, ci_low = NA_real_, ci_high = NA_real_, pvalue = 1)
    if (study == "A549" && g %in% rownames(m$v$E)) {
        j <- match(g, rownames(m$v$E)); variance <- drop(t(cc) %*% solve(crossprod(X, X * m$v$weights[j, ])) %*% cc)
        effect <- sum(cc * m$fit$coefficients[j, ]); se <- sqrt(variance * m$fit$s2.post[j]); df <- m$fit$df.total[j]
        r[1, c("effect", "se", "df", "ci_low", "ci_high", "pvalue")] <- c(effect, se, df,
            effect - qt(.975, df) * se, effect + qt(.975, df) * se, 2 * pt(-abs(effect/se), df))
        r$status <- "estimable"
    } else if (study == "ASM") {
        a <- arrays$value[arrays$feature_id == feature & arrays$group == "dex24h"]
        b <- arrays$value[arrays$feature_id == feature & arrays$group == "dex4h"]
        if (length(a) == 3L && length(b) == 3L) {
            tt <- t.test(a, b); effect <- mean(a) - mean(b); se <- sqrt(var(a)/3 + var(b)/3)
            r[1, c("effect", "se", "df", "ci_low", "ci_high", "pvalue")] <- c(effect, se,
                tt$parameter, tt$conf.int, tt$p.value); r$status <- "estimable"
        }
    }
    rows[[length(rows) + 1L]] <- r
}
res <- do.call(rbind, rows); res$holm_24_tests <- p.adjust(res$pvalue, "holm")
write.csv(res, file.path(out, "direct_temporal_results.csv"), row.names = FALSE, na = "")
print(res[res$symbol %in% c("PER2", "PER3", "TEF", "METTL7A", "MAOA"), ])
