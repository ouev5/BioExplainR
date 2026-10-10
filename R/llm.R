# LLM request building, transport and parsing -------------------------------------

.transient_status <- c(408L, 409L, 425L, 429L, 500L, 502L, 503L, 504L, 520L, 522L, 524L, 529L)

#' Build an HTTP request for a chat model
#'
#' Creates (but does not send) an \pkg{httr2} request for either the
#' OpenAI-compatible Chat Completions protocol or the Anthropic Messages
#' protocol. The key is resolved from the configuration at this point and
#' attached as a redacted header. Requests carry a timeout and retry only on
#' transient failures (HTTP 408/429/5xx and connection errors).
#'
#' @param config A \code{\link{bio_config}} with \code{protocol} other than
#'   \code{"none"} and an explicit \code{model}.
#' @param system System prompt string.
#' @param user User message string.
#' @return An \code{httr2_request}.
#' @export
#' @examples
#' cfg <- bio_config("anthropic", model = "my-model-id", api_key = "dummy-key-123")
#' req <- bio_build_request(cfg, "You are helpful.", "Hi")
#' req$url
bio_build_request <- function(config, system, user) {
  if (config$protocol == "none") stop("Local mode: no model configured (protocol = 'none').", call. = FALSE)
  if (.is_blank(config$model)) {
    stop("No model ID configured. Supply model = '<your model id>' in bio_config()/bio_configure() ",
         "or set BIOEXPLAINR_MODEL.", call. = FALSE)
  }
  key <- .resolve_key(config)
  if (is.null(key) && isTRUE(config$key_required)) {
    stop("API key not found. Set the environment variable ", config$api_key_env %||% "BIOEXPLAINR_API_KEY",
         " (e.g. in ~/.Renviron) or pass api_key.", call. = FALSE)
  }
  url <- bio_endpoint_url(config)
  req <- httr2::request(url)
  req <- httr2::req_user_agent(req, paste0("BioExplainR/", .this_version() %||% "dev"))
  if (config$protocol == "openai") {
    body <- list(model = config$model,
                 messages = list(list(role = "system", content = system),
                                 list(role = "user", content = user)),
                 max_tokens = config$max_tokens)
    if (!is.null(config$temperature)) body$temperature <- config$temperature
    if (isTRUE(config$json_mode)) body$response_format <- list(type = "json_object")
    if (!is.null(key)) req <- httr2::req_headers(req, Authorization = paste("Bearer", key), .redact = "Authorization")
  } else {
    body <- list(model = config$model, max_tokens = config$max_tokens, system = system,
                 messages = list(list(role = "user", content = user)))
    if (!is.null(config$temperature)) body$temperature <- config$temperature
    req <- httr2::req_headers(req, `anthropic-version` = config$anthropic_version)
    if (!is.null(key)) req <- httr2::req_headers(req, `x-api-key` = key, .redact = "x-api-key")
  }
  body <- c(body, config$extra_body)
  if (length(config$extra_headers)) req <- do.call(httr2::req_headers, c(list(req), config$extra_headers))
  req <- httr2::req_body_json(req, body, auto_unbox = TRUE, digits = 17, na = "null", null = "null")
  req <- httr2::req_timeout(req, config$timeout %||% 60)
  req <- httr2::req_retry(req, max_tries = max(1L, (config$max_retries %||% 0L) + 1L),
                          is_transient = function(resp) httr2::resp_status(resp) %in% .transient_status,
                           backoff = function(i) min(2^i, 20))
  req <- httr2::req_options(req, followlocation = FALSE)
  req <- httr2::req_error(req, is_error = function(resp) FALSE)
  req
}

#' Parse a chat model response body
#'
#' @param protocol \code{"openai"} or \code{"anthropic"}.
#' @param body Parsed JSON body (list).
#' @return List with \code{text}, \code{model}, \code{stop_reason}, \code{usage}.
#' @export
#' @examples
#' bio_parse_response("openai", list(model = "m",
#'   choices = list(list(message = list(content = "hi"), finish_reason = "stop"))))$text
bio_parse_response <- function(protocol, body) {
  if (!is.list(body)) stop("Unexpected response body (not JSON object).", call. = FALSE)
  if (!is.null(body$error)) {
    msg <- if (is.list(body$error)) body$error$message %||% .json(body$error) else as.character(body$error)
    stop("Model API returned an error: ", bio_redact(msg), call. = FALSE)
  }
  if (protocol == "openai") {
    ch <- body$choices
    if (!length(ch)) stop("OpenAI-compatible response has no 'choices'.", call. = FALSE)
    content <- ch[[1]]$message$content
    if (is.list(content)) content <- paste(vapply(content, function(p) p$text %||% "", ""), collapse = "")
    list(text = content %||% "", model = body$model %||% NA_character_,
         stop_reason = ch[[1]]$finish_reason %||% NA_character_, usage = body$usage)
  } else if (protocol == "anthropic") {
    blocks <- body$content
    if (!length(blocks)) stop("Anthropic response has no 'content' blocks.", call. = FALSE)
    txt <- paste(vapply(blocks, function(b) if (identical(b$type, "text")) b$text %||% "" else "", ""), collapse = "")
    list(text = txt, model = body$model %||% NA_character_,
         stop_reason = body$stop_reason %||% NA_character_, usage = body$usage)
  } else stop("Unknown protocol: ", protocol, call. = FALSE)
}

#' Send a prompt to the configured model
#'
#' Low-level helper used by \code{\link{bio_explain}} and
#' \code{\link{bio_explain_error}}. Errors are reported with HTTP status and
#' a redacted provider message; keys never appear in error messages.
#'
#' @inheritParams bio_build_request
#' @return List as returned by \code{\link{bio_parse_response}}, plus
#'   \code{endpoint_host} and \code{elapsed_sec}.
#' @export
bio_llm_chat <- function(config, system, user) {
  req <- bio_build_request(config, system, user)
  t0 <- Sys.time()
  resp <- tryCatch(httr2::req_perform(req), error = function(e) {
    stop("Could not reach model endpoint (", .endpoint_host(req$url), "): ",
         bio_redact(conditionMessage(e)), call. = FALSE)
  })
  status <- httr2::resp_status(resp)
  body <- tryCatch(httr2::resp_body_json(resp, simplifyVector = FALSE), error = function(e) NULL)
  if (status >= 300) {
    msg <- if (is.list(body) && !is.null(body$error)) {
      if (is.list(body$error)) body$error$message %||% .json(body$error) else as.character(body$error)
    } else tryCatch(substr(httr2::resp_body_string(resp), 1, 300), error = function(e) "")
    hint <- switch(as.character(status),
      "401" = " Check the API key.", "403" = " Key lacks permission for this model/endpoint.",
      "404" = " Check base_url/endpoint and model ID.", "429" = " Rate limit or quota exhausted.", "")
    stop("Model API HTTP ", status, ": ", bio_redact(msg), hint, call. = FALSE)
  }
  if (is.null(body)) stop("Model API returned a non-JSON body.", call. = FALSE)
  out <- bio_parse_response(config$protocol, body)
  out$endpoint_host <- .endpoint_host(req$url)
  out$elapsed_sec <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 2)
  wire <- do.call(jsonlite::toJSON, c(list(req$body$data), req$body$params))
  out$request_hash <- .sha256(charToRaw(enc2utf8(as.character(wire))))
  out$request_semantic_hash <- .hash_object(req$body$data)
  out$request_bytes <- nchar(as.character(wire), type = "bytes")
  out$request_hash_scope <- "UTF-8 HTTP JSON body bytes; headers excluded"
  out$response_hash <- .hash_object(body)
  out$response_hash_scope <- "canonical parsed provider JSON"
  out
}

# Extract a JSON object from model text (handles ```json fences and prose).
.extract_json <- function(text) {
  if (.is_blank(text)) return(NULL)
  t <- gsub("^\\s*```(json)?\\s*|\\s*```\\s*$", "", text)
  parsed <- tryCatch(jsonlite::fromJSON(t, simplifyVector = TRUE), error = function(e) NULL)
  if (is.null(parsed)) {
    s <- regexpr("\\{", text)
    e <- max(gregexpr("\\}", text)[[1]])
    if (s > 0 && e > s) {
      parsed <- tryCatch(jsonlite::fromJSON(substr(text, s, e), simplifyVector = TRUE), error = function(e) NULL)
    }
  }
  if (is.list(parsed)) parsed else NULL
}
