# Separate library for installed-tool experiments, not package dependencies.
library_path <- "/tmp/opencode/related-R-library"
dir.create(library_path, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(library_path, .libPaths()))
options(repos = c(CRAN = "https://cloud.r-project.org"), timeout = 180, Ncpus = 2)
dir.create("research/results/related_tools", recursive = TRUE, showWarnings = FALSE)
rows <- list()
install_one <- function(name, installer) {
  started <- Sys.time()
  message("Installing ", name)
  error <- tryCatch({ installer(); NA_character_ }, error = function(e) conditionMessage(e))
  available <- requireNamespace(name, quietly = TRUE)
  rows[[length(rows) + 1L]] <<- data.frame(package = name, installed = available,
    version = if (available) as.character(utils::packageVersion(name)) else NA_character_,
    elapsed_sec = as.numeric(difftime(Sys.time(), started, units = "secs")), error = error)
  utils::write.csv(do.call(rbind, rows), "research/results/related_tools/install_status.csv", row.names = FALSE)
}
install_one("ellmer", function() utils::install.packages("ellmer", lib = library_path))
install_one("btw", function() utils::install.packages("btw", lib = library_path))
install_one("GPTCelltype", function() {
  utils::install.packages("openai", lib = library_path)
  utils::install.packages("https://github.com/Winnie09/GPTCelltype/archive/refs/heads/master.tar.gz",
                          repos = NULL, type = "source", lib = library_path)
})
install_one("iSEE", function() {
  if (!requireNamespace("BiocManager", quietly = TRUE)) utils::install.packages("BiocManager", lib = library_path)
  BiocManager::install("iSEE", lib = library_path, update = FALSE, ask = FALSE)
})
capture.output(utils::sessionInfo(), file = "research/results/related_tools/install_session.txt")
print(do.call(rbind, rows))
