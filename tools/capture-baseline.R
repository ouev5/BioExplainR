# Run from the repository root after restoring dependencies.
out <- "research/results/w00_baseline"
stopifnot(dir.exists(out))
pkgs <- utils::installed.packages()
utils::write.csv(pkgs[, intersect(c("Package", "Version", "LibPath", "Repository", "Built"), colnames(pkgs))],
                 file.path(out, "r_packages.csv"), row.names = FALSE)
capture.output({
  print(R.version.string)
  cat("Bioconductor release:", as.character(utils::packageVersion("BiocVersion")), "\n")
  print(.libPaths())
  print(utils::sessionInfo())
}, file = file.path(out, "r_environment.txt"))

pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
exports <- sort(getNamespaceExports("BioExplainR"))
source_locations <- list()
for (file in list.files("R", pattern = "\\.R$", full.names = TRUE)) {
  expressions <- parse(file, keep.source = TRUE)
  refs <- attr(expressions, "srcref")
  for (i in seq_along(expressions)) {
    expr <- expressions[[i]]
    if (is.call(expr) && identical(expr[[1]], as.name("<-")) && is.symbol(expr[[2]]) &&
        is.call(expr[[3]]) && identical(expr[[3]][[1]], as.name("function"))) {
      source_locations[[as.character(expr[[2]])]] <- list(file = file, line = as.integer(refs[[i]][1]))
    }
  }
}
apis <- lapply(exports, function(name) {
  fn <- getExportedValue("BioExplainR", name)
  location <- source_locations[[name]]
  signature <- paste(deparse(args(fn), width.cutoff = 500L), collapse = " ")
  signature <- sub("[[:space:]]+NULL$", "", signature)
  list(name = name, source = location$file, line = location$line,
       signature = sub("^function[[:space:]]*", name, signature))
})
jsonlite::write_json(list(package_version = as.character(utils::packageVersion("BioExplainR")),
                          schema = "legacy_unversioned", n_exports = length(exports), interfaces = apis),
                     file.path(out, "api_inventory.json"), auto_unbox = TRUE, pretty = TRUE, null = "null")
utils::write.csv(do.call(rbind, lapply(apis, as.data.frame)), file.path(out, "api_inventory.csv"), row.names = FALSE)
cat("Captured", length(exports), "exported function signatures and installed R package versions.\n")
