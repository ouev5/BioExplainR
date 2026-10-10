# Fix validation in a separate R process ----------------------------------------------

#' Define a semantic invariant
#'
#' An invariant is a named check applied to the result of a candidate fix. The
#' function receives \code{result} and \code{inputs} (the named input list) and
#' must return \code{TRUE} (pass), \code{FALSE}, or a character string
#' describing the failure. Helper constructors cover common checks.
#'
#' Invariant functions are serialised to the child process; keep them
#' self-contained (use \code{pkg::fun} for package functions).
#'
#' @param name Short name.
#' @param fn \code{function(result, inputs)}.
#' @param description Human-readable description.
#' @param cls,cols,n,input,column,levels,expected Arguments of the helpers.
#' @return Object of class \code{bio_invariant}.
#' @export
#' @examples
#' bio_invariant("positive", function(result, inputs) all(result > 0))
#' inv_class("data.frame")
#' inv_has_columns(c("gene", "log2FoldChange"))
bio_invariant <- function(name, fn, description = name) {
  stopifnot(is.character(name), length(name) == 1, is.function(fn))
  structure(list(name = name, fn = fn, description = description), class = "bio_invariant")
}

# Invariant closures are sent to the child process; detach them from the
# package namespace so the child does not need BioExplainR installed.
.detached <- function(fn, ...) {
  environment(fn) <- list2env(list(...), parent = globalenv())
  fn
}

#' @rdname bio_invariant
#' @export
inv_class <- function(cls) {
  bio_invariant(paste0("class:", cls), .detached(function(result, inputs) inherits(result, cls), cls = cls),
                paste0("The result inherits class " %L% "\u7ed3\u679c\u7ee7\u627f\u7c7b ", cls))
}

#' @rdname bio_invariant
#' @export
inv_has_columns <- function(cols) {
  force(cols)
  bio_invariant(paste0("columns:", paste(cols, collapse = ",")), .detached(function(result, inputs) {
    miss <- setdiff(cols, colnames(result))
    if (length(miss)) paste("missing columns:", paste(miss, collapse = ", ")) else TRUE
  }, cols = cols), paste0("The result contains columns " %L% "\u7ed3\u679c\u5305\u542b\u5217 ", paste(cols, collapse = ", ")))
}

#' @rdname bio_invariant
#' @export
inv_nrow <- function(n) {
  force(n)
  bio_invariant(paste0("nrow==", n), .detached(function(result, inputs) {
    if (NROW(result) == n) TRUE else paste0("nrow is ", NROW(result), ", expected ", n)
  }, n = n), paste0("The number of result rows equals " %L% "\u7ed3\u679c\u884c\u6570\u7b49\u4e8e ", n))
}

#' @rdname bio_invariant
#' @export
inv_same_nrow_as_input <- function(input) {
  force(input)
  bio_invariant(paste0("nrow==nrow(", input, ")"), .detached(function(result, inputs) {
    if (!input %in% names(inputs)) return(paste0("missing input: ", input))
    if (NROW(result) == NROW(inputs[[input]])) TRUE
    else paste0("nrow ", NROW(result), " != nrow(", input, ") ", NROW(inputs[[input]]))
  }, input = input), paste0("The number of result rows equals that of input " %L% "\u7ed3\u679c\u884c\u6570\u4e0e\u8f93\u5165 ", input, " (no features lost unexpectedly)" %L% " \u76f8\u540c\uff08\u672a\u610f\u5916\u4e22\u5931\u7279\u5f81\uff09"))
}

#' @rdname bio_invariant
#' @export
inv_factor_levels <- function(column, levels) {
  force(column); force(levels)
  bio_invariant(paste0("levels:", column), .detached(function(result, inputs) {
    v <- result[[column]]
    got <- if (is.factor(v)) levels(v) else NULL
    if (identical(got, levels)) TRUE
    else paste0("levels of ", column, " are [", paste(got, collapse = ", "), "], expected [", paste(levels, collapse = ", "), "]")
  }, column = column, levels = levels), paste0(column, " has factor levels in the order " %L% " \u7684\u56e0\u5b50\u6c34\u5e73\u53ca\u987a\u5e8f\u4e3a ", paste(levels, collapse = " < "), " (keeps the comparison direction unchanged)" %L% "\uff08\u4fdd\u8bc1\u6bd4\u8f83\u65b9\u5411\u4e0d\u53d8\uff09"))
}

#' @rdname bio_invariant
#' @export
inv_no_na <- function(column = NULL) {
  bio_invariant(paste0("no_na", if (!is.null(column)) paste0(":", column)), .detached(function(result, inputs) {
    if (!is.null(column) && !column %in% colnames(result)) return(paste0("missing column: ", column))
    v <- if (is.null(column)) result else result[[column]]
    k <- sum(is.na(v))
    if (k == 0) TRUE else paste0(k, " NA values")
  }, column = column), paste0(if (is.null(column)) "The result" %L% "\u7ed3\u679c" else column, " contains no NA" %L% " \u4e0d\u542b NA"))
}

#' @rdname bio_invariant
#' @export
inv_equal <- function(name, fn, expected) {
  force(fn); force(expected)
  bio_invariant(name, .detached(function(result, inputs) {
    got <- fn(result, inputs)
    if (isTRUE(all.equal(got, expected))) TRUE
    else paste0("got ", paste(utils::head(format(got), 5), collapse = ", "),
                "; expected ", paste(utils::head(format(expected), 5), collapse = ", "))
  }, fn = fn, expected = expected), paste0(name, " equals the expected value" %L% " \u7b49\u4e8e\u671f\u671b\u503c"))
}

.child_validate <- function(expr, inputs, invariants, packages) {
  # callr runs this function with the global environment as its enclosure,
  # so it must not rely on package internals.
  `%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x
  for (p in packages) suppressPackageStartupMessages(library(p, character.only = TRUE))
  env <- new.env(parent = globalenv())
  list2env(inputs, envir = env)
  warns <- character()
  t0 <- Sys.time()
  res <- tryCatch(
    withCallingHandlers(list(ok = TRUE, value = eval(expr, env)),
      warning = function(w) {
        warns <<- c(warns, conditionMessage(w))
        invokeRestart("muffleWarning")
      }),
    error = function(e) list(ok = FALSE, error = conditionMessage(e),
                             call = paste(deparse(conditionCall(e)), collapse = " ")))
  elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  shape <- NULL
  inv <- NULL
  if (isTRUE(res$ok)) {
    v <- res$value
    shape <- list(class = class(v), type = typeof(v),
                  dim = if (!is.null(dim(v))) as.integer(dim(v)) else NULL,
                  length = length(v),
                  names = utils::head(colnames(v) %||% names(v), 50))
    inv <- lapply(invariants, function(i) {
      out <- tryCatch(i$fn(v, inputs), error = function(e) paste("invariant error:", conditionMessage(e)))
      pass <- isTRUE(out)
      list(name = i$name, description = i$description, passed = pass,
           detail = if (pass) "" else if (is.character(out)) paste(out, collapse = "; ") else "returned FALSE")
    })
  }
  list(ok = isTRUE(res$ok), error = res$error, call = res$call, warnings = warns,
       shape = shape, invariants = inv, elapsed = elapsed,
       r_version = R.version.string)
}

#' Validate a candidate fix in a separate R process
#'
#' Runs an \strong{explicit} user-supplied expression with \strong{explicitly
#' named} inputs in a fresh R process via \pkg{callr}, records whether it ran,
#' its output class/shape and warnings, and evaluates user-specified semantic
#' invariants (see \code{\link{bio_invariant}}).
#'
#' Status values:
#' \describe{
#'   \item{\code{runtime_failed}}{the expression raised an error or timed out;}
#'   \item{\code{runtime_only}}{it ran, but no invariants were given, so the
#'     result is \emph{not} semantically verified;}
#'   \item{\code{invariants_failed}}{it ran but at least one invariant failed;}
#'   \item{\code{invariants_passed}}{it ran and all given invariants passed.
#'     This only covers the specified checks, not overall scientific
#'     correctness.}
#' }
#'
#' The separate process isolates the global environment and loaded packages
#' from your session, but it is \strong{not} an operating-system security
#' sandbox: the code can still read/write files and access the network. Never
#' run untrusted (including model-generated) code without reading it first.
#' BioExplainR never executes model-generated code automatically.
#'
#' @param expr The fix: a quoted call (\code{quote({...})}), an
#'   \code{expression()}, a character string of R code, or code written
#'   directly in the call.
#' @param inputs Named list of input objects made available to \code{expr}.
#' @param invariants List of \code{bio_invariant} objects.
#' @param packages Packages to attach in the child process before running.
#' @param timeout Seconds before the child is killed.
#' @param label Optional label for reports.
#' @return Object of class \code{bio_validation}.
#' @export
#' @examples
#' \donttest{
#' if (requireNamespace("callr", quietly = TRUE)) {
#'   cd <- data.frame(condition = c("treated", "control", "treated", "control"))
#'   v <- bio_validate_fix(
#'     quote({ cd$condition <- relevel(factor(cd$condition), ref = "control"); cd }),
#'     inputs = list(cd = cd),
#'     invariants = list(inv_factor_levels("condition", c("control", "treated")),
#'                       inv_same_nrow_as_input("cd")))
#'   v$status
#' }
#' }
bio_validate_fix <- function(expr, inputs = list(), invariants = list(), packages = character(),
                             timeout = 60, label = NULL) {
  if (missing(expr)) stop("Provide an explicit fix expression.", call. = FALSE)
  sx <- substitute(expr)
  if (is.call(sx) && identical(sx[[1]], as.name("quote"))) {
    code <- sx[[2]]
  } else if (is.symbol(sx) && exists(as.character(sx), envir = parent.frame())) {
    val <- get(as.character(sx), envir = parent.frame())
    code <- if (is.language(val) || is.expression(val) || is.character(val)) val else sx
  } else if (is.call(sx) && identical(sx[[1]], as.name("expression"))) {
    code <- eval(sx)
  } else if (is.character(sx)) {
    code <- sx
  } else {
    code <- sx
  }
  if (inherits(code, "bio_fix_suggestions")) stop("Pass a specific expression, not a suggestions object.", call. = FALSE)
  if (is.character(code)) code <- parse(text = code)
  if (is.expression(code)) code <- as.call(c(as.name("{"), as.list(code)))
  if (!is.list(inputs) || (length(inputs) && (is.null(names(inputs)) || anyNA(names(inputs)) ||
      any(!nzchar(names(inputs))) || anyDuplicated(names(inputs))))) {
    stop("inputs must be a named list, e.g. inputs = list(counts = counts, coldata = coldata).", call. = FALSE)
  }
  if (inherits(invariants, "bio_invariant")) invariants <- list(invariants)
  ok_inv <- vapply(invariants, inherits, logical(1), what = "bio_invariant")
  if (!all(ok_inv)) stop("invariants must be bio_invariant objects (see ?bio_invariant).", call. = FALSE)
  if (!requireNamespace("callr", quietly = TRUE)) {
    stop("bio_validate_fix() needs the 'callr' package: install.packages('callr').", call. = FALSE)
  }
  child <- .child_validate
  environment(child) <- globalenv()
  t0 <- Sys.time()
  out <- tryCatch(
    callr::r(child, args = list(expr = code, inputs = inputs, invariants = invariants, packages = packages),
             timeout = timeout, spinner = FALSE),
    error = function(e) {
      timed_out <- inherits(e, "callr_timeout_error") || grepl("timed? ?out", conditionMessage(e), ignore.case = TRUE)
      list(ok = FALSE, error = if (timed_out) paste0("timeout after ", timeout, "s") else conditionMessage(e),
           call = NA_character_, warnings = character(), shape = NULL, invariants = NULL,
           elapsed = as.numeric(difftime(Sys.time(), t0, units = "secs")), process_error = TRUE)
    })
  inv_df <- if (length(out$invariants)) do.call(rbind, lapply(out$invariants, function(i)
    data.frame(name = i$name, description = i$description, passed = i$passed, detail = i$detail,
               stringsAsFactors = FALSE))) else
    data.frame(name = character(), description = character(), passed = logical(), detail = character())
  status <- if (!isTRUE(out$ok)) "runtime_failed"
            else if (!nrow(inv_df)) "runtime_only"
            else if (all(inv_df$passed)) "invariants_passed"
            else "invariants_failed"
  structure(list(
    label = label,
    status = status,
    runtime_ok = isTRUE(out$ok),
    semantically_verified = identical(status, "invariants_passed"),
    code = paste(deparse(code, width.cutoff = 120L), collapse = "\n"),
    inputs = lapply(inputs, .object_summary),
    output_shape = out$shape,
    invariants = inv_df,
    warnings = out$warnings,
    error = out$error,
    elapsed_sec = round(out$elapsed %||% NA_real_, 3),
    child_r_version = out$r_version %||% NA_character_,
    note = paste0(
      switch(status,
        runtime_only = "Only verified that the code runs; no semantic invariants were supplied, so this must not be treated as a verified fix." %L%
          "\u4ec5\u9a8c\u8bc1\u4e86\u4ee3\u7801\u53ef\u8fd0\u884c\uff1b\u672a\u63d0\u4f9b\u8bed\u4e49\u4e0d\u53d8\u91cf\uff0c\u4e0d\u80fd\u89c6\u4e3a\u5df2\u9a8c\u8bc1\u7684\u4fee\u590d\u3002",
        runtime_failed = "The fix code failed to run in the separate process." %L% "\u4fee\u590d\u4ee3\u7801\u5728\u72ec\u7acb\u8fdb\u7a0b\u4e2d\u8fd0\u884c\u5931\u8d25\u3002",
        invariants_failed = "The code runs, but at least one semantic invariant failed." %L% "\u4ee3\u7801\u53ef\u8fd0\u884c\uff0c\u4f46\u81f3\u5c11\u4e00\u4e2a\u8bed\u4e49\u4e0d\u53d8\u91cf\u672a\u901a\u8fc7\u3002",
        invariants_passed = "The code runs and passed the user-specified invariants; this covers only the listed checks and does not mean the overall analysis conclusion is correct." %L%
          "\u4ee3\u7801\u53ef\u8fd0\u884c\u4e14\u901a\u8fc7\u4e86\u7528\u6237\u6307\u5b9a\u7684\u4e0d\u53d8\u91cf\uff1b\u8fd9\u53ea\u8986\u76d6\u6240\u5217\u68c0\u67e5\uff0c\u4e0d\u4ee3\u8868\u6574\u4f53\u5206\u6790\u7ed3\u8bba\u6b63\u786e\u3002"),
      " The separate R process is not an operating-system-level security sandbox." %L% " \u72ec\u7acb R \u8fdb\u7a0b\u4e0d\u662f\u64cd\u4f5c\u7cfb\u7edf\u7ea7\u5b89\u5168\u6c99\u7bb1\u3002")
  ), class = "bio_validation")
}

#' @export
print.bio_validation <- function(x, ...) {
  cat("<bio_validation> status:", x$status, "\n")
  cat("  runtime ok:", x$runtime_ok, "| semantically verified (user invariants):", x$semantically_verified, "\n")
  if (!is.null(x$output_shape)) {
    cat("  output:", paste(x$output_shape$class, collapse = "/"),
        if (!is.null(x$output_shape$dim)) paste0("[", paste(x$output_shape$dim, collapse = " x "), "]")
        else paste0("(length ", x$output_shape$length, ")"), "\n")
  }
  if (!is.null(x$error)) cat("  error:", x$error, "\n")
  if (nrow(x$invariants)) {
    cat("  invariants:\n")
    for (i in seq_len(nrow(x$invariants))) {
      r <- x$invariants[i, ]
      cat("    [", if (r$passed) "PASS" else "FAIL", "] ", r$description,
          if (!r$passed) paste0(" -- ", r$detail), "\n", sep = "")
    }
  }
  if (length(x$warnings)) cat("  warnings:", paste(utils::head(x$warnings, 3), collapse = " | "), "\n")
  cat("  note:", x$note, "\n")
  invisible(x)
}
