wire_response <- function(body) httr2::response(status_code = 200,
  headers = list(`Content-Type` = "application/json"),
  body = charToRaw(as.character(jsonlite::toJSON(body, auto_unbox = TRUE))))

test_that("HTTP JSON encoding and hashes preserve full double precision", {
  values <- list(p = 1e-132, pca = 0.47842864474215936, zero = 0, missing = NA_real_)
  for (protocol in c("openai", "anthropic")) {
    cfg <- bio_config(protocol, model = "fixture", api_key = "fixture-key-private", extra_body = list(fixture = values))
    captured <- NULL
    mock <- function(req) {
      captured <<- req
      if (protocol == "openai") wire_response(list(choices = list(list(message = list(content = "ok"))))) else
        wire_response(list(content = list(list(type = "text", text = "ok"))))
    }
    result <- httr2::with_mocked_responses(mock, bio_llm_chat(cfg, "system", "user"))
    bytes <- as.character(do.call(jsonlite::toJSON, c(list(captured$body$data), captured$body$params)))
    actual <- jsonlite::fromJSON(bytes)$fixture
    expect_identical(actual$p, values$p)
    expect_identical(actual$pca, values$pca)
    expect_equal(actual$zero, 0)
    expect_null(actual$missing)
    expect_identical(result$request_hash, .sha256(charToRaw(enc2utf8(bytes))))
    expect_equal(result$request_bytes, nchar(bytes, type = "bytes"))
    expect_false(grepl("fixture-key-private", bytes))
  }
})

test_that("project, diagnostic and evidence prompts filter nested private fields", {
  cfg <- bio_config("openai", model = "fixture", api_key = "fixture-key-private")
  captured <- NULL
  mock <- function(req) {
    captured <<- req
    wire_response(list(choices = list(list(message = list(content = "prose")))))
  }
  ctx <- new_bio_context("generic", "list", facts = list(n = 1L))
  project <- bio_project(list(result = ctx), metadata = list(patient_id = "PRIVATE_PATIENT", notes = list(
    sample_id = "PRIVATE_SAMPLE", note = "/home/PRIVATE_PATH/result.csv https://example.org/?token=PRIVATE_TOKEN")))
  httr2::with_mocked_responses(mock, bio_explain_project(project, cfg, use_llm = TRUE))
  expect_false(grepl("PRIVATE_", .json(captured$body$data)))
  ev <- bio_evidence("Local", "e", content = list(patient_id = "PRIVATE_PATIENT"),
    title = "/home/PRIVATE_PATH/file", url = "https://example.org/?token=PRIVATE_TOKEN")
  httr2::with_mocked_responses(mock, bio_explain(ctx, cfg, use_llm = TRUE, evidence = list(ev),
    question = "/home/PRIVATE_PATH/result"))
  expect_false(grepl("PRIVATE_", .json(captured$body$data)))
  rec <- bio_record(stop("failed to read /home/PRIVATE_PATH/file https://example.org/?token=PRIVATE_TOKEN"))
  httr2::with_mocked_responses(mock, bio_explain_error(rec, cfg, use_llm = TRUE))
  expect_false(grepl("PRIVATE_", .json(captured$body$data)))
})
