# Project-level dependency and result integration.

.project_dependencies <- function(items, dependencies) {
  nodes <- names(items)
  edges <- data.frame(from = character(), to = character(), stringsAsFactors = FALSE)
  for (name in nodes) {
    item <- items[[name]]
    ctx <- if (inherits(item, "bio_explanation")) item$context else if (inherits(item, "bio_context")) item else NULL
    parents <- unique(c(ctx$metadata$data_dependencies, dependencies[[name]]))
    if (length(parents)) {
      missing <- setdiff(parents, nodes)
      if (length(missing)) stop("Unknown dependencies for '", name, "': ", paste(missing, collapse = ", "), call. = FALSE)
      edges <- rbind(edges, data.frame(from = parents, to = name, stringsAsFactors = FALSE))
    }
  }
  if (any(edges$from == edges$to)) stop("A result cannot depend on itself.", call. = FALSE)
  # Kahn's algorithm also orders the report from upstream to downstream.
  remaining <- nodes
  order <- character()
  while (length(remaining)) {
    ready <- remaining[!remaining %in% edges$to[edges$from %in% remaining]]
    if (!length(ready)) stop("Result dependencies contain a cycle.", call. = FALSE)
    order <- c(order, ready)
    remaining <- setdiff(remaining, ready)
  }
  list(edges = unique(edges), order = order)
}

.project_summary <- function(items) {
  rows <- lapply(names(items), function(name) {
    item <- items[[name]]
    ctx <- if (inherits(item, "bio_explanation")) item$context else if (inherits(item, "bio_context")) item else NULL
    data.frame(
      name = name,
      type = if (!is.null(ctx)) ctx$analysis_type else class(item)[1],
      source = if (!is.null(ctx)) paste(ctx$source_package, collapse = "/") else "runtime",
      source_status = if (!is.null(ctx)) ctx$source_status else "recorded",
      validation = if (inherits(item, "bio_explanation")) item$validation$status %||% "unverified"
                   else if (inherits(item, "bio_validation")) item$status else "not_applicable",
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

.project_consistency <- function(items) {
  contexts <- lapply(items, function(item) {
    if (inherits(item, "bio_explanation")) item$context else if (inherits(item, "bio_context")) item else NULL
  })
  findings <- data.frame(check = character(), status = character(), detail = character(), stringsAsFactors = FALSE)
  for (field in c("species", "tissue", "contrast")) {
    values <- unique(unlist(lapply(contexts, function(ctx) ctx$metadata[[field]]), use.names = FALSE))
    values <- values[!is.na(values) & nzchar(values)]
    findings <- rbind(findings, data.frame(
      check = field,
      status = if (!length(values)) "unknown" else if (length(values) == 1) "consistent" else "review_needed",
      detail = if (!length(values)) "No recorded value" else paste(values, collapse = " | "),
      stringsAsFactors = FALSE
    ))
  }
  findings
}

#' Organise results into a traceable analysis project
#'
#' Converts raw analysis objects to local explanations and retains only their
#' compact contexts. Named dependency edges distinguish derived results from
#' independent evidence. Cycles and unknown dependencies are rejected.
#'
#' @param results Named list of raw results, contexts, explanations, records,
#'   diagnoses or fix validations.
#' @param title Project title.
#' @param dependencies Named list: each result name maps to its upstream names.
#' @param metadata Named list of project study information. Metadata is retained
#'   and may be sent to a model only through explicit project explanation.
#' @param sample_map Optional explicit cross-modality sample map.
#' @param relations Optional claim/evidence or cross-result relation table.
#'   Tables with the direction contract columns are checked automatically by
#'   \code{\link{bio_validate_project_relations}}.
#' @return A \code{bio_project} with compact items, dependency edges, an ordered
#'   summary and cross-result consistency findings.
#' @export
#' @examples
#' deg <- data.frame(log2FoldChange = c(2, -2), padj = c(0.01, 0.02))
#' enr <- data.frame(ID = "GO:0006954", Count = 2, p.adjust = 0.01)
#' project <- bio_project(list(deg = deg, enrichment = enr),
#'                        dependencies = list(enrichment = "deg"))
#' project
bio_project <- function(results, title = "BioExplainR project", dependencies = list(), metadata = list(),
                        sample_map = NULL, relations = NULL) {
  if (!is.list(results) || !length(results) || is.null(names(results)) ||
      anyNA(names(results)) || any(!nzchar(names(results))) || anyDuplicated(names(results))) {
    stop("results must be a non-empty, uniquely named list.", call. = FALSE)
  }
  if (!is.list(dependencies) || !is.list(metadata)) stop("dependencies and metadata must be lists.", call. = FALSE)
  if (length(setdiff(names(dependencies), names(results)))) stop("Unknown result names in dependencies.", call. = FALSE)
  items <- lapply(results, function(x) {
    if (inherits(x, c("bio_explanation", "bio_context", "bio_record", "bio_error_diagnosis",
                      "bio_fix_suggestions", "bio_validation", "bio_evidence"))) {
      if (inherits(x, "bio_record")) x["value"] <- list(NULL)
      x
    } else bio_explain(x, use_llm = FALSE)
  })
  graph <- .project_dependencies(items, dependencies)
  items <- items[graph$order]
  alignment <- if (is.null(sample_map)) NULL else bio_validate_sample_map(sample_map)
  project <- structure(list(title = title, items = items, dependencies = graph$edges,
                  summary = .project_summary(items), consistency = .project_consistency(items),
                  metadata = metadata, sample_map = alignment, relations = relations,
                  created = .now(), version = .this_version(),
                   interpretation = NULL), class = "bio_project")
  if (is.data.frame(relations) && all(c("from_fact", "to_fact", "expected") %in% names(relations)))
    project$relation_validation <- bio_validate_project_relations(project)
  project
}

#' Explain a project with recorded dependency relationships
#'
#' Local integration reports the result chain and context inconsistencies.
#' Optional model integration sees only bounded result summaries and the
#' dependency graph. The integrated model prose is explicitly unverified.
#'
#' @param project A \code{bio_project}, or a named list passed to
#'   \code{\link{bio_project}}.
#' @param config A model configuration.
#' @param use_llm Whether to request an integrated model explanation. Defaults
#'   to \code{FALSE}; this function never silently activates a paid model.
#' @param max_chars Total prompt budget in characters.
#' @param language \code{"en"} (default) or \code{"zh"}: language of the local
#'   interpretation and of the model prompt. \code{NULL} uses
#'   \code{config$language}.
#' @return The project with an \code{interpretation} field.
#' @export
bio_explain_project <- function(project, config = bio_get_config(), use_llm = FALSE, max_chars = 24000,
                                language = NULL) {
  language <- .resolve_language(language, config)
  .local_language(language)
  if (!inherits(project, "bio_project")) project <- bio_project(project)
  edges <- project$dependencies
  local <- c(
    paste0("The project contains " %L% "\u9879\u76ee\u5305\u542b ", nrow(project$summary), " results and " %L% " \u4e2a\u7ed3\u679c\uff0c", nrow(edges), " recorded data dependencies." %L% " \u6761\u8bb0\u5f55\u7684\u6570\u636e\u4f9d\u8d56\u5173\u7cfb\u3002"),
    if (nrow(edges)) paste0(edges$to, " is derived from " %L% " \u6d3e\u751f\u81ea ", edges$from, "; a derived result is not an independent validation of the upstream result." %L% "\uff1b\u6d3e\u751f\u7ed3\u679c\u4e0d\u6784\u6210\u4e0a\u6e38\u7ed3\u679c\u7684\u72ec\u7acb\u9a8c\u8bc1\u3002"),
    if (any(project$consistency$status == "review_needed"))
      "Several recorded values exist for species, tissue or comparison; confirm that these results are suitable for joint interpretation." %L%
        "\u7269\u79cd\u3001\u7ec4\u7ec7\u6216\u6bd4\u8f83\u65b9\u5411\u5b58\u5728\u591a\u4e2a\u8bb0\u5f55\u503c\uff0c\u5e94\u786e\u8ba4\u8fd9\u4e9b\u7ed3\u679c\u662f\u5426\u9002\u5408\u8054\u5408\u89e3\u91ca\u3002",
    "Agreement in direction across analyses only yields a biological hypothesis to be tested; it cannot automatically establish causality." %L%
      "\u4e0d\u540c\u5206\u6790\u7ed3\u679c\u65b9\u5411\u4e00\u81f4\u53ea\u80fd\u5f62\u6210\u5f85\u9a8c\u8bc1\u7684\u751f\u7269\u5b66\u5047\u8bbe\uff0c\u4e0d\u80fd\u81ea\u52a8\u63a8\u51fa\u56e0\u679c\u5173\u7cfb\u3002"
  )
  interpretation <- list(local = local, llm = NULL, status = "local", model = NULL)
  if (isTRUE(use_llm)) {
    if (!bio_llm_available(config)) stop("Project model is not configured.", call. = FALSE)
    contexts <- lapply(project$items, function(x) {
      ctx <- if (inherits(x, "bio_explanation")) x$context else if (inherits(x, "bio_context")) x else NULL
      if (!is.null(ctx)) bio_context_payload(ctx, policy = bio_payload_policy(max_top = 5, max_chars = max_chars)) else NULL
    })
    policy <- bio_payload_policy(max_chars = max_chars)
    payload <- .payload_sanitize(list(study = .payload_metadata(project$metadata, policy), results = contexts,
                                      dependencies = edges, consistency = project$consistency,
                                      relation_validation = project$relation_validation), policy)
    prompt <- bio_redact(.json(payload, pretty = TRUE))
    if (nchar(prompt) > max_chars) stop("Project exceeds max_chars; split the project or raise the explicit limit.", call. = FALSE)
    res <- bio_llm_chat(config,
      paste0("Explain this bioinformatics project in ", if (identical(language, "zh")) "simplified Chinese" else "English", ". Use only supplied facts. Distinguish independent from derived evidence, identify conflicts, separate association from causation. Do not invent values or references. Return concise prose."),
      prompt)
    interpretation$llm <- res$text
    interpretation$status <- "model_generated_unverified"
    interpretation$model <- res$model
    interpretation$request_hash <- res$request_hash
    interpretation$request_bytes <- res$request_bytes
    interpretation$response_hash <- res$response_hash
  }
  project$interpretation <- interpretation
  project
}

#' @export
print.bio_project <- function(x, ...) {
  cat("<bio_project> ", x$title, "\n", sep = "")
  print(x$summary, row.names = FALSE)
  if (nrow(x$dependencies)) {
    cat("Dependencies (upstream -> derived):\n")
    print(x$dependencies, row.names = FALSE)
  }
  if (!is.null(x$interpretation)) cat(paste(x$interpretation$local, collapse = "\n"), "\n")
  invisible(x)
}
