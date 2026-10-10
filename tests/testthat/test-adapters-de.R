test_that("DE counts are computed from the full table before truncation", {
  de <- make_de(300)
  ctx <- bio_context(de, n_top = 3, thresholds = list(padj = 0.05, lfc = 1))
  sig <- !is.na(de$padj) & de$padj < 0.05
  expect_equal(ctx$facts$n_features, 300)
  expect_equal(ctx$facts$n_up, sum(sig & de$log2FoldChange > 1))
  expect_equal(ctx$facts$n_down, sum(sig & de$log2FoldChange < -1))
  expect_equal(ctx$facts$n_significant_any_lfc, sum(sig))
  expect_equal(ctx$facts$n_na_padj, 7)
  expect_equal(ctx$facts$n_tested, 293)
  expect_equal(nrow(ctx$top_features), 3)
  # top rows are the smallest padj values
  expect_equal(ctx$top_features$feature[1], rownames(de)[which.min(de$padj)])
  expect_equal(ctx$facts$p_value_basis, "adjusted_column")
})

test_that("raw p-values are never silently treated as adjusted", {
  de <- make_de(100)[, c("log2FoldChange", "pvalue")]
  ctx <- bio_context(de, language = "zh")
  expect_equal(ctx$facts$p_value_basis, "raw_only")
  expect_null(ctx$facts$n_significant)
  expect_null(ctx$facts$n_up)
  expect_equal(ctx$facts$n_raw_up + ctx$facts$n_raw_down,
               sum(de$pvalue < 0.05 & de$log2FoldChange != 0))
  expect_true(any(grepl("没有校正后 p 值", ctx$uncertainty)))
  expect_false("padj" %in% names(ctx$top_features))
  ex <- bio_explain(ctx, use_llm = FALSE, language = "zh")
  expect_true(any(grepl("不能称为 FDR 显著", ex$local$data_facts)))
})

test_that("explicit p_adjust_method computes FDR and says so", {
  de <- make_de(100)[, c("log2FoldChange", "pvalue")]
  ctx <- bio_context(de, p_adjust_method = "BH")
  expect_equal(ctx$facts$p_value_basis, "computed_BH")
  expect_equal(ctx$facts$n_significant_any_lfc, sum(p.adjust(de$pvalue, "BH") < 0.05))
  expect_true(any(grepl("p.adjust\\(method = 'BH'\\)", ctx$uncertainty)))
})

test_that("column patterns only yield an inferred source", {
  ctx <- bio_context(make_de())
  expect_equal(ctx$source_status, "inferred_from_columns")
  expect_equal(ctx$source_package, "DESeq2")
  lim <- data.frame(logFC = c(1, -2), AveExpr = 5, t = 1, P.Value = c(0.01, 0.001), adj.P.Val = c(0.02, 0.004), B = 1)
  c2 <- bio_context(lim)
  expect_equal(c2$source_package, "limma")
  expect_equal(c2$source_status, "inferred_from_columns")
  c3 <- bio_context(lim, source_package = "limma")
  expect_equal(c3$source_status, "user_declared")
  er <- data.frame(logFC = c(1, -2), logCPM = 5, PValue = c(0.01, 0.001), FDR = c(0.02, 0.004))
  expect_equal(bio_context(er)$source_package, "edgeR")
  odd <- data.frame(lfc = c(1, -1), pval = c(0.01, 0.2))
  expect_equal(bio_context(odd)$source_status, "unknown")
})

test_that("user context is stored and contrast warning disappears", {
  ctx <- bio_context(make_de(), species = "Mus musculus", tissue = "liver",
                     contrast = "KO vs WT", gene_id_type = "ENSEMBL", design = "~ batch + genotype",
                     background = "all expressed genes")
  expect_equal(ctx$metadata$species, "Mus musculus")
  expect_equal(ctx$metadata$contrast, "KO vs WT")
  expect_equal(ctx$metadata$gene_id_type, "ENSEMBL")
  expect_false(any(grepl("contrast", ctx$uncertainty)))
  expect_true(any(grepl("contrast", bio_context(make_de())$uncertainty)))
})

test_that("explicit analysis_type selects adapter for ambiguous tables", {
  amb <- data.frame(ID = c("a", "b"), Description = c("x", "y"), log2FoldChange = c(1, -1),
                    padj = c(0.01, 0.5), Count = c(3, 4))
  expect_equal(bio_context(amb)$analysis_type, "differential_expression")
  expect_equal(bio_context(amb, analysis_type = "enrichment_ora")$analysis_type, "enrichment_ora")
  expect_equal(bio_context(amb, analysis_type = "generic")$analysis_type, "generic")
  expect_error(bio_context(amb, analysis_type = "no_such_type"), "No adapter")
})

test_that("DESeqResults objects are recognised by class", {
  de <- make_de(50)
  obj <- structure(de, class = c("DESeqResults", "data.frame"))
  ctx <- bio_context(obj)
  expect_equal(ctx$adapter, "deseq_results")
  expect_equal(ctx$source_status, "verified_class")
  expect_equal(ctx$source_package, "DESeq2")
  expect_equal(ctx$facts$n_features, 50)
})

test_that("generic fallback and custom adapters", {
  ctx <- bio_context(list(a = 1, b = "x"))
  expect_equal(ctx$analysis_type, "generic")
  bio_register_adapter("my_thing", detect = function(x) inherits(x, "my_thing"),
                       extract = function(x, meta, n_top, thresholds, ...) {
                         new_bio_context("custom", class(x), "mypkg", "verified_class",
                                         facts = list(n = length(unclass(x))), metadata = meta)
                       })
  on.exit(bio_unregister_adapter("my_thing"))
  c2 <- bio_context(structure(1:5, class = "my_thing"))
  expect_equal(c2$analysis_type, "custom")
  expect_equal(c2$facts$n, 5)
  expect_true("my_thing" %in% bio_adapters()$name)
})

test_that("prcomp adapter reports variance explained", {
  set.seed(3)
  m <- matrix(rnorm(200), 20)
  ctx <- bio_context(prcomp(m))
  expect_equal(ctx$analysis_type, "pca")
  ve <- prcomp(m)$sdev^2
  expect_equal(ctx$facts$variance_explained[1], ve[1] / sum(ve))
})

test_that("S4 DESeqResults-like DataFrame exposes contrast description", {
  skip_if_not_installed("S4Vectors")
  skip_if(requireNamespace("DESeq2", quietly = TRUE), "real DESeq2 installed; class already defined")
  setClass("DESeqResults", contains = "DFrame", where = globalenv())
  on.exit(removeClass("DESeqResults", where = globalenv()))
  de <- make_de(40)
  df <- S4Vectors::DataFrame(de)
  S4Vectors::mcols(df) <- S4Vectors::DataFrame(
    type = "results",
    description = c("mean of normalized counts for all samples",
                    "log2 fold change (MLE): condition treated vs control",
                    "standard error", "Wald statistic", "Wald test p-value", "BH adjusted p-values"))
  S4Vectors::metadata(df)$alpha <- 0.1
  obj <- new("DESeqResults", df)
  ctx <- bio_context(obj)
  expect_equal(ctx$adapter, "deseq_results")
  expect_equal(ctx$facts$n_features, 40)
  expect_equal(ctx$metadata$contrast, "condition treated vs control")
  expect_equal(ctx$facts$deseq2_alpha, 0.1)
  expect_true(any(grepl("alpha = 0.1", ctx$uncertainty)))
})
