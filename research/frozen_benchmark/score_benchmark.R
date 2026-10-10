# Score only when a separately controlled gold file is explicitly provided.
args <- commandArgs(trailingOnly = TRUE)
getarg <- function(n) { x <- grep(paste0("^--", n, "="), args, value = TRUE); if (length(x)) sub(paste0("^--", n, "="), "", x[1]) else NULL }
calls_path <- getarg("calls"); gold_path <- getarg("gold"); output <- getarg("output")
if (is.null(calls_path) || is.null(gold_path) || is.null(output)) stop("--calls=, --gold= and --output= are required")
if (!file.exists(calls_path) || !file.exists(gold_path)) stop("calls or gold file is missing; no score written")
if (file.exists(output)) stop("score output already exists; refusing to overwrite")
calls <- read.csv(calls_path, stringsAsFactors = FALSE, colClasses = "character", na.strings = "")
gold <- read.csv(gold_path, stringsAsFactors = FALSE, colClasses = "character", na.strings = "")
need <- c("case_id", "method_id", "prediction")
if (any(!need %in% names(calls)) || any(!c("case_id", "reference") %in% names(gold))) stop("calls/gold schema is incomplete")
if (anyDuplicated(gold$case_id) || anyNA(gold$case_id) || any(!nzchar(gold$case_id))) stop("gold case IDs must be unique and non-missing")
if (anyDuplicated(calls[c("case_id", "method_id")])) stop("duplicate call keys")
if (anyNA(gold$reference) || any(!nzchar(gold$reference)) || !all(calls$case_id %in% gold$case_id)) stop("missing controlled references; no accuracy computed")
out <- merge(calls, gold[c("case_id", "reference")], by = "case_id", all.x = TRUE)
out$answered <- !is.na(out$prediction) & nzchar(out$prediction)
out$correct <- out$answered & out$prediction == out$reference
write.csv(out, output, row.names = FALSE)
cat("scored", nrow(out), "rows from explicitly supplied gold\n")
