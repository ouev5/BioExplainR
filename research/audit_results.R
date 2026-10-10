# Unified offline audit entry. Historical scope retains the original checks.
args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) sub("^--mode=", "", args[[1]]) else "current"
if (!mode %in% c("current", "historical")) stop("Use --mode=current or --mode=historical")
if (mode == "current") {
  python <- Sys.which("python3")
  if (!nzchar(python)) stop("python3 is required for the current file/hash audit")
  status <- system2(python, "research/audit_current_results.py --output research/results/w00_baseline/current_audit.json")
  quit(status = status)
}

# Historical experiment (2026-10-03): not the current scale experiment.
scores <- read.csv("research/results/fact_scores.csv")
calls <- read.csv("research/results/model_calls.csv")
summary <- read.csv("research/results/ablation_summary.csv")
stopifnot(nrow(scores) == 225, nrow(calls) == 54, all(calls$success), all(calls$structured))
for (m in summary$method) {
  row <- summary[summary$method == m, ]
  observed <- scores[scores$method == m, ]
  stopifnot(nrow(observed) == row$expected, sum(observed$correct) == row$correct,
            isTRUE(all.equal(mean(observed$correct), row$accuracy)),
            isTRUE(all.equal(mean(observed$answered), row$coverage)))
}
challenge <- read.csv("research/results/plot_challenges.csv")
stopifnot(nrow(challenge) == 9, all(challenge$actual == challenge$expected))
mutations <- read.csv("research/results/validation_ablation.csv")
stopifnot(nrow(mutations) == 90,
          all(mutations$with_validator[mutations$mutation != "reference_only"] == "fail"),
          all(mutations$with_validator[mutations$mutation == "reference_only"] == "partial"))
manifest <- jsonlite::read_json("research/results/data_manifest.json")
stopifnot(manifest$reference$n_significant == 999, manifest$reference$n_up == 519,
          manifest$reference$n_down == 480, manifest$pbmc_cells == 2700)
browser <- jsonlite::read_json("research/results/browser/summary.json")
stopifnot(browser$status == "pass", length(browser$steps) == 11)
explanation <- jsonlite::read_json("research/results/deepseek_explanation.json")
stopifnot(explanation$validation$status == "pass")
check <- readLines("research/results/R-CMD-check.txt")
stopifnot(any(check == "Status: OK"))
stopifnot(file.exists("docs/BioExplainR-paper-draft.docx"), file.exists("docs/BioExplainR-paper-draft.html"))
result <- list(status = "pass", mode = "historical", scope = "2026-10-03 six-case mechanism experiment",
               requests = nrow(calls), fact_evaluations = nrow(scores),
               claim_challenges = nrow(mutations), plot_challenges = nrow(challenge),
               package_check = "saved historical Status: OK; not a current check")
jsonlite::write_json(result, "research/results/w00_baseline/historical_audit.json", auto_unbox = TRUE, pretty = TRUE)
cat("Historical stored-result audit passed:", nrow(calls), "requests,", nrow(scores),
    "fact evaluations,", nrow(mutations), "claim challenges,", nrow(challenge), "plot challenges.\n")
