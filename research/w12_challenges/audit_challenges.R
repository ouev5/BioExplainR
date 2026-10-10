# Audit the public shape of a W12 challenge table. Controlled labels are not read.
args <- commandArgs(trailingOnly = TRUE)
hit <- grep("^--cases=", args, value = TRUE)
path <- if (length(hit)) sub("^--cases=", "", hit[1]) else file.path("research", "w12_challenges", "cases.csv")
if (!file.exists(path)) stop("challenge table is missing")
x <- read.csv(path, stringsAsFactors = FALSE)
required <- c("case_id", "task", "source_ref", "challenge_type", "reference_ref")
status <- if (all(required %in% names(x)) && !anyDuplicated(x$case_id)) "pass" else "fail"
if (any(grepl("TO_BE_FILLED", x$reference_ref, fixed = TRUE))) status <- "template"
cat("W12 challenge audit:", status, "rows=", nrow(x), "\n", sep = "")
