cd <- data.frame(condition = c("treated", "control", "treated", "control"), stringsAsFactors = FALSE)

test_that("runnable fix without invariants is runtime-only", {
  skip_if_not_installed("callr")
  v <- bio_validate_fix(quote(cd[order(cd$condition), , drop = FALSE]), inputs = list(cd = cd))
  expect_equal(v$status, "runtime_only")
  expect_true(v$runtime_ok)
  expect_false(v$semantically_verified)
  expect_equal(v$output_shape$dim, c(4L, 1L))
  expect_match(v$note, "operating-system-level security sandbox")
})

test_that("invariants decide semantic status", {
  skip_if_not_installed("callr")
  fix <- quote({
    cd$condition <- relevel(factor(cd$condition), ref = "control")
    cd
  })
  ok <- bio_validate_fix(fix, inputs = list(cd = cd),
                         invariants = list(inv_factor_levels("condition", c("control", "treated")),
                                           inv_same_nrow_as_input("cd"), inv_class("data.frame"),
                                           inv_has_columns("condition"), inv_no_na("condition")))
  expect_equal(ok$status, "invariants_passed")
  expect_true(ok$semantically_verified)
  expect_true(all(ok$invariants$passed))

  wrong <- bio_validate_fix(quote({ cd$condition <- factor(cd$condition, levels = c("treated", "control")); cd }),
                            inputs = list(cd = cd),
                            invariants = list(inv_factor_levels("condition", c("control", "treated"))))
  expect_equal(wrong$status, "invariants_failed")
  expect_false(wrong$semantically_verified)
  expect_match(wrong$invariants$detail, "expected")

  custom <- bio_validate_fix("nrow(cd)", inputs = list(cd = cd),
                             invariants = bio_invariant("is_four", function(result, inputs) result == 4))
  expect_equal(custom$status, "invariants_passed")
})

test_that("runtime failures are recorded", {
  skip_if_not_installed("callr")
  v <- bio_validate_fix(quote(stop("fix does not work")), inputs = list(cd = cd), invariants = list(inv_nrow(4)))
  expect_equal(v$status, "runtime_failed")
  expect_match(v$error, "fix does not work")
  v2 <- bio_validate_fix(quote(undefined_input + 1), inputs = list(cd = cd))
  expect_equal(v2$status, "runtime_failed")
})

test_that("explicit, named inputs are required", {
  expect_error(bio_validate_fix(), "explicit")
  expect_error(bio_validate_fix(quote(1), inputs = list(1, 2)), "named list")
  expect_error(bio_validate_fix(quote(1), invariants = list(function(x) TRUE)), "bio_invariant")
})

test_that("the child does not see the parent session", {
  skip_if_not_installed("callr")
  assign("parent_only_object_xyz", 1, envir = globalenv())
  on.exit(rm("parent_only_object_xyz", envir = globalenv()))
  v <- bio_validate_fix(quote(exists("parent_only_object_xyz")), inputs = list(a = 1),
                        invariants = bio_invariant("not_visible", function(result, inputs) isFALSE(result)))
  expect_equal(v$status, "invariants_passed")
})

test_that("timeouts are reported as runtime failures", {
  skip_if_not_installed("callr")
  skip_on_cran()
  v <- bio_validate_fix(quote(Sys.sleep(10)), inputs = list(a = 1), timeout = 2)
  expect_equal(v$status, "runtime_failed")
})
