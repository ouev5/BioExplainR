# Independent R implementation from original TPM and original pairing supplement.
args <- commandArgs(TRUE); out <- args[1]
if (file.exists(file.path(out, "external_r_audit.json"))) stop("Refusing to overwrite audit")
src <- "research/results/discovery_donors_v1"
ann <- read.csv(file.path(out, "candidate_annotation.csv")); ids <- ann$feature_id
con <- gzfile(file.path(src, "tpm.txt.gz"), "rt"); header <- strsplit(readLines(con, n = 1), " +")[[1]]
pattern <- paste(ids, collapse = "|"); chunks <- list(); total <- 0L
repeat {
    lines <- readLines(con, n = 50000L); if (!length(lines)) break
    total <- total + length(lines); hit <- lines[grepl(pattern, lines)]
    if (length(hit)) chunks[[length(chunks) + 1L]] <- read.table(text = hit, col.names = header, stringsAsFactors = FALSE)
}
close(con); raw <- do.call(rbind, chunks); raw$ens_gene <- sub("\\.[0-9]+$", "", raw$ens_gene)
stopifnot(!anyDuplicated(raw[c("target_id", "sample")]))
md <- read.csv(file.path(out, "external_samples.csv")); supp <- readLines(file.path(src, "supplement_text.txt"))
discovery <- read.csv("research/results/discovery_context_v1/samples.csv")
stopifnot(nrow(md) == 26L, length(unique(md$donor)) == 13L, !any(md$donor %in% discovery$donor))
for (i in seq_len(nrow(md))) {
    r <- md[i, ]; line <- which(supp == as.character(r$title)); stopifnot(length(line) == 1L,
        supp[line+1L] == r$donor, supp[line+2L] == if (r$disease == "fatal_asthma") "asthma" else "non-asthma",
        supp[line+3L] == if (r$treatment == "BUD") "budesonide" else "control")
}
eq <- function(x, y) {
    if (!all(abs(as.numeric(x) - as.numeric(y)) <= 1e-10 + 1e-8 * abs(as.numeric(y))))
        stop("Numeric mismatch: ", paste(x, collapse = ","), " vs ", paste(y, collapse = ","))
}
measure <- read.csv(file.path(out, "external_gene_measurements.csv"))
for (i in seq_len(nrow(measure))) {
    r <- measure[i, ]; tpm <- sum(raw$tpm[raw$ens_gene == r$feature_id & raw$sample == r$tpm_column])
    eq(r$tpm, tpm); eq(r$log2_tpm_plus_one, log2(tpm + 1))
}
effects <- read.csv(file.path(out, "external_donor_effects.csv"))
for (i in seq_len(nrow(effects))) {
    r <- effects[i, ]; a <- measure[measure$feature_id == r$feature_id & measure$donor == r$donor, ]
    stopifnot(nrow(a) == 2L); bud <- a$tpm[a$treatment == "BUD"]; veh <- a$tpm[a$treatment == "vehicle"]
    for (pc in c(1, .5, .1)) eq(r[[paste0("effect_pc", pc)]], log2(bud+pc)-log2(veh+pc))
}
res <- read.csv(file.path(out, "external_results.csv")); checks <- list()
for (i in seq_len(nrow(res))) {
    r <- res[i, ]; x <- effects[effects$feature_id == r$feature_id, ]
    if (r$status != "estimable") {stopifnot(nrow(x) == 0L, r$pvalue == 1); next}
    if (r$contrast == "fatal_asthma_minus_non_asthma_response") {
        a <- x$effect_pc1[x$disease == "fatal_asthma"]; b <- x$effect_pc1[x$disease == "non_asthma"]
        tt <- t.test(a, b); estimate <- mean(a) - mean(b); pool <- c(a, b)
        perm <- combn(length(pool), length(a), function(idx) mean(pool[idx])-mean(pool[-idx]))
    } else {
        group <- sub("_BUD_vs_vehicle$", "", r$contrast)
        a <- if (group == "all13") x$effect_pc1 else x$effect_pc1[x$disease == group]
        tt <- t.test(a); estimate <- mean(a)
        signs <- as.matrix(expand.grid(rep(list(c(-1, 1)), length(a))))
        perm <- rowMeans(sweep(signs, 2, a, "*"))
    }
    values <- c(effect = estimate, ci_low = tt$conf.int[1], ci_high = tt$conf.int[2], pvalue = tt$p.value,
        exact_p = mean(abs(perm) >= abs(estimate)-1e-12), permutations = length(perm))
    for (field in names(values)) {
        eq(r[[field]], values[[field]])
        checks[[length(checks)+1L]] <- data.frame(feature_id = r$feature_id, contrast = r$contrast, field = field,
            Python = r[[field]], R = values[[field]], status = "pass")
    }
}
eq(res$holm_all_tests, p.adjust(res$pvalue, "holm")); eq(res$holm_exact_all_tests, p.adjust(res$exact_p, "holm"))
write.csv(do.call(rbind, checks), file.path(out, "external_r_numeric_checks.csv"), row.names = FALSE)
jsonlite::write_json(list(status = "pass", original_rows = total, measurement_checks = nrow(measure),
    donor_effects = nrow(effects), estimable_tests = sum(res$status == "estimable"), tests_in_family = nrow(res),
    numeric_checks = length(checks) + 2*nrow(res),
    scope = "Original TPM and original supplement re-read; gene aggregation, pairing, effects, t/Welch/CI/exact/Holm"),
    file.path(out, "external_r_audit.json"), pretty = TRUE, auto_unbox = TRUE)
cat("Original TPM independent R audit passed\n")
