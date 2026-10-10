# Model / provider configuration -------------------------------------------

.builtin_presets <- function() {
  list(
    local = list(
      protocol = "none", base_url = NULL, api_key_env = NULL, key_required = FALSE,
      description = "No network: deterministic local explanations only."
    ),
    openai = list(
      protocol = "openai", base_url = "https://api.openai.com/v1",
      api_key_env = "OPENAI_API_KEY", key_required = TRUE,
      description = "OpenAI Chat Completions endpoint."
    ),
    openai_compatible = list(
      protocol = "openai", base_url = NULL,
      api_key_env = "BIOEXPLAINR_API_KEY", key_required = TRUE,
      description = "Any OpenAI-compatible /chat/completions service or proxy; supply base_url."
    ),
    anthropic = list(
      protocol = "anthropic", base_url = "https://api.anthropic.com",
      api_key_env = "ANTHROPIC_API_KEY", key_required = TRUE,
      description = "Anthropic Messages API (/v1/messages)."
    ),
    deepseek = list(
      protocol = "openai", base_url = "https://api.deepseek.com",
      api_key_env = "DEEPSEEK_API_KEY", key_required = TRUE,
      description = "DeepSeek, OpenAI-compatible protocol."
    ),
    ollama = list(
      protocol = "openai", base_url = "http://localhost:11434/v1",
      api_key_env = NULL, key_required = FALSE,
      description = "Local Ollama server through its OpenAI-compatible endpoint."
    )
  )
}

.preset_store <- new.env(parent = emptyenv())

.all_presets <- function() {
  user <- as.list(.preset_store)
  b <- .builtin_presets()
  b[names(user)] <- user
  b
}

#' List or register connection presets
#'
#' Presets only describe \emph{how} to connect (protocol, base URL and the name
#' of the environment variable holding the key). They never contain keys and
#' never choose a model: the model ID is always supplied by the user.
#'
#' Built-in presets: \code{local} (no network), \code{openai},
#' \code{openai_compatible} (any proxy / gateway, requires \code{base_url}),
#' \code{anthropic}, \code{deepseek} and \code{ollama}.
#'
#' @param name Preset name.
#' @param protocol \code{"openai"} (chat completions), \code{"anthropic"}
#'   (Messages API) or \code{"none"}.
#' @param base_url Base URL or full endpoint URL.
#' @param api_key_env Name of the environment variable that holds the key.
#' @param key_required Whether requests must carry a key.
#' @param description Free text.
#' @param overwrite Allow replacing an existing user preset or shadowing a
#'   built-in preset.
#' @return \code{bio_presets()} returns a data.frame; \code{bio_register_preset()}
#'   invisibly returns the preset list.
#' @export
#' @examples
#' bio_presets()
#' bio_register_preset("my_gateway", protocol = "openai",
#'                     base_url = "https://llm.example.org/v1",
#'                     api_key_env = "MY_GATEWAY_KEY", overwrite = TRUE)
#' bio_unregister_preset("my_gateway")
bio_presets <- function() {
  p <- .all_presets()
  user <- ls(.preset_store)
  data.frame(
    name = names(p),
    protocol = vapply(p, function(z) z$protocol, character(1)),
    base_url = vapply(p, function(z) z$base_url %||% NA_character_, character(1)),
    api_key_env = vapply(p, function(z) z$api_key_env %||% NA_character_, character(1)),
    key_required = vapply(p, function(z) isTRUE(z$key_required), logical(1)),
    user_defined = names(p) %in% user,
    description = vapply(p, function(z) z$description %||% "", character(1)),
    stringsAsFactors = FALSE, row.names = NULL
  )
}

#' @rdname bio_presets
#' @export
bio_register_preset <- function(name, protocol = c("openai", "anthropic", "none"),
                                base_url = NULL, api_key_env = NULL,
                                key_required = !is.null(api_key_env),
                                description = "", overwrite = FALSE) {
  protocol <- match.arg(protocol)
  stopifnot(is.character(name), length(name) == 1, nzchar(name))
  if (!overwrite && name %in% names(.all_presets())) {
    stop("Preset '", name, "' already exists; use overwrite = TRUE.", call. = FALSE)
  }
  if (!is.null(api_key_env) && grepl("^(sk-|sk_)", api_key_env)) {
    stop("api_key_env must be the *name* of an environment variable, not a key.", call. = FALSE)
  }
  preset <- list(protocol = protocol, base_url = base_url, api_key_env = api_key_env,
                 key_required = key_required, description = description)
  assign(name, preset, envir = .preset_store)
  invisible(preset)
}

#' @rdname bio_presets
#' @export
bio_unregister_preset <- function(name) {
  if (exists(name, envir = .preset_store, inherits = FALSE)) rm(list = name, envir = .preset_store)
  invisible(TRUE)
}

.env_or_null <- function(var) {
  if (.is_blank(var)) return(NULL)
  v <- Sys.getenv(var, unset = "")
  if (nzchar(v)) v else NULL
}

#' Create a model configuration
#'
#' Builds an explicit configuration object. Arguments override preset values,
#' which in turn are overridden by nothing else: the model ID is never guessed.
#' Unset fields fall back to environment variables:
#' \code{BIOEXPLAINR_BASE_URL}, \code{BIOEXPLAINR_MODEL},
#' \code{BIOEXPLAINR_PROTOCOL}, and for the key the preset's
#' \code{api_key_env} or \code{BIOEXPLAINR_API_KEY}.
#'
#' Keys are best supplied through environment variables (for example in
#' \code{~/.Renviron}). A literal \code{api_key} is accepted but is kept in a
#' closure, masked when printed and never written into reports.
#'
#' @param preset Preset name (see \code{\link{bio_presets}}). Default
#'   \code{"local"} when nothing else is given, otherwise
#'   \code{"openai_compatible"}.
#' @param base_url Base URL (e.g. \code{https://my-proxy.example/v1}) or full
#'   endpoint URL ending in \code{/chat/completions} or \code{/messages}.
#' @param api_key Literal key (discouraged; prefer \code{api_key_env}).
#' @param api_key_env Environment variable name holding the key.
#' @param model Model ID string exactly as the provider expects it. Any custom
#'   ID is accepted.
#' @param protocol \code{"openai"}, \code{"anthropic"} or \code{"none"}.
#' @param endpoint Optional exact full endpoint URL; used verbatim.
#' @param timeout Request timeout in seconds.
#' @param max_retries Retries for transient failures only (HTTP 408/429/5xx,
#'   connection errors).
#' @param temperature Optional sampling temperature.
#' @param max_tokens Maximum output tokens.
#' @param language Default output language: \code{"en"} (default) or
#'   \code{"zh"} (Simplified Chinese, opt-in). Any other value is an error.
#' @param anthropic_version Value of the \code{anthropic-version} header.
#' @param extra_headers Named list of additional, non-secret HTTP headers.
#' @param extra_body Named list of provider-specific JSON fields, for example
#'   \code{list(thinking = list(type = "disabled"))} for DeepSeek. Core request
#'   fields cannot be replaced. Do not put secrets in this list.
#' @param json_mode For OpenAI-compatible services, request
#'   \code{response_format = json_object}. Off by default because not all
#'   compatible servers support it.
#' @return An object of class \code{bio_config}.
#' @seealso \code{\link{bio_configure}}, \code{\link{bio_endpoint_url}}
#' @export
#' @examples
#' bio_config()                       # local, no network
#' cfg <- bio_config("openai_compatible",
#'                   base_url = "https://my-proxy.example.com/v1",
#'                   api_key_env = "MY_PROXY_KEY", model = "my-custom-model")
#' cfg
#' bio_endpoint_url(cfg)
bio_config <- function(preset = NULL, base_url = NULL, api_key = NULL,
                       api_key_env = NULL, model = NULL, protocol = NULL,
                       endpoint = NULL, timeout = 60, max_retries = 2,
                       temperature = NULL, max_tokens = 1500, language = "en",
                       anthropic_version = "2023-06-01", extra_headers = NULL,
                        json_mode = FALSE, extra_body = NULL) {
  if (length(extra_body) && (!is.list(extra_body) || is.null(names(extra_body)) ||
      any(!nzchar(names(extra_body))) || anyDuplicated(names(extra_body)))) {
    stop("extra_body must be a uniquely named list.", call. = FALSE)
  }
  if (any(names(extra_body) %in% c("model", "messages", "system", "max_tokens", "temperature", "response_format")))
    stop("extra_body cannot replace core request fields.", call. = FALSE)
  language <- .check_language(language)
  env_base <- .env_or_null("BIOEXPLAINR_BASE_URL")
  env_model <- .env_or_null("BIOEXPLAINR_MODEL")
  env_proto <- .env_or_null("BIOEXPLAINR_PROTOCOL")
  if (is.null(preset)) {
    anything <- !is.null(base_url) || !is.null(endpoint) || !is.null(model) ||
      !is.null(protocol) || !is.null(api_key) || !is.null(env_base) || !is.null(env_model)
    preset <- if (anything) "openai_compatible" else "local"
  }
  presets <- .all_presets()
  if (!preset %in% names(presets)) {
    stop("Unknown preset '", preset, "'. Available: ",
         paste(names(presets), collapse = ", "), call. = FALSE)
  }
  p <- presets[[preset]]
  protocol <- protocol %||% (if (preset == "openai_compatible") env_proto) %||% p$protocol
  protocol <- match.arg(protocol, c("openai", "anthropic", "none"))
  api_key_env <- api_key_env %||% p$api_key_env %||%
    (if (protocol != "none") "BIOEXPLAINR_API_KEY")
  if (!is.null(api_key)) {
    if (!is.character(api_key) || length(api_key) != 1) stop("api_key must be a single string.", call. = FALSE)
    .register_secret(api_key)
  }
  key_holder <- local({ k <- api_key; function() k })
  if (!is.numeric(timeout) || length(timeout) != 1 || is.na(timeout) || !is.finite(timeout) || timeout <= 0) {
    stop("timeout must be a positive finite number.", call. = FALSE)
  }
  for (field in c("max_retries", "max_tokens")) {
    value <- get(field)
    minimum <- if (field == "max_retries") 0 else 1
    if (!is.numeric(value) || length(value) != 1 || is.na(value) || !is.finite(value) ||
        value < minimum || value != floor(value) || value > .Machine$integer.max) {
      stop(field, " must be a whole number >= ", minimum, ".", call. = FALSE)
    }
  }
  if (!is.null(extra_headers)) {
    bad <- grepl("auth|key|token|secret", names(extra_headers), ignore.case = TRUE)
    if (any(bad)) stop("Do not pass credentials through extra_headers; use api_key_env.", call. = FALSE)
  }
  cfg <- list(
    preset = preset,
    protocol = protocol,
    base_url = if (protocol == "none") NULL else base_url %||% (if (preset != "local") env_base) %||% p$base_url,
    endpoint = endpoint,
    model = if (protocol == "none") model else model %||% env_model,
    api_key_env = api_key_env,
    key_source = if (!is.null(api_key)) "literal" else if (!is.null(api_key_env)) paste0("env:", api_key_env) else "none",
    key_required = isTRUE(p$key_required),
    timeout = timeout,
    max_retries = as.integer(max_retries),
    temperature = temperature,
    max_tokens = as.integer(max_tokens),
    language = language,
    anthropic_version = anthropic_version,
    extra_headers = extra_headers,
    extra_body = extra_body,
    json_mode = json_mode,
    .key = key_holder
  )
  class(cfg) <- "bio_config"
  cfg
}

# Resolve the key at request time (env vars may be set after configuration).
.resolve_key <- function(cfg) {
  k <- cfg$.key()
  if (is.null(k)) k <- .env_or_null(cfg$api_key_env)
  if (is.null(k) && cfg$protocol != "none") k <- .env_or_null("BIOEXPLAINR_API_KEY")
  if (!is.null(k)) .register_secret(k)
  k
}

.key_status <- function(cfg) {
  if (cfg$protocol == "none") return("not needed (local mode)")
  k <- tryCatch(.resolve_key(cfg), error = function(e) NULL)
  if (is.null(k)) {
    if (isTRUE(cfg$key_required)) paste0("MISSING (set ", cfg$api_key_env %||% "an API key", ")")
    else "not set (not required)"
  } else {
    paste0("set [****] via ", cfg$key_source)
  }
}

#' Is a configuration able to call a model?
#'
#' @param config A \code{bio_config}; defaults to the active configuration.
#' @param reason If \code{TRUE}, return a character reason instead of logical.
#' @return Logical (or character if \code{reason = TRUE}).
#' @export
#' @examples
#' bio_llm_available(bio_config())
bio_llm_available <- function(config = bio_get_config(), reason = FALSE) {
  why <- character()
  if (config$protocol == "none") why <- "local mode (protocol = 'none')"
  else {
    if (.is_blank(config$model)) why <- c(why, "no model ID configured")
    if (.is_blank(config$base_url) && .is_blank(config$endpoint)) why <- c(why, "no base_url/endpoint configured")
    if (isTRUE(config$key_required) && is.null(.resolve_key(config))) {
      why <- c(why, paste0("API key missing (", config$api_key_env %||% "api_key", ")"))
    }
  }
  if (reason) return(if (length(why)) paste(why, collapse = "; ") else "ok")
  length(why) == 0
}

#' Resolve the request URL for a configuration
#'
#' If \code{endpoint} is set it is used verbatim. A \code{base_url} that
#' already ends in \code{/chat/completions} or \code{/messages} is treated as a
#' full endpoint. Otherwise the protocol path is appended, adding \code{/v1}
#' only when the base URL does not already end in a version segment such as
#' \code{/v1}, \code{/v4} or \code{/api/v3}; this avoids duplicated
#' \code{/v1/v1}.
#'
#' @param config A \code{bio_config}.
#' @return A single URL string.
#' @export
#' @examples
#' bio_endpoint_url(bio_config(base_url = "https://proxy.example/v1/", model = "m"))
#' bio_endpoint_url(bio_config(base_url = "https://proxy.example", model = "m"))
#' bio_endpoint_url(bio_config("anthropic", model = "my-claude-model"))
bio_endpoint_url <- function(config) {
  if (!.is_blank(config$endpoint)) {
    url <- httr2::url_parse(config$endpoint)
    if (!url$scheme %in% c("http", "https") || .is_blank(url$hostname)) {
      stop("endpoint must be a full http:// or https:// URL.", call. = FALSE)
    }
    return(config$endpoint)
  }
  base <- config$base_url
  if (.is_blank(base)) stop("No base_url or endpoint configured.", call. = FALSE)
  base <- trimws(base)
  if (!grepl("^https?://", base)) stop("base_url must start with http:// or https://", call. = FALSE)
  url <- httr2::url_parse(base)
  if (.is_blank(url$hostname)) stop("base_url must contain a hostname.", call. = FALSE)
  current_path <- sub("/+$", "", url$path %||% "")
  if (grepl("/chat/completions$|/messages$", current_path)) {
    url$path <- current_path
    return(httr2::url_build(url))
  }
  has_version <- grepl("/v[0-9]+[a-z0-9]*$", current_path)
  path <- switch(config$protocol,
    openai = "chat/completions",
    anthropic = "messages",
    stop("protocol 'none' has no endpoint", call. = FALSE))
  url$path <- if (has_version) paste0(current_path, "/", path) else paste0(current_path, "/v1/", path)
  httr2::url_build(url)
}

#' Set, get or reset the global configuration
#'
#' \code{bio_configure()} builds a \code{\link{bio_config}} (or accepts one)
#' and stores it for the session. \code{bio_get_config()} returns it, or a
#' local no-network config when nothing was configured.
#'
#' @param ... Passed to \code{\link{bio_config}}, or a single \code{bio_config}.
#' @return \code{bio_configure()} invisibly returns the configuration.
#' @export
#' @examples
#' old <- bio_configure("local")
#' bio_get_config()
#' bio_reset_config()
bio_configure <- function(...) {
  args <- list(...)
  cfg <- if (length(args) == 1 && inherits(args[[1]], "bio_config")) args[[1]] else bio_config(...)
  .pkg_env$config <- cfg
  invisible(cfg)
}

#' @rdname bio_configure
#' @export
bio_get_config <- function() {
  .pkg_env$config %||% bio_config("local")
}

#' @rdname bio_configure
#' @export
bio_reset_config <- function() {
  .pkg_env$config <- NULL
  invisible(NULL)
}

# Public, secret-free view used by reports and provenance.
.config_public <- function(cfg) {
  if (is.null(cfg)) return(NULL)
  url <- tryCatch(if (cfg$protocol == "none") NA_character_ else bio_endpoint_url(cfg),
                  error = function(e) NA_character_)
  host <- if (!is.na(url)) .endpoint_host(url) else NA_character_
  list(preset = cfg$preset, protocol = cfg$protocol, model = cfg$model %||% NA_character_,
       endpoint_host = host, key_source = sub("^literal$", "literal (masked)", cfg$key_source),
       timeout = cfg$timeout, max_retries = cfg$max_retries,
       temperature = cfg$temperature %||% NA, max_tokens = cfg$max_tokens)
}

#' @export
print.bio_config <- function(x, ...) {
  cat("<bio_config>\n")
  cat("  preset     :", x$preset, "\n")
  cat("  protocol   :", x$protocol, "\n")
  if (x$protocol != "none") {
    url <- tryCatch(bio_endpoint_url(x), error = function(e) paste0("<", conditionMessage(e), ">"))
    cat("  endpoint   :", tryCatch(.public_url(url), error = function(e) "<unavailable>"), "\n")
    cat("  model      :", x$model %||% "<not set - supply model = '...'>", "\n")
    cat("  api key    :", .key_status(x), "\n")
    cat("  timeout    :", x$timeout, "s; retries:", x$max_retries, "\n")
  } else {
    cat("  network    : disabled (deterministic local explanations only)\n")
  }
  cat("  language   :", x$language, "\n")
  invisible(x)
}

#' @export
format.bio_config <- function(x, ...) utils::capture.output(print(x))

#' @export
as.list.bio_config <- function(x, ...) .config_public(x)
