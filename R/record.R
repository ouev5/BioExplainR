# Execution recording --------------------------------------------------------------

# Marker frame used to locate the user's code inside sys.calls().
.bio_record_eval <- function(expr, envir) eval(expr, envir)

.assigned_names <- function(expr) {
  out <- character()
  walk <- function(e) {
    if (is.call(e)) {
      fn <- e[[1]]
      if (is.symbol(fn) && as.character(fn) %in% c("<-", "=", "<<-") && length(e) >= 2) {
        lhs <- e[[2]]
        while (is.call(lhs)) lhs <- lhs[[2]]  # x$a <- ..., names(x) <- ...
        if (is.symbol(lhs)) out <<- c(out, as.character(lhs))
      }
      if (is.symbol(fn) && identical(as.character(fn), "assign") && length(e) >= 2 && is.character(e[[2]])) {
        out <<- c(out, e[[2]])
      }
      for (i in seq_along(e)[-1]) tryCatch(walk(e[[i]]), error = function(err) NULL)
    }
  }
  walk(expr)
  unique(out)
}

.clean_stack <- function(calls) {
  n <- length(calls)
  if (!n) return(character())
  is_marker <- vapply(calls, function(cl) {
    f <- cl[[1]]
    is.symbol(f) && identical(as.character(f), ".bio_record_eval") ||
      (is.call(f) && identical(deparse(f), "BioExplainR:::.bio_record_eval"))
  }, logical(1))
  start <- if (any(is_marker)) max(which(is_marker)) + 1 else 1
  keep <- if (start <= n) calls[start:n] else list()
  txt <- vapply(keep, function(cl) .truncate_chr(paste(deparse(cl, width.cutoff = 200L, nlines = 3L), collapse = " "), 300), "")
  # Drop eval() wrappers right after the marker and the handler frames at the end.
  while (length(txt) && grepl("^eval\\(expr, envir", txt[1])) txt <- txt[-1]
  while (length(txt) && grepl("^\\(function ?\\(|^h\\(simpleError|^\\.handleSimpleError|^withCallingHandlers|^signalCondition|^stop\\(e\\)$", txt[length(txt)])) {
    txt <- txt[-length(txt)]
  }
  txt
}

.bio_record_impl <- function(code_expr, label = NULL, envir = parent.frame(), muffle_warnings = FALSE,
                             rethrow = FALSE, purpose = NULL) {
  code <- paste(deparse(code_expr, width.cutoff = 120L), collapse = "\n")
  before <- ls(envir, all.names = FALSE)
  loaded_before <- loadedNamespaces()
  package_calls <- .code_package_calls(code_expr, envir = envir)
  warnings <- list()
  err_stack <- NULL
  t0 <- Sys.time()
  value <- NULL
  visible <- FALSE
  err <- NULL
  res <- tryCatch(
    withCallingHandlers(
      withVisible(.bio_record_eval(code_expr, envir)),
      warning = function(w) {
        warnings[[length(warnings) + 1L]] <<- list(
          message = conditionMessage(w),
          call = if (!is.null(conditionCall(w))) .truncate_chr(paste(deparse(conditionCall(w)), collapse = " "), 200) else NA_character_,
          class = class(w)[1])
        if (muffle_warnings) invokeRestart("muffleWarning")
      },
      error = function(e) {
        err_stack <<- .clean_stack(sys.calls())
      }
    ),
    error = function(e) {
      err <<- e
      NULL
    }
  )
  if (!is.null(res)) {
    value <- res$value
    visible <- res$visible
  }
  elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  loaded_after <- loadedNamespaces()
  package_calls <- .record_package_usage(package_calls, loaded_before, loaded_after)
  after <- ls(envir, all.names = FALSE)
  assigned <- intersect(unique(c(.assigned_names(code_expr), setdiff(after, before))), after)
  used <- intersect(setdiff(all.names(code_expr), assigned), after)
  used <- used[vapply(used, function(n) !is.function(get0(n, envir = envir, inherits = FALSE)), logical(1))]
  summarize <- function(nms) {
    nms <- utils::head(nms, 30)
    stats::setNames(lapply(nms, function(n) .object_summary(get(n, envir = envir, inherits = FALSE), name = n)), nms)
  }
  error_info <- NULL
  if (!is.null(err)) {
    error_info <- list(
      message = conditionMessage(err),
      class = class(err),
      call = if (!is.null(conditionCall(err))) .truncate_chr(paste(deparse(conditionCall(err)), collapse = " "), 300) else NA_character_,
      stack = err_stack %||% character(),
      location = if (length(err_stack)) {
        cand <- err_stack[!grepl("^(stop|stopifnot|abort|rlang::abort|signal_abort|cnd_signal|\\.handleSimpleError)\\(", err_stack)]
        if (length(cand)) cand[length(cand)] else err_stack[length(err_stack)]
      } else NA_character_
    )
  }
  rec <- structure(list(
    label = label,
    purpose = purpose,
    code = code,
    status = if (!is.null(err)) "error" else if (length(warnings)) "warning" else "ok",
    value = value,
    visible = visible,
    warnings = warnings,
    error = error_info,
    objects_created = summarize(assigned),
    objects_used = summarize(used),
    environment_names = utils::head(after, 200),
    started = format(t0, "%Y-%m-%d %H:%M:%S %Z"),
    elapsed_sec = round(elapsed, 3),
    session = .session_versions(),
    package_usage = package_calls
  ), class = "bio_record")
  # Session history keeps summaries only, not (possibly large) result values.
  slim <- rec
  slim["value"] <- list(NULL)
  .pkg_env$last_record <- slim
  if (!is.null(err)) .pkg_env$last_error <- slim
  .pkg_env$records <- utils::tail(c(.pkg_env$records, list(slim)), .max_records)
  if (!is.null(err)) {
    if (rethrow) stop(err)
    message("bio_record: error captured -> ", conditionMessage(err),
            "\n  Use bio_explain_error() / bio_suggest_fix() for diagnosis.")
  }
  rec
}

#' Record the execution of R code
#'
#' Evaluates \code{expr} in the caller's environment (so assignments and other
#' side effects persist exactly as if the code were run directly), while
#' recording warnings, errors, the call stack at the moment of the error, compact
#' summaries of created/used objects and package versions.
#'
#' @param expr Code to run, typically a \code{\{ ... \}} block.
#' @param label Optional label for reports.
#' @param envir Environment in which to evaluate; defaults to the caller's.
#' @param muffle_warnings If \code{TRUE}, recorded warnings are not re-signalled.
#' @param rethrow If \code{TRUE}, re-signal an error after recording it.
#' @param purpose Optional free text describing the analysis goal (used by diagnosis).
#' @return An object of class \code{bio_record}; the expression value is in
#'   \code{$value} (also via \code{\link{bio_value}}).
#' @seealso \code{\link{bio_last_error}}, \code{\link{bio_explain_error}}
#' @export
#' @examples
#' run <- bio_record({
#'   x <- c(1, 2, 3)
#'   y <- mean(x)
#' })
#' run
#' y
bio_record <- function(expr, label = NULL, envir = parent.frame(), muffle_warnings = FALSE,
                       rethrow = FALSE, purpose = NULL) {
  .bio_record_impl(substitute(expr), label = label, envir = envir,
                   muffle_warnings = muffle_warnings, rethrow = rethrow,
                   purpose = purpose)
}

#' Record code supplied as text
#'
#' This is the browser and notebook friendly counterpart to \code{bio_record()}.
#' Code is parsed locally and then evaluated in the supplied environment. It is
#' never generated or executed automatically by an LLM.
#'
#' @param code Character string containing one or more R expressions.
#' @param label Optional label for reports.
#' @param envir Environment in which to evaluate the code.
#' @param muffle_warnings,rethrow,purpose Passed to \code{bio_record()}.
#' @return An object of class \code{bio_record}.
#' @export
bio_record_code <- function(code, label = NULL, envir = parent.frame(), muffle_warnings = FALSE,
                            rethrow = FALSE, purpose = NULL) {
  if (!is.character(code) || length(code) != 1L || is.na(code)) {
    stop("code must be one non-missing character string.", call. = FALSE)
  }
  parsed <- tryCatch(parse(text = code, keep.source = FALSE), error = function(e) e)
  if (inherits(parsed, "error")) stop("Code could not be parsed: ", conditionMessage(parsed), call. = FALSE)
  if (!length(parsed)) stop("code is empty.", call. = FALSE)
  expr <- if (length(parsed) == 1L) parsed[[1L]] else as.call(c(list(as.name("{")), as.list(parsed)))
  .bio_record_impl(expr, label = label, envir = envir,
                   muffle_warnings = muffle_warnings, rethrow = rethrow,
                   purpose = purpose)
}

#' Access recorded values and history
#'
#' \code{bio_value()} returns the value of a recorded expression.
#' \code{bio_last_error()} returns the most recent failed record (or the
#' error part of a given record). \code{bio_records()} lists recent records of
#' this session (at most 50 are kept).
#'
#' @param x A \code{bio_record}.
#' @return See description.
#' @export
#' @examples
#' r <- bio_record(1 + 1)
#' bio_value(r)
#' bio_last_error()
bio_value <- function(x) {
  stopifnot(inherits(x, "bio_record"))
  x$value
}

#' @rdname bio_value
#' @export
bio_last_error <- function(x = NULL) {
  if (!is.null(x)) {
    stopifnot(inherits(x, "bio_record"))
    return(if (identical(x$status, "error")) x else NULL)
  }
  .pkg_env$last_error
}

#' @rdname bio_value
#' @export
bio_records <- function() .pkg_env$records

#' @export
print.bio_record <- function(x, ...) {
  cat("<bio_record>", if (!is.null(x$label)) paste0("'", x$label, "'"), "status:", x$status,
      sprintf("(%.3fs)", x$elapsed_sec), "\n")
  code <- strsplit(x$code, "\n")[[1]]
  cat("  code:", utils::head(code, 1), if (length(code) > 1) paste0("... (+", length(code) - 1, " lines)"), "\n")
  if (length(x$objects_created)) cat("  objects created/modified:", paste(names(x$objects_created), collapse = ", "), "\n")
  if (length(x$warnings)) {
    cat("  warnings (", length(x$warnings), "):\n", sep = "")
    for (w in utils::head(x$warnings, 5)) cat("    - ", w$message, "\n", sep = "")
  }
  if (!is.null(x$error)) {
    cat("  error:", x$error$message, "\n")
    if (!is.na(x$error$location)) cat("  location:", x$error$location, "\n")
    if (length(x$error$stack)) {
      cat("  stack (innermost last):\n")
      for (s in utils::tail(x$error$stack, 8)) cat("    > ", s, "\n", sep = "")
    }
  } else {
    cat("  value:", paste(class(x$value), collapse = "/"), "(use bio_value())\n")
  }
  invisible(x)
}
