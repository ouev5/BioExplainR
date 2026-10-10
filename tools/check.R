# Run from the repository root with: R --vanilla --slave -f tools/check.R
required <- c("testthat", "pkgload", "roxygen2")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Install development packages: ", paste(missing, collapse = ", "))
roxygen2::roxygenise(".")
tests <- testthat::test_local(".", reporter = "summary", stop_on_failure = TRUE)
totals <- colSums(as.data.frame(tests)[c("nb", "failed", "skipped", "error", "warning", "passed")])
print(totals)
if (totals[["failed"]] || totals[["error"]]) stop("Tests failed.")
