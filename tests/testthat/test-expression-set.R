test_that("Biobase ExpressionSet input is summarized when Biobase is available", {
  skip_if_not_installed("Biobase")
  set.seed(1)
  assay <- matrix(rnorm(20), nrow = 5, dimnames = list(paste0("f", 1:5), paste0("s", 1:4)))
  pheno <- data.frame(sample = colnames(assay), condition = c("a", "b", "a", "b"),
                      batch = c("b1", "b1", "b2", "b2"), row.names = colnames(assay))
  eset <- Biobase::ExpressionSet(assayData = assay,
                                 phenoData = Biobase::AnnotatedDataFrame(pheno))
  ctx <- bio_context(eset, sample_col = "sample", group_col = "condition", batch_col = "batch")
  expect_equal(ctx$analysis_type, "expression_set")
  expect_equal(ctx$adapter, "expression_set")
  expect_equal(ctx$facts$n_features, 5L)
  expect_equal(ctx$facts$n_samples, 4L)
  expect_equal(ctx$facts$n_groups, 2L)
  expect_equal(ctx$facts$n_batches, 2L)
})
