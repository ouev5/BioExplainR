# Unified intermediate representation -----------------------------------------

#' Construct a bio_context object
#'
#' A \code{bio_context} is the compact, inspectable intermediate representation
#' shared by explanations, LLM prompts and reports. Adapters create it; users
#' rarely call this constructor directly except when writing new adapters.
#'
#' @param analysis_type For example \code{"differential_expression"},
#'   \code{"enrichment_ora"}, \code{"enrichment_gsea"}, \code{"single_cell"},
#'   \code{"pca"}, \code{"plot"}, \code{"generic"}.
#' @param source_class Class of the input object.
#' @param source_package Package known (or suspected) to have produced it.
#' @param source_status One of \code{"verified_class"} (class identifies the
#'   producer), \code{"user_declared"}, \code{"inferred_from_columns"} (a guess)
#'   or \code{"unknown"}.
#' @param facts Named list of deterministic statistics computed in R.
#' @param top_features Small data.frame of top rows (already truncated).
#' @param plot_mapping List describing plot semantics (plots only).
#' @param provenance List: adapter, parameters, timestamps, dependencies.
#' @param uncertainty Character vector of caveats about source and facts.
#' @param metadata User-supplied study context (species, tissue, contrast...).
#' @param adapter Adapter name.
#' @param schema_version Version of the BioExplainR context contract.
#' @param scope Known dataset, analysis, comparison, sample and modality scope.
#' @param design Structured design information, including independent units.
#' @param fact_descriptors Optional descriptions of fact paths and completeness.
#' @param modalities Optional modality summary for multi-assay contexts.
#' @return Object of class \code{bio_context}.
#' @export
new_bio_context <- function(analysis_type, source_class, source_package = NA_character_,
                            source_status = c("verified_class", "user_declared",
                                              "inferred_from_columns", "unknown"),
                             facts = list(), top_features = NULL, plot_mapping = NULL,
                             provenance = list(), uncertainty = character(),
                             metadata = list(), adapter = NA_character_,
                             schema_version = "1.0", scope = list(), design = list(),
                             fact_descriptors = list(), modalities = NULL) {
  source_status <- match.arg(source_status)
  structure(list(
    analysis_type = analysis_type,
    source_class = source_class,
    source_package = source_package,
    source_status = source_status,
    facts = facts,
    top_features = top_features,
    plot_mapping = plot_mapping,
    provenance = provenance,
    uncertainty = unique(uncertainty),
    metadata = metadata,
    adapter = adapter,
    schema_version = as.character(schema_version)[1L],
    scope = scope %||% list(),
    design = design %||% list(),
    fact_descriptors = fact_descriptors %||% list(),
    modalities = modalities
  ), class = "bio_context") |> .finalize_context()
}

#' Register a custom object adapter
#'
#' Adapters translate an R object into a \code{\link{new_bio_context}}. User
#' adapters are tried before built-in ones.
#'
#' @param name Unique adapter name.
#' @param detect \code{function(x)} returning \code{TRUE} if the adapter
#'   handles \code{x}.
#' @param extract \code{function(x, meta, n_top, thresholds, ...)} returning a
#'   \code{bio_context}.
#' @param analysis_types Character vector of \code{analysis_type} values for
#'   which this adapter may be selected explicitly.
#' @return Invisibly, the list of registered adapter names.
#' @export
#' @examples
#' bio_register_adapter("my_counts",
#'   detect = function(x) inherits(x, "my_counts"),
#'   extract = function(x, meta, n_top, thresholds, ...) {
#'     new_bio_context("generic", class(x), source_status = "verified_class",
#'                     facts = list(n = length(x)), metadata = meta)
#'   })
#' bio_adapters()
#' bio_unregister_adapter("my_counts")
bio_register_adapter <- function(name, detect, extract, analysis_types = character()) {
  stopifnot(is.function(detect), is.function(extract))
  .pkg_env$adapters[[name]] <- list(name = name, detect = detect, extract = extract,
                                    analysis_types = analysis_types, builtin = FALSE)
  invisible(names(.pkg_env$adapters))
}

#' @rdname bio_register_adapter
#' @export
bio_unregister_adapter <- function(name) {
  .pkg_env$adapters[[name]] <- NULL
  invisible(names(.pkg_env$adapters))
}

#' @rdname bio_register_adapter
#' @export
bio_adapters <- function() {
  all <- .adapter_list()
  data.frame(
    name = names(all),
    builtin = vapply(all, function(a) isTRUE(a$builtin), logical(1)),
    analysis_types = vapply(all, function(a) paste(a$analysis_types, collapse = ", "), character(1)),
    stringsAsFactors = FALSE, row.names = NULL
  )
}

.builtin_adapters <- function() {
  list(
    deseq_results = list(detect = function(x) inherits(x, "DESeqResults"),
                         extract = .adapt_deseq_results,
                         analysis_types = character()),
    gsea_result = list(detect = function(x) inherits(x, "gseaResult"),
                             extract = .adapt_gsea_result,
                             analysis_types = character()),
    enrich_result = list(detect = function(x) inherits(x, "enrichResult") || inherits(x, "compareClusterResult"),
                         extract = .adapt_enrich_result,
                         analysis_types = character()),
    marray_lm = list(detect = function(x) inherits(x, "MArrayLM"),
                     extract = .adapt_marray_lm, analysis_types = character()),
    edger_result = list(detect = function(x) inherits(x, c("TopTags", "DGEExact", "DGELRT")),
                        extract = .adapt_edger, analysis_types = character()),
    spatial_experiment = list(detect = function(x) inherits(x, "SpatialExperiment"),
                              extract = .adapt_spatial_experiment, analysis_types = character()),
    multi_assay_experiment = list(detect = function(x) inherits(x, "MultiAssayExperiment"),
                                  extract = .adapt_multi_assay_experiment, analysis_types = character()),
    cell_proportions = list(detect = function(x) inherits(x, "bio_cell_proportions"),
                            extract = .adapt_cell_proportions, analysis_types = character()),
    seurat = list(detect = function(x) inherits(x, "Seurat"),
                  extract = .adapt_seurat, analysis_types = character()),
    single_cell_experiment = list(detect = function(x) inherits(x, "SingleCellExperiment"),
                                  extract = .adapt_sce, analysis_types = character()),
    summarized_experiment = list(detect = function(x) inherits(x, "SummarizedExperiment"),
                                 extract = .adapt_se, analysis_types = character()),
    expression_set = list(detect = function(x) inherits(x, "ExpressionSet"),
                          extract = .adapt_expression_set, analysis_types = character()),
    ggplot = list(detect = function(x) inherits(x, "ggplot"),
                  extract = .adapt_ggplot, analysis_types = character()),
    prcomp = list(detect = function(x) inherits(x, "prcomp"),
                  extract = .adapt_prcomp, analysis_types = character()),
    de_table = list(detect = .detect_de_table, extract = .adapt_de_table,
                    analysis_types = c("differential_expression", "de", "markers")),
    enrichment_table = list(detect = .detect_enrichment_table, extract = .adapt_enrichment_table,
                            analysis_types = c("enrichment", "enrichment_ora", "enrichment_gsea")),
    cell_metadata = list(detect = function(x) FALSE, extract = .adapt_cell_metadata,
                         analysis_types = c("single_cell", "cell_metadata")),
    generic = list(detect = function(x) TRUE, extract = .adapt_generic,
                   analysis_types = "generic")
  )
}

.adapter_list <- function() {
  b <- .builtin_adapters()
  b <- lapply(names(b), function(n) c(b[[n]], list(name = n, builtin = TRUE)))
  names(b) <- vapply(b, `[[`, "", "name")
  c(.pkg_env$adapters, b[setdiff(names(b), names(.pkg_env$adapters))])
}

.select_adapter <- function(x, analysis_type = NULL, adapter = NULL) {
  all <- .adapter_list()
  if (!is.null(adapter)) {
    if (!adapter %in% names(all)) stop("Unknown adapter '", adapter, "'. See bio_adapters().", call. = FALSE)
    return(all[[adapter]])
  }
  detects <- function(a) tryCatch(isTRUE(a$detect(x)), error = function(e) FALSE)
  pattern_based <- c("de_table", "enrichment_table", "cell_metadata", "generic")
  # 1. Class-based adapters (and user adapters): the class is stronger
  #    evidence than a hint.
  for (a in all) {
    if (a$name %in% pattern_based) next
    if (detects(a)) return(a)
  }
  # 2. An explicit analysis_type selects among table adapters.
  if (!is.null(analysis_type)) {
    for (a in all) if (analysis_type %in% a$analysis_types) return(a)
    stop("No adapter declares analysis_type '", analysis_type, "'. See bio_adapters().", call. = FALSE)
  }
  # 3. Column-pattern detection, then generic fallback.
  for (n in c("de_table", "enrichment_table")) if (detects(all[[n]])) return(all[[n]])
  all[["generic"]]
}

#' Build an inspectable context from an analysis object
#'
#' Dispatches \code{x} to an adapter (see \code{\link{bio_adapters}}) that
#' computes deterministic facts \emph{from the full input}, then keeps only a
#' few top rows. User-supplied study context is stored with the result.
#'
#' Plain data.frames are recognised by column patterns; the resulting
#' \code{source_status} is \code{"inferred_from_columns"} unless
#' \code{source_package} is supplied, because column names alone cannot prove
#' which package produced a table.
#'
#' @param x Object: DE table, \code{DESeqResults}, enrichment table,
#'   \code{enrichResult}, \code{gseaResult}, \code{Seurat},
#'   \code{SingleCellExperiment}, \code{SummarizedExperiment}, limma
#'   \code{MArrayLM}, edgeR \code{TopTags}/\code{DGEExact}/\code{DGELRT},
#'   \code{compareClusterResult}, \code{bio_cell_proportions}, \code{ggplot},
#'   \code{prcomp}, \code{Biobase::ExpressionSet}, or anything else (generic summary).
#' @param analysis_type Optional explicit type to select an adapter for
#'   ambiguous tables (\code{"differential_expression"}, \code{"enrichment"},
#'   \code{"enrichment_ora"}, \code{"enrichment_gsea"}, \code{"single_cell"},
#'   \code{"generic"}).
#' @param adapter Optional adapter name, overrides detection.
#' @param species,tissue,contrast,gene_id_type,design,background Free-text
#'   study context supplied by the user.
#' @param source_package Declare the producing package (sets
#'   \code{source_status = "user_declared"} for tables).
#' @param thresholds List with \code{padj} (default 0.05), \code{lfc}
#'   (absolute log2 fold-change cut-off, default 0) and \code{p} (raw p cut-off
#'   used only for explicitly labelled raw counts, default 0.05).
#' @param p_adjust_method If the table has raw p-values only, optionally a
#'   \code{\link[stats]{p.adjust}} method (e.g. \code{"BH"}) to compute FDR
#'   explicitly. Default \code{NULL}: no FDR is invented.
#' @param coefficient For \code{limma} \code{MArrayLM} fits with several
#'   coefficients/contrasts: the single coefficient (name or index) to explain.
#'   Required when the fit has more than one; ignored by other objects.
#' @param n_top Number of top rows to keep.
#' @param data_dependencies Character vector naming upstream objects this
#'   result derives from (e.g. \code{"deg"} for an enrichment of DE genes).
#' @param notes Free-text user notes.
#' @param language \code{"en"} (default) or \code{"zh"}: language of the
#'   generated caveats (\code{uncertainty}). Facts are identical in both
#'   languages. The value is stored in \code{ctx$language}. Any other value is
#'   an error.
#' @param scope Optional known dataset, analysis, comparison, sample or modality scope.
#' @param fact_descriptors Optional descriptions of fact paths and completeness.
#' @param modalities Optional modality summary for a joint context.
#' @param schema_version Context contract version.
#' @param ... Passed to the adapter, e.g. \code{cluster_col}, \code{sample_col},
#'   \code{group_col}, \code{batch_col} for single-cell / SummarizedExperiment
#'   objects, or \code{group_col} for per-cluster marker or compareCluster tables.
#' @return A \code{bio_context}.
#' @export
#' @examples
#' set.seed(1)
#' de <- data.frame(gene = paste0("G", 1:200), log2FoldChange = rnorm(200),
#'                  pvalue = runif(200), padj = runif(200))
#' ctx <- bio_context(de, species = "Homo sapiens", contrast = "treated vs control")
#' ctx
#' ctx$facts$n_significant
bio_context <- function(x, analysis_type = NULL, adapter = NULL, species = NULL,
                        tissue = NULL, contrast = NULL, gene_id_type = NULL,
                        design = NULL, background = NULL, source_package = NULL,
                         thresholds = list(), p_adjust_method = NULL, coefficient = NULL,
                         n_top = 10, data_dependencies = NULL, notes = NULL,
                         language = NULL, scope = NULL,
                         fact_descriptors = NULL, modalities = NULL,
                         schema_version = "1.0", ...) {
  language <- .resolve_language(language, .pkg_env$config)
  if (inherits(x, "bio_context")) return(x)
  .local_language(language)
  th <- utils::modifyList(list(padj = 0.05, lfc = 0, p = 0.05), thresholds)
  for (name in c("padj", "p", "lfc")) {
    value <- th[[name]]
    if (!is.numeric(value) || length(value) != 1 || is.na(value) || !is.finite(value) ||
        value < 0 || (name != "lfc" && value > 1)) {
      stop("Invalid threshold '", name, "'.", call. = FALSE)
    }
  }
  if (!is.numeric(n_top) || length(n_top) != 1 || is.na(n_top) || !is.finite(n_top) ||
      n_top < 0 || n_top != floor(n_top)) stop("n_top must be a non-negative whole number.", call. = FALSE)
  attr(th, "user_set") <- names(thresholds)
  meta <- list(species = species, tissue = tissue, contrast = contrast,
               gene_id_type = gene_id_type, design = design, background = background,
               source_package = source_package, data_dependencies = data_dependencies,
               notes = notes, analysis_type_hint = analysis_type, coefficient = coefficient,
                scope = scope)
  meta <- meta[!vapply(meta, is.null, logical(1))]
  a <- .select_adapter(x, analysis_type, adapter)
  ctx <- a$extract(x, meta = meta, n_top = n_top, thresholds = th,
                   p_adjust_method = p_adjust_method, analysis_type = analysis_type, ...)
  if (!inherits(ctx, "bio_context")) stop("Adapter '", a$name, "' did not return a bio_context.", call. = FALSE)
  if (!is.null(source_package) && ctx$source_status %in% c("inferred_from_columns", "unknown")) {
    ctx$source_package <- source_package
    ctx$source_status <- "user_declared"
  }
  ctx$adapter <- a$name
  ctx$language <- language
  ctx$schema_version <- as.character(schema_version)[1L]
  if (!is.null(scope)) ctx$scope <- scope
  if (!is.null(design)) ctx$design <- design
  if (!is.null(fact_descriptors)) ctx$fact_descriptors <- fact_descriptors
  if (!is.null(modalities)) ctx$modalities <- modalities
  ctx$metadata <- utils::modifyList(ctx$metadata %||% list(), meta)
  if (is.null(meta$species)) ctx$uncertainty <- c(ctx$uncertainty,
    "No species was provided, so the user must confirm the species background for any biological interpretation." %L%
      "\u672a\u63d0\u4f9b\u7269\u79cd\uff08species\uff09\uff0c\u751f\u7269\u5b66\u89e3\u91ca\u9700\u8981\u7528\u6237\u786e\u8ba4\u7269\u79cd\u80cc\u666f\u3002")
  ctx$provenance <- utils::modifyList(list(
    adapter = a$name,
    created = .now(),
    bioexplainr_version = .this_version(),
    thresholds = th,
    p_adjust_method = p_adjust_method,
    n_top = n_top,
    input_summary = .object_summary(x)
  ), ctx$provenance %||% list())
  ctx$uncertainty <- unique(ctx$uncertainty)
  .finalize_context(ctx)
}

#' @export
print.bio_context <- function(x, ...) {
  cat("<bio_context>", x$analysis_type, "\n")
  cat("  source  :", paste(x$source_class, collapse = "/"),
      "| package:", x$source_package %||% NA, "| status:", x$source_status, "\n")
  cat("  adapter :", x$adapter, "\n")
  md <- x$metadata[setdiff(names(x$metadata), "analysis_type_hint")]
  if (length(md)) {
    cat("  context :", paste(names(md), vapply(md, function(v) paste(v, collapse = ", "), ""),
                             sep = "=", collapse = "; "), "\n")
  }
  cat("  facts:\n")
  f <- x$facts
  for (n in names(f)) {
    v <- f[[n]]
    if (is.list(v)) v <- unlist(v)
    if (is.numeric(v)) v <- .fmt_num(v, 4)
    if (length(v) > 6) v <- c(utils::head(v, 6), "...")
    cat("    ", n, ": ", paste(v, collapse = ", "), "\n", sep = "")
  }
  if (!is.null(x$top_features) && nrow(x$top_features)) {
    cat("  top features (", nrow(x$top_features), " rows):\n", sep = "")
    print(utils::head(x$top_features, 5), row.names = FALSE)
  }
  if (length(x$uncertainty)) {
    cat("  uncertainty:\n")
    for (u in x$uncertainty) cat("    - ", u, "\n", sep = "")
  }
  invisible(x)
}

#' Bounded, privacy-preserving payload for a model
#'
#' Converts a \code{bio_context} into a JSON-ready list. It contains the
#' deterministic facts, at most \code{max_top} top feature rows, plot mapping,
#' user study context and caveats. It never contains raw matrices, cell
#' barcodes, sample names or patient identifiers. If the JSON is longer than
#' \code{max_chars}, top features are dropped progressively.
#'
#' @param ctx A \code{bio_context}.
#' @param max_top Maximum number of top feature rows.
#' @param max_chars Maximum JSON length.
#' @param include_features Include top feature rows.
#' @param policy Optional \code{bio_payload_policy}; an explicit policy can
#'   require complete facts or select an explicit chunked mode.
#' @return A list (use \code{jsonlite::toJSON(auto_unbox = TRUE)} to view).
#' @export
#' @examples
#' de <- data.frame(log2FoldChange = c(2, -1, 0.1), padj = c(0.001, 0.02, 0.9),
#'                  row.names = c("IL6", "CXCL8", "ACTB"))
#' str(bio_context_payload(bio_context(de)))
bio_context_payload <- function(ctx, max_top = 10, max_chars = 12000, include_features = TRUE,
                                policy = NULL) {
  stopifnot(inherits(ctx, "bio_context"))
  legacy_policy <- is.null(policy)
  # The original positional API progressively reduced previews and then long
  # fact vectors. Keep that read/write behaviour for old callers; callers that
  # need the W02 completeness guarantee pass an explicit policy with
  # fact_mode = "complete".
  policy <- policy %||% bio_payload_policy(max_top = max_top, max_chars = max_chars,
                                           include_features = include_features,
                                           fact_mode = "chunked")
  if (!inherits(policy, "bio_payload_policy")) stop("policy must be a bio_payload_policy.", call. = FALSE)
  max_top <- policy$max_top
  max_chars <- policy$max_chars
  include_features <- policy$include_features
  if (!is.numeric(max_chars) || length(max_chars) != 1 || is.na(max_chars) ||
      !is.finite(max_chars) || max_chars <= 0) stop("max_chars must be positive and finite.", call. = FALSE)
  tf <- if (include_features && !is.null(ctx$top_features)) utils::head(ctx$top_features, max_top) else NULL
  md <- .payload_metadata(ctx$metadata, policy)
  build <- function(tf) list(
    schema_version = ctx$schema_version %||% "legacy",
    context_id = ctx$context_id %||% NA_character_,
    analysis_type = ctx$analysis_type,
    source = list(class = ctx$source_class, package = ctx$source_package %||% NA,
                  status = ctx$source_status),
    study_context = md,
    facts = ctx$facts,
    fact_descriptors = ctx$fact_descriptors %||% list(),
    scope = ctx$scope %||% list(),
    design = ctx$design %||% list(),
    top_features = tf,
    plot_mapping = ctx$plot_mapping,
    thresholds = ctx$provenance$thresholds,
    uncertainty = ctx$uncertainty
  )
  p <- build(tf)
  while (!is.null(tf) && nchar(.json(p)) > max_chars && nrow(tf) > 0) {
    tf <- if (nrow(tf) > 1) utils::head(tf, floor(nrow(tf) / 2)) else NULL
    p <- build(tf)
  }
  if (nchar(.json(p)) > max_chars) {
    p$plot_mapping <- NULL
    # Descriptors are useful in manifests and reports, but are optional in the
    # legacy bounded prompt. Do not let their recursive bookkeeping consume the
    # budget needed for the actual facts.
    p$fact_descriptors <- NULL
    if (identical(policy$fact_mode, "complete")) {
    stop("Context summary exceeds max_chars; complete context facts do not fit. Increase the explicit limit or choose fact_mode = 'chunked'.",
           call. = FALSE)
    }
    p$facts <- lapply(p$facts, function(v) if (length(v) > policy$max_fact_items) utils::head(v, policy$max_fact_items) else v)
    p$completeness <- list(status = "partial", reason = "fact_items_reduced",
                           omitted_fact_paths = names(ctx$facts)[vapply(ctx$facts, length, integer(1)) > policy$max_fact_items])
    # Legacy callers expect a bounded JSON value. Continue reducing preview
    # vectors only after the full facts have been attempted and retain scalar
    # facts such as n_features whenever possible.
    while (nchar(.json(p)) > max_chars) {
      sizes <- vapply(p$facts, length, integer(1))
      candidates <- which(sizes > 1L)
      if (!length(candidates)) break
       j <- candidates[which.max(sizes[candidates])]
       p$completeness$omitted_fact_paths <- unique(c(p$completeness$omitted_fact_paths, names(p$facts)[j]))
      p$facts[[j]] <- utils::head(p$facts[[j]], max(1L, floor(sizes[j] / 2L)))
    }
  }
  if (nchar(.json(p)) > max_chars) {
    stop("Context summary exceeds max_chars; shorten study metadata or increase the explicit limit.", call. = FALSE)
  }
  p$completeness <- p$completeness %||% list(status = "complete", reason = NULL,
                                              omitted_fact_paths = character())
   before <- p
   p <- .payload_sanitize(p, policy)
   omitted <- character()
   removed <- function(a, b, prefix = "") {
     if (!is.list(a)) return(invisible(NULL))
     for (nm in names(a)) {
       field <- paste0(prefix, nm)
       if (!nm %in% names(b)) omitted <<- c(omitted, field)
       else removed(a[[nm]], b[[nm]], paste0(field, "."))
     }
   }
   removed(before, p)
   if (!identical(tf, ctx$top_features)) omitted <- c(omitted, "top_features.preview_rows")
   if (is.null(before$plot_mapping) && !is.null(ctx$plot_mapping)) omitted <- c(omitted, "plot_mapping")
   if (is.null(before$fact_descriptors)) omitted <- c(omitted, "fact_descriptors")
   if (length(ctx$metadata)) omitted <- c(omitted, paste0("study_context.", setdiff(names(ctx$metadata), names(md))))
   p$completeness$omitted_fields <- unique(.sensitive_value(omitted))
   if (nchar(.json(p)) > max_chars) stop("Context summary exceeds max_chars after omission accounting; increase the explicit limit.", call. = FALSE)
  attr(p, "payload_hash") <- .sha256(.canonical_json(p))
  attr(p, "policy_id") <- policy$policy_id
  p
}
