# Reproducible software and educational evaluation.

#' Run a fixed set of interpretation benchmark cases
#'
#' Cases use named reference facts computed or checked independently. This
#' function evaluates actual outputs rather than asking the model to rate
#' itself. It can compare local, direct-model and evidence-assisted methods by
#' supplying different named functions. Live calls occur only inside methods
#' explicitly supplied by the caller.
#'
#' @param cases Named list. Each case has \code{input}, \code{expected} (named
#'   list of fact paths and expected values), and optional \code{args} passed
#'   to each method.
#' @param methods Named list of functions accepting an object and \code{...}.
#' @param tolerance Numeric comparison tolerance.
#' @return A \code{bio_benchmark} with per-fact results, elapsed time, errors
#'   and method summary. Accuracy counts checked facts only.
#' @export
bio_benchmark <- function(cases, methods = list(local = function(x, ...) bio_explain(x, use_llm = FALSE, ...)),
                          tolerance = 1e-8) {
  if (!is.list(cases) || !length(cases) || is.null(names(cases)) || anyDuplicated(names(cases))) stop("cases must be a named list.", call. = FALSE)
  if (!is.list(methods) || !length(methods) || is.null(names(methods)) ||
      !all(vapply(methods, is.function, logical(1)))) stop("methods must be a named list of functions.", call. = FALSE)
  rows <- list()
  get_fact <- function(facts, path) {
    parts <- strsplit(path, ".", fixed = TRUE)[[1]]
    if (length(parts) && parts[1] == "facts") parts <- parts[-1]
    value <- facts
    for (part in parts) {
      if (is.null(value) || !is.list(value) || !part %in% names(value)) return(NULL)
      value <- value[[part]]
    }
    value
  }
  for (case_name in names(cases)) {
    case <- cases[[case_name]]
    if (!is.list(case$expected) || !length(case$expected) || is.null(names(case$expected))) {
      stop("Case '", case_name, "' must supply named expected facts.", call. = FALSE)
    }
    for (method in names(methods)) {
      started <- Sys.time()
      output <- tryCatch(do.call(methods[[method]], c(list(case$input), case$args %||% list())), error = identity)
      elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
      error <- if (inherits(output, "error")) bio_redact(conditionMessage(output)) else NA_character_
      ctx <- if (inherits(output, "bio_explanation")) output$context else if (inherits(output, "bio_context")) output else NULL
      facts <- ctx$facts %||% if (is.list(output) && !inherits(output, "condition")) output$facts else NULL
      for (path in names(case$expected)) {
        actual <- get_fact(facts, path)
        expected <- case$expected[[path]]
        ok <- !is.null(actual) && isTRUE(all.equal(actual, expected, tolerance = tolerance, check.attributes = FALSE))
        rows[[length(rows) + 1L]] <- data.frame(case = case_name, method = method, fact = path,
          expected = as.character(.json(expected)), actual = as.character(.json(actual)), passed = ok,
          elapsed_sec = elapsed, error = error, stringsAsFactors = FALSE)
      }
    }
  }
  findings <- do.call(rbind, rows)
  summary <- do.call(rbind, lapply(names(methods), function(method) {
    d <- findings[findings$method == method, , drop = FALSE]
    runs <- unique(d[c("case", "elapsed_sec", "error")])
    data.frame(method = method, n_cases = nrow(runs), checked_facts = nrow(d), passed = sum(d$passed),
                accuracy = mean(d$passed), failed_runs = sum(!is.na(runs$error)),
                elapsed_sec = sum(runs$elapsed_sec), stringsAsFactors = FALSE)
  }))
  structure(list(findings = findings, summary = summary, created = .now(), session = .session_versions()), class = "bio_benchmark")
}

#' Compare pre/post learning scores between two study groups
#'
#' Computes within-participant change, group summaries, Welch confidence
#' interval for the between-group change difference and Hedges' g. Participant
#' IDs are used to validate uniqueness and are omitted from returned data.
#' This is an analysis tool, not evidence that BioExplainR improves learning.
#'
#' @param data Data frame of actual study observations.
#' @param id,group,pre,post Column names. Exactly two groups are required.
#' @param delayed,transfer Optional score columns for additional endpoints.
#' @param reference Reference group label; difference is other minus reference.
#' @param conf_level Confidence level.
#' @return A \code{bio_learning_evaluation}. Missing outcomes are reported and
#'   omitted per endpoint, without imputing participant scores.
#' @export
bio_evaluate_learning <- function(data, id = "participant", group = "group", pre = "pre", post = "post",
                                  delayed = NULL, transfer = NULL, reference = NULL, conf_level = 0.95) {
  required <- c(id, group, pre, post, delayed, transfer)
  if (!is.data.frame(data) || !all(required %in% names(data))) stop("Required study columns are missing.", call. = FALSE)
  if (anyNA(data[[id]]) || anyDuplicated(data[[id]])) stop("Participant IDs must be non-missing and unique.", call. = FALSE)
  groups <- unique(as.character(data[[group]]))
  if (anyNA(groups) || length(groups) != 2) stop("Exactly two non-missing study groups are required.", call. = FALSE)
  reference <- reference %||% groups[1]
  if (!reference %in% groups) stop("reference is not a study group.", call. = FALSE)
  treatment <- setdiff(groups, reference)
  scores <- lapply(c(pre, post, delayed, transfer), function(column) {
    x <- data[[column]]
    if (!is.numeric(x) || any(!is.finite(x) & !is.na(x))) stop("Score column '", column, "' must be numeric and finite.", call. = FALSE)
    x
  })
  names(scores) <- c(pre, post, delayed, transfer)
  endpoints <- list(change = scores[[post]] - scores[[pre]])
  if (!is.null(delayed)) endpoints$delayed_change <- scores[[delayed]] - scores[[pre]]
  if (!is.null(transfer)) endpoints$transfer <- scores[[transfer]]
  labels <- as.character(data[[group]])
  summaries <- list()
  comparisons <- list()
  for (endpoint in names(endpoints)) {
    value <- endpoints[[endpoint]]
    a <- value[labels == treatment & !is.na(value)]
    b <- value[labels == reference & !is.na(value)]
    for (name in c(reference, treatment)) {
      x <- value[labels == name & !is.na(value)]
      summaries[[length(summaries) + 1L]] <- data.frame(endpoint = endpoint, group = name,
        n = length(x), missing = sum(labels == name & is.na(value)),
        mean = if (length(x)) mean(x) else NA_real_, sd = if (length(x) > 1) stats::sd(x) else NA_real_,
        stringsAsFactors = FALSE)
    }
    test <- if (length(a) > 1 && length(b) > 1) tryCatch(stats::t.test(a, b, conf.level = conf_level), error = function(e) NULL) else NULL
    pooled <- if (length(a) > 1 && length(b) > 1) sqrt(((length(a) - 1) * stats::var(a) + (length(b) - 1) * stats::var(b)) / (length(a) + length(b) - 2)) else NA_real_
    g <- if (!is.na(pooled) && pooled > 0) (1 - 3 / (4 * (length(a) + length(b)) - 9)) * (mean(a) - mean(b)) / pooled else NA_real_
    comparisons[[length(comparisons) + 1L]] <- data.frame(endpoint = endpoint, comparison = paste(treatment, "minus", reference),
      difference = if (length(a) && length(b)) mean(a) - mean(b) else NA_real_,
      ci_lower = if (!is.null(test)) test$conf.int[1] else NA_real_, ci_upper = if (!is.null(test)) test$conf.int[2] else NA_real_,
      pvalue = if (!is.null(test)) test$p.value else NA_real_, hedges_g = g,
      status = if (is.null(test)) "insufficient_or_constant_data" else "estimated", stringsAsFactors = FALSE)
  }
  findings <- do.call(rbind, comparisons)
  findings$padj <- stats::p.adjust(findings$pvalue, "BH")
  structure(list(summary = do.call(rbind, summaries), findings = findings, conf_level = conf_level,
    n_participants = nrow(data), note = "Observational score summaries do not establish causality; use a prespecified randomized design and blinded scoring.",
    created = .now()), class = "bio_learning_evaluation")
}

#' @export
print.bio_benchmark <- function(x, ...) {
  cat("<bio_benchmark>\n")
  print(x$summary, row.names = FALSE)
  invisible(x)
}

#' Benchmark explicit candidate fixes
#'
#' Measures runtime success and preservation of caller-specified invariants
#' separately. A passing process with no invariants never counts as semantic
#' success. Candidate expressions are explicitly supplied, not automatically
#' executed model suggestions.
#'
#' @param cases Named list, each with \code{expr}, \code{inputs},
#'   \code{invariants} and optional \code{packages}.
#' @param timeout Per-case process timeout in seconds.
#' @return A \code{bio_fix_benchmark} with per-case results and aggregate rates.
#' @export
bio_benchmark_fixes <- function(cases, timeout = 60) {
  if (!is.list(cases) || !length(cases) || is.null(names(cases)) || anyDuplicated(names(cases))) {
    stop("cases must be a non-empty named list.", call. = FALSE)
  }
  validations <- lapply(names(cases), function(name) {
    case <- cases[[name]]
    if (is.null(case$expr)) stop("Missing expr for case '", name, "'.", call. = FALSE)
    expr <- case$expr
    bio_validate_fix(expr, inputs = case$inputs %||% list(), invariants = case$invariants %||% list(),
                     packages = case$packages %||% character(), timeout = timeout, label = name)
  })
  names(validations) <- names(cases)
  findings <- do.call(rbind, lapply(validations, function(v) {
    data.frame(case = v$label, status = v$status, runtime_ok = v$runtime_ok,
                semantic_checks = nrow(v$invariants), semantic_ok = v$semantically_verified,
                elapsed_sec = v$elapsed_sec, error = v$error %||% NA_character_, stringsAsFactors = FALSE)
  }))
  checked <- findings$semantic_checks > 0
  summary <- data.frame(n_cases = nrow(findings), runtime_success_rate = mean(findings$runtime_ok),
                        semantically_checked_cases = sum(checked),
                        semantic_success_rate = if (any(checked)) mean(findings$semantic_ok[checked]) else NA_real_,
                        unverified_cases = sum(!checked))
  structure(list(findings = findings, summary = summary, validations = validations, created = .now()), class = "bio_fix_benchmark")
}

#' Summarise independent expert ratings
#'
#' Validates rubric score ranges and summarises each item/dimension across
#' independent raters. Agreement is the proportion of multi-rater items for
#' which all raters gave exactly the same score, not a reliability coefficient.
#'
#' @param ratings Data frame containing \code{item}, \code{rater},
#'   \code{dimension}, \code{score}. Rater identifiers are omitted from results.
#' @param rubric Data frame returned by \code{bio_review_rubric()}.
#' @return A \code{bio_expert_evaluation} with summaries and agreement.
#' @export
bio_evaluate_experts <- function(ratings, rubric = bio_review_rubric()) {
  if (!is.data.frame(ratings) || !all(c("item", "rater", "dimension", "score") %in% names(ratings))) {
    stop("ratings requires item, rater, dimension and score columns.", call. = FALSE)
  }
  if (!nrow(ratings) || anyNA(ratings[c("item", "rater", "dimension")])) stop("Rating identifiers cannot be missing.", call. = FALSE)
  index <- match(ratings$dimension, rubric$dimension)
  if (anyNA(index)) stop("Unknown rubric dimensions.", call. = FALSE)
  if (!is.numeric(ratings$score) || anyNA(ratings$score) || any(!is.finite(ratings$score)) ||
      any(ratings$score < rubric$minimum[index] | ratings$score > rubric$maximum[index])) {
    stop("Ratings fall outside the rubric score range.", call. = FALSE)
  }
  if (any(duplicated(ratings[c("item", "rater", "dimension")]))) stop("Duplicate ratings for the same item/rater/dimension.", call. = FALSE)
  combinations <- unique(ratings[c("item", "dimension")])
  findings <- do.call(rbind, lapply(seq_len(nrow(combinations)), function(i) {
    combination <- combinations[i, ]
    values <- ratings$score[ratings$item == combination$item & ratings$dimension == combination$dimension]
    data.frame(item = combination$item, dimension = combination$dimension, n_raters = length(values),
                mean = mean(values), sd = if (length(values) > 1) stats::sd(values) else NA_real_,
                unanimous = if (length(values) > 1) length(unique(values)) == 1 else NA,
                stringsAsFactors = FALSE)
  }))
  summary <- do.call(rbind, lapply(unique(findings$dimension), function(dimension) {
    d <- findings[findings$dimension == dimension, ]
    data.frame(dimension = dimension, n_items = nrow(d), mean = mean(d$mean),
                multi_rater_items = sum(!is.na(d$unanimous)),
                exact_agreement = if (all(is.na(d$unanimous))) NA_real_ else mean(d$unanimous, na.rm = TRUE),
                stringsAsFactors = FALSE)
  }))
  structure(list(findings = findings, summary = summary, created = .now()), class = "bio_expert_evaluation")
}

#' @export
print.bio_fix_benchmark <- function(x, ...) {
  cat("<bio_fix_benchmark>\n")
  print(x$summary, row.names = FALSE)
  invisible(x)
}

#' @export
print.bio_expert_evaluation <- function(x, ...) {
  cat("<bio_expert_evaluation>\n")
  print(x$summary, row.names = FALSE)
  invisible(x)
}

#' Plan a two-arm learning study and assign participants
#'
#' The power calculation assumes an independent, equal-size two-arm t-test of
#' change scores. The assumed effect size and variability must come from a pilot
#' or justified external evidence, not the package's synthetic examples.
#'
#' @param effect Standardized between-group difference (Cohen's d).
#' @param power Target statistical power.
#' @param alpha Two-sided significance level.
#' @param attrition Expected fraction lost to follow-up.
#' @return One-row planning data frame with assumptions and sample counts.
#' @export
bio_plan_learning_study <- function(effect, power = 0.8, alpha = 0.05, attrition = 0) {
  if (!is.numeric(effect) || length(effect) != 1 || !is.finite(effect) || effect <= 0) stop("effect must be positive.", call. = FALSE)
  for (name in c("power", "alpha")) {
    value <- get(name)
    if (!is.numeric(value) || length(value) != 1 || !is.finite(value) || value <= 0 || value >= 1) stop(name, " must be between 0 and 1.", call. = FALSE)
  }
  if (!is.numeric(attrition) || length(attrition) != 1 || !is.finite(attrition) || attrition < 0 || attrition >= 1) stop("attrition must be in [0, 1).", call. = FALSE)
  calculation <- stats::power.t.test(delta = effect, sd = 1, power = power, sig.level = alpha,
                                     type = "two.sample", alternative = "two.sided")
  required <- ceiling(calculation$n)
  planned <- ceiling(required / (1 - attrition))
  data.frame(effect = effect, power = power, alpha = alpha, attrition = attrition,
               required_per_group = required, recruit_per_group = planned, total_recruit = 2 * planned,
               assumptions = "independent equal-size groups; two-sided t-test of change scores", stringsAsFactors = FALSE)
}

#' Reproducible stratified two-arm randomization
#'
#' Returns local participant allocation for experiment administration. Unlike
#' score summaries, this table deliberately includes participant identifiers;
#' keep it separate from blinded outcome review. Allocation is balanced within
#' each stratum up to one participant. Odd remainders are assigned at random.
#'
#' @param participants Character vector of unique non-missing participant IDs.
#' @param strata Vector of baseline strata matching participants; defaults to
#'   one stratum.
#' @param seed Explicit integer seed.
#' @param groups Two distinct study labels.
#' @return Allocation data frame. The caller's random number state is restored.
#' @export
bio_randomize_learning_study <- function(participants, strata = rep("all", length(participants)),
                                         seed = 1, groups = c("control", "tool")) {
  if (!length(participants) || anyNA(participants) || anyDuplicated(participants) || any(!nzchar(as.character(participants)))) stop("participants must be unique non-missing IDs.", call. = FALSE)
  if (length(strata) != length(participants) || anyNA(strata)) stop("strata must match participants and be non-missing.", call. = FALSE)
  if (length(groups) != 2 || anyNA(groups) || anyDuplicated(groups)) stop("groups must contain two distinct labels.", call. = FALSE)
  if (!is.numeric(seed) || length(seed) != 1 || !is.finite(seed)) stop("seed must be a finite number.", call. = FALSE)
  saved <- if (exists(".Random.seed", globalenv(), inherits = FALSE)) get(".Random.seed", globalenv()) else NULL
  on.exit(if (is.null(saved)) {
    if (exists(".Random.seed", globalenv(), inherits = FALSE)) rm(".Random.seed", envir = globalenv())
  } else assign(".Random.seed", saved, globalenv()), add = TRUE)
  set.seed(seed)
  assigned <- character(length(participants))
  for (indices in split(seq_along(participants), strata)) {
    labels <- rep(groups, each = floor(length(indices) / 2))
    if (length(indices) %% 2) labels <- c(labels, sample(groups, 1))
    assigned[indices] <- sample(labels, length(labels))
  }
  data.frame(participant = as.character(participants), stratum = as.character(strata), group = assigned, stringsAsFactors = FALSE)
}

#' @export
print.bio_learning_evaluation <- function(x, ...) {
  cat("<bio_learning_evaluation> ", x$n_participants, " participants\n", sep = "")
  print(x$findings, row.names = FALSE)
  invisible(x)
}
