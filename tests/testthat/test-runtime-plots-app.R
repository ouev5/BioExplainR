test_that("code recording exposes package calls and runtime object inventory", {
  env <- new.env()
  rec <- bio_record_code("a <- 1:4\nmean_a <- base::mean(a)\nmean_a", envir = env)
  expect_equal(rec$status, "ok")
  expect_true(all(c("a", "mean_a") %in% names(rec$objects_created)))
  expect_true(any(rec$package_usage$package == "base"))
  inv <- bio_object_inventory(env)
  expect_true(all(c("a", "mean_a") %in% inv$name))
  usage <- bio_package_usage()
  expect_true(is.data.frame(usage))
  expect_true(all(c("package", "function_name", "argument_names", "argument_values", "calls") %in% names(usage)))
  expect_true(any(grepl("string omitted", usage$argument_values, fixed = TRUE) | usage$package == "base"))
})

test_that("runtime summary is value-free and includes loaded packages", {
  rt <- bio_runtime_info(include_installed = FALSE)
  expect_true(is.character(rt$r_version))
  expect_true(is.data.frame(rt$loaded_packages))
  expect_true(is.character(rt$search_path))
  expect_true(is.data.frame(rt$package_usage))
})

test_that("common plotting helpers return explainable ggplots", {
  skip_if_not_installed("ggplot2")
  set.seed(12)
  x <- matrix(rnorm(80), nrow = 10, dimnames = list(paste0("g", 1:10), paste0("s", 1:8)))
  md <- data.frame(condition = rep(c("control", "treated"), 4))
  pca <- bio_plot_pca(x, metadata = md, group = "condition")
  expect_s3_class(pca, "ggplot")
  expect_equal(attr(pca, "bio_plot_type"), "pca_plot")
  expect_equal(nrow(attr(pca, "bio_plot_data")), 8)
  pca_ex <- bio_explain(pca, use_llm = FALSE, language = "zh")
  expect_true(any(grepl("方差解释率", pca_ex$local$data_facts, fixed = TRUE)))
  pca_en <- bio_explain(pca, use_llm = FALSE)
  expect_false(any(grepl("[^\\x01-\\x7F]", unlist(pca_en$local), perl = TRUE)))
  heat <- bio_plot_heatmap(x, top_n = 5)
  expect_s3_class(heat, "ggplot")
  expect_equal(attr(heat, "bio_plot_type"), "heatmap_like")
  heat_grouped <- bio_plot_heatmap(x, metadata = md, top_n = 5)
  expect_s3_class(heat_grouped, "ggplot")
  enr <- bio_plot_enrichment(data.frame(
    Description = c("term A", "term B"), GeneRatio = c("2/10", "3/10"),
    p.adjust = c(0.001, 0.04), Count = c(2, 3)))
  expect_s3_class(enr, "ggplot")
  expect_equal(attr(enr, "bio_plot_type"), "enrichment_dotplot")
  emb <- bio_plot_umap(matrix(rnorm(24), nrow = 6, ncol = 4)[, 1:2])
  expect_s3_class(emb, "ggplot")
  expect_equal(attr(emb, "bio_plot_type"), "embedding_plot")
  fake <- make_fake_seurat()
  attr(fake, "reductions") <- list(umap = list(`cell.embeddings` = matrix(rnorm(240), 120, 2)))
  emb_sc <- bio_plot_umap(fake, reduction = "umap", group = "seurat_clusters")
  expect_s3_class(emb_sc, "ggplot")
  expect_true(any(grepl("热图", bio_explain(heat, use_llm = FALSE, language = "zh")$local$statistical_meaning)))
  expect_true(any(grepl("heatmap", bio_explain(heat, use_llm = FALSE)$local$statistical_meaning, ignore.case = TRUE)))
})

test_that("browser launcher gives a useful optional dependency error", {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    expect_error(bio_run_app(launch.browser = FALSE), "requires the optional package 'shiny'")
  } else {
    succeed()
  }
})
