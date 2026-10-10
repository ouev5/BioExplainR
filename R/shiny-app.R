# Optional local browser application -----------------------------------------

.bio_app_require_shiny <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("bio_run_app() requires the optional package 'shiny'. Install it with install.packages('shiny').",
         call. = FALSE)
  }
}

.bio_app_copy_bindings <- function(from, to) {
  if (!is.environment(from) || !is.environment(to)) return(invisible(NULL))
  nms <- ls(from, all.names = FALSE)
  for (nm in nms) {
    if (exists(nm, envir = from, inherits = FALSE)) {
      value <- get(nm, envir = from, inherits = FALSE)
      assign(nm, value, envir = to)
    }
  }
  invisible(nms)
}

.bio_app_safe <- function(expr, fallback = NULL) {
  tryCatch(expr, error = function(e) fallback)
}

.bio_app_object_names <- function(envir) {
  nms <- ls(envir, all.names = FALSE)
  nms[vapply(nms, function(n) !is.function(get(n, envir = envir, inherits = FALSE)), logical(1))]
}

# The language selected in the browser; falls back to the start-up language if the
# input is missing or tampered with (strict validation happens in bio_explain/bio_config).
.bio_app_lang <- function(x, default = .default_language) {
  if (is.character(x) && length(x) == 1L && !is.na(x) && x %in% .languages) x else default
}

.bio_app_explain <- function(x, input, config = NULL, source = NULL, language = NULL) {
  language <- .check_language(language %||% input$language %||% .default_language)
  if (inherits(x, "bio_project")) {
    if (is.data.frame(x$relations) && all(c("from_fact", "to_fact", "expected") %in% names(x$relations)))
      x$relation_validation <- bio_validate_project_relations(x)
    return(bio_explain_project(x, config = config, use_llm = isTRUE(input$use_llm), language = language))
  }
  thresholds <- list(
    padj = as.numeric(input$padj %||% 0.05),
    lfc = as.numeric(input$lfc %||% 0),
    p = as.numeric(input$p %||% 0.05)
  )
  use_llm <- if (isTRUE(input$use_llm)) TRUE else FALSE
  bio_explain(x, config = config, cross_check = source,
              allow_subset = isTRUE(input$allow_subset), use_llm = use_llm, language = language,
              level = input$level %||% "beginner", question = input$question,
              species = if (nzchar(input$species %||% "")) input$species else NULL,
              tissue = if (nzchar(input$tissue %||% "")) input$tissue else NULL,
              contrast = if (nzchar(input$contrast %||% "")) input$contrast else NULL,
              thresholds = thresholds,
              p_adjust_method = if (identical(input$p_adjust, "none")) NULL else input$p_adjust)
}

#' Start the BioExplainR local browser application
#'
#' Opens a Shiny application on the local computer. The app provides model
#' configuration, R/package inspection, a recorded code console, deterministic
#' object explanations, common bioinformatics plots and report download.
#' Code entered in the browser runs in a session-local environment through
#' \code{bio_record_code()}; an LLM is never allowed to execute code.
#'
#' The interface and the explanations are in English by default. The language
#' selector on the model settings tab switches the interface labels, status
#' messages, explanations and downloaded reports to Simplified Chinese (and
#' back) without restarting the app.
#'
#' @param envir Environment whose objects are copied into the app workspace.
#'   Defaults to the calling environment.
#' @param host Host interface. The default only accepts connections from the
#'   local computer.
#' @param port TCP port, or \code{NULL} for Shiny's automatic selection.
#' @param launch.browser Whether to open the default browser.
#' @param language Initial interface and explanation language: \code{"en"}
#'   (default) or \code{"zh"}. \code{NULL} uses the active configuration's
#'   \code{language}. The user can change it later in the app.
#' @param ... Additional arguments passed to \code{shiny::runApp()}.
#' @return Invisibly, the result of \code{shiny::runApp()} after the app exits.
#' @export
#' @examples
#' \dontrun{
#' bio_run_app()
#' bio_run_app(language = "zh")
#' }
bio_run_app <- function(envir = parent.frame(), host = "127.0.0.1", port = NULL,
                        launch.browser = interactive(), language = NULL, ...) {
  language <- .resolve_language(language, bio_get_config())
  app <- .bio_app(envir, language = language)
  shiny::runApp(app, host = host, port = port, launch.browser = launch.browser, ...)
}

.bio_app_shiny <- function() {
  .bio_app_require_shiny()
  exports <- getNamespaceExports("shiny")
  stats::setNames(lapply(exports, function(n) getExportedValue("shiny", n)), exports)
}

# Strings rendered as server-side text outputs so they can change with the language.
.app_txt_keys <- c("app_title", "app_subtitle", "tab_model", "tab_runtime", "tab_code", "tab_analysis",
                   "tab_plots", "privacy_h", "privacy_p", "h_objects", "h_installed", "h_usage", "h_history",
                   "h_record_out", "code_help", "h_result", "plots_help")

.app_level_choices <- function(language) {
  stats::setNames(c("beginner", "undergraduate", "advanced"),
                  c(.app_t("level_beginner", language), .app_t("level_undergraduate", language),
                    .app_t("level_advanced", language)))
}
.app_plot_choices <- function(language) {
  stats::setNames(c("auto", "pca", "umap", "enrichment", "heatmap"),
                  c(.app_t("plot_auto", language), "PCA", .app_t("plot_umap", language),
                    .app_t("plot_enrichment", language), .app_t("plot_heatmap", language)))
}
.app_padjust_choices <- function(language) {
  stats::setNames(c("none", "BH"), c(.app_t("p_adjust_none", language), "BH"))
}
.app_none_choice <- function(language) stats::setNames("", .app_t("none", language))

.app_default_code <- function(language) {
  paste(.app_t("code_default", language), "# result <- bio_explain(your_object, use_llm = FALSE)", "ls()", sep = "\n")
}

.bio_app_ui <- function(shiny, language = .default_language, initial_config = bio_get_config()) {
  language <- .check_language(language)
  t <- function(key) .app_t(key, language)
  # Static text outputs are pre-filled in the start-up language and re-rendered by the server.
  txt <- function(key, container = shiny$span, class = NULL)
    container(id = paste0("txt_", key), class = paste(c("shiny-text-output", class), collapse = " "), t(key))
  shiny$fluidPage(
    shiny$tags$head(
      shiny$tags$title(t("app_title")),
      shiny$tags$script(shiny$HTML(paste0(
        "document.documentElement.lang='", .html_lang(language), "';",
        "$(document).on('shiny:inputchanged',function(e){if(e.name==='language'){",
        "document.documentElement.lang=(e.value==='zh'?'zh-CN':'en');}});"))),
      shiny$tags$style(shiny$HTML(paste(
        ".bio-title{color:#215a7a;margin-bottom:0}.bio-subtitle{color:#5d6870;margin-top:4px}",
        ".shiny-input-container{margin-bottom:12px} .well{background:#f7fafc}",
        "pre{max-height:420px;overflow:auto;background:#f6f8fa;padding:12px}",
        "table{font-size:13px} .bio-scroll{max-width:100%;overflow-x:auto}", sep = "\n")))
    ),
    shiny$div(class = "container-fluid",
      txt("app_title", shiny$h2, "bio-title"),
      txt("app_subtitle", shiny$p, "bio-subtitle"),
      shiny$tabsetPanel(id = "main_tabs",
        shiny$tabPanel(txt("tab_model"), value = "model",
          shiny$br(), shiny$fluidRow(
            shiny$column(4, shiny$selectInput("preset", t("preset"), choices = names(.all_presets()), selected = initial_config$preset),
                         shiny$textInput("base_url", t("base_url"), value = initial_config$base_url %||% ""),
                         shiny$textInput("model", t("model"), value = initial_config$model %||% "")),
            shiny$column(4, shiny$textInput("api_key_env", t("api_key_env"), value = initial_config$api_key_env %||% "BIOEXPLAINR_API_KEY"),
                         shiny$passwordInput("api_key", t("api_key")),
                         shiny$selectInput("language", t("language"), choices = .app_language_choices, selected = language)),
            shiny$column(4, shiny$numericInput("timeout", t("timeout"), value = 60, min = 1),
                         shiny$numericInput("max_retries", t("max_retries"), value = 2, min = 0, step = 1),
                         shiny$numericInput("max_tokens", t("max_tokens"), value = initial_config$max_tokens, min = 1, step = 100),
                         shiny$checkboxInput("json_mode", t("json_mode"), value = isTRUE(initial_config$json_mode)),
                         shiny$selectInput("thinking", t("thinking"), choices = c("disabled", "enabled"), selected = "disabled"),
                         shiny$actionButton("save_config", t("save_config"), class = "btn-primary"), shiny$br(), shiny$br(),
                         shiny$verbatimTextOutput("config_status"))
          ),
          shiny$hr(), txt("privacy_h", shiny$h4),
          txt("privacy_p", shiny$p)
        ),
        shiny$tabPanel(txt("tab_runtime"), value = "runtime",
          shiny$br(), shiny$fluidRow(
            shiny$column(3, shiny$actionButton("refresh_runtime", t("refresh_runtime")), shiny$br(), shiny$br(),
                         shiny$uiOutput("ui_download_runtime")),
            shiny$column(9, shiny$verbatimTextOutput("runtime_summary"))
          ),
          txt("h_objects", shiny$h4), shiny$tableOutput("object_table"),
          txt("h_installed", shiny$h4), shiny$tableOutput("installed_table"),
          txt("h_usage", shiny$h4), shiny$tableOutput("usage_table"),
          txt("h_history", shiny$h4), shiny$tableOutput("record_table"),
          txt("h_record_out", shiny$h4), shiny$verbatimTextOutput("record_output")
        ),
        shiny$tabPanel(txt("tab_code"), value = "code",
          shiny$br(), txt("code_help", shiny$p),
          shiny$textAreaInput("code", t("code_label"), value = .app_default_code(language), rows = 14, width = "100%"),
          shiny$textInput("run_label", t("run_label"), value = t("run_label_default")),
          shiny$textInput("run_purpose", t("run_purpose"), value = ""),
          shiny$actionButton("run_code", t("run_code"), class = "btn-primary"), shiny$br(), shiny$br(),
          shiny$verbatimTextOutput("run_status"), shiny$verbatimTextOutput("run_console")
        ),
        shiny$tabPanel(txt("tab_analysis"), value = "analysis",
          shiny$br(),
          shiny$fluidRow(
            shiny$column(4, shiny$selectInput("analysis_object", t("analysis_object"), choices = NULL),
                         shiny$textInput("species", t("species"), value = ""),
                         shiny$textInput("tissue", t("tissue"), value = ""),
                         shiny$textInput("contrast", t("contrast"), value = "")),
            shiny$column(4, shiny$selectInput("level", t("level"), choices = .app_level_choices(language)),
                         shiny$numericInput("padj", t("padj"), value = 0.05, min = 0, max = 1, step = 0.01),
                         shiny$numericInput("lfc", t("lfc"), value = 0, min = 0, step = 0.1),
                         shiny$selectInput("p_adjust", t("p_adjust"), choices = .app_padjust_choices(language))),
            shiny$column(4, shiny$checkboxInput("use_llm", t("use_llm"), value = FALSE),
                         shiny$selectInput("source_object", t("source_object"), choices = .app_none_choice(language)),
                         shiny$checkboxInput("allow_subset", t("allow_subset"), value = FALSE),
                         shiny$textAreaInput("question", t("question"), value = "", rows = 5),
                         shiny$actionButton("analyze_object", t("analyze_object"), class = "btn-primary"))
          ),
          txt("h_result", shiny$h4), shiny$verbatimTextOutput("analysis_status"),
          shiny$uiOutput("analysis_sections"),
          shiny$uiOutput("ui_download_report")
        ),
        shiny$tabPanel(txt("tab_plots"), value = "plots",
          shiny$br(), txt("plots_help", shiny$p),
          shiny$fluidRow(
            shiny$column(4, shiny$selectInput("plot_object", t("plot_object"), choices = NULL),
                         shiny$selectInput("plot_type", t("plot_type"), choices = .app_plot_choices(language)),
                         shiny$numericInput("plot_top_n", t("plot_top_n"), value = 30, min = 2, step = 1),
                         shiny$selectInput("plot_metadata", t("plot_metadata"), choices = .app_none_choice(language)),
                         shiny$textInput("plot_group", t("plot_group"), value = ""),
                         shiny$textInput("plot_name", t("plot_name"), value = "bio_generated_plot"),
                         shiny$actionButton("make_plot", t("make_plot"), class = "btn-primary")),
             shiny$column(8, shiny$verbatimTextOutput("plot_status"), shiny$uiOutput("ui_download_plot"),
                          shiny$plotOutput("bio_plot", height = "600px"))
          )
        )
      )
    )
  )
}

.bio_app <- function(envir, language = NULL) {
  shiny <- .bio_app_shiny()
  if (!is.environment(envir)) stop("envir must be an environment.", call. = FALSE)
  initial <- new.env(parent = envir)
  .bio_app_copy_bindings(envir, initial)
  initial_config <- bio_get_config()
  initial_language <- .resolve_language(language, initial_config)
  ui <- .bio_app_ui(shiny, initial_language, initial_config)
  server <- function(input, output, session) {
    workspace <- new.env(parent = envir)
    .bio_app_copy_bindings(initial, workspace)
    state <- shiny$reactiveValues(records = list(), config = initial_config,
                                  analyses = list(), last_analysis = NULL,
                                  last_plot = NULL, plot_status = NULL, runtime_tick = 0L, selected_record = NULL,
                                  config_tick = 0L, run_status = NULL, analysis_status = NULL)
    lang <- shiny$reactive(.bio_app_lang(input$language, initial_language))
    tt <- function(key, ...) .app_t(key, lang(), ...)

    refresh_objects <- function(language = NULL, keep = FALSE) {
      language <- language %||% shiny$isolate(lang())
      nms <- .bio_app_object_names(workspace)
      pick <- function(id) {
        cur <- shiny$isolate(input[[id]])
        if (keep && !is.null(cur) && cur %in% nms) cur else if (length(nms)) nms[length(nms)] else character()
      }
      shiny$updateSelectInput(session, "analysis_object", choices = nms, selected = pick("analysis_object"))
      shiny$updateSelectInput(session, "plot_object", choices = nms, selected = pick("plot_object"))
      shiny$updateSelectInput(session, "source_object", choices = c(.app_none_choice(language), nms),
                              selected = if (keep) shiny$isolate(input$source_object) %||% "" else "")
      md <- nms[vapply(nms, function(n) is.data.frame(get(n, workspace)), logical(1))]
      shiny$updateSelectInput(session, "plot_metadata", choices = c(.app_none_choice(language), md),
                              selected = if (keep) shiny$isolate(input$plot_metadata) %||% "" else "")
    }
    session_usage <- shiny$reactive({
      rows <- lapply(state$records, function(r) r$package_usage)
      rows <- Filter(function(x) !is.null(x) && nrow(x) > 0L, rows)
      if (!length(rows)) return(data.frame())
      unique(do.call(rbind, rows))
    })
    refresh_objects(initial_language)

    # Language switching: static text outputs re-render with lang(); input labels,
    # button captions and choice labels are pushed to the browser here.
    lapply(.app_txt_keys, function(k) {
      output[[paste0("txt_", k)]] <- shiny$renderText(tt(k))
    })
    output$ui_download_runtime <- shiny$renderUI(shiny$downloadButton("download_runtime", tt("download_runtime")))
    output$ui_download_report <- shiny$renderUI(shiny$downloadButton("download_report", tt("download_report")))
    output$ui_download_plot <- shiny$renderUI({
      if (!is.null(state$last_plot)) shiny$downloadButton("download_plot", tt("download_plot"))
    })
    shiny$observeEvent(lang(), {
      language <- lang()
      t <- function(key) .app_t(key, language)
      for (id in c("base_url", "model", "api_key_env", "api_key", "run_label", "run_purpose", "species",
                   "tissue", "contrast", "plot_group", "plot_name")) {
        shiny$updateTextInput(session, id, label = t(id))
      }
      shiny$updateTextAreaInput(session, "code", label = t("code_label"))
      shiny$updateTextAreaInput(session, "question", label = t("question"))
      for (id in c("timeout", "max_retries", "max_tokens", "padj", "lfc", "plot_top_n")) {
        shiny$updateNumericInput(session, id, label = t(id))
      }
      for (id in c("json_mode", "use_llm", "allow_subset")) shiny$updateCheckboxInput(session, id, label = t(id))
      for (id in c("save_config", "refresh_runtime", "run_code", "analyze_object", "make_plot")) {
        shiny$updateActionButton(session, id, label = t(id))
      }
      for (id in c("preset", "language", "thinking", "analysis_object", "plot_object")) {
        shiny$updateSelectInput(session, id, label = t(id))
      }
      shiny$updateSelectInput(session, "level", label = t("level"), choices = .app_level_choices(language),
                              selected = input$level %||% "beginner")
      shiny$updateSelectInput(session, "p_adjust", label = t("p_adjust"), choices = .app_padjust_choices(language),
                              selected = input$p_adjust %||% "none")
      shiny$updateSelectInput(session, "plot_type", label = t("plot_type"), choices = .app_plot_choices(language),
                              selected = input$plot_type %||% "auto")
      shiny$updateSelectInput(session, "source_object", label = t("source_object"))
      shiny$updateSelectInput(session, "plot_metadata", label = t("plot_metadata"))
      # Untouched example text follows the language; edited text is left alone.
      for (other in setdiff(.languages, language)) {
        if (identical(input$run_label, .app_t("run_label_default", other)))
          shiny$updateTextInput(session, "run_label", value = t("run_label_default"))
        if (identical(input$code, .app_default_code(other)))
          shiny$updateTextAreaInput(session, "code", value = .app_default_code(language))
      }
      refresh_objects(language, keep = TRUE)
    })

    shiny$observeEvent(input$save_config, {
      args <- list(preset = input$preset, model = if (nzchar(input$model)) input$model else NULL,
                   api_key_env = if (nzchar(input$api_key_env)) input$api_key_env else NULL,
                   timeout = input$timeout, max_retries = input$max_retries,
                   max_tokens = input$max_tokens %||% 5000, json_mode = isTRUE(input$json_mode),
                   extra_body = if (identical(input$preset, "deepseek")) list(thinking = list(type = input$thinking %||% "disabled")) else NULL,
                   language = input$language %||% initial_language)
      if (nzchar(input$base_url)) args$base_url <- input$base_url
      if (nzchar(input$api_key)) args$api_key <- input$api_key
      cfg <- tryCatch(do.call(bio_config, args), error = function(e) e)
      if (inherits(cfg, "error")) {
        shiny$showNotification(conditionMessage(cfg), type = "error")
      } else {
        state$config <- cfg; state$config_tick <- state$config_tick + 1L
        shiny$updateTextInput(session, "api_key", value = "")
        shiny$showNotification(tt("config_saved"), type = "message")
      }
    })
    output$config_status <- shiny$renderPrint({
      state$config_tick
      cfg <- state$config
      print(cfg)
      cat(tt("callable"), bio_llm_available(cfg, reason = TRUE), "\n", sep = "")
    })

    shiny$observeEvent(input$run_code, {
      rec <- tryCatch(bio_record_code(input$code, label = input$run_label,
                                      purpose = input$run_purpose, envir = workspace,
                                      muffle_warnings = FALSE), error = function(e) e)
      if (inherits(rec, "error")) {
        state$run_status <- list(error = conditionMessage(rec))
      } else {
        state$records <- c(state$records, list(rec)); state$selected_record <- length(state$records)
        state$run_status <- list(status = rec$status, elapsed = rec$elapsed_sec,
                                 created = paste(names(rec$objects_created), collapse = ", "))
        refresh_objects(); state$runtime_tick <- state$runtime_tick + 1L
      }
    })
    output$run_status <- shiny$renderText({
      s <- state$run_status
      if (is.null(s)) return("")
      if (!is.null(s$error)) paste(tt("run_failed"), s$error)
      else tt("run_status", s$status, s$elapsed, s$created)
    })
    output$run_console <- shiny$renderPrint({
      i <- state$selected_record
      if (is.null(i) || !length(state$records)) return(invisible(NULL))
      rec <- state$records[[i]]
      if (!is.null(rec$error)) print(rec$error) else {
        value <- bio_value(rec)
        cat(tt("return_class"), paste(class(value), collapse = "/"), "\n", sep = "")
        if (is.data.frame(value)) print(utils::head(value, 20)) else print(value)
      }
    })

    output$runtime_summary <- shiny$renderPrint({
      state$runtime_tick
      rt <- bio_runtime_info(include_installed = FALSE)
      cat(rt$r_version, "\n", rt$platform, "\n", tt("search_path"), paste(rt$search_path, collapse = " | "), "\n", sep = "")
      cat(tt("loaded_pkgs", nrow(rt$loaded_packages), length(state$records)), "\n", sep = "")
    })
    output$object_table <- shiny$renderTable({
      state$runtime_tick
      tab <- bio_object_inventory(workspace)
      if (nrow(tab)) tab else data.frame(message = tt("no_objects"))
    }, striped = TRUE, bordered = TRUE, hover = TRUE)
    output$usage_table <- shiny$renderTable({
      state$runtime_tick
      tab <- session_usage()
      if (nrow(tab)) utils::head(tab, 100) else data.frame(message = tt("no_usage"))
    }, striped = TRUE, bordered = TRUE, hover = TRUE)
    output$record_table <- shiny$renderTable({
      state$runtime_tick
      rs <- state$records
      if (!length(rs)) return(data.frame(message = tt("no_records")))
      do.call(rbind, lapply(seq_along(rs), function(i) data.frame(index = i, label = rs[[i]]$label %||% "",
        status = rs[[i]]$status, purpose = rs[[i]]$purpose %||% "", elapsed_sec = rs[[i]]$elapsed_sec,
        objects_created = paste(names(rs[[i]]$objects_created), collapse = ", "),
        value_class = paste(class(rs[[i]]$value), collapse = "/"),
        stringsAsFactors = FALSE)))
    }, striped = TRUE, bordered = TRUE, hover = TRUE)
    output$installed_table <- shiny$renderTable({
      state$runtime_tick
      pk <- bio_runtime_info(include_installed = TRUE)$installed_packages
      if (is.null(pk) || !nrow(pk)) data.frame(message = tt("no_installed")) else pk
    }, striped = TRUE, bordered = TRUE, hover = TRUE)
    output$record_output <- shiny$renderPrint({
      rs <- state$records; i <- state$selected_record
      if (!length(rs) || is.null(i)) return(cat(tt("pick_run"), "\n", sep = ""))
      r <- rs[[i]]; cat(tt("code_prefix"), "\n", r$code, "\n\n", sep = "")
      if (!is.null(r$error)) print(r$error) else if (!is.null(r$value)) print(utils::head(bio_value(r), 30))
      else cat(tt("record_no_value"), "\n", sep = "")
    })
    shiny$observeEvent(input$refresh_runtime, { state$runtime_tick <- state$runtime_tick + 1L; refresh_objects(keep = TRUE) })

    shiny$observeEvent(input$analyze_object, {
      req <- input$analysis_object
      if (is.null(req) || !nzchar(req) || !exists(req, envir = workspace, inherits = FALSE)) {
        state$analysis_status <- list(pick = TRUE)
        return()
      }
      source <- if (nzchar(input$source_object %||% "") && exists(input$source_object, workspace, inherits = FALSE))
        get(input$source_object, workspace, inherits = FALSE) else NULL
      object <- get(req, envir = workspace, inherits = FALSE)
      ans <- tryCatch(if (inherits(object, "bio_explanation")) object else .bio_app_explain(object, input,
                                       config = state$config, source = source, language = lang()),
                      error = function(e) e)
      if (inherits(ans, "error")) {
        state$analysis_status <- list(error = conditionMessage(ans))
        state$last_analysis <- NULL
      } else {
        state$analyses[[req]] <- ans; state$last_analysis <- ans
        state$analysis_status <- list(object = req,
          type = if (inherits(ans, "bio_project")) "project" else ans$context$analysis_type,
          claims = if (inherits(ans, "bio_project")) ans$relation_validation$status else ans$validation$status,
          plot = ans$cross_check$status)
      }
    })
    output$analysis_status <- shiny$renderText({
      s <- state$analysis_status
      if (is.null(s)) return("")
      if (isTRUE(s$pick)) return(tt("pick_object"))
      if (!is.null(s$error)) return(paste(tt("analysis_failed"), s$error))
      paste0(tt("analysis_ok", s$object, s$type),
             if (!is.null(s$claims)) paste0(" claims: ", s$claims),
             if (!is.null(s$plot)) paste0(" plot: ", s$plot))
    })
    output$analysis_sections <- shiny$renderUI({
      ex <- state$last_analysis
      if (is.null(ex)) return(shiny$helpText(tt("analysis_hint")))
      if (inherits(ex, "bio_project")) {
        table <- function(x, id) {
          if (is.null(x) || !is.data.frame(x) || !nrow(x)) return(NULL)
          shiny$div(class = "bio-scroll", id = id, shiny$tags$table(class = "table table-striped",
            shiny$tags$thead(shiny$tags$tr(lapply(names(x), shiny$tags$th))),
            shiny$tags$tbody(lapply(seq_len(nrow(x)), function(i)
              shiny$tags$tr(lapply(x[i, , drop = FALSE], function(v) shiny$tags$td(as.character(v))))))))
        }
        a <- ex$sample_map
        return(shiny$tagList(
          shiny$h4(tt("project_summary")), table(ex$summary, "project_summary"),
          shiny$tags$ul(lapply(ex$interpretation$local, shiny$tags$li)),
          if (!is.null(ex$interpretation$llm)) shiny$tagList(shiny$h4(tt("llm_h")), shiny$pre(ex$interpretation$llm)),
          shiny$h4(tt("project_dependencies")), table(ex$dependencies, "project_dependencies"),
          if (!is.null(a)) shiny$tagList(shiny$h4(tt("alignment")),
            shiny$pre(id = "project_coverage_counts", .json(a[c("n_primary_units", "n_complete_units", "n_unmeasured_units", "coverage_basis")], pretty = TRUE)),
            table(a$coverage, "project_coverage"), table(a$pairwise, "project_pairwise")),
          if (!is.null(ex$relation_validation)) shiny$tagList(shiny$h4(tt("project_relations")),
            table(ex$relation_validation$findings, "project_relations"))
        ))
      }
      titles <- .section_titles_for(ex$language %||% lang())
      blocks <- lapply(names(ex$local), function(n) {
        title <- titles[[n]] %||% n
        shiny$tagList(shiny$h4(title), shiny$tags$ul(lapply(ex$local[[n]], shiny$tags$li)))
      })
      if (!is.null(ex$llm)) blocks <- c(blocks, list(shiny$h4(tt("llm_h")), shiny$pre(.json(ex$llm, pretty = TRUE))))
      if (!is.null(ex$validation)) blocks <- c(blocks, list(shiny$h4(tt("claims")), shiny$pre(.json(ex$validation, pretty = TRUE))))
      preview <- tryCatch(.json(bio_context_payload(ex$context, policy = bio_payload_policy()), pretty = TRUE), error = function(e) conditionMessage(e))
      blocks <- c(blocks, list(shiny$tags$details(id = "payload_preview", shiny$tags$summary(tt("payload_preview")), shiny$pre(preview))))
      if (!is.null(ex$claim_ledger)) blocks <- c(blocks, list(shiny$h4(tt("typed_claims")), shiny$pre(id = "typed_claims", .json(ex$claim_ledger, pretty = TRUE))))
      if (!is.null(ex$evidence)) blocks <- c(blocks, list(shiny$h4(tt("evidence_relations")), shiny$pre(id = "evidence_relations", .json(list(evidence = lapply(ex$evidence, function(e) e[c("id", "source", "title", "scope", "role")]), findings = ex$validation$evidence_findings), pretty = TRUE))))
      if (!is.null(ex$context$provenance$alignment)) blocks <- c(blocks, list(shiny$h4(tt("alignment")), shiny$pre(id = "sample_alignment", .json(ex$context$provenance$alignment$findings, pretty = TRUE))))
      if (!is.null(ex$manifest)) blocks <- c(blocks, list(shiny$tags$details(id = "runtime_manifest", shiny$tags$summary(tt("runtime_manifest")), shiny$pre(.json(ex$manifest, pretty = TRUE)))))
      if (!is.null(ex$cross_check)) blocks <- c(blocks, list(shiny$h4(tt("plot_source")), shiny$pre(.json(ex$cross_check, pretty = TRUE))))
      shiny$tagList(blocks)
    })

    shiny$observeEvent(input$make_plot, {
      nm <- input$plot_object
      if (is.null(nm) || !exists(nm, envir = workspace, inherits = FALSE)) return()
      x <- get(nm, envir = workspace, inherits = FALSE)
      md <- if (nzchar(input$plot_metadata %||% "") && exists(input$plot_metadata, workspace, inherits = FALSE))
        get(input$plot_metadata, workspace, inherits = FALSE) else NULL
      group <- if (nzchar(input$plot_group %||% "")) input$plot_group else NULL
      p <- tryCatch(.with_language(lang(), switch(input$plot_type,
                           auto = if (is.matrix(x) || inherits(x, "Matrix"))
                             bio_plot_pca(x, metadata = md, group = group, n_top_features = input$plot_top_n) else bio_plot(x, "auto"),
                           pca = bio_plot_pca(x, metadata = md, group = group, n_top_features = input$plot_top_n),
                           umap = bio_plot_umap(x, metadata = md, group = group),
                           enrichment = bio_plot_enrichment(x, top_n = input$plot_top_n),
                           heatmap = bio_plot_heatmap(x, metadata = md, top_n = input$plot_top_n))),
                    error = function(e) e)
      if (inherits(p, "error")) {
        shiny$showNotification(conditionMessage(p), type = "error"); state$last_plot <- NULL
        state$plot_status <- conditionMessage(p)
      } else {
        name <- input$plot_name %||% "bio_generated_plot"
        if (!nzchar(name)) name <- "bio_generated_plot"
        assign(name, p, envir = workspace)
        state$last_plot <- p
        refresh_objects(keep = TRUE); state$runtime_tick <- state$runtime_tick + 1L
        state$plot_status <- paste0(name, " <- ", nm)
      }
    })
    output$plot_status <- shiny$renderText(state$plot_status %||% "")
    output$bio_plot <- shiny$renderPlot({
      p <- state$last_plot
      if (is.null(p)) return(graphics::plot.new())
      print(p)
    })

    output$download_report <- shiny$downloadHandler(
      filename = function() paste0("BioExplainR_report_", format(Sys.Date(), "%Y%m%d"), ".html"),
      content = function(file) {
        ex <- state$last_analysis
        if (is.null(ex)) stop(.app_t("report_first", lang()), call. = FALSE)
        bio_report(ex, file = file, format = "html", config = state$config, language = lang())
      }
    )
    output$download_plot <- shiny$downloadHandler(
      filename = function() paste0("BioExplainR_plot_", format(Sys.Date(), "%Y%m%d"), ".pdf"),
      contentType = "application/pdf",
      content = function(file) {
        p <- state$last_plot
        if (is.null(p)) stop(.app_t("plot_first", lang()), call. = FALSE)
        ggplot2::ggsave(file, p, device = grDevices::cairo_pdf, width = 9, height = 6,
                       units = "in", bg = "white")
      }
    )
    output$download_runtime <- shiny$downloadHandler(
      filename = function() paste0("BioExplainR_runtime_", format(Sys.Date(), "%Y%m%d"), ".json"),
      content = function(file) {
        rt <- bio_runtime_info(include_installed = TRUE)
        rt$package_usage <- session_usage()
        writeLines(.json(rt, pretty = TRUE), file, useBytes = TRUE)
      }
    )
  }
  shiny$shinyApp(ui = ui, server = server)
}
