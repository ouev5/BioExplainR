test_that("local config needs no provider and makes no network", {
  withr::local_envvar(BIOEXPLAINR_BASE_URL = NA, BIOEXPLAINR_MODEL = NA)
  cfg <- bio_config()
  expect_s3_class(cfg, "bio_config")
  expect_equal(cfg$protocol, "none")
  expect_false(bio_llm_available(cfg))
  expect_match(bio_llm_available(cfg, reason = TRUE), "local")
  expect_error(bio_build_request(cfg, "s", "u"), "Local mode")
  expect_equal(cfg$language, "en")
})

test_that("language values are strict and Chinese is opt-in", {
  expect_error(bio_config(language = "fr"), "one of")
  expect_error(bio_config(language = c("en", "zh")), "one of")
  expect_equal(bio_config(language = "zh")$language, "zh")
})

test_that("presets never contain keys or default models", {
  p <- bio_presets()
  expect_true(all(c("local", "openai", "openai_compatible", "anthropic", "deepseek", "ollama") %in% p$name))
  withr::local_envvar(BIOEXPLAINR_MODEL = NA, BIOEXPLAINR_BASE_URL = NA)
  for (nm in c("openai", "anthropic", "deepseek", "ollama")) {
    cfg <- bio_config(nm)
    expect_null(cfg$model)
    expect_error(bio_build_request(cfg, "s", "u"), "No model ID")
  }
})

test_that("custom model IDs and proxy URLs are accepted", {
  cfg <- bio_config("openai_compatible", base_url = "https://gw.example.org/llm/v1",
                    model = "org/custom-model:2026-preview", api_key = "dummy-key-0001")
  expect_equal(cfg$model, "org/custom-model:2026-preview")
  expect_equal(bio_endpoint_url(cfg), "https://gw.example.org/llm/v1/chat/completions")
})

test_that("endpoint URL normalisation avoids duplicated /v1", {
  mk <- function(...) bio_config(model = "m", api_key = "dummy-key-0001", ...)
  expect_equal(bio_endpoint_url(mk(base_url = "https://x.org/v1")), "https://x.org/v1/chat/completions")
  expect_equal(bio_endpoint_url(mk(base_url = "https://x.org/v1/")), "https://x.org/v1/chat/completions")
  expect_equal(bio_endpoint_url(mk(base_url = "https://x.org")), "https://x.org/v1/chat/completions")
  expect_equal(bio_endpoint_url(mk(base_url = "https://x.org/api/v3")), "https://x.org/api/v3/chat/completions")
  expect_equal(bio_endpoint_url(mk(base_url = "https://x.org/v1/chat/completions")), "https://x.org/v1/chat/completions")
  expect_equal(bio_endpoint_url(mk(endpoint = "https://exact.example/custom/path")), "https://exact.example/custom/path")
  a <- bio_config("anthropic", model = "m")
  expect_equal(bio_endpoint_url(a), "https://api.anthropic.com/v1/messages")
  a2 <- bio_config("anthropic", base_url = "https://proxy.example/v1", model = "m")
  expect_equal(bio_endpoint_url(a2), "https://proxy.example/v1/messages")
  a3 <- bio_config("anthropic", base_url = "https://proxy.example/v1/messages", model = "m")
  expect_equal(bio_endpoint_url(a3), "https://proxy.example/v1/messages")
  expect_equal(bio_endpoint_url(bio_config("deepseek", model = "m")), "https://api.deepseek.com/v1/chat/completions")
  expect_equal(bio_endpoint_url(bio_config("ollama", model = "llama3")), "http://localhost:11434/v1/chat/completions")
  expect_error(bio_endpoint_url(mk(base_url = "ftp://bad")), "http")
})

test_that("environment variables are resolved at request time", {
  withr::local_envvar(BIOEXPLAINR_BASE_URL = "https://env.example/v1", BIOEXPLAINR_MODEL = "env-model",
                      BIOEXPLAINR_API_KEY = "env-secret-key-123456")
  cfg <- bio_config("openai_compatible")
  expect_equal(cfg$model, "env-model")
  expect_true(bio_llm_available(cfg))
  req <- bio_build_request(cfg, "s", "u")
  expect_equal(req$url, "https://env.example/v1/chat/completions")
  expect_equal(req$headers$Authorization, "Bearer env-secret-key-123456")
})

test_that("preset-specific key env var is used and missing key is reported", {
  withr::local_envvar(ANTHROPIC_API_KEY = NA, BIOEXPLAINR_API_KEY = NA)
  cfg <- bio_config("anthropic", model = "m")
  expect_false(bio_llm_available(cfg))
  expect_error(bio_build_request(cfg, "s", "u"), "ANTHROPIC_API_KEY")
  withr::local_envvar(ANTHROPIC_API_KEY = "ant-test-key-abcdef")
  expect_true(bio_llm_available(cfg))
})

test_that("printing masks keys and public config omits them", {
  cfg <- bio_config("openai", model = "m", api_key = "sk-SUPERSECRET-123456789")
  out <- paste(capture.output(print(cfg)), collapse = "\n")
  expect_false(grepl("SUPERSECRET", out))
  expect_match(out, "\\*\\*\\*\\*")
  pub <- as.list(cfg)
  expect_false(grepl("SUPERSECRET", paste(unlist(pub), collapse = " ")))
  expect_false(grepl("SUPERSECRET", paste(format(cfg), collapse = " ")))
})

test_that("bio_redact masks known and key-like secrets", {
  cfg <- bio_config("openai", model = "m", api_key = "plainsecretvalue987")
  expect_equal(bio_redact("key=plainsecretvalue987"), "key=[REDACTED]")
  expect_false(grepl("sk-abc", bio_redact("token sk-abcdefghijklmnop")))
  expect_match(bio_redact("Authorization: Bearer abcdefghijklmnop"), "Bearer \\[REDACTED\\]")
})

test_that("register / unregister presets and validation", {
  bio_register_preset("tmp_gw", protocol = "anthropic", base_url = "https://gw.example/v1",
                      api_key_env = "TMP_GW_KEY", overwrite = TRUE)
  on.exit(bio_unregister_preset("tmp_gw"))
  expect_true("tmp_gw" %in% bio_presets()$name)
  cfg <- bio_config("tmp_gw", model = "x")
  expect_equal(cfg$protocol, "anthropic")
  expect_equal(bio_endpoint_url(cfg), "https://gw.example/v1/messages")
  expect_error(bio_register_preset("tmp_gw", protocol = "openai"), "exists")
  expect_error(bio_register_preset("bad", api_key_env = "sk-livekey123"), "name")
  expect_error(bio_config("nope_preset"), "Unknown preset")
  expect_error(bio_config("openai", model = "m", extra_headers = list(`X-Api-Token` = "a")), "credentials")
})

test_that("global configuration can be set and reset", {
  on.exit(bio_reset_config())
  bio_configure("ollama", model = "qwen-local")
  expect_equal(bio_get_config()$model, "qwen-local")
  bio_reset_config()
  expect_equal(bio_get_config()$protocol, "none")
})
