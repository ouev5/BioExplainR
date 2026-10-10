# Select context-retained response genes before external expression inspection.
args <- commandArgs(TRUE); stopifnot(length(args) == 2L)
src <- normalizePath(args[1], mustWork = TRUE); out <- args[2]
if (dir.exists(out)) stop("Refusing to overwrite response run")
dir.create(out)
sha <- function(p) digest::digest(file = p, algo = "sha256")
json <- function(x, n) jsonlite::write_json(x, file.path(out, n), pretty = TRUE, auto_unbox = TRUE, digits = NA)
csv <- function(x, n) write.csv(x, file.path(out, n), row.names = FALSE, na = "")
inputs <- c("research/discovery/RESPONSE_PROTOCOL.md", "research/discovery/screen_response.R",
    file.path(src, c("deseq2_all_contrasts.csv", "voom_all_contrasts.csv", "all_donor_effects.csv")),
    "research/results/discovery_mechanism_fit_v4/model.rds", "research/results/discovery_donors_v1/tpm.txt.gz",
    "research/results/discovery_donors_v1/samples.csv")
json(list(frozen_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    phase = "before stable response ranking or external gene expression inspection",
    files = lapply(inputs, function(p) list(path = p, sha256 = sha(p)))), "analysis_freeze.json")
suppressPackageStartupMessages({library(edgeR); library(limma); library(DESeq2)})
contrasts <- c("bud_NT_noTNF", "bud_NT_TNF", "bud_KD_noTNF", "bud_KD_TNF")
de <- read.csv(file.path(src, "deseq2_all_contrasts.csv"))
de <- de[de$contrast %in% contrasts, ]; p <- de$pvalue; p[!is.finite(p)] <- 1
de$response_pooled_BH <- p.adjust(p, "BH")
vr <- read.csv(file.path(src, "voom_all_contrasts.csv")); vr <- vr[vr$contrast %in% contrasts, ]
vr$response_pooled_BH <- p.adjust(vr$pvalue, "BH")
names(vr)[3:ncol(vr)] <- paste0("voom_", names(vr)[3:ncol(vr)])
de <- merge(de, vr, by = c("feature_id", "contrast"), all.x = TRUE, sort = FALSE)
don <- read.csv(file.path(src, "all_donor_effects.csv")); don <- don[don$contrast %in% contrasts, ]
ds <- split(seq_len(nrow(don)), paste(don$feature_id, don$contrast))
get_d <- function(field) vapply(ds, function(i) {
    x <- don$effect[i]; x <- x[is.finite(x)]
    switch(field, n = length(x), pos = sum(x > 0), neg = sum(x < 0))
}, integer(1))
key <- paste(de$feature_id, de$contrast)
de$n_donors <- unname(get_d("n")[key]); de$positive_donors <- unname(get_d("pos")[key]); de$negative_donors <- unname(get_d("neg")[key])
de$pass <- de$baseMean >= 10 & abs(de$log2FoldChange) >= .5 & de$response_pooled_BH < .05 &
    is.finite(de$voom_response_pooled_BH) & de$voom_response_pooled_BH < .05 &
    sign(de$log2FoldChange) == sign(de$voom_log2_effect) & de$n_donors >= 3 &
    ifelse(de$log2FoldChange > 0, de$positive_donors == de$n_donors, de$negative_donors == de$n_donors)
de$pass[is.na(de$pass)] <- FALSE
groups <- split(de, de$feature_id)
screen <- do.call(rbind, lapply(groups, function(r) data.frame(feature_id = r$feature_id[1], baseMean = r$baseMean[1],
    weakest_abs_stat = min(abs(r$stat)), smallest_abs_log2FC = min(abs(r$log2FoldChange)),
    largest_response_BH = max(r$response_pooled_BH),
    all_contexts_pass = nrow(r) == 4L && all(r$pass) && length(unique(sign(r$log2FoldChange))) == 1L,
    direction = sign(r$log2FoldChange[1]))))
screen <- screen[order(-screen$weakest_abs_stat, screen$feature_id), ]
pre <- screen$feature_id[screen$all_contexts_pass]
dds <- readRDS("research/results/discovery_context_v1/model.rds")
md <- as.data.frame(SummarizedExperiment::colData(dds))
ct <- counts(dds); rownames(md) <- colnames(ct)
mm <- model.matrix(~ donor + kd * bud * tnf, md)
cc <- matrix(0, ncol(mm), 4, dimnames = list(colnames(mm), contrasts))
cc["budyes", ] <- 1; cc["budyes:tnfyes", c("bud_NT_TNF", "bud_KD_TNF")] <- 1
cc["kdKD:budyes", c("bud_KD_noTNF", "bud_KD_TNF")] <- 1; cc["kdKD:budyes:tnfyes", "bud_KD_TNF"] <- 1
loo <- list()
for (d in levels(md$donor)) {
    use <- md$donor != d; metadata <- droplevels(md[use, ]); dm <- model.matrix(~ donor + kd * bud * tnf, metadata)
    stopifnot(qr(dm)$rank == ncol(dm))
    y <- DGEList(ct[, use]); keep <- filterByExpr(y, design = dm)
    y <- calcNormFactors(y[keep, , keep.lib.sizes = FALSE]); v <- voom(y, dm, plot = FALSE)
    f <- eBayes(contrasts.fit(lmFit(v, dm), cc[colnames(dm), ]))
    loo[[d]] <- do.call(rbind, lapply(contrasts, function(k) {
        ii <- match(pre, rownames(f))
        data.frame(feature_id = pre, contrast = k, excluded_donor = d, log2_effect = f$coefficients[ii, k], pvalue = f$p.value[ii, k])
    }))
}
loo <- do.call(rbind, loo); csv(loo, "all_priority_leave_one_donor_out.csv")
loo_direction <- vapply(pre, function(g) {
    r <- loo[loo$feature_id == g, ]; nrow(r) == 16L && all(is.finite(r$log2_effect)) &&
        all(sign(r$log2_effect) == screen$direction[match(g, screen$feature_id)])
}, logical(1))
screen$leave_one_direction_pass <- FALSE
screen$leave_one_direction_pass[match(pre, screen$feature_id)] <- loo_direction
screen$priority_pass <- screen$all_contexts_pass & screen$leave_one_direction_pass
selected <- head(screen[screen$priority_pass, ], 12L)
csv(screen, "stable_response_screen.csv"); csv(de, "response_full_results.csv")
csv(selected, "frozen_candidates.csv")
csv(de[de$feature_id %in% selected$feature_id, ], "candidate_context_effects.csv")
csv(don[don$feature_id %in% selected$feature_id, ], "candidate_context_donor_effects.csv")
json(list(frozen_utc = format(Sys.time(), tz = "UTC", usetz = TRUE), selected = selected,
    phase = "ranked before external gene TPM or GR candidate extraction",
    candidate_file_sha256 = sha(file.path(out, "frozen_candidates.csv"))), "candidate_freeze.json")
json(list(status = "completed", tested_genes = nrow(screen), two_model_four_context_pass = length(pre),
    leave_one_direction_pass = sum(screen$priority_pass), selected = nrow(selected)), "screen_run.json")
print(selected)
