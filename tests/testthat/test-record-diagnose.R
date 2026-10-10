test_that("successful expressions keep side effects and value", {
  env <- new.env()
  rec <- bio_record({
    x1 <- 1:10
    y1 <- sum(x1)
    y1 * 2
  }, envir = env)
  expect_equal(rec$status, "ok")
  expect_equal(bio_value(rec), 110)
  expect_equal(get("y1", envir = env), 55)
  expect_true(all(c("x1", "y1") %in% names(rec$objects_created)))
  expect_null(rec$error)
})

test_that("default environment is the caller's", {
  f <- function() {
    bio_record(local_var <- 42)
    local_var
  }
  expect_equal(f(), 42)
})

test_that("errors are recorded with the original stack before unwinding", {
  outer_fn <- function(v) middle_fn(v)
  middle_fn <- function(v) inner_fn(v)
  inner_fn <- function(v) stop("deliberate failure in inner_fn")
  env <- environment()
  rec <- suppressMessages(bio_record({
    before <- "kept"
    outer_fn(1)
  }, envir = env))
  expect_equal(rec$status, "error")
  expect_equal(rec$error$message, "deliberate failure in inner_fn")
  st <- rec$error$stack
  expect_true(any(grepl("^outer_fn\\(1\\)", st)))
  expect_true(any(grepl("^middle_fn\\(v\\)", st)))
  expect_true(any(grepl("^inner_fn\\(v\\)", st)))
  expect_lt(which(grepl("^outer_fn", st)), which(grepl("^inner_fn", st)))
  expect_false(any(grepl("bio_record_eval|withCallingHandlers|tryCatch", st)))
  expect_equal(rec$error$location, "inner_fn(v)")
  expect_equal(before, "kept")
  expect_identical(bio_last_error()$error$message, "deliberate failure in inner_fn")
  expect_identical(bio_last_error(rec)$status, "error")
})

test_that("errors can be re-thrown and warnings are recorded", {
  expect_error(suppressMessages(bio_record(stop("boom"), rethrow = TRUE)), "boom")
  rec <- bio_record({
    warning("first warning")
    "done"
  }, muffle_warnings = TRUE)
  expect_equal(rec$status, "warning")
  expect_equal(rec$warnings[[1]]$message, "first warning")
  expect_equal(bio_value(rec), "done")
})

test_that("object summaries contain no values", {
  env <- new.env()
  rec <- bio_record(secret_df <- data.frame(patient = c("PATIENT_SECRET_1", "PATIENT_SECRET_2"), v = 1:2), envir = env)
  s <- jsonlite::toJSON(rec$objects_created, auto_unbox = TRUE)
  expect_false(grepl("PATIENT_SECRET", s))
  expect_equal(rec$objects_created$secret_df$dim, c(2L, 2L))
})

test_that("offline categories cover common errors", {
  cat_of <- function(msg) bio_explain_error(msg)$category
  expect_equal(cat_of("there is no package called 'DESeq2'"), "package_missing")
  expect_equal(cat_of("could not find function \"FindMarkers\""), "function_missing")
  expect_equal(cat_of("object 'dds' not found"), "object_missing")
  expect_equal(cat_of("undefined columns selected"), "column_missing")
  expect_equal(cat_of("arguments imply differing number of rows: 10, 12"), "dimension_mismatch")
  expect_equal(cat_of("unable to find an inherited method for function 'assay' for signature '\"data.frame\"'"), "s4_slot_or_method")
  expect_equal(cat_of("None of the keys entered are valid keys for 'SYMBOL'"), "gene_id_mapping")
  expect_equal(cat_of("contrasts can be applied only to factors with 2 or more levels"), "factor_level_contrast")
  expect_equal(cat_of("some values in assay are not integers"), "count_data_invalid")
  expect_equal(cat_of("NA/NaN/Inf in foreign function call (arg 1)"), "na_nan_inf")
  expect_equal(cat_of("non-numeric argument to binary operator"), "type_mismatch")
  expect_equal(cat_of("unused argument (foo = 1)"), "argument_issue")
  expect_equal(cat_of("cannot open file 'x.csv': No such file or directory"), "file_path")
  expect_equal(cat_of("something totally new"), "unknown")
})

test_that("fix suggestions are unverified and Bioconductor-aware", {
  s <- bio_suggest_fix("there is no package called 'DESeq2'")
  expect_s3_class(s, "bio_fix_suggestions")
  expect_true(all(vapply(s$suggestions, function(z) grepl("unverified", z$status), logical(1))))
  expect_match(s$suggestions[[1]]$code, "BiocManager::install\\(\"DESeq2\"\\)")
  f <- bio_suggest_fix("could not find function \"enrichGO\"")
  expect_match(f$suggestions[[1]]$code, "clusterProfiler")
  env <- new.env()
  assign("counts_matrix", matrix(1:4, 2), envir = env)
  rec <- suppressMessages(bio_record(counts_matrx + 1, envir = env))
  s2 <- bio_suggest_fix(rec)
  expect_true(any(grepl("counts_matrix", vapply(s2$suggestions, `[[`, "", "text"))))
})

test_that("error diagnosis with mocked model stays unverified and is not executed", {
  cfg <- bio_config("openai", model = "m", api_key = "sk-diag-mock-12345678")
  mock <- function(req) httr2::response(200, headers = list(`Content-Type` = "application/json"),
    body = charToRaw(as.character(jsonlite::toJSON(list(choices = list(list(message = list(
      content = '{"direct_cause":"x","possible_causes":["a"],"suggested_steps":["s"],"proposed_code":"file.create(\'SHOULD_NOT_EXIST.txt\')","semantic_risks":["r"],"learning_tip":"t"}'),
      finish_reason = "stop"))), auto_unbox = TRUE))))
  rec <- suppressMessages(bio_record(stop("object 'abc' not found")))
  s <- httr2::with_mocked_responses(mock, bio_suggest_fix(rec, config = cfg, use_llm = TRUE))
  llm_s <- s$suggestions[[length(s$suggestions)]]
  expect_match(llm_s$status, "not executed")
  expect_match(llm_s$code, "SHOULD_NOT_EXIST")
  expect_false(file.exists("SHOULD_NOT_EXIST.txt"))
})
