# Resume frozen independent auditor with only empty-string annotation parsing corrected.
# Original frozen auditor and all Python numeric results remain byte-for-byte preserved.
execution <- new.env(parent=globalenv())
execution$read.csv <- function(...) {
  value <- utils::read.csv(...)
  if ("gene" %in% names(value)) value$gene[is.na(value$gene)] <- ""
  value
}
sys.source("research/discovery/audit_epithelial_protein.R", envir=execution)
