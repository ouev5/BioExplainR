# Internal helpers -----------------------------------------------------------

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x

.pkg_env <- new.env(parent = emptyenv())
.pkg_env$config <- NULL
.pkg_env$records <- list()
.pkg_env$last_record <- NULL
.pkg_env$last_error <- NULL
.pkg_env$evidence <- list()
.pkg_env$evidence_providers <- list()
.pkg_env$adapters <- list()
.pkg_env$secrets <- character()
.pkg_env$package_usage <- data.frame(
  package = character(), function_name = character(), argument_names = character(),
  argument_values = character(), calls = integer(), first_used = character(), last_used = character(),
  source = character(), stringsAsFactors = FALSE
)

.max_records <- 50L

.is_blank <- function(x) {
  is.null(x) || length(x) == 0 || (length(x) == 1 && (is.na(x) || !nzchar(trimws(x))))
}

.now <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")

.truncate_chr <- function(x, n = 200) {
  x <- as.character(x)
  long <- !is.na(x) & nchar(x) > n
  x[long] <- paste0(substr(x[long], 1, n - 3), "...")
  x
}

.fmt_num <- function(x, digits = 3) {
  if (is.null(x) || length(x) == 0) return("NA")
  vapply(x, function(v) {
    if (is.na(v)) return("NA")
    if (!is.numeric(v)) return(as.character(v))
    if (v != 0 && (abs(v) < 1e-3 || abs(v) >= 1e6)) formatC(v, format = "e", digits = 2)
    else format(signif(v, digits), scientific = FALSE, trim = TRUE)
  }, character(1))
}

.pkg_version <- function(pkg) {
  v <- tryCatch(as.character(utils::packageVersion(pkg)), error = function(e) NA_character_)
  v
}

.this_version <- function() .pkg_version("BioExplainR")

# Approximate memory footprint, never fails.
.obj_size <- function(x) {
  tryCatch(format(utils::object.size(x), units = "auto"), error = function(e) NA_character_)
}

# Compact, value-free description of any R object. Never includes cell values,
# dimnames or row names, so it is safe to put into reports or LLM payloads.
.object_summary <- function(x, name = NULL) {
  out <- list(
    name = name,
    class = class(x),
    type = typeof(x),
    is_s4 = isS4(x),
    size = .obj_size(x)
  )
  d <- tryCatch(dim(x), error = function(e) NULL)
  if (!is.null(d)) out$dim <- as.integer(d) else out$length <- tryCatch(length(x), error = function(e) NA_integer_)
  if (is.data.frame(x)) {
    cn <- names(x)
    out$column_types <- vapply(x, function(col) class(col)[1], character(1))
    if (length(cn) > 30 || .looks_matrix_like(x)) {
      out$column_types <- NULL
      out$columns_note <- "column names withheld (wide or matrix-like table; may contain sample IDs)"
    }
    fac <- names(x)[vapply(x, is.factor, logical(1))]
    if (length(fac) && length(fac) <= 10) {
      out$factor_levels_count <- vapply(x[fac], nlevels, integer(1))
    }
  }
  if (is.factor(x)) out$n_levels <- nlevels(x)
  out
}

# A data.frame that is (almost) entirely numeric and wide is probably an
# expression / count matrix whose column names are sample identifiers.
.looks_matrix_like <- function(df) {
  if (!is.data.frame(df) || ncol(df) < 6) return(FALSE)
  num <- vapply(df, is.numeric, logical(1))
  mean(num) >= 0.9
}

# Find the first column whose name matches one of the candidate aliases.
.find_col <- function(df, aliases) {
  nm <- names(df)
  for (a in aliases) {
    hit <- which(nm == a)
    if (length(hit)) return(nm[hit[1]])
  }
  low <- tolower(nm)
  for (a in tolower(aliases)) {
    hit <- which(low == a)
    if (length(hit)) return(nm[hit[1]])
  }
  NULL
}

.numeric_column <- function(df, column, probability = FALSE) {
  value <- df[[column]]
  if (is.factor(value)) value <- as.character(value)
  if (!is.numeric(value) && !is.character(value)) {
    stop("Column '", column, "' must contain numeric values.", call. = FALSE)
  }
  number <- suppressWarnings(as.numeric(value))
  invalid <- !is.na(value) & (is.na(number) | !is.finite(number))
  if (probability) invalid <- invalid | (!is.na(number) & (number < 0 | number > 1))
  if (any(invalid)) {
    stop("Column '", column, "' contains invalid ",
         if (probability) "p-values (expected numbers between 0 and 1)." else "numeric values.",
         call. = FALSE)
  }
  number
}

.endpoint_host <- function(url) {
  parsed <- httr2::url_parse(url)
  paste0(parsed$scheme, "://", parsed$hostname,
         if (!is.null(parsed$port)) paste0(":", parsed$port))
}

.public_url <- function(url) {
  parsed <- httr2::url_parse(url)
  parsed$username <- parsed$password <- parsed$query <- parsed$fragment <- NULL
  bio_redact(httr2::url_build(parsed))
}

.code_payload <- function(code) {
  if (is.null(code) || length(code) != 1 || is.na(code)) return(NULL)
  expr <- tryCatch(parse(text = code), error = function(e) NULL)
  if (is.null(expr)) return("<code omitted: not parseable>")
  scrub <- function(x) {
    if (is.character(x)) return(rep("[LITERAL OMITTED]", length(x)))
    if (is.call(x)) {
      for (i in seq_along(x)) tryCatch(x[[i]] <- scrub(x[[i]]), error = function(e) NULL)
    } else if (is.expression(x)) {
      for (i in seq_along(x)) x[[i]] <- scrub(x[[i]])
    }
    x
  }
  .truncate_chr(paste(deparse(scrub(expr)), collapse = " "), 3000)
}

# Access an S4 slot (or attribute / list element) without requiring the
# owning package to be loaded. S4 slots are stored as attributes.
.slot_or <- function(x, name, default = NULL) {
  val <- tryCatch({
    if (isS4(x) && methods::.hasSlot(x, name)) methods::slot(x, name)
    else if (!is.null(attr(x, name, exact = TRUE))) attr(x, name, exact = TRUE)
    else if (is.list(x) && !is.null(x[[name]])) x[[name]]
    else NULL
  }, error = function(e) attr(x, name, exact = TRUE))
  val %||% default
}

.register_secret <- function(value) {
  if (!.is_blank(value) && nchar(value) >= 6) {
    .pkg_env$secrets <- unique(c(.pkg_env$secrets, value))
  }
  invisible(NULL)
}

#' Remove secrets from text
#'
#' Replaces API keys that are known to the current session (configured or read
#' from environment variables through BioExplainR) and common key-like tokens
#' (for example \code{sk-...}, \code{Bearer ...}) with \code{[REDACTED]}.
#'
#' @param x Character vector.
#' @return Character vector with secrets masked.
#' @export
#' @examples
#' bio_redact("Authorization: Bearer sk-abcdefghijklmnop")
bio_redact <- function(x) {
  if (is.null(x)) return(x)
  x <- as.character(x)
  for (s in .pkg_env$secrets) {
    x <- gsub(s, "[REDACTED]", x, fixed = TRUE)
  }
  x <- gsub("sk-[A-Za-z0-9_\\-]{8,}", "[REDACTED]", x, perl = TRUE)
  x <- gsub("(?i)(bearer\\s+)[A-Za-z0-9._\\-]{8,}", "\\1[REDACTED]", x, perl = TRUE)
  x <- gsub("(?i)(x-api-key\\s*[:=]\\s*)[^\\s,;\"']{6,}", "\\1[REDACTED]", x, perl = TRUE)
  x <- gsub("(?i)(api[_-]?key\\s*[:=]\\s*[\"']?)[^\\s,;\"']{6,}", "\\1[REDACTED]", x, perl = TRUE)
  x <- gsub("(https?://)[^/@\\s]+:[^/@\\s]+@", "\\1[REDACTED]@", x, perl = TRUE)
  x
}

.json <- function(x, pretty = FALSE) {
  jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null",
                   digits = 17, pretty = pretty, force = TRUE)
}

.session_versions <- function(packages = NULL) {
  pk <- packages %||% sort(setdiff(loadedNamespaces(), c(
    "base", "compiler", "datasets", "graphics", "grDevices", "grid", "methods",
    "parallel", "splines", "stats", "stats4", "tcltk", "tools", "utils")))
  list(
    r_version = R.version.string,
    platform = R.version$platform,
    os = utils::sessionInfo()$running %||% NA_character_,
    bioexplainr = .this_version(),
    packages = stats::setNames(vapply(pk, .pkg_version, character(1)), pk)
  )
}

.user_set <- function(thresholds, name) name %in% (attr(thresholds, "user_set") %||% character())
