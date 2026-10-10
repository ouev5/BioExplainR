# Common-task comparison framework for models and code-execution agents.
#
# This script separates the task definition and score calculation from the
# provider.  It can replay saved responses offline, call user-configured
# OpenAI-compatible models, or invoke an explicitly supplied CLI agent.  No
# live provider is contacted unless BIOEXPLAINR_COMMON_TASK_LIVE=1 is set.
# The score is target-fact matching, not a quality or biological correctness
# score for the surrounding prose.
suppressPackageStartupMessages({
  library(BioExplainR)
  library(jsonlite)
})

root <- getwd()
results_dir <- Sys.getenv("BIOEXPLAINR_COMMON_TASK_RESULTS_DIR", file.path(root, "research/results/common_task"))
dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
facts_file <- Sys.getenv("BIOEXPLAINR_COMMON_TASK_FACTS", file.path(root, "research/results/reference_facts.json"))
facts <- read_json(facts_file, simplifyVector = FALSE)
methods <- read_json(file.path(root, "research/common_task_methods.json"), simplifyVector = FALSE)$methods
case_names <- names(facts)

value_at <- function(x, path) {
  if (!is.null(names(x)) && path %in% names(x)) return(x[[path]])
  pieces <- strsplit(path, "\\.", fixed = FALSE)[[1]]
  for (piece in pieces) {
    if (is.null(x)) return(NULL)
    if (grepl("^[0-9]+$", piece)) x <- x[[as.integer(piece)]] else x <- x[[piece]]
  }
  x
}
as_claims <- function(parsed) {
  claims <- parsed$claims %||% list()
  if (is.data.frame(claims)) claims <- lapply(seq_len(nrow(claims)), function(i) as.list(claims[i, ]))
  if (!is.list(claims)) list() else claims
}
score_claims <- function(case, parsed) {
  claims <- as_claims(parsed)
  requested <- names(facts[[case]])
  rows <- lapply(requested, function(path) {
    hit <- Filter(function(x) is.list(x) && identical(as.character(x$fact %||% ""), path), claims)
    value <- if (length(hit) == 1L) hit[[1L]]$value else NULL
    expected <- value_at(facts[[case]], path)
    answered <- !is.null(value) && length(value) == 1L
    correct <- answered && if (is.numeric(expected)) {
      got <- suppressWarnings(as.numeric(value))
      is.finite(got) && abs(got - as.numeric(expected)) <=
        if (as.numeric(expected) == 0) 1e-6 else abs(as.numeric(expected)) * 1e-6
    } else identical(as.character(value), as.character(expected))
    data.frame(case = case, fact = path, value = if (answered) as.character(value) else NA_character_,
               expected = if (length(expected)) as.character(expected) else NA_character_, answered = answered, correct = isTRUE(correct),
               stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}
normalize_claims <- function(value) {
  if (!is.list(value) || is.null(value$claims)) return(value)
  value$claims <- lapply(value$claims, function(claim) {
    if (is.list(claim) && is.null(claim$fact) && !is.null(claim$path)) claim$fact <- claim$path
    if (is.list(claim) && is.null(claim$value) && !is.null(claim$`_value`)) claim$value <- claim$`_value`
    claim
  })
  value
}
make_parsed_from_facts <- function(case) {
  list(claims = lapply(names(facts[[case]]), function(path) {
    list(id = paste0("reference_", path), text = path, fact = path,
         value = value_at(facts[[case]], path), evidence = character())
  }))
}
parse_model_response <- function(text) {
  if (is.null(text) || !nzchar(text)) return(list())
  parsed <- tryCatch(BioExplainR:::.parse_model_json(text), error = function(e) NULL)
  if (is.list(parsed) && !is.null(parsed$claims)) return(normalize_claims(parsed))
  # Some compatible gateways ignore JSON mode or return a fenced JSON object.
  cleaned <- trimws(text)
  cleaned <- sub("^```(?:json)?\\s*", "", cleaned, perl = TRUE)
  cleaned <- sub("\\s*```$", "", cleaned, perl = TRUE)
  parsed <- tryCatch(fromJSON(cleaned, simplifyVector = FALSE), error = function(e) NULL)
  if (is.list(parsed) && !is.null(parsed$claims)) return(normalize_claims(parsed))
  list()
}
prompt_for <- function(case) {
  paste0(
    "Return exactly one JSON object and nothing else: no prose, no markdown fences, and no metadata. ",
    "The object must have exactly one top-level key named claims. claims must be an array containing ",
    "one object for every requested path, in the same order. Each item must have exactly two keys: ",
    "fact (the exact requested path string) and value (one scalar copied from the supplied context). ",
    "Use fact, not path; include all requested paths exactly once; do not return a flat object. ",
    "Copy numeric values exactly from Facts. Never round, truncate, summarize, or re-compute a number. ",
    "For every non-integer decimal, value MUST be a JSON string containing the exact decimal characters ",
    "shown in Facts, preserving every digit and decimal place; do not use scientific notation. ",
    "For integers, return a JSON integer. This string rule is required so decimal precision is not lost ",
    "during JSON generation. ",
    "Example shape: {\"claims\":[{\"fact\":\"n_features\",\"value\":123}]}. ",
    "Do not invent values.\n",
    "Case: ", case, "\nFacts: ", toJSON(facts[[case]], auto_unbox = TRUE, digits = 17),
    "\nRequested paths: ", paste(names(facts[[case]]), collapse = ", ")
  )
}
`%||%` <- function(x, y) if (is.null(x)) y else x
all_scores <- list(); call_rows <- list()
add_result <- function(method, mode, case, parsed, status = "executed", detail = "") {
  score <- score_claims(case, parsed)
  score$method <- method; score$mode <- mode; score$status <- status
  all_scores[[length(all_scores) + 1L]] <<- score
  call_rows[[length(call_rows) + 1L]] <<- data.frame(method = method, mode = mode, case = case,
    status = status, detail = detail, stringsAsFactors = FALSE)
}

for (spec in methods) {
  mode <- spec$mode; name <- spec$name
  if (identical(mode, "deterministic_reference")) {
    for (case in case_names) add_result(name, mode, case, make_parsed_from_facts(case), "executed", "R reference")
  } else if (identical(mode, "saved_response")) {
    for (case in case_names) {
      path <- file.path(root, "research/results/model",
                        paste0(case, "__", spec$method %||% "facts_only", "__",
                               spec$replicate %||% 1, ".json"))
      if (!file.exists(path)) {
        add_result(name, mode, case, list(claims = list()), "missing", path)
      } else {
        saved <- read_json(path, simplifyVector = FALSE)
        parsed <- saved$parsed %||% tryCatch(fromJSON(saved$response$text, simplifyVector = FALSE), error = function(e) list())
        add_result(name, mode, case, parsed, "replayed", "saved response")
      }
    }
  } else if (identical(mode, "openai_compatible")) {
    live <- identical(Sys.getenv("BIOEXPLAINR_COMMON_TASK_LIVE", ""), "1")
    configs <- Sys.getenv("BIOEXPLAINR_BENCHMARK_MODELS_JSON", "")
    if (!live || !nzchar(configs)) {
      for (case in case_names) add_result(name, mode, case, list(claims = list()), "not_configured",
                                          "Set BIOEXPLAINR_COMMON_TASK_LIVE=1 and BIOEXPLAINR_BENCHMARK_MODELS_JSON")
    } else {
      model_specs <- fromJSON(configs, simplifyVector = FALSE)
      for (model_spec in model_specs) for (case in case_names) {
        cfg <- bio_config(preset = model_spec$preset %||% "openai_compatible",
                          base_url = model_spec$base_url %||% NULL,
                          endpoint = model_spec$endpoint %||% NULL,
                           api_key_env = model_spec$api_key_env %||% "BIOEXPLAINR_API_KEY",
                           model = model_spec$model, json_mode = isTRUE(model_spec$json_mode %||% TRUE),
                           temperature = model_spec$temperature %||% 0,
                           max_tokens = as.integer(model_spec$max_tokens %||% 800),
                          timeout = 120, max_retries = 1)
        response <- tryCatch(bio_llm_chat(cfg, "You are a benchmark adapter.", prompt_for(case)),
                             error = function(e) list(error = conditionMessage(e)))
         model_label <- gsub("[^A-Za-z0-9_.-]", "_", model_spec$name %||% model_spec$model)
         safe_file <- file.path(results_dir, paste0(gsub("[^A-Za-z0-9_.-]", "_", name),
                                                     "__", model_label, "__", case, ".json"))
        write_json(response, safe_file, pretty = TRUE, auto_unbox = TRUE)
        parsed <- if (is.null(response$error)) parse_model_response(response$text) else list()
        add_result(paste0(name, ":", model_spec$name %||% model_spec$model), mode, case, parsed,
                   if (is.null(response$error) && length(parsed$claims)) "executed" else if (is.null(response$error)) "invalid_response" else "failed",
                   if (is.null(response$error)) paste0("response_chars=", nchar(response$text %||% "")) else response$error)
      }
    }
  } else if (identical(mode, "command_agent")) {
    command_template <- Sys.getenv("BIOEXPLAINR_CODE_AGENT_COMMAND", "")
    live <- identical(Sys.getenv("BIOEXPLAINR_COMMON_TASK_LIVE", ""), "1")
    if (!live || !nzchar(command_template)) {
      for (case in case_names) add_result(name, mode, case, list(claims = list()), "not_configured",
                                           "Set BIOEXPLAINR_COMMON_TASK_LIVE=1 and BIOEXPLAINR_CODE_AGENT_COMMAND")
    } else {
      agent_dir <- file.path(results_dir, "code_agent")
      dir.create(agent_dir, recursive = TRUE, showWarnings = FALSE)
      for (case in case_names) {
      stem <- paste0(gsub("[^A-Za-z0-9_.-]", "_", name), "__", case)
      input <- file.path(agent_dir, paste0(stem, ".input.json"))
      output <- file.path(agent_dir, paste0(stem, ".output.json"))
      stdout <- file.path(agent_dir, paste0(stem, ".stdout.txt"))
      stderr <- file.path(agent_dir, paste0(stem, ".stderr.txt"))
      unlink(c(output, stdout, stderr))
      write_json(list(case = case, facts = facts[[case]], prompt = prompt_for(case)), input, auto_unbox = TRUE)
      command <- gsub("%INPUT%", shQuote(input), command_template, fixed = TRUE)
      command <- gsub("%OUTPUT%", shQuote(output), command, fixed = TRUE)
      status <- system(paste(command, ">", shQuote(stdout), "2>", shQuote(stderr)))
      parsed <- list()
      parse_error <- ""
      if (identical(status, 0L) && file.exists(output)) {
        parsed <- tryCatch(read_json(output, simplifyVector = FALSE), error = function(e) {
          parse_error <<- conditionMessage(e)
          list()
        })
        parsed <- normalize_claims(parsed)
      } else if (identical(status, 0L)) {
        parse_error <- "agent exited successfully but did not create output JSON"
      }
      has_claims <- is.list(parsed) && !is.null(parsed$claims) && length(parsed$claims) > 0L
      result_status <- if (!identical(status, 0L)) "failed" else if (has_claims) "executed" else "invalid_response"
      detail <- paste0("exit_status=", status,
                       "; claims=", if (has_claims) length(parsed$claims) else 0L,
                       if (nzchar(parse_error)) paste0("; parse_error=", parse_error) else "",
                       "; input=", input, "; output=", output,
                       "; stdout=", stdout, "; stderr=", stderr)
      add_result(name, mode, case, parsed, result_status, detail)
      }
    }
  }
}

scores <- do.call(rbind, all_scores)
calls <- do.call(rbind, call_rows)
summary <- do.call(rbind, lapply(split(scores, scores$method), function(x) {
  data.frame(method = x$method[1], mode = x$mode[1], status = paste(sort(unique(x$status)), collapse = ";"),
             expected = nrow(x), correct = sum(x$correct), answered = sum(x$answered),
             accuracy = if (nrow(x)) mean(x$correct) else NA_real_,
             coverage = if (nrow(x)) mean(x$answered) else NA_real_, stringsAsFactors = FALSE)
}))
write.csv(scores, file.path(results_dir, "common_task_fact_scores.csv"), row.names = FALSE)
write.csv(calls, file.path(results_dir, "common_task_calls.csv"), row.names = FALSE)
write.csv(summary, file.path(results_dir, "common_task_summary.csv"), row.names = FALSE)
public_model_specs <- tryCatch({
  configured <- Sys.getenv("BIOEXPLAINR_BENCHMARK_MODELS_JSON", "")
  if (!nzchar(configured)) list() else {
    lapply(fromJSON(configured, simplifyVector = FALSE), function(spec) {
      list(name = spec$name %||% spec$model %||% NA_character_,
           model = spec$model %||% NA_character_,
           base_url = spec$base_url %||% NA_character_,
           endpoint = spec$endpoint %||% NA_character_,
           json_mode = isTRUE(spec$json_mode %||% FALSE),
           temperature = spec$temperature %||% 0,
           max_tokens = as.integer(spec$max_tokens %||% 800))
    })
  }
}, error = function(e) list())
write_json(list(date_utc = format(Sys.time(), tz = "UTC", usetz = TRUE), live = identical(Sys.getenv("BIOEXPLAINR_COMMON_TASK_LIVE", ""), "1"),
                  models_env_present = nzchar(Sys.getenv("BIOEXPLAINR_BENCHMARK_MODELS_JSON", "")),
                  code_agent_env_present = nzchar(Sys.getenv("BIOEXPLAINR_CODE_AGENT_COMMAND", "")), methods = methods,
                  model_specs_public = public_model_specs, facts_file = normalizePath(facts_file, mustWork = FALSE),
                  n_cases = length(case_names), n_facts = sum(vapply(facts, length, integer(1))), cases = case_names),
            file.path(results_dir, "common_task_manifest.json"), pretty = TRUE, auto_unbox = TRUE)
print(summary)
