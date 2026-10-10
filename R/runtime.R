# Runtime inspection and execution provenance --------------------------------

.call_text <- function(x) {
  tryCatch(.truncate_chr(.code_payload(paste(deparse(x, width.cutoff = 160L), collapse = " ")), 240),
           error = function(e) "<unavailable>")
}

.argument_value_text <- function(x) {
  raw <- paste(deparse(x, width.cutoff = 80L), collapse = " ")
  if (is.character(x) || grepl("['\"]", raw)) return("[string omitted]")
  .truncate_chr(.code_payload(raw), 120)
}

.symbol_or_string <- function(x) {
  if (is.symbol(x)) return(as.character(x))
  if (is.character(x) && length(x) == 1L) return(x)
  NA_character_
}

.non_function_call_heads <- c(
  "{", "(", "[", "[[", "$", "@", "<-", "=", "<<-", ":", "::", ":::",
  "+", "-", "*", "/", "^", "%%", "%/%", "==", "!=", "<", ">", "<=", ">=",
  "&", "&&", "|", "||", "!", "~", "if", "else", "for", "while", "repeat",
  "function", "switch", "on.exit", "return", "break", "next"
)

.unqualified_package <- function(fn, envir = parent.frame()) {
  hit <- tryCatch(utils::find(fn, mode = "function", envir = envir), error = function(e) character())
  if (!length(hit)) return("<unqualified>")
  env_name <- hit[1L]
  if (identical(env_name, ".GlobalEnv")) return("<unqualified>")
  if (grepl("^package:", env_name)) return(sub("^package:", "", env_name))
  if (grepl("^namespace:", env_name)) return(sub("^namespace:", "", env_name))
  "<unqualified>"
}

.call_argument_names <- function(e) {
  n <- length(e) - 1L
  if (n <= 0L) return(character())
  nm <- names(e)
  nm <- if (is.null(nm)) rep("", length(e)) else nm
  nm <- nm[-1L]
  nm[is.na(nm) | !nzchar(nm)] <- "..."
  nm
}

.call_argument_values <- function(e) {
  if (length(e) <= 1L) return(character())
  vapply(as.list(e)[-1L], .argument_value_text, character(1))
}

# Extract package-qualified calls and library()/require() calls from a parsed
# expression. Character literals are omitted and other expressions are truncated
# before the package-level history is shown in reports and a browser UI.
.code_package_calls <- function(expr, envir = parent.frame()) {
  rows <- list()
  add <- function(package, fn, call, args, values, source) {
    if (.is_blank(package)) return(invisible(NULL))
    rows[[length(rows) + 1L]] <<- data.frame(
      package = as.character(package), function_name = as.character(fn %||% "<unknown>"),
      argument_names = paste(if (length(args)) args else character(), collapse = ", "),
      argument_values = paste(if (length(values)) values else character(), collapse = ", "),
      call = .call_text(call), source = source, stringsAsFactors = FALSE
    )
    invisible(NULL)
  }
  walk <- function(e) {
    if (is.expression(e)) {
      for (z in as.list(e)) walk(z)
      return(invisible(NULL))
    }
    if (!is.call(e)) return(invisible(NULL))
    head <- e[[1L]]
    if (is.call(head) && is.symbol(head[[1L]]) &&
        as.character(head[[1L]]) %in% c("::", ":::")) {
      pkg <- if (length(head) >= 2L) .symbol_or_string(head[[2L]]) else NA_character_
      fn <- if (length(head) >= 3L) .symbol_or_string(head[[3L]]) else NA_character_
      nm <- .call_argument_names(e)
      add(pkg, fn, e, nm, .call_argument_values(e), "namespace_call")
    } else if (is.symbol(head) && as.character(head) %in% c("library", "require", "requireNamespace")) {
      pkg <- if (length(e) >= 2L) .symbol_or_string(e[[2L]]) else NA_character_
      nm <- .call_argument_names(e)
      add(pkg, as.character(head), e, nm, .call_argument_values(e), "package_loader")
    } else if (is.symbol(head) && !as.character(head) %in% .non_function_call_heads) {
      # Direct calls are retained as unqualified functions. They are useful in
      # the UI alongside namespace calls, but do not claim a package owner.
      nm <- .call_argument_names(e)
      add(.unqualified_package(as.character(head), envir = envir), as.character(head), e, nm,
          .call_argument_values(e), "direct_call")
    }
    for (i in seq_along(e)[-1L]) walk(e[[i]])
    invisible(NULL)
  }
  walk(expr)
  if (!length(rows)) return(data.frame(
    package = character(), function_name = character(), argument_names = character(),
    argument_values = character(), call = character(), source = character(), stringsAsFactors = FALSE
  ))
  unique(do.call(rbind, rows))
}

.record_package_usage <- function(calls, loaded_before = character(), loaded_after = character()) {
  now <- .now()
  out <- calls
  newly_loaded <- setdiff(loaded_after, loaded_before)
  if (length(newly_loaded)) {
    out <- rbind(out, data.frame(
      package = newly_loaded, function_name = "<namespace loaded>", argument_names = "",
      argument_values = "",
      call = "", source = "namespace_loaded", stringsAsFactors = FALSE
    ))
  }
  if (nrow(out)) {
    for (i in seq_len(nrow(out))) {
      key <- paste(out$package[i], out$function_name[i], out$argument_names[i],
                   out$argument_values[i], sep = "\r")
      old_key <- paste(.pkg_env$package_usage$package,
                       .pkg_env$package_usage$function_name,
                       .pkg_env$package_usage$argument_names,
                       .pkg_env$package_usage$argument_values, sep = "\r")
      hit <- match(key, old_key)
      if (is.na(hit)) {
        .pkg_env$package_usage <- rbind(.pkg_env$package_usage, data.frame(
          package = out$package[i], function_name = out$function_name[i],
          argument_names = out$argument_names[i], argument_values = out$argument_values[i], calls = 1L,
          first_used = now, last_used = now, source = out$source[i],
          stringsAsFactors = FALSE
        ))
      } else {
        .pkg_env$package_usage$calls[hit] <- .pkg_env$package_usage$calls[hit] + 1L
        .pkg_env$package_usage$last_used[hit] <- now
      }
    }
  }
  out
}

#' Inspect packages used by recorded code
#'
#' Returns package-qualified and unqualified functions observed in
#' \code{bio_record()} or \code{bio_record_code()} calls. Character literals are
#' omitted and other argument expressions are truncated before being placed in
#' the table; the corresponding record keeps the original code for the local
#' user to inspect.
#'
#' @param reset If \code{TRUE}, clear the session table before returning it.
#' @return A data.frame with package, function, argument names, safe argument
#'   expressions, call count and first/last use times.
#' @export
bio_package_usage <- function(reset = FALSE) {
  if (isTRUE(reset)) {
    .pkg_env$package_usage <- .pkg_env$package_usage[FALSE, , drop = FALSE]
  }
  .pkg_env$package_usage
}

#' Inspect the current R runtime
#'
#' @param include_installed If \code{TRUE}, include the installed package
#'   table. Set to \code{FALSE} for a faster lightweight summary.
#' @return A list containing R/platform information, installed and loaded
#'   packages, the search path and recorded package usage.
#' @export
bio_runtime_info <- function(include_installed = TRUE) {
  loaded <- sort(loadedNamespaces())
  loaded_df <- data.frame(
    package = loaded,
    version = vapply(loaded, .pkg_version, character(1)),
    stringsAsFactors = FALSE, row.names = NULL
  )
  installed <- NULL
  if (isTRUE(include_installed)) {
    installed <- tryCatch({
      ip <- utils::installed.packages(noCache = TRUE)
      keep <- intersect(c("Package", "Version", "LibPath"), colnames(ip))
      as.data.frame(ip[, keep, drop = FALSE], stringsAsFactors = FALSE, row.names = NULL)
    }, error = function(e) data.frame(error = conditionMessage(e), stringsAsFactors = FALSE))
  }
  list(
    r_version = R.version.string,
    platform = R.version$platform,
    os = utils::sessionInfo()$running %||% NA_character_,
    loaded_packages = loaded_df,
    installed_packages = installed,
    search_path = search(),
    package_usage = bio_package_usage()
  )
}

#' Summarise objects in an R environment
#'
#' @param envir Environment to inspect. Defaults to the caller's environment.
#' @param include_functions Include functions as rows when \code{TRUE}.
#' @param include_hidden Include names beginning with a dot when \code{TRUE}.
#' @return A value-free data.frame containing object names, classes, shapes and
#'   approximate sizes.
#' @export
bio_object_inventory <- function(envir = parent.frame(), include_functions = FALSE,
                                 include_hidden = FALSE) {
  stopifnot(is.environment(envir))
  nms <- ls(envir, all.names = include_hidden)
  if (!length(nms)) return(data.frame(
    name = character(), class = character(), type = character(), shape = character(),
    size = character(), stringsAsFactors = FALSE
  ))
  rows <- lapply(nms, function(n) {
    x <- get(n, envir = envir, inherits = FALSE)
    if (!include_functions && is.function(x)) return(NULL)
    s <- .object_summary(x, name = n)
    data.frame(
      name = n, class = paste(s$class, collapse = "/"), type = s$type,
      shape = if (!is.null(s$dim)) paste(s$dim, collapse = " x ") else paste0("length ", s$length %||% NA),
      size = s$size %||% NA_character_, stringsAsFactors = FALSE
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) return(data.frame(
    name = character(), class = character(), type = character(), shape = character(),
    size = character(), stringsAsFactors = FALSE
  ))
  do.call(rbind, rows)
}
