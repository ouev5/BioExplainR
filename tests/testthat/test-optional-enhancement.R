test_that("real MultiAssayExperiment retains child facts and ID alignment", {
  skip_if_not_installed("MultiAssayExperiment")
  rna <- matrix(1:6, 3, dimnames = list(paste0("g", 1:3), c("PRIVATE_S2", "PRIVATE_S1")))
  protein <- matrix(1:2, 2, dimnames = list(c("p1", "p2"), "PRIVATE_P1"))
  sm <- S4Vectors::DataFrame(assay = factor(c("rna", "rna", "protein")), primary = c("b", "a", "a"),
                           colname = c("PRIVATE_S2", "PRIVATE_S1", "PRIVATE_P1"))
  x <- MultiAssayExperiment::MultiAssayExperiment(experiments = list(rna = rna, protein = protein),
    colData = S4Vectors::DataFrame(group = c("case", "control"), row.names = c("a", "b")), sampleMap = sm)
  ctx <- bio_context(x)
  expect_equal(ctx$adapter, "multi_assay_experiment")
  expect_equal(ctx$facts$n_modalities, 2L)
  expect_equal(ctx$facts$n_primary_units, 2L)
  expect_equal(ctx$facts$alignment_status, "pass")
  expect_s3_class(ctx$modalities$rna, "bio_context")
  expect_equal(ctx$modalities$rna$facts$dim, c(3L, 2L))
  expect_false(grepl("PRIVATE_", .json(bio_context_payload(ctx))))
})

test_that("real SpatialExperiment uses the spatial adapter and empty-image semantics", {
  skip_if_not_installed("SpatialExperiment")
  x <- SpatialExperiment::SpatialExperiment(assays = list(counts = matrix(1:6, 2)),
    colData = S4Vectors::DataFrame(sample_id = c("s1", "s1", "s2")),
    spatialCoords = matrix(c(0, 1, 10, 0, 1, 10), 3, dimnames = list(NULL, c("x", "y"))))
  ctx <- bio_context(x)
  expect_equal(ctx$adapter, "spatial_experiment")
  expect_equal(ctx$facts$n_spots, 3L)
  expect_equal(ctx$facts$n_sections, 2L)
  expect_equal(ctx$facts$coordinate_ranges, list(c(0, 10), c(0, 10)))
  expect_false(ctx$facts$has_image_metadata)
  expect_true(is.na(ctx$facts$coordinate_units))
  expect_false(grepl('"s1"|"s2"', .json(bio_context_payload(ctx))))
})
