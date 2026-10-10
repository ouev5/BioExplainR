# W11 analysis entry: refuses to call preparation data a completed study.
args <- commandArgs(trailingOnly = TRUE)
hit <- grep("^--ratings=", args, value = TRUE)
if (!length(hit)) {
  cat("No ratings supplied; W11 human evaluation is not run.\n")
  quit(save = "no", status = 0)
}
ratings <- read.csv(sub("^--ratings=", "", hit[1]), stringsAsFactors = FALSE)
required <- c("item_id", "dimension", "label")
if (any(!required %in% names(ratings))) stop("ratings schema is incomplete")
cat("Ratings loaded for analysis preparation:", nrow(ratings), "rows. Verify ethics, blinding and gold provenance before inference.\n")
