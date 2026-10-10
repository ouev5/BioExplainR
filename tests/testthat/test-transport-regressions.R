test_that("usage counters and public URLs survive credential filtering", {
  ctx <- new_bio_context("generic", "list", facts = list(n = 1L))
  m <- bio_context_manifest(ctx, usage = list(total_tokens = 12L, input_tokens = 8L,
    output_tokens = 4L, api_token = "PRIVATE_SECRET"), request_hash_scope = "JSON body bytes")
  expect_equal(m$usage$total_tokens, 12L)
  expect_equal(m$usage$input_tokens, 8L)
  expect_null(m$usage$api_token)
  expect_equal(m$request_hash_scope, "JSON body bytes")
  expect_identical(.sensitive_value("https://example.org/paper?id=24926665"), "https://example.org/paper?id=24926665")
  clean <- .sensitive_value("https://example.org/paper?id=24926665&token=PRIVATE_TOKEN#PRIVATE_FRAGMENT")
  expect_false(grepl("PRIVATE|LOCAL_PATH", clean))
  expect_match(clean, "id=24926665", fixed = TRUE)
})

test_that("auto evidence passes through provider retrieval before object validation", {
  testthat::local_mocked_bindings(bio_fetch_evidence = function(...) list(bio_evidence("Local", "fixture")))
  ctx <- bio_context(data.frame(log2FoldChange = 2, padj = .01, row.names = "IL6"))
  ex <- bio_explain(ctx, use_llm = FALSE, evidence = "auto", evidence_sources = "europepmc")
  expect_equal(ex$evidence[[1]]$id, "Local:fixture")
  expect_equal(ex$evidence[[1]]$origin, "retrieved")
})
