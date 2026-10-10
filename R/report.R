# Reports ------------------------------------------------------------------------------

.b_h <- function(text, level = 2) list(type = "h", level = level, text = text)
.b_p <- function(text) list(type = "p", text = paste(text, collapse = " "))
.b_label <- function(text) list(type = "label", text = paste(text, collapse = " "))
.b_ul <- function(items) list(type = "ul", items = as.character(unlist(items)))
.b_code <- function(text) list(type = "code", text = paste(text, collapse = "\n"))
.b_table <- function(df, max_rows = 20) list(type = "table", df = utils::head(as.data.frame(df, stringsAsFactors = FALSE), max_rows))
.b_kv <- function(lst) {
  lst <- lst[!vapply(lst, is.null, logical(1))]
  if (!length(lst)) return(NULL)
  vals <- vapply(lst, function(v) {
    if (is.list(v)) v <- unlist(v)
    paste(.truncate_chr(format(v, trim = TRUE, digits = 4), 120), collapse = ", ")
  }, "")
  .b_table(data.frame(item = names(lst), value = vals, stringsAsFactors = FALSE), max_rows = 200)
}

.html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub("\"", "&quot;", x, fixed = TRUE)
  gsub("'", "&#39;", x, fixed = TRUE)
}

.md_cell <- function(x) {
  x <- gsub("\\|", "\\\\|", as.character(x))
  gsub("\n", " ", x)
}

.html_lang <- function(language) if (identical(language, "zh")) "zh-CN" else "en"

.render_md <- function(blocks, language = .current_language()) {
  .local_language(language)
  out <- character()
  for (b in blocks) {
    if (is.null(b)) next
    out <- c(out, switch(b$type,
      h = c(paste(strrep("#", b$level), b$text), ""),
      p = c(b$text, ""),
      label = c(paste0("**", b$text, "**"), ""),
      ul = c(if (length(b$items)) paste0("- ", gsub("\n", " ", b$items)) else paste("- ", "(none)" %L% "\uff08\u65e0\uff09", sep = ""), ""),
      code = c("```", b$text, "```", ""),
      table = {
        df <- b$df
        if (!nrow(df)) c("(empty table)" %L% "\uff08\u7a7a\u8868\uff09", "") else {
          cells <- lapply(df, function(col) .md_cell(if (is.numeric(col)) .fmt_num(col, 4) else col))
          c(paste0("| ", paste(.md_cell(names(df)), collapse = " | "), " |"),
            paste0("|", paste(rep("---", ncol(df)), collapse = "|"), "|"),
            vapply(seq_len(nrow(df)), function(i) paste0("| ", paste(vapply(cells, `[`, "", i), collapse = " | "), " |"), ""),
            "")
        }
      }))
  }
  paste(out, collapse = "\n")
}

.render_html <- function(blocks, title, language = .current_language()) {
  e <- .html_escape
  .local_language(language)
  body <- character()
  for (b in blocks) {
    if (is.null(b)) next
    body <- c(body, switch(b$type,
      h = sprintf("<h%d>%s</h%d>", b$level, e(b$text), b$level),
      p = sprintf("<p>%s</p>", e(b$text)),
      label = sprintf("<p><strong>%s</strong></p>", e(b$text)),
      ul = paste0("<ul>", paste0("<li>", e(if (length(b$items)) b$items else "(none)" %L% "\uff08\u65e0\uff09"), "</li>", collapse = ""), "</ul>"),
      code = sprintf("<pre><code>%s</code></pre>", e(b$text)),
      table = {
        df <- b$df
        if (!nrow(df)) paste0("<p>", "(empty table)" %L% "\uff08\u7a7a\u8868\uff09", "</p>") else {
          cells <- lapply(df, function(col) if (is.numeric(col)) .fmt_num(col, 4) else as.character(col))
          head <- paste0("<tr>", paste0("<th>", e(names(df)), "</th>", collapse = ""), "</tr>")
          rows <- vapply(seq_len(nrow(df)), function(i)
            paste0("<tr>", paste0("<td>", e(vapply(cells, `[`, "", i)), "</td>", collapse = ""), "</tr>"), "")
          paste0("<table>", head, paste(rows, collapse = ""), "</table>")
        }
      }))
  }
  css <- paste("body{font-family:-apple-system,'Segoe UI','Noto Sans CJK SC','Microsoft YaHei',sans-serif;max-width:960px;margin:2em auto;padding:0 1em;line-height:1.6;color:#222}",
               "table{border-collapse:collapse;margin:.5em 0;font-size:.9em}th,td{border:1px solid #ccc;padding:3px 8px;text-align:left}",
               "th{background:#f3f3f3}pre{background:#f6f8fa;padding:.8em;overflow-x:auto}h1{border-bottom:2px solid #2a6f97}h2{color:#2a6f97}")
  paste0("<!DOCTYPE html>\n<html lang=\"", .html_lang(language), "\"><head><meta charset=\"utf-8\"><title>", e(title),
         "</title><style>", css, "</style></head><body>\n", paste(body, collapse = "\n"), "\n</body></html>\n")
}

.blocks_context <- function(ctx) {
  f <- ctx$facts
  facts_flat <- lapply(f, function(v) if (is.list(v)) .json(v) else v)
  md <- ctx$metadata[setdiff(names(ctx$metadata), "analysis_type_hint")]
  list(
    .b_h("Source and parameters" %L% "\u6765\u6e90\u4e0e\u53c2\u6570", 3),
    .b_kv(list(analysis_type = ctx$analysis_type, source_class = paste(ctx$source_class, collapse = "/"),
               source_package = ctx$source_package, source_status = ctx$source_status, adapter = ctx$adapter,
               thresholds = if (length(ctx$provenance$thresholds)) paste(names(ctx$provenance$thresholds),
                                                                          unlist(ctx$provenance$thresholds), sep = "=", collapse = "; "),
               p_adjust_method = ctx$provenance$p_adjust_method, created = ctx$provenance$created)),
    if (length(md)) .b_h("User-supplied study context" %L% "\u7528\u6237\u63d0\u4f9b\u7684\u7814\u7a76\u80cc\u666f", 3),
    if (length(md)) .b_kv(md),
    .b_h("Deterministic statistical facts" %L% "\u786e\u5b9a\u6027\u7edf\u8ba1\u4e8b\u5b9e", 3),
    .b_kv(facts_flat),
    if (!is.null(ctx$top_features) && nrow(ctx$top_features))
      .b_h(if (.is_zh()) paste0("\u524d ", nrow(ctx$top_features), " \u884c\u6458\u8981") else paste0("Summary of the top ", nrow(ctx$top_features), " rows"), 3),
    if (!is.null(ctx$top_features) && nrow(ctx$top_features)) .b_table(ctx$top_features),
    if (!is.null(ctx$plot_mapping)) .b_h("Plot mapping" %L% "\u56fe\u5f62\u6620\u5c04", 3),
    if (!is.null(ctx$plot_mapping)) .b_code(.json(ctx$plot_mapping, pretty = TRUE))
  )
}

.blocks_explanation <- function(ex, include_llm = TRUE) {
  b <- .blocks_context(ex$context)
  titles <- .section_titles_for(.current_language())
  b <- c(b, list(.b_h("Local explanation (rule template)" %L% "\u672c\u5730\u89e3\u91ca\uff08\u89c4\u5219\u6a21\u677f\uff09", 3)))
  for (n in .section_names) {
    b <- c(b, list(.b_label(titles[[n]]), .b_ul(ex$local[[n]])))
  }
  if (length(ex$local$concepts)) b <- c(b, list(.b_label(titles[["concepts"]]), .b_ul(ex$local$concepts)))
  if (include_llm && !is.null(ex$llm)) {
    m <- ex$llm_meta
    b <- c(b, list(.b_h("Model-generated explanation (numerically unverified)" %L% "\u6a21\u578b\u751f\u6210\u7684\u89e3\u91ca\uff08\u672a\u7ecf\u6570\u503c\u6838\u9a8c\uff09", 3),
                   .b_kv(list(protocol = m$protocol, preset = m$preset, model_requested = m$model_requested,
                              model_reported = m$model_reported, endpoint_host = m$endpoint_host,
                              time = m$time, structured_json = m$structured,
                              unknown_evidence_ids = if (length(m$unknown_evidence_ids)) paste(m$unknown_evidence_ids, collapse = ", ")))))
    for (n in names(ex$llm)) {
      ttl <- if (n %in% names(titles)) titles[[n]] else n
      b <- c(b, list(.b_label(ttl), .b_ul(ex$llm[[n]])))
    }
  } else if (!isTRUE(ex$llm_meta$used)) {
    b <- c(b, list(.b_p(paste0("Model not used: " %L% "\u6a21\u578b\u672a\u4f7f\u7528\uff1a", ex$llm_meta$reason %||% "local mode"))))
  }
  if (length(ex$evidence)) b <- c(b, .blocks_evidence(ex$evidence))
  if (!is.null(ex$claim_ledger)) {
    b <- c(b, list(.b_h("Typed claim ledger" %L% "\u7c7b\u578b\u5316\u58f0\u660e\u53f0\u8d26", 3),
                   .b_table(ex$claim_ledger$claims, max_rows = 200),
                    .b_table(ex$validation$typed_findings %||% data.frame(), max_rows = 200),
                    .b_table(ex$validation$evidence_findings %||% data.frame(), max_rows = 200)))
  }
  if (!is.null(ex$manifest)) b <- c(b, list(.b_h("Runtime manifest" %L% "\u8fd0\u884c\u6e05\u5355", 3), .b_code(.json(ex$manifest, pretty = TRUE))))
  b
}

.blocks_evidence <- function(evs) {
  if (!length(evs)) return(list())
  df <- do.call(rbind, lapply(evs, function(e) data.frame(
    id = e$id, type = e$type, title = e$title %||% "", claim = e$claim %||% "",
    source = e$source %||% "", supplied_by = e$supplied_by %||% "user",
    url = e$url %||% "", version = e$version %||% "", accessed = e$accessed %||% "", stringsAsFactors = FALSE)))
  list(.b_h("Traceable evidence sources" %L% "\u53ef\u8ffd\u6eaf\u8bc1\u636e\u6765\u6e90", 3), .b_table(df, max_rows = 100))
}

.blocks_record <- function(r) {
  b <- list(.b_h("Run record" %L% "\u8fd0\u884c\u8bb0\u5f55", 3),
            .b_kv(list(label = r$label, status = r$status, started = r$started, elapsed_sec = r$elapsed_sec,
                       purpose = r$purpose, value_class = paste(class(r$value), collapse = "/"))),
             .b_code(.code_payload(r$code) %||% ""))
  if (length(r$warnings)) b <- c(b, list(.b_label("Warnings" %L% "\u8b66\u544a"), .b_ul(vapply(r$warnings, function(w) w$message, ""))))
  if (!is.null(r$error)) {
    b <- c(b, list(.b_label("Error" %L% "\u9519\u8bef"), .b_ul(c(r$error$message, paste0("Location: " %L% "\u4f4d\u7f6e\uff1a", .code_payload(r$error$location)))),
                    .b_label("Call stack (outermost first)" %L% "\u8c03\u7528\u6808\uff08\u7531\u5916\u5230\u5185\uff09"), .b_code(paste(vapply(r$error$stack, function(s) .code_payload(s) %||% "", ""), collapse = "\n"))))
  }
  objs <- c(r$objects_created, r$objects_used)
  if (length(objs)) {
    df <- do.call(rbind, lapply(objs, function(o) data.frame(
      name = o$name %||% "", class = paste(o$class, collapse = "/"),
      shape = if (!is.null(o$dim)) paste(o$dim, collapse = " x ") else paste0("length ", o$length %||% NA),
      size = o$size %||% NA_character_, stringsAsFactors = FALSE)))
    b <- c(b, list(.b_label("Object summary (no values)" %L% "\u5bf9\u8c61\u6458\u8981\uff08\u4e0d\u542b\u6570\u503c\uff09"), .b_table(unique(df), max_rows = 60)))
  }
  b
}

.blocks_diagnosis <- function(d) {
  b <- list(.b_h(paste0("Error diagnosis: " %L% "\u9519\u8bef\u8bca\u65ad\uff1a", d$title), 3),
             .b_kv(list(category = d$category, message = d$message, location = .code_payload(d$location), call = .code_payload(d$call))),
            .b_p(d$explanation), .b_p(paste0("Learning tip: " %L% "\u5b66\u4e60\u63d0\u793a\uff1a", d$learning_tip)))
  if (length(d$stack)) b <- c(b, list(.b_code(paste(vapply(d$stack, function(s) .code_payload(s) %||% "", ""), collapse = "\n"))))
  if (!is.null(d$llm)) {
    b <- c(b, list(.b_label(paste0("Model diagnosis (" %L% "\u6a21\u578b\u8bca\u65ad\uff08", d$llm$model, ", unverified)" %L% "\uff0c\u672a\u7ecf\u9a8c\u8bc1\uff09")),
                   .b_code(.json(d$llm$content, pretty = TRUE))))
  }
  b
}

.blocks_fix <- function(s) {
  items <- vapply(s$suggestions, function(z) paste0("[", z$status, "] ", z$text,
                                                    if (!is.null(z$code)) paste0("  Code: " %L% "  \u4ee3\u7801\uff1a", gsub("\n", "; ", z$code)) else ""), "")
  list(.b_h(paste0("Fix suggestions: " %L% "\u4fee\u590d\u5efa\u8bae\uff1a", s$title), 3), .b_ul(items), .b_p(s$note))
}

.blocks_validation <- function(v) {
  b <- list(.b_h("Fix validation (separate R process)" %L% "\u4fee\u590d\u9a8c\u8bc1\uff08\u72ec\u7acb R \u8fdb\u7a0b\uff09", 3),
            .b_kv(list(label = v$label, status = v$status, runtime_ok = v$runtime_ok,
                       semantically_verified = v$semantically_verified, error = v$error,
                       output_class = paste(v$output_shape$class, collapse = "/"),
                       output_dim = if (!is.null(v$output_shape$dim)) paste(v$output_shape$dim, collapse = " x "),
                       elapsed_sec = v$elapsed_sec)),
             .b_code(.code_payload(v$code) %||% ""))
  if (nrow(v$invariants)) b <- c(b, list(.b_table(v$invariants)))
  c(b, list(.b_p(v$note)))
}

.blocks_check <- function(x, title) {
  if (is.null(x)) return(list())
  blocks <- list(.b_h(title, 3), .b_p(paste0("Status: " %L% "\u72b6\u6001\uff1a", x$status %||% "unknown")))
  if (is.data.frame(x$findings)) blocks <- c(blocks, list(.b_table(x$findings, max_rows = 100)))
  blocks
}

.blocks_project <- function(project, include_llm, show_answers) {
  blocks <- list(.b_h("Cross-analysis project summary" %L% "\u8de8\u5206\u6790\u9879\u76ee\u6458\u8981", 3), .b_table(project$summary, max_rows = 100),
                 .b_h("Source consistency check" %L% "\u6765\u6e90\u4e00\u81f4\u6027\u68c0\u67e5", 3), .b_table(project$consistency),
                 .b_h("Data dependencies (upstream -> derived result)" %L% "\u6570\u636e\u4f9d\u8d56\u5173\u7cfb\uff08\u4e0a\u6e38 \u2192 \u6d3e\u751f\u7ed3\u679c\uff09", 3), .b_table(project$dependencies),
                 .b_p("Derived enrichment results or plots share inputs with their upstream results and are not independent validation." %L%
                        "\u6d3e\u751f\u7684\u5bcc\u96c6\u6216\u56fe\u8868\u4e0e\u4e0a\u6e38\u5171\u4eab\u8f93\u5165\uff0c\u4e0d\u6784\u6210\u72ec\u7acb\u9a8c\u8bc1\u3002"))
  if (!is.null(project$sample_map)) blocks <- c(blocks, list(.b_h("Sample alignment" %L% "\u6837\u672c\u5bf9\u9f50", 3),
                                                              .b_table(project$sample_map$findings),
                                                              if (!is.null(project$sample_map$coverage)) .b_table(project$sample_map$coverage),
                                                              if (!is.null(project$sample_map$pairwise)) .b_table(project$sample_map$pairwise),
                                                              .b_kv(list(n_primary_units = project$sample_map$n_primary_units,
                                                                         n_complete_units = project$sample_map$n_complete_units,
                                                                         n_unmeasured_units = project$sample_map$n_unmeasured_units,
                                                                         coverage_basis = project$sample_map$coverage_basis))))
  if (!is.null(project$relation_validation)) blocks <- c(blocks,
    list(.b_h("Explicit cross-result direction checks" %L% "\u8de8\u7ed3\u679c\u660e\u786e\u65b9\u5411\u68c0\u67e5", 3),
         .b_kv(list(status = project$relation_validation$status,
                    scope = project$relation_validation$scope)),
         .b_table(project$relation_validation$findings, max_rows = 200)))
  if (!is.null(project$interpretation)) {
    blocks <- c(blocks, list(.b_ul(project$interpretation$local)))
    if (include_llm && !is.null(project$interpretation$llm)) {
      blocks <- c(blocks, list(.b_label("Project-level model explanation (unverified)" %L% "\u9879\u76ee\u7ea7\u6a21\u578b\u89e3\u91ca\uff08\u672a\u7ecf\u9a8c\u8bc1\uff09"), .b_p(project$interpretation$llm)))
    }
  }
  for (name in names(project$items)) {
    blocks <- c(blocks, .item_blocks(project$items[[name]], name, include_llm, show_answers))
  }
  blocks
}

.item_blocks <- function(obj, name, include_llm, show_answers = FALSE) {
  head <- .b_h(name, 2)
  body <- if (inherits(obj, "bio_explanation")) {
      c(.blocks_explanation(obj, include_llm),
        .blocks_check(obj$validation, "Explanation fact and citation check" %L% "\u89e3\u91ca\u4e8b\u5b9e\u4e0e\u5f15\u7528\u68c0\u67e5"),
        .blocks_check(obj$cross_check, "Plot vs. source-result cross-check" %L% "\u56fe\u8868\u4e0e\u539f\u7ed3\u679c\u4ea4\u53c9\u6838\u5bf9"))
    }
    else if (inherits(obj, "bio_project")) .blocks_project(obj, include_llm, show_answers)
    else if (inherits(obj, "bio_context")) .blocks_context(obj)
    else if (inherits(obj, "bio_record")) .blocks_record(obj)
    else if (inherits(obj, "bio_error_diagnosis")) .blocks_diagnosis(obj)
    else if (inherits(obj, "bio_fix_suggestions")) .blocks_fix(obj)
    else if (inherits(obj, "bio_validation")) .blocks_validation(obj)
    else if (inherits(obj, "bio_evidence")) .blocks_evidence(list(obj))
    else if (inherits(obj, "bio_quiz")) {
      c(list(.b_h(paste0("Teaching quiz: " %L% "\u6559\u5b66\u6d4b\u9a8c\uff1a", obj$form), 3), .b_table(obj$items, max_rows = 100)),
        if (show_answers) list(.b_h("Instructor answers and rationale" %L% "\u6559\u5e08\u7b54\u6848\u4e0e\u4f9d\u636e", 3), .b_table(obj$key, max_rows = 100)))
    }
    else if (inherits(obj, "bio_assessment")) {
      c(list(.b_p(paste0("Score: " %L% "\u5f97\u5206\uff1a", obj$score, "/", obj$total, if (.is_zh()) "\uff08" else " (", round(obj$percent, 1), if (.is_zh()) "%\uff09" else "%)"))),
        if (show_answers) list(.b_table(obj$items)) else list(.b_table(obj$items[c("id", "answer", "correct")])))
    }
    else if (inherits(obj, "bio_benchmark")) list(.b_h("Explanation accuracy benchmark" %L% "\u89e3\u91ca\u51c6\u786e\u6027\u8bc4\u6d4b", 3), .b_table(obj$summary), .b_table(obj$findings, max_rows = 200))
    else if (inherits(obj, "bio_fix_benchmark")) list(.b_h("Fix execution and semantic-preservation benchmark" %L% "\u4fee\u590d\u8fd0\u884c\u4e0e\u8bed\u4e49\u4fdd\u6301\u8bc4\u6d4b", 3), .b_table(obj$summary), .b_table(obj$findings, max_rows = 200))
    else if (inherits(obj, "bio_expert_evaluation")) list(.b_h("Expert evaluation summary" %L% "\u4e13\u5bb6\u8bc4\u4ef7\u6c47\u603b", 3), .b_table(obj$summary), .b_table(obj$findings, max_rows = 200))
    else if (inherits(obj, "bio_learning_evaluation")) list(.b_h("Learning outcome analysis" %L% "\u6559\u5b66\u6548\u679c\u5206\u6790", 3), .b_table(obj$summary), .b_table(obj$findings), .b_p(obj$note))
    else .blocks_explanation(bio_explain(obj, use_llm = FALSE, language = .current_language()), include_llm)
  c(list(head), body)
}

#' Write a Markdown or HTML report
#'
#' Accepts one object or a (preferably named) list of objects: explanations,
#' contexts, records, error diagnoses, fix suggestions, validations, evidence,
#' or raw analysis objects (which are explained locally, without a model).
#' The report includes source, parameters, thresholds, package versions and
#' model information, but never API keys, raw expression matrices, cell
#' barcodes or sample names. HTML output is escaped and needs no Quarto or
#' Pandoc.
#'
#' @param x Object or list of objects.
#' @param file Optional output path. Format is inferred from \code{.html} /
#'   \code{.md} extension if \code{format} is not given.
#' @param format \code{"markdown"}, \code{"html"} or \code{"quarto"}.
#'   Quarto output is a self-contained \code{.qmd} report; rendering it with
#'   \code{quarto render} is optional and requires Quarto installed separately.
#' @param title Report title. \code{NULL} (default) uses a title in the report
#'   language.
#' @param include_llm Include model-generated text sections.
#' @param include_session Include R/package version section.
#' @param show_answers Include instructor keys in quiz/assessment reports.
#'   Defaults to \code{FALSE} for student-facing reports.
#' @param config Configuration whose public part (protocol, model, endpoint
#'   host; no key) is shown. Default: active configuration.
#' @param language \code{"en"} (default) or \code{"zh"}: language of the report
#'   headings, default title, notes, HTML \code{lang} attribute and Quarto
#'   \code{lang} field. \code{NULL} uses \code{config$language}. Text already
#'   stored inside the supplied objects (for example an explanation generated
#'   earlier in another language) is reproduced unchanged.
#' @return Invisibly, the report text (character string).
#' @export
#' @examples
#' de <- data.frame(log2FoldChange = c(2, -1.2, 0.1), padj = c(0.001, 0.03, 0.7),
#'                  row.names = c("IL6", "SOX2", "ACTB"))
#' txt <- bio_report(list(deg = de), format = "markdown")
#' cat(substr(txt, 1, 300))
#' f <- tempfile(fileext = ".html")
#' bio_report(list(deg = de), file = f)
bio_report <- function(x, file = NULL, format = NULL, title = NULL,
                        include_llm = TRUE, include_session = TRUE, config = NULL, show_answers = FALSE,
                        language = NULL) {
  cfg <- config %||% bio_get_config()
  language <- .resolve_language(language, cfg)
  .local_language(language)
  if (is.null(title)) title <- "BioExplainR Analysis Explanation Report" %L% "BioExplainR \u5206\u6790\u89e3\u91ca\u62a5\u544a"
  if (is.null(format)) {
    format <- if (!is.null(file) && grepl("\\.html?$", file, ignore.case = TRUE)) "html"
              else if (!is.null(file) && grepl("\\.qmd$", file, ignore.case = TRUE)) "quarto" else "markdown"
  }
  format <- match.arg(format, c("markdown", "html", "quarto"))
  # A plain list is a collection of items; any classed object is one item.
  is_single <- !identical(class(x), "list")
  items <- if (is_single) list(x) else x
  nms <- names(items) %||% rep("", length(items))
  nms[!nzchar(nms)] <- paste0("Object " %L% "\u5bf9\u8c61 ", which(!nzchar(nms)))
  .resolve_key(cfg)
  blocks <- list(.b_h(title, 1),
                 .b_p(if (.is_zh()) paste0("\u751f\u6210\u65f6\u95f4\uff1a", .now(), "\uff1bBioExplainR ", .this_version() %||% "dev", "\u3002")
                      else paste0("Generated: ", .now(), "; BioExplainR ", .this_version() %||% "dev", ".")),
                 .b_p("Note: statistical facts are computed deterministically by R from the full input; model text (if any) only organises language and is not numerically verified. The report contains no API key, raw expression matrix, cell barcodes or sample names." %L%
                        "\u8bf4\u660e\uff1a\u7edf\u8ba1\u4e8b\u5b9e\u7531 R \u4ece\u5b8c\u6574\u8f93\u5165\u786e\u5b9a\u6027\u8ba1\u7b97\uff1b\u6a21\u578b\u6587\u672c\uff08\u5982\u6709\uff09\u4ec5\u7ec4\u7ec7\u8bed\u8a00\uff0c\u672a\u7ecf\u6570\u503c\u6838\u9a8c\u3002\u62a5\u544a\u4e0d\u5305\u542b API key\u3001\u539f\u59cb\u8868\u8fbe\u77e9\u9635\u3001\u7ec6\u80de\u6761\u7801\u6216\u6837\u672c\u540d\u79f0\u3002"))
  for (i in seq_along(items)) blocks <- c(blocks, .item_blocks(items[[i]], nms[i], include_llm, show_answers))
  reg <- bio_evidence_list()
  if (length(reg)) blocks <- c(blocks, list(.b_h("Registered evidence" %L% "\u5df2\u6ce8\u518c\u8bc1\u636e", 2)), .blocks_evidence(reg)[-1])
  blocks <- c(blocks, list(.b_h("Model configuration (no key)" %L% "\u6a21\u578b\u914d\u7f6e\uff08\u4e0d\u542b\u5bc6\u94a5\uff09", 2), .b_kv(.config_public(cfg))))
  if (include_session) {
    sv <- .session_versions()
    prov <- bio_dependency_provenance(unique(c("BioExplainR", "httr2", "jsonlite",
                                               intersect(names(sv$packages), c("DESeq2", "limma", "edgeR", "clusterProfiler", "DOSE",
                                                                               "Seurat", "SeuratObject", "SingleCellExperiment",
                                                                               "SummarizedExperiment", "ggplot2", "callr")))))
    blocks <- c(blocks, list(.b_h("Runtime environment and dependency provenance" %L% "\u8fd0\u884c\u73af\u5883\u4e0e\u4f9d\u8d56\u6765\u6e90", 2),
                             .b_kv(list(R = sv$r_version, platform = sv$platform, os = sv$os)),
                             .b_table(prov, max_rows = 100)))
  }
  txt <- if (format == "html") .render_html(blocks, title, language) else .render_md(blocks, language)
  if (format == "quarto") {
    # JSON-quoted scalar is also a valid YAML string, including quotes/newlines.
    txt <- paste0("---\ntitle: ", .json(title), "\nformat:\n  html:\n    toc: true\nlang: ", .html_lang(language), "\n---\n\n", txt)
  }
  txt <- paste(bio_redact(strsplit(txt, "\n", fixed = TRUE)[[1]]), collapse = "\n")
  if (!is.null(file)) {
    writeLines(enc2utf8(txt), file, useBytes = TRUE)
    message("Report written to ", file)
  }
  invisible(txt)
}
