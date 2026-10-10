# Parse saved signatures as data; do not evaluate their defaults or function body.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) %in% c(1L, 2L))
installed <- length(args) == 2L
if (installed) {
  stopifnot(args[2] == "--installed")
  library(BioExplainR)
} else pkgload::load_all(".", quiet = TRUE)
baseline <- jsonlite::fromJSON("research/results/w00_baseline/api_inventory.json", simplifyVector = FALSE)
namespace <- asNamespace("BioExplainR")
exports <- getNamespaceExports(namespace)
rows <- lapply(baseline$interfaces, function(item) {
  signature <- str2lang(item$signature)
  arguments <- as.list(signature)[-1L]
  old <- names(arguments)
  if (is.null(old)) old <- character(length(arguments))
  missing_name <- !nzchar(old)
  old[missing_name] <- vapply(arguments[missing_name], deparse, "")
  current <- if (item$name %in% exports) names(formals(get(item$name, namespace))) else character()
  if (is.null(current)) current <- character()
  fixed <- old[old != "..."]
  ok <- length(current) >= length(fixed) && identical(current[seq_along(fixed)], fixed)
  data.frame(name = item$name, status = if (ok) "pass" else "fail",
    legacy_positions = paste(fixed, collapse = ","), current_positions = paste(current, collapse = ","))
})
findings <- do.call(rbind, rows)
jsonlite::write_json(list(status = if (all(findings$status == "pass")) "pass" else "fail",
  checked = nrow(findings), package_mode = if (installed) "installed" else "source",
  package_version = as.character(packageVersion("BioExplainR")), package_path = find.package("BioExplainR"),
  scope = "exported names and positional parameter order; not full behavioral sign-off",
  findings = findings), args[1], auto_unbox = TRUE, pretty = TRUE)
print(table(findings$status))
stopifnot(all(findings$status == "pass"))
