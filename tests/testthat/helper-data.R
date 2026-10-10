make_de <- function(n = 200, seed = 1) {
  set.seed(seed)
  df <- data.frame(
    baseMean = rexp(n, 0.01),
    log2FoldChange = rnorm(n, sd = 1.5),
    lfcSE = 0.3,
    stat = rnorm(n),
    pvalue = runif(n)^3,
    row.names = paste0("GENE", seq_len(n))
  )
  df$padj <- p.adjust(df$pvalue, "BH")
  df$padj[1:7] <- NA
  df
}

make_fake_seurat <- function(n = 120) {
  set.seed(2)
  md <- data.frame(
    nCount_RNA = rpois(n, 3000), nFeature_RNA = rpois(n, 900), percent.mt = runif(n, 0, 12),
    seurat_clusters = factor(sample(0:3, n, TRUE)),
    orig.ident = sample(c("PATIENT_001_SECRET", "PATIENT_002_SECRET", "PATIENT_003_SECRET"), n, TRUE),
    row.names = paste0("BARCODE_AAACCTG_", seq_len(n))
  )
  so <- structure(list(), class = "Seurat")
  attr(so, "meta.data") <- md
  attr(so, "assays") <- list(RNA = list())
  attr(so, "active.assay") <- "RNA"
  so
}
