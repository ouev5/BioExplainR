# Local transport fixture; endpoints are supplied by the Python loopback server.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
pkgload::load_all(".", quiet = TRUE)
base <- args[1]
out <- args[2]
records <- list()
for (protocol in c("openai", "anthropic")) {
  cfg <- bio_config(protocol, model = "local-fixture", api_key = "fixture-key-for-local-test",
    endpoint = paste0(base, "/", protocol), max_retries = 0,
    extra_body = list(fixture = list(p = 1e-132, pca = 0.47842864474215936, zero = 0, missing = NA_real_)))
  ctx <- new_bio_context("generic", "list", facts = list(n = 3L, p = 1e-132))
  ex <- bio_explain(ctx, cfg, use_llm = TRUE, question = "precision \u6570\u503c")
  records[[protocol]] <- list(request_hash = ex$manifest$request_hash,
    request_bytes = ex$manifest$request_bytes, request_hash_scope = ex$manifest$request_hash_scope,
    usage = ex$manifest$usage, structured = ex$llm_meta$structured)
}
cfg <- bio_config("openai", model = "local-fixture", api_key = "fixture-key-for-local-test",
  endpoint = paste0(base, "/retry"), max_retries = 1)
records$retry <- bio_llm_chat(cfg, "system", "user")[c("text", "request_hash", "request_bytes")]
cfg$endpoint <- paste0(base, "/unauthorized")
records$unauthorized <- tryCatch(bio_llm_chat(cfg, "system", "user"), error = function(e) conditionMessage(e))
stopifnot(grepl("HTTP 401", records$unauthorized), !grepl("fixture-key-for-local-test", records$unauthorized))
jsonlite::write_json(records, out, auto_unbox = TRUE, pretty = TRUE)
cat("Local OpenAI/Anthropic transport, retry and 401 checks completed\n")
