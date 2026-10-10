# Offline benchmark contracts for W09/W12 --------------------------------------

.benchmark_status <- c("pass", "fail", "partial", "not_assessable", "unverified")

#' Validate the structure of a frozen benchmark manifest
#'
#' @param manifest A list or JSON file.
#' @param require_gold Whether a separate gold reference is required.
#' @return A benchmark audit result.
#' @export
bio_audit_benchmark_manifest <- function(manifest, require_gold = FALSE) {
  if (is.character(manifest) && length(manifest) == 1L) manifest <- jsonlite::fromJSON(manifest, simplifyVector = FALSE)
  if (!is.list(manifest)) stop("manifest must be a list or JSON path.", call. = FALSE)
  required <- c("manifest_version", "benchmark_id", "schema_version", "cases", "methods")
  rows <- lapply(required, function(k) data.frame(check = k,
    status = if (!is.null(manifest[[k]])) "pass" else "fail", detail = if (!is.null(manifest[[k]]) ) "present" else "missing", stringsAsFactors = FALSE))
  if (require_gold) rows[[length(rows) + 1L]] <- data.frame(check = "gold_separation", status = if (is.null(manifest$gold_path)) "fail" else "pass",
                                                               detail = "gold is referenced outside runner input", stringsAsFactors = FALSE)
  f <- do.call(rbind, rows)
  structure(list(status = if (any(f$status == "fail")) "fail" else "pass", findings = f,
                 manifest_hash = .hash_object(manifest)), class = "bio_benchmark_audit")
}

#' Score explicit benchmark rows without inventing labels
#'
#' @param scores Data frame with prediction, reference, answered and case IDs.
#' @param reference_col Reference column name.
#' @return A score summary.
#' @export
bio_score_benchmark <- function(scores, reference_col = "reference") {
  if (!is.data.frame(scores)) stop("scores must be a data.frame.", call. = FALSE)
  need <- c("case_id", "method_id", "prediction", reference_col)
  if (any(!need %in% names(scores))) stop("scores missing: ", paste(setdiff(need, names(scores)), collapse = ", "), call. = FALSE)
  if (!nrow(scores)) stop("scores must contain rows.", call. = FALSE)
  if (anyNA(scores[c("case_id", "method_id")]) || any(!nzchar(scores$case_id)) || any(!nzchar(scores$method_id)))
    stop("case_id and method_id must be non-missing.", call. = FALSE)
  if (anyDuplicated(paste(scores$case_id, scores$method_id, sep = "\r"))) stop("Duplicate case/method score rows.", call. = FALSE)
  scores$answered <- !is.na(scores$prediction) & nzchar(as.character(scores$prediction)) &
    if ("answered" %in% names(scores)) !is.na(scores$answered) & as.logical(scores$answered) else TRUE
  labeled <- !is.na(scores[[reference_col]]) & nzchar(as.character(scores[[reference_col]]))
  scores$correct <- rep(NA, nrow(scores))
  scores$correct[labeled] <- scores$answered[labeled] &
    as.character(scores$prediction[labeled]) == as.character(scores[[reference_col]][labeled])
  summary <- do.call(rbind, lapply(split(scores, scores$method_id), function(d) data.frame(
    method_id = d$method_id[1], n = nrow(d), answered = sum(d$answered, na.rm = TRUE),
    correct = sum(d$correct, na.rm = TRUE), coverage = mean(d$answered, na.rm = TRUE),
     all_target_accuracy = if (all(!is.na(d$correct))) mean(d$correct) else NA_real_,
     answered_accuracy = if (any(d$answered) && all(!is.na(d$correct))) mean(d$correct[d$answered]) else NA_real_,
    stringsAsFactors = FALSE)))
   structure(list(scores = scores, summary = summary, status = if (all(labeled)) "scored" else "unverified"), class = "bio_benchmark_score")
}

#' @export
print.bio_benchmark_score <- function(x, ...) {
  cat("<bio_benchmark_score>\n"); print(x$summary, row.names = FALSE); invisible(x)
}

#' Create an offline W12 challenge manifest
#'
#' @param cases Data frame describing diagnostic, plot or repair cases.
#' @param task Task family.
#' @return A frozen challenge manifest.
#' @export
bio_challenge_manifest <- function(cases, task = c("diagnostic", "plot", "repair")) {
  task <- match.arg(task)
  if (!is.data.frame(cases) || !"case_id" %in% names(cases)) stop("cases must include a unique case_id column.", call. = FALSE)
  if (anyDuplicated(cases$case_id)) stop("case_id must be unique.", call. = FALSE)
  structure(list(manifest_version = "1.0", task = task, cases = cases,
                 created = .now(), cases_hash = .hash_object(cases)), class = "bio_challenge_manifest")
}
