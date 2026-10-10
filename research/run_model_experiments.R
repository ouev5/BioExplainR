# Explicit live experiment. DEEPSEEK_API_KEY must be supplied at runtime.
# No configuration/key objects or full HTTP requests are written to disk.
suppressPackageStartupMessages(library(BioExplainR))
`%||%` <- function(x, y) if (is.null(x)) y else x
stopifnot(nzchar(Sys.getenv("DEEPSEEK_API_KEY")))
d <- readRDS("research/cache/real_objects.rds")
dir.create("research/results/model", recursive = TRUE, showWarnings = FALSE)
cfg <- bio_config("deepseek", base_url = "https://api.deepseek.com", model = "deepseek-flash",
                  api_key_env = "DEEPSEEK_API_KEY", json_mode = TRUE, max_tokens = 5000,
                  timeout = 120, max_retries = 1, temperature = 0,
                  extra_body = list(thinking = list(type = "disabled")))
plain <- function(x) if (is.list(x) && !is.data.frame(x)) lapply(x, plain) else x
write_json <- function(x, file) jsonlite::write_json(plain(x), file, pretty = TRUE, auto_unbox = TRUE, null = "null", digits = 10)
j <- function(x) jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", digits = 10, pretty = TRUE)
evidence <- bio_fetch_evidence("EXT_ID:24926665 AND SRC:MED", source = "europepmc", limit = 1)
stopifnot(length(evidence) >= 1L)
write_json(evidence, "research/results/evidence.json")
cases <- list()
add <- function(name, input, expected, args = list(), raw = NULL) {
  context <- do.call(bio_context, c(list(input), args))
  cases[[name]] <<- list(input = input, context = context, expected = expected, raw = raw)
}
for (threshold in c(0, 1)) {
  sig <- !is.na(d$tab$padj) & d$tab$padj < .05 & abs(d$tab$log2FoldChange) > threshold
  add(paste0("airway_lfc", threshold), d$res,
      list(n_features = nrow(d$tab), n_significant = sum(sig), n_up = sum(sig & d$tab$log2FoldChange > 0),
           n_down = sum(sig & d$tab$log2FoldChange < 0), n_na_padj = sum(is.na(d$tab$padj))),
      list(thresholds = list(padj = .05, lfc = threshold), species = "Homo sapiens",
           contrast = "dexamethasone trt vs untrt", design = "~ cell + dex"),
      list(dim = dim(d$tab), provided_rows = utils::head(d$tab, 10), rows_complete = FALSE))
}
# A complete, small real-data slice controls the input-information difference.
slice <- d$tab[order(d$tab$padj, na.last = TRUE)[1:120], ]
sig <- !is.na(slice$padj) & slice$padj < .05 & abs(slice$log2FoldChange) > 1
add("complete_slice120", slice,
    list(n_features = 120, n_significant = sum(sig), n_up = sum(sig & slice$log2FoldChange > 0),
         n_down = sum(sig & slice$log2FoldChange < 0), n_na_padj = sum(is.na(slice$padj))),
    list(thresholds = list(padj = .05, lfc = 1)), list(provided_rows = slice, rows_complete = TRUE))
add("reactome_ora", d$ora,
    list(n_terms = nrow(d$ora), n_significant = sum(d$ora$p.adjust < .05), enrichment_method = "ORA"),
    list(analysis_type = "enrichment_ora", species = "Homo sapiens", data_dependencies = "airway_lfc1"),
    list(dim = dim(d$ora), provided_rows = utils::head(d$ora[c("ID", "Description", "GeneRatio", "Count", "p.adjust")], 10), rows_complete = FALSE))
ve <- d$fit$sdev^2 / sum(d$fit$sdev^2)
add("airway_pca", d$fit,
    list(n_observations = nrow(d$fit$x), n_variables = nrow(d$fit$rotation),
         "variance_explained.1" = ve[1], "variance_explained.2" = ve[2]),
    raw = list(sdev = d$fit$sdev, observations = nrow(d$fit$x), variables = nrow(d$fit$rotation)))
add("pbmc3k_sce", d$sce,
    list(n_cells = ncol(d$sce), n_features = nrow(d$sce), n_samples = 1),
    list(sample_col = "sample_id", species = "Homo sapiens", tissue = "PBMC"),
    list(dim = dim(d$sce), assays = "counts", n_distinct_samples = 1))
write_json(lapply(cases, function(c) c$expected), "research/results/reference_facts.json")
methods <- c("direct_bounded", "facts_only", "facts_evidence")
tasks <- expand.grid(case = names(cases), method = methods, replicate = 1:3, stringsAsFactors = FALSE)
common <- paste(
  "Return ONLY JSON in simplified Chinese. Keys data_facts, statistical_meaning, biological_interpretation,",
  "uncertainty, cannot_conclude, learning_questions must be arrays of strings; evidence_used an array of supplied evidence IDs;",
  "claims an array of {id, text, fact, value, evidence}. For every requested fact return a scalar claim with that exact fact path.",
  "If a requested value cannot be determined from the input, value must be null; do not invent a number.",
  "Array paths such as variance_explained.1 use 1-based indices. Counts and PCA proportions are not signed biological effects.",
  "Keep each section to at most 3 short sentences; the claims must fit. Preserve all provided digits in numeric claim values.")
run <- function(i) {
  t <- tasks[i, ]; c <- cases[[t$case]]
  prefix <- file.path("research/results/model", paste(t$case, t$method, t$replicate, sep = "__"))
  result_file <- paste0(prefix, ".json")
  if (file.exists(result_file)) {
    cached <- jsonlite::read_json(result_file, simplifyVector = FALSE)
    ex <- bio_explain(c$context, use_llm = FALSE, evidence = if (t$method == "facts_evidence") evidence else NULL)
    ex$llm <- cached$parsed
    cached$validation <- bio_validate_explanation(ex)$validation
    cached$validation_rechecked_utc <- format(Sys.time(), tz = "UTC", usetz = TRUE)
    write_json(cached, result_file)
    return(cached)
  }
  payload <- bio_context_payload(c$context, max_top = 10)
  if (t$method == "direct_bounded") {
    system <- paste("You interpret bioinformatics R output. Compute requested values only if the provided data are complete.", common)
    user <- paste("Study metadata and thresholds:", j(c$context$metadata), j(c$context$provenance$thresholds),
                  "R output:", j(c$raw), "Requested fact paths:", j(names(c$expected)))
  } else {
    system <- paste(BioExplainR:::.llm_system_prompt("zh", "beginner"), common)
    ev <- if (t$method == "facts_evidence") evidence else NULL
    user <- paste(BioExplainR:::.llm_user_prompt(payload, ev), "Requested fact paths:", j(names(c$expected)))
  }
  write_json(list(system = system, user = user), paste0(prefix, "__prompt.json"))
  response <- tryCatch(bio_llm_chat(cfg, system, user), error = function(e) list(error = bio_redact(conditionMessage(e))))
  parsed <- if (is.null(response$error)) BioExplainR:::.parse_model_json(response$text) else NULL
  ex <- bio_explain(c$context, use_llm = FALSE, evidence = if (t$method == "facts_evidence") evidence else NULL)
  ex$llm <- parsed
  checked <- bio_validate_explanation(ex)
  claims <- parsed$claims
  if (is.data.frame(claims)) claims <- lapply(seq_len(nrow(claims)), function(k) as.list(claims[k, ]))
  scores <- lapply(names(c$expected), function(path) {
    hit <- Filter(function(cl) is.list(cl) && identical(cl$fact, path), claims)
    value <- if (length(hit) == 1L) hit[[1L]]$value else NULL
    available <- length(value) == 1L && !is.null(value)
    expected <- c$expected[[path]]
    correct <- available && if (is.numeric(expected)) {
      v <- suppressWarnings(as.numeric(value)); is.finite(v) && abs(v - expected) <=
        if (expected == 0) 1e-6 else abs(expected) * 1e-6
    } else identical(as.character(value), as.character(expected))
    list(fact = path, expected = expected, value = value, answered = available, correct = isTRUE(correct))
  })
  output <- list(case = t$case, method = t$method, replicate = t$replicate,
                 requested_model = cfg$model, requested_thinking = "disabled", requested_temperature = 0,
                 created_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
                 response = response, parsed = parsed, validation = checked$validation, scores = scores,
                 prompt_chars = nchar(system) + nchar(user))
  write_json(output, result_file)
  cat(t$case, t$method, t$replicate, if (is.null(response$error)) "ok" else "failed", "\n")
  output
}
results <- parallel::mclapply(seq_len(nrow(tasks)), run, mc.cores = 3, mc.preschedule = FALSE)
stopifnot(all(vapply(results, is.list, logical(1))))
rows <- do.call(rbind, lapply(results, function(r) do.call(rbind, lapply(r$scores, function(s)
  data.frame(case = r$case, method = r$method, replicate = r$replicate, fact = s$fact,
             expected = as.character(s$expected), value = if (length(s$value)) as.character(s$value) else NA_character_,
             answered = s$answered, correct = s$correct, stringsAsFactors = FALSE)))))
utils::write.csv(rows, "research/results/fact_scores.csv", row.names = FALSE)
calls <- do.call(rbind, lapply(results, function(r) data.frame(
  case = r$case, method = r$method, replicate = r$replicate,
  success = is.null(r$response$error), structured = !is.null(r$parsed),
  model_reported = r$response$model %||% NA_character_, elapsed_sec = r$response$elapsed_sec %||% NA_real_,
  prompt_chars = r$prompt_chars, prompt_tokens = r$response$usage$prompt_tokens %||% NA_real_,
  completion_tokens = r$response$usage$completion_tokens %||% NA_real_,
  stop_reason = r$response$stop_reason %||% NA_character_,
  validation = r$validation$status, citations = length(unlist(r$parsed$evidence_used)),
  unknown_citations = length(setdiff(as.character(unlist(r$parsed$evidence_used)),
                                    if (r$method == "facts_evidence") vapply(evidence, function(e) e$id, "") else character())),
  stringsAsFactors = FALSE)))
utils::write.csv(calls, "research/results/model_calls.csv", row.names = FALSE)
summary <- do.call(rbind, lapply(methods, function(m) {
  z <- rows[rows$method == m, ]; cc <- calls[calls$method == m, ]
  data.frame(method = m, correct = sum(z$correct), expected = nrow(z),
             accuracy = mean(z$correct), coverage = mean(z$answered),
             answered_accuracy = if (sum(z$answered)) sum(z$correct) / sum(z$answered) else NA_real_,
             api_success = sum(cc$success), calls = nrow(cc), structured = sum(cc$structured),
             median_elapsed_sec = stats::median(cc$elapsed_sec, na.rm = TRUE),
             prompt_tokens = sum(cc$prompt_tokens, na.rm = TRUE), completion_tokens = sum(cc$completion_tokens, na.rm = TRUE))
}))
utils::write.csv(summary, "research/results/ablation_summary.csv", row.names = FALSE)

# A paired verification ablation reuses identical genuine model responses.
# Controlled mutations measure error detection, not model hallucination rates.
mutations <- list()
full <- Filter(function(r) r$method == "facts_evidence" && !is.null(r$parsed), results)
for (r in full) {
  c <- cases[[r$case]]; ex <- bio_explain(c$context, use_llm = FALSE, evidence = evidence); ex$llm <- r$parsed
  numeric_path <- names(c$expected)[vapply(c$expected, is.numeric, logical(1))][1]
  mutants <- list(
    wrong_number = list(list(fact = numeric_path, value = c$expected[[numeric_path]] + 1)),
    unknown_path = list(list(fact = "invented_statistic", value = 1)),
    vector_value = list(list(fact = numeric_path, value = c(1, 2))),
    fabricated_citation = list(list(fact = numeric_path, value = c$expected[[numeric_path]], evidence = "fabricated-source")),
    reference_only = list(list(fact = numeric_path)))
  for (name in names(mutants)) {
    status <- bio_validate_explanation(ex, claims = mutants[[name]])$validation$status
    mutations[[length(mutations) + 1L]] <- data.frame(case = r$case, replicate = r$replicate, mutation = name,
                                                    with_validator = status, without_validator = "unchecked")
  }
}
utils::write.csv(do.call(rbind, mutations), "research/results/validation_ablation.csv", row.names = FALSE)

# Test the public explanation API, including live evidence and model metadata.
live_file <- "research/results/deepseek_explanation.json"
if (file.exists(live_file)) {
  old <- jsonlite::read_json(live_file, simplifyVector = FALSE)
  live <- bio_explain(d$res, use_llm = FALSE, evidence = evidence,
                      thresholds = list(padj = .05, lfc = 1), species = "Homo sapiens",
                      contrast = "dexamethasone trt vs untrt", design = "~ cell + dex")
  live$llm <- old$llm; live$llm_meta <- old$llm_meta
  live$verification <- old$verification; live$created <- old$created
  live <- bio_validate_explanation(live)
} else live <- bio_explain(d$res, config = cfg, use_llm = TRUE, evidence = evidence,
                           thresholds = list(padj = .05, lfc = 1), species = "Homo sapiens",
                           contrast = "dexamethasone trt vs untrt", design = "~ cell + dex")
write_json(live, "research/results/deepseek_explanation.json")
bio_report(live, file = "research/results/deepseek_report.html", config = cfg)
write_json(list(date = format(Sys.time(), tz = "UTC", usetz = TRUE), model = cfg$model,
                 base_url = cfg$base_url, protocol = cfg$protocol, replicates = 3, cases = names(cases),
                 methods = methods, thinking = "disabled", temperature = 0, summary = summary),
           "research/results/experiment_manifest.json")
print(summary)
