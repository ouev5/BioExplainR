# Install comparator in an isolated library; keep the project's system R intact.
lib <- "/tmp/opencode/common-performance-R-library"
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib, .libPaths()))
options(repos = c(CRAN = "https://cloud.r-project.org"), timeout = 300, Ncpus = 2)
link <- "/tmp/opencode/common-performance-runtime/curl-dev/libcurl.so"
if (!file.exists(link)) stopifnot(file.symlink("/usr/lib/x86_64-linux-gnu/libcurl.so.4", link))
install.packages("curl", lib = lib, configure.vars = "INCLUDE_DIR=/tmp/opencode/common-performance-runtime/curl-dev/usr/include/x86_64-linux-gnu LIB_DIR=/tmp/opencode/common-performance-runtime/curl-dev")
install.packages("ellmer", lib = lib)
stopifnot(requireNamespace("ellmer", quietly = TRUE))
cat("ellmer", as.character(packageVersion("ellmer")), "\n")
capture.output(sessionInfo(), file = "/tmp/opencode/common-performance-runtime/comparator_session.txt")
