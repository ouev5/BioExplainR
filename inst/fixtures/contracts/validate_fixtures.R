# Small structural/semantic fixture validator; not a full JSON Schema engine.
args <- commandArgs(trailingOnly = FALSE)
script_arg <- grep("^--file=", args, value = TRUE)
script <- if (length(script_arg)) sub("^--file=", "", script_arg[1]) else
  file.path("inst", "fixtures", "contracts", "validate_fixtures.R")
directory <- dirname(normalizePath(script, mustWork = TRUE))
schema_dir <- normalizePath(file.path(directory, "../../schema"), mustWork = TRUE)
if (!requireNamespace("jsonlite", quietly = TRUE)) stop("jsonlite is required")
validate <- function(x, schema) {
  if (!is.null(schema$required) && any(!unlist(schema$required) %in% names(x))) return(FALSE)
  if (!is.null(schema$enum) && !x %in% unlist(schema$enum)) return(FALSE)
  if (!is.null(schema$const) && !identical(x, schema$const)) return(FALSE)
  types <- unlist(schema$type)
  if (length(types)) {
    ok <- ("null" %in% types && is.null(x)) || ("string" %in% types && is.character(x) && length(x) == 1L) ||
      ("object" %in% types && is.list(x) && (!length(x) || !is.null(names(x)))) ||
      ("array" %in% types && is.list(x) && is.null(names(x)))
    if (!ok) return(FALSE)
  }
  if (is.list(x) && length(schema$properties)) for (k in intersect(names(x), names(schema$properties)))
    if (!validate(x[[k]], schema$properties[[k]])) return(FALSE)
  if (is.list(x) && !is.null(schema$items)) for (item in x) if (!validate(item, schema$items)) return(FALSE)
  TRUE
}
files <- list.files(directory, pattern = "\\.json$", full.names = TRUE)
stopifnot(length(files) >= 5L)
for (file in files) {
  family <- if (grepl("^claims", basename(file))) "claim-ledger" else if (grepl("^context", basename(file))) "context" else "evidence-relation"
  schema <- jsonlite::fromJSON(file.path(schema_dir, paste0(family, ".schema.json")), simplifyVector = FALSE)
  object <- jsonlite::fromJSON(file, simplifyVector = FALSE)
  valid <- validate(object, schema)
  if (family == "claim-ledger" && length(object$claims)) {
    ids <- vapply(object$claims, function(cl) cl$id, "")
    valid <- valid && !anyDuplicated(ids) && all(nzchar(ids))
  }
  expected <- !grepl("-invalid-", basename(file), fixed = TRUE)
  if (!identical(isTRUE(valid), expected)) stop("unexpected fixture validation: ", basename(file))
  cat(basename(file), if (valid) "accepted" else "rejected", "as expected\n")
}
