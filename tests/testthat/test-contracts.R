test_that("versioned contexts and payload policies preserve facts and bound previews", {
  ctx <- bio_context(make_de(20), species = "Homo sapiens", contrast = "treated vs control")
  expect_equal(ctx$schema_version, "1.0")
  expect_true(nchar(ctx$context_id) == 64)
  expect_true(nchar(ctx$facts_hash) == 64)
  expect_true(length(ctx$fact_descriptors) > 0)
  p <- bio_context_payload(ctx, max_top = 2, max_chars = 12000)
  expect_equal(p$completeness$status, "complete")
  expect_equal(attr(p, "policy_id") |> nchar(), 64)
  expect_error(bio_payload_policy(max_top = 1.5), "whole number")
  expect_error(bio_context_payload(ctx, policy = bio_payload_policy(max_chars = 100, fact_mode = "complete")), "exceed")
})

test_that("runtime manifests distinguish facts and payload hashes", {
  ctx <- bio_context(make_de(12))
  p <- bio_context_payload(ctx)
  m <- bio_context_manifest(ctx, payload = p, request = list(model = "m", secret = "should not persist"), status = "executed")
  expect_s3_class(m, "bio_manifest")
  expect_equal(m$context_id, ctx$context_id)
  expect_equal(m$payload_hash, attr(p, "payload_hash"))
  expect_true(is.null(m$request_hash) || nchar(m$request_hash) == 64)
  expect_false(grepl("should not persist", jsonlite::toJSON(m, auto_unbox = TRUE, force = TRUE)))
})

test_that("typed claim ledgers validate values and keep legacy validation readable", {
  ctx <- new_bio_context("generic", "list", facts = list(n = 10), scope = list(species = "human"))
  ex <- bio_explain(ctx, use_llm = FALSE)
  good <- list(list(id = "c1", claim_type = "statistical_fact", text = "ten", fact = "n", value = 10))
  v <- bio_validate_claims(ex, good)
  expect_s3_class(v$claim_ledger, "bio_claim_ledger")
  expect_true(any(v$validation$typed_findings$check == "value"))
  expect_true(v$validation$status %in% c("pass", "partial"))
  bad <- bio_validate_claims(ex, list(list(id = "c1", claim_type = "statistical_fact", fact = "n", value = 11)))
  expect_equal(bad$validation$status, "fail")
  malformed <- bio_claim_ledger(ex, list("prose only"))
  expect_equal(nrow(malformed$claims), 1)
})

test_that("evidence support is pair-level and checks scope", {
  ev <- bio_evidence("Local", "E1", title = "definition", type = "database",
                     scope = list(species = "mouse"), content = "definition")
  ctx <- new_bio_context("generic", "list", facts = list(n = 1), scope = list(species = "human"))
  ex <- bio_explain(ctx, use_llm = FALSE)
  ledger <- bio_claim_ledger(ex, list(list(id = "c1", claim_type = "biological_association", fact = "n", value = 1,
                                           scope = ctx$scope, evidence = ev$id)))
  rel <- bio_evidence_support(ledger$claims[1, ], ev, relation = "supports", origin = "user_declared")
  expect_equal(rel$pairs$status, "fail")
  checked <- bio_validate_evidence_support(ledger, ev, rel)
  expect_true(any(checked$findings$status %in% c("fail", "partial")))
})

test_that("sample maps, docking tables and benchmark contracts expose explicit missingness", {
  sm <- bio_sample_map(data.frame(modality = c("rna", "protein"), source_id = c("s2", "s1"),
                                  biological_unit = c("d1", "d1")))
  expect_equal(bio_validate_sample_map(sm)$status, "pass")
  dock <- bio_docking_context(data.frame(receptor = "R1", ligand = "L1", score = -7.2))
  expect_equal(dock$analysis_type, "docking")
  expect_equal(bio_docking_audit(dock)$status, "partial")
  scored <- bio_score_benchmark(data.frame(case_id = "c1", method_id = "m1", prediction = "yes", reference = "yes"))
  expect_equal(scored$summary$all_target_accuracy, 1)
  expect_error(bio_challenge_manifest(data.frame(case_id = c("x", "x"))), "unique")
})
