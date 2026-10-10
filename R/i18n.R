# Language support ----------------------------------------------------------------------
# English ("en") is the package default. Simplified Chinese ("zh") is an explicit
# opt-in through a `language` argument, bio_config(language = ) or the Shiny selector.
# Facts are always computed in R; only wording is translated.

.languages <- c("en", "zh")
.default_language <- "en"

# Strict validation: exactly "en" or "zh" (no partial matching, no NA, no vectors).
.check_language <- function(language, arg = "language") {
  if (!is.character(language) || length(language) != 1L || is.na(language) ||
      !language %in% .languages) {
    stop(arg, " must be one of \"en\" or \"zh\".", call. = FALSE)
  }
  language
}

# Explicit argument first, then the configuration, then the English default.
.resolve_language <- function(language = NULL, config = NULL) {
  .check_language(language %||% config$language %||% .default_language)
}

# Language of the call currently executing; falls back to the active configuration.
.current_language <- function() {
  lang <- .pkg_env$language %||% .pkg_env$config$language
  if (is.null(lang) || !lang %in% .languages) .default_language else lang
}

# Make `language` current until the calling function exits.
.local_language <- function(language, envir = parent.frame()) {
  language <- .check_language(language)
  old <- .pkg_env$language
  .pkg_env$language <- language
  do.call(on.exit, list(bquote(.pkg_env$language <- .(old)), add = TRUE), envir = envir)
  invisible(language)
}

.with_language <- function(language, expr) {
  .local_language(language)
  expr
}

# Pair an English text with its Chinese counterpart: "English" %L% "<Chinese>".
# Only the branch for the current language is evaluated.
`%L%` <- function(en, zh) if (identical(.current_language(), "zh")) zh else en

.is_zh <- function() identical(.current_language(), "zh")
