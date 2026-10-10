# ggplot and generic adapters ----------------------------------------------------

.aes_text <- function(m) {
  if (is.null(m)) return(NULL)
  vapply(m, function(q) {
    txt <- tryCatch({
      if (requireNamespace("rlang", quietly = TRUE)) rlang::as_label(q)
      else paste(deparse(q[[length(q)]]), collapse = "")
    }, error = function(e) paste(deparse(q), collapse = ""))
    .truncate_chr(txt, 80)
  }, character(1))
}

.adapt_ggplot <- function(x, meta = list(), n_top = 10, ...) {
  data <- x$data
  data_summary <- if (is.data.frame(data)) {
    list(n_rows = nrow(data), n_cols = ncol(data),
         columns = if (ncol(data) <= 40 && !.looks_matrix_like(data))
           vapply(data, function(col) class(col)[1], character(1)) else NULL)
  } else list(n_rows = NA, note = "no global data (layers may carry their own data)")
  global_aes <- .aes_text(x$mapping)
  layers <- lapply(x$layers, function(l) {
    list(
      geom = class(l$geom)[1],
      stat = class(l$stat)[1],
      position = class(l$position)[1],
      aes = .aes_text(l$mapping),
      inherit_aes = isTRUE(l$inherit.aes),
      own_data = is.data.frame(l$data),
      fixed_params = {
        p <- l$aes_params
        if (length(p)) vapply(p, function(v) paste(utils::head(format(v), 3), collapse = ","), "") else NULL
      }
    )
  })
  facet_class <- class(x$facet)[1]
  facet_vars <- tryCatch({
    fp <- x$facet$params
    c(names(fp$facets), names(fp$rows), names(fp$cols))
  }, error = function(e) NULL)
  labels <- tryCatch({
    lb <- x$labels
    lb <- lb[vapply(lb, function(v) is.character(v) && length(v) == 1, logical(1))]
    lapply(lb, .truncate_chr, n = 120)
  }, error = function(e) list())
  scales <- tryCatch(vapply(x$scales$scales, function(s) {
    paste0(paste(s$aesthetics, collapse = "/"), ":", class(s)[1],
           if (!is.null(s$trans$name)) paste0("(", s$trans$name, ")") else "")
  }, character(1)), error = function(e) character())
  coord <- class(x$coordinates)[1]

  # Semantic guesses, clearly labelled as guesses.
  all_aes <- c(global_aes, unlist(lapply(layers, `[[`, "aes")))
  x_aes <- all_aes[names(all_aes) == "x"][1]
  y_aes <- all_aes[names(all_aes) == "y"][1]
  geoms <- vapply(layers, `[[`, "", "geom")
  guess <- attr(x, "bio_plot_type") %||% NA_character_
  if (!is.na(x_aes) && !is.na(y_aes)) {
    if (grepl("^lfc$|log2?_?F(old)?_?C|log2FoldChange|avg_log2FC", x_aes, ignore.case = TRUE) &&
        grepl("log10", y_aes) && grepl("p", y_aes, ignore.case = TRUE)) guess <- "volcano_plot"
    else if (grepl("^PC1|PC_1", x_aes) && grepl("^PC2|PC_2", y_aes)) guess <- "pca_plot"
    else if (grepl("UMAP|tSNE|TSNE", x_aes, ignore.case = TRUE)) guess <- "embedding_plot"
    else if (grepl("GeneRatio|Count|NES", x_aes) && grepl("Description|term", y_aes, ignore.case = TRUE)) guess <- "enrichment_dotplot"
  }
  if (is.na(guess) && any(geoms %in% c("GeomBoxplot", "GeomViolin"))) guess <- "distribution_comparison"
  if (is.na(guess) && any(geoms %in% c("GeomTile", "GeomRaster"))) guess <- "heatmap_like"

  facts <- list(n_layers = length(layers), geoms = unname(geoms), coord = coord,
                facet = facet_class, plot_type_guess = guess)
  if (is.data.frame(data)) facts$n_data_rows <- nrow(data)
  plot_source <- attr(x, "bio_plot_source", exact = TRUE)
  plot_data <- attr(x, "bio_plot_data", exact = TRUE)
  if (is.list(plot_source)) {
    if (!is.null(plot_source$variance_explained)) {
      facts$variance_explained <- as.numeric(plot_source$variance_explained)
      facts$n_observations <- if (is.data.frame(plot_data)) nrow(plot_data) else NA_integer_
      facts$n_variables <- plot_source$feature_count %||% NA_integer_
      facts$plot_generated_by <- "bio_plot_pca"
    }
    if (!is.null(plot_source$coordinates)) {
      coords <- plot_source$coordinates
      facts$n_observations <- nrow(coords)
      facts$n_coordinates <- ncol(coords)
      facts$coordinate_ranges <- lapply(seq_len(min(2L, ncol(coords))), function(i) range(coords[, i], na.rm = TRUE))
      facts$plot_generated_by <- "bio_plot_umap"
    }
    if (!is.null(plot_source$feature_count) && identical(guess, "heatmap_like")) {
      facts$n_features <- plot_source$feature_count
      facts$n_samples <- plot_source$sample_count
      facts$scaled_rows <- isTRUE(plot_source$scale_rows)
      facts$plot_generated_by <- "bio_plot_heatmap"
    }
    if (!is.null(plot_source$term) && identical(guess, "enrichment_dotplot")) {
      facts$n_terms <- if (is.data.frame(plot_data)) nrow(plot_data) else NA_integer_
      facts$plot_generated_by <- "bio_plot_enrichment"
    }
  }
  unc <- c("The plot type is guessed from the aes mapping and geometries (plot_type_guess); it does not mean the source has been verified." %L% "\u56fe\u5f62\u7c7b\u578b\u662f\u6839\u636e aes \u6620\u5c04\u4e0e\u51e0\u4f55\u5bf9\u8c61\u63a8\u6d4b\u7684\uff08plot_type_guess\uff09\uff0c\u4e0d\u4ee3\u8868\u6765\u6e90\u5df2\u6838\u5b9e\u3002",
           "Labels and colours in a plot cannot replace the full result table; interpret the plot together with the data object that produced it." %L% "\u56fe\u4e0a\u7684\u6807\u7b7e\u548c\u989c\u8272\u4e0d\u80fd\u66ff\u4ee3\u5b8c\u6574\u7ed3\u679c\u8868\uff1b\u8bf7\u7ed3\u5408\u4ea7\u751f\u8be5\u56fe\u7684\u6570\u636e\u5bf9\u8c61\u4e00\u8d77\u89e3\u91ca\u3002")
  if (identical(guess, "volcano_plot")) {
    unc <- c(unc, "The y axis of a volcano plot is usually -log10(p); confirm whether raw or adjusted p-values were used." %L% "\u706b\u5c71\u56fe\u7eb5\u8f74\u901a\u5e38\u4e3a -log10(p)\uff1b\u9700\u786e\u8ba4\u4f7f\u7528\u7684\u662f\u539f\u59cb p \u503c\u8fd8\u662f\u6821\u6b63\u540e p \u503c\u3002")
  }
  if (identical(guess, "embedding_plot")) unc <- c(unc, "Distances and gaps between clusters on a UMAP/t-SNE should not be interpreted quantitatively." %L% "UMAP/t-SNE \u4e0a\u7684\u8ddd\u79bb\u4e0e\u7c07\u95f4\u95f4\u9694\u4e0d\u5e94\u88ab\u5b9a\u91cf\u89e3\u8bfb\u3002")
  if (length(scales) && any(grepl("log|sqrt|reverse", scales))) {
    unc <- c(unc, "A coordinate transformation (such as log/sqrt/reverse) is present; convert back to the original scale when reading the plot." %L% "\u5b58\u5728\u5750\u6807\u53d8\u6362\uff08\u5982 log/sqrt/reverse\uff09\uff0c\u8bfb\u56fe\u65f6\u9700\u8981\u6362\u7b97\u56de\u539f\u5c3a\u5ea6\u3002")
  }
  new_bio_context(
    analysis_type = "plot", source_class = class(x), source_package = "ggplot2",
    source_status = "verified_class", facts = facts,
    plot_mapping = list(data = data_summary, global_aes = as.list(global_aes), layers = layers,
                        facet_vars = facet_vars, labels = labels, scales = scales),
    uncertainty = unc, metadata = meta
  )
}

.adapt_generic <- function(x, meta = list(), n_top = 10, ...) {
  s <- .object_summary(x)
  facts <- s[setdiff(names(s), "name")]
  unc <- c("There is no dedicated adapter for this object type; only a structural summary is given. Extend it with bio_register_adapter(), or set the table type with analysis_type." %L% "\u6ca1\u6709\u9488\u5bf9\u8be5\u5bf9\u8c61\u7c7b\u578b\u7684\u4e13\u7528\u9002\u914d\u5668\uff1b\u53ea\u7ed9\u51fa\u7ed3\u6784\u6458\u8981\u3002\u53ef\u7528 bio_register_adapter() \u6269\u5c55\uff0c\u6216\u7528 analysis_type \u6307\u5b9a\u8868\u683c\u7c7b\u578b\u3002")
  if (is.matrix(x) || .looks_matrix_like(x)) {
    v <- suppressWarnings(as.numeric(as.matrix(x)))
    if (length(v) && any(!is.na(v))) {
      facts$value_quantiles <- as.list(.q(v))
      facts$n_na <- sum(is.na(v))
      facts$integer_like <- isTRUE(all(abs(v - round(v)) < 1e-8, na.rm = TRUE))
      facts$has_dimnames <- !is.null(dimnames(x))
      facts$fraction_zero <- round(mean(v == 0, na.rm = TRUE), 4)
    }
    facts$column_types <- NULL
    unc <- c(unc, "This looks like an expression/count matrix; row and column names (possibly sample or patient identifiers) and raw values are not sent or written into reports." %L% "\u770b\u8d77\u6765\u662f\u8868\u8fbe/\u8ba1\u6570\u77e9\u9635\uff1b\u884c\u5217\u540d\uff08\u53ef\u80fd\u662f\u6837\u672c\u6216\u60a3\u8005\u6807\u8bc6\uff09\u4e0e\u539f\u59cb\u6570\u503c\u4e0d\u4f1a\u88ab\u53d1\u9001\u6216\u5199\u5165\u62a5\u544a\u3002",
             if (isTRUE(facts$integer_like)) "All values are integers and may be raw counts; normalise them before comparing expression between samples." %L% "\u6570\u503c\u5747\u4e3a\u6574\u6570\uff0c\u53ef\u80fd\u662f\u539f\u59cb\u8ba1\u6570\uff0c\u9700\u6807\u51c6\u5316\u540e\u624d\u80fd\u76f4\u63a5\u6bd4\u8f83\u6837\u672c\u95f4\u8868\u8fbe\u91cf\u3002")
  }
  new_bio_context("generic", class(x), NA_character_, "unknown", facts = facts,
                  metadata = meta, uncertainty = unc)
}
