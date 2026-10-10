test_that("numeric factors are read by value and invalid probabilities are rejected", {
  x <- data.frame(log2FoldChange = factor(c("2", "-2")), padj = factor(c("0.01", "0.03")))
  expect_equal(bio_context(x)$facts$n_significant, 2)
  expect_equal(bio_context(x)$facts$n_down, 1)
  x$padj <- c(-0.1, 0.01)
  expect_error(bio_context(x), "invalid p-values")
  expect_error(bio_context(make_de(), thresholds = list(lfc = -1)), "Invalid threshold")
  expect_error(bio_context(make_de(), n_top = -1), "n_top")
  expect_error(bio_config(timeout = 0), "timeout")
  expect_error(bio_config(max_retries = Inf), "max_retries")
})

test_that("configuration omits URL credentials and payload budgets are enforced", {
  cfg <- bio_config(base_url = "https://user:PRIVATE_PASSWORD@gateway.example/v1", model = "m", api_key = "dummy-secret-123")
  expect_false(grepl("PRIVATE_PASSWORD", paste(format(cfg), collapse = " ")))
  expect_equal(as.list(cfg)$endpoint_host, "https://gateway.example")
  ctx <- bio_context(make_de(), notes = strrep("long-background-", 2000))
  expect_error(bio_context_payload(ctx, max_chars = 1000), "exceeds max_chars")
  query_cfg <- bio_config(base_url = "https://gateway.example/v1?route=alpha", model = "m")
  expect_equal(bio_endpoint_url(query_cfg), "https://gateway.example/v1/chat/completions?route=alpha")
  expect_error(bio_endpoint_url(bio_config(endpoint = "file:///etc/passwd", model = "m")), "full http")
})

test_that("model diagnosis omits code and strips character literals from stacks", {
  cfg <- bio_config("anthropic", model = "m", api_key_env = "BIO_TEST_SECRET")
  withr::local_envvar(BIO_TEST_SECRET = "unknown-format-secret-987654321")
  leak <- function(x) stop("diagnostic failure")
  run <- suppressMessages(bio_record({
    patient <- "PRIVATE_PATIENT_ABC"
    leak("PRIVATE_PATIENT_ABC")
  }))
  sent <- NULL
  mock <- function(req) {
    sent <<- req$body$data$messages[[1]]$content
    httr2::response(200, headers = list(`Content-Type` = "application/json"),
      body = charToRaw('{"content":[{"type":"text","text":"{\\"direct_cause\\":\\"failed\\"}"}]}'))
  }
  httr2::with_mocked_responses(mock, bio_explain_error(run, config = cfg, use_llm = TRUE))
  expect_false(grepl("PRIVATE_PATIENT_ABC", sent))
  expect_match(sent, '"code": null', fixed = TRUE)
  httr2::with_mocked_responses(mock, bio_explain_error(run, config = cfg, use_llm = TRUE, include_code = TRUE))
  expect_false(grepl("PRIVATE_PATIENT_ABC", sent))
  expect_match(sent, "LITERAL OMITTED", fixed = TRUE)
  txt <- bio_report(run, config = cfg)
  expect_false(grepl("PRIVATE_PATIENT_ABC", txt))
})

test_that("known configured environment keys are filtered from reports without a live request", {
  cfg <- bio_config("openai", model = "m", api_key_env = "BIO_TEST_SECRET")
  withr::local_envvar(BIO_TEST_SECRET = "unusual-format-secret-0123456789")
  txt <- bio_report(bio_context(make_de(), notes = "unusual-format-secret-0123456789"), config = cfg)
  expect_false(grepl("unusual-format-secret", txt))
})

test_that("semantic invariants fail when their required inputs or columns are missing", {
  skip_if_not_installed("callr")
  result <- bio_validate_fix(quote(data.frame(x = integer())),
    invariants = list(inv_same_nrow_as_input("missing"), inv_no_na("missing")))
  expect_equal(result$status, "invariants_failed")
  expect_true(all(!result$invariants$passed))
  expect_error(bio_validate_fix(quote(x), inputs = list(x = 1, x = 2)), "named list")
})
