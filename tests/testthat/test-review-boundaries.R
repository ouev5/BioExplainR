test_that("context identity is idempotent and legacy identity stays missing", {
  ctx <- new_bio_context("generic", "list", facts = list(n = 1L))
  expect_identical(.finalize_context(ctx)$context_id, ctx$context_id)
  expect_identical(bio_explain(ctx, use_llm = FALSE)$manifest$context_id, ctx$context_id)
  ctx$context_id <- ctx$facts_hash <- ctx$schema_version <- NULL
  expect_null(bio_context_manifest(ctx)$context_id)
  expect_null(bio_context_manifest(ctx)$facts_hash)
  expect_false(identical(.hash_object(c(a = 1, b = 2)), .hash_object(c(x = 1, y = 2))))
})

test_that("typed findings govern status and reject type and scope coercion", {
  scope <- list(species = "human")
  ctx <- new_bio_context("generic", "list", facts = list(n = 10L, flag = TRUE, label = "1", p = 1e-132, `a.b` = 2), scope = scope,
    fact_descriptors = list(n = list(unit = "features")))
  ex <- bio_explain(ctx, use_llm = FALSE)
  cl <- list(id = "c", path_tokens = c("a.b"), value = 2, scope = scope)
  expect_equal(bio_validate_claims(ex, cl)$validation$status, "pass")
  expect_equal(bio_validate_claims(ex, list(cl, cl))$validation$status, "fail")
  expect_equal(bio_validate_claims(ex, list(id = "c", fact = "flag", value = 1, scope = scope))$validation$status, "fail")
  expect_equal(bio_validate_claims(ex, list(id = "c", fact = "label", value = 1, scope = scope))$validation$status, "fail")
  expect_equal(bio_validate_claims(ex, list(id = "c", fact = "n", value = 10.000001, scope = scope))$validation$status, "fail")
  expect_equal(bio_validate_claims(ex, list(id = "c", fact = "p", value = 0, scope = scope))$validation$status, "fail")
  expect_equal(bio_validate_claims(ex, list(id = "c", fact = "p", value = "1e-132", scope = scope))$validation$status, "pass")
  expect_equal(bio_validate_claims(ex, list(id = "c", fact = "n", value = 10L, unit = "spots", scope = scope))$validation$status, "fail")
  expect_equal(bio_validate_claims(ex, list(id = "c", fact = "n", value = 10L, scope = list(species = "mouse")))$validation$status, "fail")
  expect_equal(bio_validate_claims(ex, list(id = "c", fact = "n", value = 10L))$validation$status, "partial")
  expect_false(.ledger_fact_get(ctx, c("99999999999999999999999"))$found)
  ex$llm <- list(claims = list(c(cl, list(origin = "local_template", validation = list(status = "pass")))))
  ledger <- bio_claim_ledger(ex)
  expect_equal(ledger$claims$origin, "model")
  expect_null(ledger$claims$validation[[1]])
  expect_equal(bio_validate_claims(ex)$validation$status, "partial")
})

test_that("evidence contradictions and missing provenance cannot pass", {
  scope <- list(species = "human")
  ev <- bio_evidence("Local", "E", scope = scope, role = "experimental_support", content = "fixed excerpt")
  ctx <- new_bio_context("generic", "list", facts = list(n = 1L), scope = scope)
  ex <- bio_explain(ctx, use_llm = FALSE, evidence = ev)
  cl <- list(id = "c", fact = "n", value = 1L, claim_type = "biological_association", evidence_refs = ev$id, scope = scope)
  ledger <- bio_claim_ledger(ex, cl)
  for (relation in c("contradicts", "irrelevant", "definition_only")) {
    rel <- bio_evidence_support(cl, ev, relation = relation)
    expect_equal(bio_validate_evidence_support(ledger, ev, rel)$status, "fail")
    expect_equal(bio_validate_claims(ex, cl, relations = rel)$validation$status, "fail")
  }
  expect_error(bio_evidence_support(cl, ev, origin = "expert_reviewed"), "requires")
  rel <- bio_evidence_support(cl, ev, origin = "expert_reviewed", reviewed_at = "fixture", reviewer_id = "fixture-reviewer", rubric_version = "fixture")
  expect_equal(bio_validate_evidence_support(ledger, ev, rel)$status, "pass")
  rel$pairs$content_hash <- "different"
  expect_equal(bio_validate_evidence_support(ledger, ev, rel)$status, "unverified")
  expect_equal(bio_validate_claims(ex, cl)$validation$status, "partial")
})

test_that("technical roles do not mask conflicting mappings or absent modalities", {
  map <- data.frame(modality = c("rna", "rna"), source_id = "s", biological_unit = c("a", "b"), replicate_role = "technical")
  expect_error(bio_sample_map(map), "ambiguous")
  map$biological_unit <- "a"
  expect_equal(bio_validate_sample_map(bio_sample_map(map))$status, "pass")
  map <- data.frame(modality = c("rna", "protein"), source_id = c("s1", "s2"), biological_unit = "a")
  expect_equal(bio_validate_sample_map(map, observed = list(rna = "s1"))$status, "partial")
})

test_that("payload sanitization retains array shape and removes nested identifiers", {
  ctx <- new_bio_context("generic", "list", facts = list(n = 1L, entries = list(list(n = 2L), list(n = 3L))),
    metadata = list(notes = list(sample_id = "PRIVATE_SAMPLE", text = "https://example.org/?token=PRIVATE_TOKEN")))
  p <- bio_context_payload(ctx)
  expect_null(names(p$facts$entries))
  js <- .json(p)
  expect_false(grepl("PRIVATE_SAMPLE|PRIVATE_TOKEN", js))
  m <- bio_context_manifest(ctx, api_key = "PRIVATE_KEY", model = "m")
  expect_null(m$api_key)
  expect_equal(m$model, "m")
  expect_false(grepl("PRIVATE", .json(.payload_sanitize(list(notes = c(sample_id = "PRIVATE"),
    preview = data.frame(label = factor("/home/PRIVATE/file"))), bio_payload_policy()))))
})

test_that("docking parsing and scoring preserve unknown references", {
  expect_error(bio_docking_context(data.frame(ligand = "L", score = 1)), "receptor")
  ctx <- bio_docking_context(data.frame(receptor = "R", ligand = c("L1", "L2"), score = c(1, 3), rmsd = 0),
    provenance = list(score_direction = "higher_is_better"))
  expect_equal(ctx$top_features$score, c(3, 1))
  expect_equal(bio_docking_audit(ctx)$findings$status[bio_docking_audit(ctx)$findings$check == "rmsd_reference"], "unverified")
  s <- bio_score_benchmark(data.frame(case_id = "c", method_id = "m", prediction = "yes", reference = NA_character_, correct = TRUE))
  expect_equal(s$status, "unverified")
  expect_true(is.na(s$summary$all_target_accuracy))
  s <- bio_score_benchmark(data.frame(case_id = "c", method_id = "m", prediction = "no", reference = "yes", correct = TRUE))
  expect_equal(s$summary$all_target_accuracy, 0)
})
