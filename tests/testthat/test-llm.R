json_resp <- function(body, status = 200, headers = list()) {
  httr2::response(status_code = status, headers = c(list(`Content-Type` = "application/json"), headers),
                  body = charToRaw(enc2utf8(as.character(jsonlite::toJSON(body, auto_unbox = TRUE)))))
}

model_json <- '{"data_facts":["共 200 个特征"],"statistical_meaning":["s"],"biological_interpretation":["b"],"uncertainty":["u"],"cannot_conclude":["c"],"learning_questions":["q"],"evidence_used":["GO:GO:0006954","made-up:1"]}'

test_that("OpenAI-compatible request builder", {
  cfg <- bio_config("openai_compatible", base_url = "https://proxy.example/v1", model = "my-model",
                    api_key = "sk-test-openai-000001", temperature = 0.2, max_tokens = 300)
  req <- bio_build_request(cfg, "SYS", "USER")
  expect_equal(req$url, "https://proxy.example/v1/chat/completions")
  expect_equal(req$headers$Authorization, "Bearer sk-test-openai-000001")
  expect_true("Authorization" %in% attr(req$headers, "redact"))
  b <- req$body$data
  expect_equal(b$model, "my-model")
  expect_equal(b$messages[[1]]$role, "system")
  expect_equal(b$messages[[2]]$content, "USER")
  expect_equal(b$max_tokens, 300L)
  expect_equal(b$temperature, 0.2)
  expect_equal(req$options$timeout_ms, 60000)
  msg <- NULL
  out <- capture.output(msg <- capture.output(print(req), type = "message"))
  printed <- c(out, msg)
  expect_false(grepl("sk-test-openai", paste(printed, collapse = "")))
})

test_that("Anthropic request builder", {
  cfg <- bio_config("anthropic", model = "claude-custom-id", api_key = "ant-test-key-000002")
  req <- bio_build_request(cfg, "SYS", "USER")
  expect_equal(req$url, "https://api.anthropic.com/v1/messages")
  expect_equal(req$headers$`x-api-key`, "ant-test-key-000002")
  expect_equal(req$headers$`anthropic-version`, "2023-06-01")
  expect_null(req$headers$Authorization)
  b <- req$body$data
  expect_equal(b$system, "SYS")
  expect_equal(b$messages[[1]]$role, "user")
  expect_equal(b$model, "claude-custom-id")
})

test_that("local Ollama needs no key", {
  withr::local_envvar(BIOEXPLAINR_API_KEY = NA)
  req <- bio_build_request(bio_config("ollama", model = "llama3"), "s", "u")
  expect_null(req$headers$Authorization)
})

test_that("response parsers handle both protocols", {
  o <- bio_parse_response("openai", list(model = "m", choices = list(list(message = list(content = "hello"), finish_reason = "stop")),
                                         usage = list(total_tokens = 5)))
  expect_equal(o$text, "hello")
  a <- bio_parse_response("anthropic", list(model = "m", stop_reason = "end_turn",
                                            content = list(list(type = "text", text = "he"), list(type = "text", text = "llo"))))
  expect_equal(a$text, "hello")
  expect_error(bio_parse_response("openai", list(error = list(message = "bad key sk-zzzzzzzzzzzzzz"))), "REDACTED")
  expect_error(bio_parse_response("anthropic", list(content = list())), "no 'content'")
})

test_that("bio_explain with mocked OpenAI-compatible model keeps facts separate", {
  cfg <- bio_config("openai_compatible", base_url = "https://mock.example/v1", model = "mock-model",
                    api_key = "sk-mock-key-1234567890")
  captured <- NULL
  mock <- function(req) {
    captured <<- req
    json_resp(list(model = "mock-model-2026", choices = list(list(message = list(content = model_json), finish_reason = "stop"))))
  }
  so_ev <- bio_evidence("GO", id = "GO:0006954", title = "inflammatory response", claim = "c", type = "database")
  ex <- httr2::with_mocked_responses(mock, bio_explain(make_de(200), config = cfg, use_llm = TRUE, evidence = list(so_ev)))
  expect_s3_class(ex, "bio_explanation")
  expect_true(ex$llm_meta$used)
  expect_true(ex$llm_meta$structured)
  expect_equal(ex$llm$data_facts, "共 200 个特征")
  expect_equal(ex$llm_meta$model_reported, "mock-model-2026")
  expect_equal(ex$llm_meta$unknown_evidence_ids, "made-up:1")
  expect_match(ex$verification$llm_text, "not numerically verified")
  # local deterministic facts are untouched by model output
  expect_equal(ex$context$facts$n_features, 200)
  sent <- captured$body$data$messages[[2]]$content
  expect_match(sent, "n_significant")
  expect_false(grepl("baseMean\":\\s*\\[", sent))  # no full columns
})

test_that("bio_explain with mocked Anthropic model, private data never sent", {
  cfg <- bio_config("anthropic", model = "mock-claude", api_key = "ant-mock-key-123456")
  captured <- NULL
  mock <- function(req) {
    captured <<- req
    json_resp(list(model = "mock-claude", stop_reason = "end_turn",
                   content = list(list(type = "text", text = paste0("```json\n", model_json, "\n```")))))
  }
  ex <- httr2::with_mocked_responses(mock, bio_explain(make_fake_seurat(), config = cfg, use_llm = TRUE))
  expect_true(ex$llm_meta$structured)
  body_txt <- jsonlite::toJSON(captured$body$data, auto_unbox = TRUE)
  expect_false(grepl("PATIENT_", body_txt))
  expect_false(grepl("BARCODE_", body_txt))
  expect_false(grepl("ant-mock-key", body_txt))
})

test_that("unstructured model text is kept as free text", {
  cfg <- bio_config("openai", model = "m", api_key = "sk-free-text-12345678")
  mock <- function(req) json_resp(list(choices = list(list(message = list(content = "just prose"), finish_reason = "stop"))))
  ex <- httr2::with_mocked_responses(mock, bio_explain(make_de(), config = cfg, use_llm = TRUE))
  expect_false(ex$llm_meta$structured)
  expect_equal(ex$llm$free_text, "just prose")
})

test_that("HTTP errors are clear and do not leak keys; non-transient errors are not retried", {
  cfg <- bio_config("openai", model = "m", api_key = "sk-leakcheck-99999999", max_retries = 2)
  n <- 0
  mock <- function(req) {
    n <<- n + 1
    json_resp(list(error = list(message = "Incorrect API key provided: sk-leakcheck-99999999")), status = 401)
  }
  err <- tryCatch(httr2::with_mocked_responses(mock, bio_llm_chat(cfg, "s", "u")), error = function(e) conditionMessage(e))
  expect_match(err, "HTTP 401")
  expect_match(err, "Check the API key")
  expect_false(grepl("sk-leakcheck", err))
  expect_equal(n, 1)
})

test_that("retry policy is bounded and limited to transient statuses", {
  # httr2 mocks bypass the retry loop, so the policy itself is inspected.
  cfg <- bio_config("openai", model = "m", api_key = "sk-retry-test-1234567", max_retries = 1, timeout = 7)
  req <- bio_build_request(cfg, "s", "u")
  expect_equal(req$policies$retry_max_tries, 2)
  expect_equal(req$options$timeout_ms, 7000)
  transient <- req$policies$retry_is_transient
  for (st in c(408, 429, 500, 502, 503, 504, 529)) expect_true(transient(httr2::response(st)))
  for (st in c(400, 401, 403, 404, 422)) expect_false(transient(httr2::response(st)))
  expect_equal(bio_build_request(bio_config("openai", model = "m", api_key = "sk-retry-test-1234567",
                                            max_retries = 0), "s", "u")$policies$retry_max_tries, 1)
})

test_that("use_llm = TRUE without configuration fails clearly; NA falls back to local", {
  expect_error(bio_explain(make_de(), config = bio_config(), use_llm = TRUE), "no model is usable")
  ex <- bio_explain(make_de(), config = bio_config())
  expect_false(ex$llm_meta$used)
  expect_null(ex$llm)
})
test_that("provider-specific body parameters reach the request without overriding core fields", {
  cfg <- bio_config("deepseek", model = "test-model", api_key = "dummy",
                    extra_body = list(thinking = list(type = "disabled")))
  req <- bio_build_request(cfg, "Return JSON", "Hi")
  expect_equal(req$body$data$thinking$type, "disabled")
  expect_error(bio_config(extra_body = list(model = "other")), "core request")
})
