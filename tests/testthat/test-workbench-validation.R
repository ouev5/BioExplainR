test_that("PCA metadata is aligned by ID and numeric corruption is detected", {
  skip_if_not_installed("ggplot2")
  x <- matrix(seq_len(24)^2, 4, dimnames = list(letters[1:4], LETTERS[1:6]))
  md <- data.frame(condition = rep(c("control", "treated"), 3), row.names = LETTERS[1:6])
  p <- bio_plot_pca(x, metadata = md[6:1, , drop = FALSE], group = "condition")
  fit <- attr(p, "bio_plot_source")$prcomp
  expect_equal(bio_context(fit)$facts$variance_explained, fit$sdev^2 / sum(fit$sdev^2))
  expect_identical(as.character(p$data$group), md$condition)
  expect_equal(bio_cross_check(p, x, metadata = md, group = "condition")$status, "pass")
  bad <- p; bad$data$PC1[1] <- bad$data$PC1[1] + 10
  expect_equal(bio_cross_check(bad, x)$status, "fail")
  bad <- p + ggplot2::labs(x = "PC1 (999%)")
  expect_equal(bio_cross_check(bad, x)$status, "fail")
  expect_error(bio_plot_pca(matrix(1, 4, 6)), "non-constant")
  rownames(md)[1] <- "unknown"
  expect_error(bio_plot_pca(x, metadata = md), "row names")
})

test_that("enrichment dot plots check term IDs, subsets, sizes and colour", {
  skip_if_not_installed("ggplot2")
  tab <- data.frame(ID = c("GO:1", "GO:2", "GO:3"), Description = c("A", "B", "C"),
                    GeneRatio = c("2/10", "3/10", "4/10"), Count = 2:4, p.adjust = c(0, .01, .5))
  p <- bio_plot_enrichment(tab, top_n = 2)
  expect_equal(bio_cross_check(p, tab)$status, "fail")
  expect_equal(bio_cross_check(p, tab, allow_subset = TRUE)$status, "pass")
  expect_true(all(is.finite(p$data$neglog10_p)))
  bad <- p; bad$data$count[1] <- 99
  expect_equal(bio_cross_check(bad, tab, allow_subset = TRUE)$status, "fail")
  bad <- p; bad$data$neglog10_p <- 1
  expect_equal(bio_cross_check(bad, tab, allow_subset = TRUE)$status, "fail")
  expect_error(bio_plot_enrichment(tab, ratio_col = "missing"), "required")
})

test_that("claim validation handles vectors, indexed paths and empty claims", {
  ex <- bio_explain(new_bio_context("generic", "list", facts = list(variance_explained = c(.6, .3), n = 10)), use_llm = FALSE)
  expect_equal(bio_validate_explanation(ex, list(list(fact = "n")))$validation$status, "unverified")
  expect_equal(bio_validate_explanation(ex, list(list(fact = "n", value = c(10, 11))))$validation$status, "fail")
  expect_equal(bio_validate_explanation(ex, list(list(fact = "variance_explained.1", value = .6)))$validation$status, "pass")
  expect_equal(bio_validate_explanation(ex, list("malformed"))$validation$status, "unverified")
  ex$context$facts$p <- 1e-132
  expect_equal(bio_validate_explanation(ex, list(list(fact = "p", value = 0)))$validation$status, "fail")
  expect_equal(bio_validate_explanation(ex, list(list(fact = "p", value = 1e-132)))$validation$status, "pass")
  ex$context$top_features <- data.frame(log2fc = c(2.111, -1.25))
  expect_equal(bio_validate_explanation(ex, list(list(fact = "top_features.2.log2fc", value = -1.25)))$validation$status, "pass")
})

test_that("Shiny sessions keep workspaces and model configuration separate", {
  skip_if_not_installed("shiny")
  env <- new.env(); env$seed_object <- 1
  app <- BioExplainR:::.bio_app(env)
  shiny::testServer(app, {
    session$setInputs(code = "only_session_one <- 42", run_code = 1, run_label = "test")
    expect_true(exists("only_session_one", workspace, inherits = FALSE))
    session$setInputs(preset = "local", model = "session-one", api_key_env = "", api_key = "",
                      base_url = "", timeout = 60, max_retries = 0, language = "zh", save_config = 1)
    expect_equal(state$config$model, "session-one")
  })
  shiny::testServer(app, {
    expect_false(exists("only_session_one", workspace, inherits = FALSE))
    expect_length(state$records, 0)
    expect_false(identical(state$config$model, "session-one"))
  })
})
