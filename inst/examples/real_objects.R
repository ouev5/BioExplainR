# End-to-end adapters against actual installed analysis libraries.
# Uses synthetic input; no patient data or live model calls.
library(BioExplainR)
bio_configure("local")
set.seed(42)
group <- factor(rep(c("control", "treated"), each = 3))
counts <- matrix(rnbinom(600 * 6, mu = 50, size = 5), nrow = 600,
                 dimnames = list(paste0("gene", 1:600), paste0("sample", 1:6)))
counts[1:60, 4:6] <- counts[1:60, 4:6] * 3L
items <- list()

if (requireNamespace("DESeq2", quietly = TRUE)) {
  dds <- DESeq2::DESeqDataSetFromMatrix(counts,
    colData = data.frame(condition = group, row.names = colnames(counts)), design = ~condition)
  dds <- DESeq2::DESeq(dds, quiet = TRUE, fitType = "mean")
  result <- DESeq2::results(dds, contrast = c("condition", "treated", "control"))
  items$deseq2 <- bio_explain(result, species = "Homo sapiens")
  expected <- sum(!is.na(result$padj) & result$padj < 0.05 & result$log2FoldChange != 0)
  stopifnot(items$deseq2$context$facts$n_significant == expected)
  cat("DESeq2 actual DESeqResults: PASS\n")
}

if (requireNamespace("limma", quietly = TRUE)) {
  design <- stats::model.matrix(~group)
  fit <- limma::eBayes(limma::lmFit(log2(counts + 1), design))
  items$limma <- bio_explain(fit, coefficient = "grouptreated", contrast = "treated vs control")
  table <- limma::topTable(fit, coef = "grouptreated", n = Inf, sort.by = "none")
  stopifnot(items$limma$context$facts$n_significant == sum(table$adj.P.Val < 0.05 & table$logFC != 0, na.rm = TRUE))
  cat("limma actual MArrayLM: PASS\n")
}

if (requireNamespace("edgeR", quietly = TRUE)) {
  y <- edgeR::DGEList(counts, group = group)
  y <- edgeR::calcNormFactors(y)
  y <- edgeR::estimateDisp(y)
  result <- edgeR::exactTest(y, pair = c("control", "treated"))
  items$edger <- bio_explain(result, contrast = "treated vs control")
  table <- edgeR::topTags(result, n = Inf)$table
  stopifnot(items$edger$context$facts$n_significant == sum(table$FDR < 0.05 & table$logFC != 0))
  cat("edgeR actual DGEExact: PASS\n")
}

cell_counts <- matrix(rpois(100 * 24, 3), nrow = 100,
                      dimnames = list(paste0("g", 1:100), paste0("barcode", 1:24)))
cell_md <- data.frame(sample = rep(paste0("donor", 1:6), each = 4),
                       cluster = rep(c("T", "B", "T", "NK"), 6),
                       condition = rep(c("control", "treated"), each = 12),
                       row.names = colnames(cell_counts))
if (requireNamespace("SeuratObject", quietly = TRUE)) {
  obj <- SeuratObject::CreateSeuratObject(cell_counts, meta.data = cell_md)
  items$seurat <- bio_explain(obj, sample_col = "sample", cluster_col = "cluster")
  stopifnot(items$seurat$context$facts$n_cells == 24, items$seurat$context$facts$n_samples == 6)
  cat("SeuratObject actual v5 object: PASS\n")
}
if (requireNamespace("SingleCellExperiment", quietly = TRUE)) {
  sce <- SingleCellExperiment::SingleCellExperiment(assays = list(counts = cell_counts), colData = cell_md)
  items$sce <- bio_explain(sce, sample_col = "sample", cluster_col = "cluster")
  stopifnot(items$sce$context$facts$n_cells == 24, items$sce$context$facts$n_samples == 6)
  cat("SingleCellExperiment actual object: PASS\n")
}
stopifnot(length(items) > 0)
out_dir <- getOption("bioexplainr.demo_dir", tempdir())
bio_report(bio_project(items), file = file.path(out_dir, "real_objects.html"), title = "Real object adapter checks with synthetic input")
