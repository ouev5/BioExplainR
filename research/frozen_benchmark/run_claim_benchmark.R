# W09 offline benchmark runner. No live provider is contacted by this script.
args <- commandArgs(trailingOnly = TRUE)
arg <- function(name, default = NULL) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (!length(hit)) return(default)
  sub(paste0("^--", name, "="), "", hit[1])
}
mode <- arg("mode", "dry-run")
if (!mode %in% c("dry-run", "replay")) stop("mode must be dry-run or replay")
input <- arg("input", file.path("research", "frozen_benchmark", "fixtures", "cases.json"))
output <- arg("output", file.path("research", "results", "frozen_v1", paste0("run-", format(Sys.time(), "%Y%m%d%H%M%S"))))
if (file.exists(output)) stop("output already exists; frozen runs cannot be overwritten")
cases <- jsonlite::fromJSON(input, simplifyVector = FALSE)
if (!requireNamespace("digest", quietly = TRUE)) stop("digest is required for benchmark hashes")
if (!length(cases)) stop("input has no cases")
case_ids <- vapply(cases, `[[`, "", "case_id")
if (anyDuplicated(case_ids)) stop("case_id must be unique")
if (anyNA(case_ids) || any(!nzchar(case_ids))) stop("case_id must be non-empty")
# Check public inputs before creating the immutable output directory. This is a
# data boundary, not an OS sandbox; the external controller owns mount isolation.
check_public <- function(x) {
  if (!is.list(x)) return(invisible(NULL))
  if (any(grepl("(?i)(gold|reference|rating|adjudication|answer_key|expected|correct)", names(x), perl = TRUE)))
    stop("public inputs must not contain controlled label fields")
  invisible(lapply(x, check_public))
}
check_public(cases)
replay_path <- arg("replay")
replay <- NULL
if (mode == "replay" && !is.null(replay_path)) {
  replay <- read.csv(replay_path, stringsAsFactors = FALSE, colClasses = "character", na.strings = "")
  if (!all(c("case_id", "prediction") %in% names(replay))) stop("replay needs case_id and prediction")
  if (anyDuplicated(replay$case_id) || !setequal(replay$case_id, case_ids)) stop("replay case IDs must match input exactly")
  replay <- replay[match(case_ids, replay$case_id), , drop = FALSE]
}
if (!dir.create(output, recursive = TRUE)) stop("could not create new output")
file.copy(input, file.path(output, "public_cases.json"), overwrite = FALSE)
calls <- do.call(rbind, lapply(cases, function(x) data.frame(
  run_id = basename(output), case_id = x$case_id, method_id = "configured_model", repeat_no = 1L,
  attempt = 1L, request_hash = NA_character_, response_hash = NA_character_,
  status = if (mode == "dry-run") "not_run" else "missing_replay", usage = NA_character_,
  elapsed_sec = NA_real_, prediction = NA_character_, stringsAsFactors = FALSE)))
if (!is.null(replay)) {
  file.copy(replay_path, file.path(output, "replay.csv"), overwrite = FALSE)
  calls$prediction <- replay$prediction
  calls$status <- ifelse(is.na(replay$prediction) | !nzchar(replay$prediction), "unanswered", "replayed")
  calls$response_hash <- vapply(seq_len(nrow(replay)), function(i) digest::digest(
    jsonlite::toJSON(as.list(replay[i, , drop = FALSE]), auto_unbox = TRUE, na = "null"), algo = "sha256", serialize = FALSE), "")
}
write.csv(calls, file.path(output, "calls.csv"), row.names = FALSE, na = "")
hash <- function(path) digest::digest(file = path, algo = "sha256")
manifest <- list(manifest_version = "1.0", benchmark_id = "claim_benchmark_fixture",
                 run_id = basename(output), schema_version = "1.0", mode = mode,
                  input = list(path = "public_cases.json", hash = hash(file.path(output, "public_cases.json"))),
                  calls = list(path = "calls.csv", hash = hash(file.path(output, "calls.csv"))),
                  replay = if (is.null(replay)) NULL else list(path = "replay.csv", hash = hash(file.path(output, "replay.csv"))),
                  runner_hash = hash("research/frozen_benchmark/run_claim_benchmark.R"),
                 gold = list(status = "missing", path = NULL), cases = length(cases),
                  methods = list("configured_model"), status = if (mode == "dry-run") "not_run" else if (is.null(replay)) "missing_replay" else "replayed",
                 created = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"))
jsonlite::write_json(manifest, file.path(output, "benchmark_manifest.json"), auto_unbox = TRUE, pretty = TRUE, null = "null")
cat("W09", mode, "run written to", output, "with", nrow(calls), "call rows; gold is missing\n")
