# Audit public artifacts only; controlled gold is never opened here.
args <- commandArgs(trailingOnly = TRUE)
hit <- grep("^--manifest=", args, value = TRUE)
manifest_path <- if (length(hit)) sub("^--manifest=", "", hit[1]) else stop("--manifest= is required")
checks <- data.frame(check = character(), status = character(), stringsAsFactors = FALSE)
add <- function(name, ok) checks <<- rbind(checks, data.frame(check = name, status = if (isTRUE(ok)) "pass" else "fail"))
tryCatch({
  m <- jsonlite::fromJSON(manifest_path, simplifyVector = FALSE)
  required <- c("manifest_version", "benchmark_id", "run_id", "schema_version", "mode", "cases", "methods", "gold", "status", "input", "calls")
  for (k in required) add(k, !is.null(m[[k]]))
  artifact <- function(entry) {
    if (is.null(entry$path) || !entry$path %in% c("calls.csv", "public_cases.json", "replay.csv")) stop("unsafe artifact path")
    path <- file.path(dirname(manifest_path), entry$path)
    if (!file.exists(path) || !identical(digest::digest(file = path, algo = "sha256"), entry$hash)) stop("artifact hash mismatch")
    path
  }
  cases <- jsonlite::fromJSON(artifact(m$input), simplifyVector = FALSE)
  case_ids <- vapply(cases, `[[`, "", "case_id")
  calls <- read.csv(artifact(m$calls), stringsAsFactors = FALSE, colClasses = "character", na.strings = "")
  if (!is.null(m$replay)) artifact(m$replay)
  need <- c("run_id", "case_id", "method_id", "repeat_no", "attempt", "status", "prediction", "response_hash")
  add("call_schema", all(need %in% names(calls)))
  add("input_ids", !anyDuplicated(case_ids) && !anyNA(case_ids) && all(nzchar(case_ids)))
  methods <- unlist(m$methods, use.names = FALSE)
  add("call_rows", nrow(calls) == m$cases * length(methods) && length(cases) == m$cases)
  add("call_keys", !anyNA(calls[c("case_id", "method_id", "run_id", "repeat_no")]) &&
    !anyDuplicated(calls[c("case_id", "method_id", "repeat_no")]) &&
    setequal(calls$case_id, case_ids) && setequal(calls$method_id, methods) && all(calls$run_id == m$run_id))
  expected <- if (m$mode == "dry-run") "not_run" else if (is.null(m$replay)) "missing_replay" else c("replayed", "unanswered")
  add("call_status", all(calls$status %in% expected))
  add("response_record", if (is.null(m$replay)) all(is.na(calls$prediction) & is.na(calls$response_hash)) else all(!is.na(calls$response_hash)))
  add("gold_separation", identical(m$gold$status, "missing") && is.null(m$gold$path))
}, error = function(e) add(paste("artifact_error", conditionMessage(e)), FALSE))
out <- list(status = if (any(checks$status == "fail")) "fail" else "pass", findings = checks,
            accuracy = NULL, note = "Artifact consistency only; no scientific score or execution sandbox is inferred.")
jsonlite::write_json(out, file.path(dirname(manifest_path), "audit.json"), auto_unbox = TRUE, pretty = TRUE, null = "null")
cat("benchmark audit", out$status, "\n")
if (out$status != "pass") quit(status = 1L)
