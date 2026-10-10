test_that("spatial neighbor graphs respect section boundaries and units", {
  coords <- data.frame(x = c(0, 1, 0, 100), y = c(0, 0, 1, 100))
  graph <- bio_spatial_neighbors(coords, mode = "knn", k = 2,
                                 section = c("a", "a", "a", "b"), units = "micron")
  expect_s3_class(graph, "bio_spatial_neighbors")
  expect_equal(graph$units, "micron")
  expect_true(all(graph$edges$from_section == graph$edges$to_section))
  radius_graph <- bio_spatial_neighbors(coords[1:3, ], mode = "radius", radius = 1.01)
  expect_true(nrow(radius_graph$edges) > 0)
  expect_true(all(radius_graph$edges$distance <= 1.01))
  expect_error(bio_spatial_neighbors(coords, k = 0), "positive")
})
