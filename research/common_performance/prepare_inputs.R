# Recover saved DE tables without refitting or selecting by method outcomes.
out <- commandArgs(TRUE)[1]
if (dir.exists(out)) stop("Use a new directory")
dir.create(out)
a <- read.csv("research/results/paper_cn_cases_v1/airway_de.csv", check.names = FALSE)
p <- read.csv("research/results/related_tools/pasilla_volcano.csv")
ids <- rownames(read.delim("research/cache/pasilla/inst/extdata/pasilla_gene_counts.tsv", row.names = 1))
stopifnot(length(ids) == nrow(p), !anyDuplicated(ids))
p <- data.frame(feature_id = ids, log2FoldChange = p$log2FC, padj = p$padj)
for (nm in c("airway", "pasilla")) {
  x <- get(if (nm == "airway") "a" else "p")
  x <- x[order(x$feature_id, method = "radix"), c("feature_id", "log2FoldChange", "padj")]
  write.csv(x, file.path(out, paste0(nm, "_source.csv")), row.names = FALSE, na = "NA")
  for (n in c(50, 200)) {
    index <- round(seq(1, nrow(x), length.out = n))
    stopifnot(!anyDuplicated(index))
    write.csv(x[index, ], file.path(out, paste0(nm, "_", n, ".csv")), row.names = FALSE, na = "NA")
  }
}
