#!/usr/bin/env bash
# Prepare or verify the R development library used by tools/check.R.
# R 4.3.3 is sufficient for BioExplainR; the compatibility pin is for the
# temporary roxygen2/xfun toolchain, not for the package runtime itself.
set -euo pipefail

root_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if [[ ! -f "$root_dir/tools/server-R" ]]; then
  printf '%s\n' "tools/server-R is unavailable; install R and use the normal R library." >&2
  exit 1
fi

bash "$root_dir/tools/server-R" --vanilla --slave <<'RSCRIPT'
lib <- .libPaths()[1]
if (getRversion() < "4.1.0") stop("BioExplainR requires R >= 4.1.0")
temporary_runtime <- file.exists("/tmp/opencode/r-env.sh")
xfun_ok <- requireNamespace("xfun", quietly = TRUE) &&
  identical(as.character(packageVersion("xfun")), "0.53") &&
  "attr" %in% getNamespaceExports("xfun")
if (temporary_runtime && !xfun_ok) {
  utils::install.packages(
    "https://cran.r-project.org/src/contrib/Archive/xfun/xfun_0.53.tar.gz",
    lib = lib, repos = NULL, type = "source"
  )
}
if (!requireNamespace("roxygen2", quietly = TRUE)) {
  utils::install.packages(
    "https://cran.r-project.org/src/contrib/Archive/roxygen2/roxygen2_7.3.1.tar.gz",
    lib = lib, repos = NULL, type = "source"
  )
}
stopifnot(requireNamespace("roxygen2", quietly = TRUE))
stopifnot(requireNamespace("testthat", quietly = TRUE), requireNamespace("pkgload", quietly = TRUE))
cat("R", R.version.string, "\n")
cat("xfun", as.character(packageVersion("xfun")), "temporary-runtime pin:", temporary_runtime, "\n")
cat("roxygen2", as.character(packageVersion("roxygen2")), "\n")
RSCRIPT
