# Independent implementation: re-read TPM/metadata, reconstruct pairs and all tests.
args <- commandArgs(trailingOnly = TRUE); stopifnot(length(args) == 1L)
out <- normalizePath(args[[1]], mustWork = TRUE)
# Stream the public long table independently and keep only pre-specified genes.
con <- gzfile(file.path(out, "tpm.txt.gz"), open = "rt"); header <- strsplit(readLines(con, n = 1), " +")[[1]]
selected <- list(); total <- 0L
repeat {
    lines <- readLines(con, n = 50000L)
    if (!length(lines)) break
    total <- total + length(lines)
    hit <- lines[grepl(" ENSG00000152583 | ENSG00000096060 | ENSG00000157514 ", lines)]
    if (length(hit)) selected[[length(selected)+1L]] <- read.table(text = hit, col.names = header)
}
close(con); raw <- do.call(rbind, selected)
md <- read.csv(file.path(out, "samples.csv"))
ms <- read.csv(file.path(out, "gene_measurements.csv"))
stopifnot(!anyDuplicated(raw[c("target_id", "sample")]), !anyDuplicated(md$sample), nrow(md) == 32L)
# Re-read original Supplement Table E1 text, not inferred expression pairing.
supp <- readLines(file.path(out, "supplement_text.txt"))
for (i in seq_len(nrow(md))) {
    r <- md[i, ]; line <- which(supp == r$title)
    stopifnot(length(line) == 1L, supp[line+1L] == r$donor,
        supp[line+2L] == if (r$disease == "fatal_asthma") "asthma" else "non-asthma",
        supp[line+3L] == if (r$treatment == "BUD") "budesonide" else "control")
}
close <- function(x, y) stopifnot(isTRUE(all.equal(as.numeric(x), as.numeric(y), tolerance = 1e-10)))
for (i in seq_len(nrow(ms))) {
    r <- ms[i, ]; v <- sum(raw$tpm[raw$ens_gene == r$feature_id & raw$sample == r$tpm_column])
    close(r$tpm, v); close(r$log2_tpm_plus_one, log2(v+1))
}
effects <- read.csv(file.path(out, "donor_effects.csv"))
for (i in seq_len(nrow(effects))) {
    r <- effects[i, ]; p <- ms[ms$symbol == r$symbol & ms$donor == r$donor, ]
    stopifnot(nrow(p) == 2L); a <- p$tpm[p$treatment == "BUD"]; b <- p$tpm[p$treatment == "vehicle"]
    close(r$bud_tpm, a); close(r$vehicle_tpm, b)
    for (pc in c(1, .5, .1)) close(r[[paste0("effect_pc", pc)]], log2(a+pc)-log2(b+pc))
}
rows <- read.csv(file.path(out, "results.csv")); x <- effects[effects$symbol == "SPARCL1", ]
a <- x$effect_pc1[x$disease == "fatal_asthma"]; b <- x$effect_pc1[x$disease == "non_asthma"]
checks <- list()
for (i in seq_len(nrow(rows))) {
    r <- rows[i, ]; group <- if (i == 1) b else a
    tt <- if (i < 3) t.test(group) else t.test(a, b)
    effect <- if (i < 3) mean(group) else mean(a)-mean(b)
    if (i < 3) {
        signs <- as.matrix(expand.grid(rep(list(c(-1, 1)), length(group))))
        perm <- rowMeans(sweep(signs, 2, group, "*"))
    } else {
        pool <- c(a, b); perm <- combn(length(pool), length(a), function(idx) mean(pool[idx])-mean(pool[-idx]))
    }
    for (field in c("effect", "pvalue", "ci_low", "ci_high", "permutation_p", "permutations")) {
        value <- switch(field, effect = effect, pvalue = tt$p.value, ci_low = tt$conf.int[1],
            ci_high = tt$conf.int[2], permutation_p = mean(abs(perm) >= abs(effect)-1e-12), permutations = length(perm))
        close(r[[field]], value)
        checks[[length(checks)+1L]] <- data.frame(contrast = r$contrast, field, python = r[[field]], R = value, status = "pass")
    }
}
close(rows$holm_three_tests, p.adjust(rows$pvalue, "holm"))
write.csv(do.call(rbind, checks), file.path(out, "r_numeric_checks.csv"), row.names = FALSE)
jsonlite::write_json(list(status = "pass", measurements = nrow(ms), donor_effects = nrow(effects),
    tests = 3L, numeric_checks = length(checks)+3L, scope = "Raw TPM re-read, transformed measurements, paired effects, t/Welch/CI/exact/Holm"),
    file.path(out, "audit.json"), pretty = TRUE, auto_unbox = TRUE)
capture.output(sessionInfo(), file = file.path(out, "sessionInfo.txt"))
print(rows)
