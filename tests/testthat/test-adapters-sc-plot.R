test_that("Seurat-like object is summarised without barcodes or sample names", {
  so <- make_fake_seurat()
  ctx <- bio_context(so, language = "zh")
  md <- attr(so, "meta.data")
  expect_equal(ctx$analysis_type, "single_cell")
  expect_equal(ctx$facts$n_cells, 120)
  expect_equal(ctx$facts$n_clusters, 4)
  expect_equal(ctx$facts$n_samples, 3)
  expect_equal(ctx$facts$qc$pct_mt$column, "percent.mt")
  expect_equal(sum(ctx$top_features$n_cells), 120)
  expect_true(any(grepl("细胞数不等于生物学重复数", ctx$uncertainty)))
  js <- jsonlite::toJSON(bio_context_payload(ctx), auto_unbox = TRUE)
  expect_false(grepl("PATIENT_", js))
  expect_false(grepl("BARCODE_", js))
  ex <- bio_explain(ctx, use_llm = FALSE, language = "zh")
  expect_false(grepl("PATIENT_", paste(unlist(ex$local), collapse = " ")))
})

test_that("per-cell metadata can be declared as single-cell", {
  md <- attr(make_fake_seurat(), "meta.data")
  ctx <- bio_context(md, analysis_type = "single_cell")
  expect_equal(ctx$adapter, "cell_metadata")
  expect_equal(ctx$source_status, "user_declared")
  expect_equal(ctx$facts$n_samples, 3)
})

test_that("SingleCellExperiment adapter degrades gracefully without Bioconductor", {
  fake <- structure(list(), class = "SingleCellExperiment")
  if (!requireNamespace("SummarizedExperiment", quietly = TRUE)) {
    ctx <- bio_context(fake)
    expect_equal(ctx$analysis_type, "single_cell")
    expect_true(any(grepl("SummarizedExperiment", ctx$uncertainty)))
  } else {
    succeed()
  }
})

test_that("ggplot semantics are extracted", {
  skip_if_not_installed("ggplot2")
  df <- data.frame(log2FoldChange = c(-2, 0, 3), padj = c(0.01, 0.5, 0.001), grp = c("a", "b", "a"))
  p <- ggplot2::ggplot(df, ggplot2::aes(log2FoldChange, -log10(padj), colour = padj < 0.05)) +
    ggplot2::geom_point() + ggplot2::facet_wrap(~grp) + ggplot2::labs(title = "Volcano", x = "log2FC")
  ctx <- bio_context(p)
  expect_equal(ctx$analysis_type, "plot")
  expect_equal(ctx$facts$geoms, "GeomPoint")
  expect_equal(ctx$facts$plot_type_guess, "volcano_plot")
  expect_equal(ctx$plot_mapping$global_aes$x, "log2FoldChange")
  expect_true("grp" %in% ctx$plot_mapping$facet_vars)
  expect_equal(ctx$plot_mapping$labels$title, "Volcano")
  expect_equal(ctx$plot_mapping$data$n_rows, 3)
  ex <- bio_explain(p, use_llm = FALSE, language = "zh")
  expect_true(any(grepl("火山图", ex$local$statistical_meaning)))
})

test_that("expression matrices never leak sample names or values into payloads", {
  set.seed(4)
  m <- matrix(rpois(60, 50) + 0.123456, 6,
              dimnames = list(paste0("G", 1:6), paste0("PATIENT_ID_", 1:10)))
  ctx <- bio_context(m)
  js <- jsonlite::toJSON(bio_context_payload(ctx), auto_unbox = TRUE)
  expect_false(grepl("PATIENT_ID_", js))
  expect_false(grepl(format(m[1, 1], nsmall = 6), js, fixed = TRUE))
  wide <- as.data.frame(m)
  ctx2 <- bio_context(wide)
  js2 <- jsonlite::toJSON(bio_context_payload(ctx2), auto_unbox = TRUE)
  expect_false(grepl("PATIENT_ID_", js2))
})

test_that("payload is bounded", {
  de <- make_de(2000)
  de$gene <- paste0(strrep("X", 50), seq_len(2000))
  ctx <- bio_context(de, n_top = 200)
  p <- bio_context_payload(ctx, max_top = 200, max_chars = 3000)
  expect_lte(nchar(jsonlite::toJSON(p, auto_unbox = TRUE)), 3500)
  expect_lt(NROW(p$top_features), 200)
  expect_equal(p$facts$n_features, 2000)
})

test_that("real SingleCellExperiment objects are summarised", {
  skip_if_not_installed("SingleCellExperiment")
  skip_if_not_installed("SummarizedExperiment")
  set.seed(5)
  counts <- matrix(rpois(600, 2), 30, 20, dimnames = list(paste0("g", 1:30), paste0("PATIENT_CELL_", 1:20)))
  sce <- SingleCellExperiment::SingleCellExperiment(
    assays = list(counts = counts),
    colData = S4Vectors::DataFrame(sample = rep(c("PAT_A", "PAT_B"), 10), label = rep(c("T", "B"), 10)))
  SingleCellExperiment::reducedDim(sce, "PCA") <- matrix(rnorm(40), 20, 2)
  ctx <- bio_context(sce)
  expect_equal(ctx$adapter, "single_cell_experiment")
  expect_equal(ctx$facts$n_cells, 20)
  expect_equal(ctx$facts$n_features, 30)
  expect_equal(ctx$facts$n_samples, 2)
  expect_equal(ctx$facts$reductions, "PCA")
  js <- jsonlite::toJSON(bio_context_payload(ctx), auto_unbox = TRUE)
  expect_false(grepl("PAT_|PATIENT_CELL", js))
})
