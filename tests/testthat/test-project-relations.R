test_that("coverage distinguishes mapping validity from missing measurements", {
  sm <- bio_sample_map(data.frame(modality = c("rna", "rna", "protein", "protein"),
    source_id = c("r1", "r2", "p2", "p3"), biological_unit = c("u1", "u2", "u2", "u3")))
  z <- bio_validate_sample_map(sm, list(protein = c("p3", "p2"), rna = c("r2", "r1")),
                               primary_units = paste0("u", 1:4))
  expect_identical(z$status, "pass")
  expect_equal(z$coverage$n_units, c(2L, 2L))
  expect_equal(z$coverage$n_missing, c(2L, 2L))
  expect_equal(z$pairwise$n_shared, 1L)
  expect_equal(z$n_complete_units, 1L)
  expect_equal(z$n_unmeasured_units, 1L)
  expect_identical(z$complete_units, "u2")
  missing <- bio_validate_sample_map(sm, list(rna = c("r1", "r2")))
  expect_identical(missing$status, "partial")
  expect_equal(missing$coverage$n_units, c(2L, 0L))
  expect_equal(missing$n_complete_units, 0L)
  expect_identical(bio_validate_sample_map(sm, primary_units = "u1")$status, "fail")
  expect_error(bio_validate_sample_map(sm, list(rna = "r1", rna = "r2")), "uniquely")
  expect_error(bio_validate_sample_map(sm, list(rna = c("r1", "r1"))), "unique")
  sm$map$biological_unit[1] <- NA_character_
  expect_error(bio_validate_sample_map(sm), "non-missing")
})

relation_context <- function(effect, feature = "TP53") {
  new_bio_context("generic", "list", "test", "user_declared", facts = list(effect = effect),
    scope = list(dataset_id = "study", comparison_id = "late_vs_early", species = "Homo sapiens",
                 tissue = "adrenal", sample_level = "patient"),
    design = list(numerator = "late", denominator = "early"),
    fact_descriptors = list(effect = list(feature_id = feature)))
}

test_that("direction checks require compatible scope and explicit feature mapping", {
  rel <- data.frame(id = "pair1", from = "rna", to = "protein", from_fact = "effect",
                    to_fact = "effect", feature_id = "TP53", expected = "same")
  a <- relation_context(2); b <- relation_context(0.3)
  check <- function(a, b, r = rel) bio_project(list(rna = a, protein = b), relations = r)$relation_validation
  expect_identical(check(a, b)$status, "pass")
  expect_identical(check(a, relation_context(-0.3))$status, "fail")
  inverse <- rel; inverse$expected <- "opposite"
  expect_identical(check(a, relation_context(-0.3), inverse)$status, "pass")
  expect_identical(check(a, relation_context(0))$status, "partial")
  expect_identical(check(a, relation_context(NA_real_))$status, "partial")
  expect_identical(check(a, relation_context(1, "PTEN"))$status, "fail")
  b$scope$comparison_id <- "early_vs_late"
  expect_identical(check(a, b)$status, "fail")
  b <- relation_context(1); b$design <- list(numerator = "early", denominator = "late")
  z <- check(a, b)
  expect_identical(z$status, "fail")
  expect_identical(z$findings$status[z$findings$check == "direction"], "unverified")
  b <- relation_context(1); b$design <- "~ stage"
  expect_identical(check(a, b)$status, "partial")
  b <- relation_context(1); b$scope$dataset_id <- NULL
  expect_identical(check(a, b)$status, "partial")
  invalid <- rel; invalid$from <- "absent"
  expect_identical(check(a, relation_context(1), invalid)$status, "fail")
  expect_error(check(a, relation_context(1), rbind(rel, rel)), "unique")
  expect_match(bio_report(bio_project(list(rna = a, protein = relation_context(1)), relations = rel)),
               "Explicit cross-result direction checks")
})

test_that("exact tokens support scientific identifiers containing dots", {
  a <- relation_context(1); a$facts <- list("HLA.A" = 1)
  a$fact_descriptors <- list("HLA.A" = list(feature_id = "HLA.A"))
  rel <- data.frame(id = "r1", from = "rna", to = "protein", from_fact = "HLA.A",
                    to_fact = "HLA.A", feature_id = "HLA.A", expected = "same")
  rel$from_tokens <- rel$to_tokens <- list("HLA.A")
  p <- bio_project(list(rna = a, protein = a), relations = rel)
  expect_identical(p$relation_validation$status, "pass")
})
