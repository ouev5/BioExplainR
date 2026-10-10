# Reproducible common bioinformatics plots -----------------------------------

utils::globalVariables(c("PC1", "PC2", "UMAP1", "UMAP2", "x_value", "neglog10_p",
                         "feature", "value", "sample", "term", "count", "group",
                         "sample_group"))

.require_ggplot2 <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("This plotting function requires the optional package 'ggplot2'. Install it with install.packages('ggplot2').",
         call. = FALSE)
  }
}

.plot_matrix <- function(x, feature_axis = c("rows", "columns"), transform = c("none", "log1p")) {
  feature_axis <- match.arg(feature_axis)
  transform <- match.arg(transform)
  if (is.data.frame(x)) {
    keep <- vapply(x, is.numeric, logical(1))
    if (!any(keep)) stop("x must contain numeric expression columns.", call. = FALSE)
    x <- as.matrix(x[, keep, drop = FALSE])
  } else if (is.matrix(x) || inherits(x, "Matrix")) {
    x <- as.matrix(x)
  } else stop("x must be a numeric matrix or data.frame.", call. = FALSE)
  if (!is.numeric(x) || any(!is.finite(x))) {
    stop("x contains non-finite values; clean or impute them before plotting.", call. = FALSE)
  }
  if (!nrow(x) || !ncol(x)) stop("x must have at least one row and one column.", call. = FALSE)
  if (feature_axis == "columns") x <- t(x)
  if (transform == "log1p") {
    if (any(x < 0, na.rm = TRUE)) stop("log1p transformation requires non-negative values.", call. = FALSE)
    x <- log1p(x)
  }
  x
}

.plot_group <- function(metadata, group, n, default = "All samples") {
  if (is.null(group) && is.null(metadata)) return(rep(default, n))
  if (is.character(group) && length(group) == 1L && !is.null(metadata) && group %in% names(metadata)) {
    group <- metadata[[group]]
  } else if (is.character(group) && length(group) == 1L && is.null(metadata)) {
    return(rep(group, n))
  }
  if (is.null(group) && !is.null(metadata) && ncol(metadata)) group <- metadata[[1L]]
  if (length(group) != n) stop("group/metadata must have one value per observation.", call. = FALSE)
  as.factor(group)
}

.plot_metadata <- function(metadata, n, group, row_names = NULL) {
  if (is.null(metadata)) {
    return(data.frame(group = .plot_group(NULL, group, n), stringsAsFactors = FALSE))
  }
  metadata <- as.data.frame(metadata, stringsAsFactors = FALSE)
  if (nrow(metadata) != n) stop("metadata must have one row per observation.", call. = FALSE)
  if (!is.null(row_names) && .has_rn(metadata)) {
    if (anyDuplicated(row_names) || anyDuplicated(rownames(metadata)) ||
        !setequal(row_names, rownames(metadata))) {
      stop("metadata row names must match observation names uniquely.", call. = FALSE)
    }
    metadata <- metadata[match(row_names, rownames(metadata)), , drop = FALSE]
  }
  metadata$group <- .plot_group(metadata, group, n)
  metadata
}

.plot_theme <- function() {
  ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                   legend.position = "right")
}

#' Plot sample-level PCA from an expression matrix
#'
#' Rows are features and columns are samples by default. PCA is calculated by
#' R with \code{stats::prcomp}; the returned ggplot stores the scores and the
#' \code{prcomp} object in attributes for later inspection by BioExplainR.
#'
#' @param x Numeric matrix or data.frame.
#' @param metadata Optional data.frame with one row per sample.
#' @param group A metadata column name or vector used for colour.
#' @param feature_axis Whether features are in rows or columns.
#' @param transform \code{"none"} or \code{"log1p"}.
#' @param center,scale. Passed to \code{stats::prcomp}.
#' @param n_top_features Keep at most this many most variable features.
#' @return A \code{ggplot2} object with \code{bio_plot_type = "pca_plot"}.
#' @export
bio_plot_pca <- function(x, metadata = NULL, group = NULL,
                         feature_axis = c("rows", "columns"),
                         transform = c("none", "log1p"), center = TRUE,
                         scale. = FALSE, n_top_features = 500) {
  .require_ggplot2()
  x <- .plot_matrix(x, feature_axis, transform)
  if (!is.numeric(n_top_features) || length(n_top_features) != 1L ||
       is.na(n_top_features) || !is.finite(n_top_features) ||
       n_top_features < 1 || n_top_features != floor(n_top_features)) {
    stop("n_top_features must be a positive whole number.", call. = FALSE)
  }
  v <- apply(x, 1L, stats::var)
  keep <- which(is.finite(v) & v > 0)
  keep <- keep[order(v[keep], decreasing = TRUE)]
  x <- x[utils::head(keep, n_top_features), , drop = FALSE]
  if (ncol(x) < 2L) stop("PCA needs at least two samples/observations.", call. = FALSE)
  if (nrow(x) < 2L) stop("PCA needs at least two non-constant features.", call. = FALSE)
  fit <- tryCatch(stats::prcomp(t(x), center = center, scale. = scale.),
                  error = function(e) stop("PCA failed: ", conditionMessage(e), call. = FALSE))
  ve <- fit$sdev^2 / sum(fit$sdev^2)
  md <- .plot_metadata(metadata, nrow(fit$x), group, rownames(fit$x))
  scores <- data.frame(PC1 = fit$x[, 1L], PC2 = if (ncol(fit$x) > 1L) fit$x[, 2L] else 0,
                       md, check.names = FALSE, stringsAsFactors = FALSE)
  p <- ggplot2::ggplot(scores, ggplot2::aes(x = PC1, y = PC2, colour = group)) +
    ggplot2::geom_point(size = 3, alpha = 0.9) +
    ggplot2::labs(x = paste0("PC1 (", round(100 * ve[1L], 1), "%)"),
                  y = paste0("PC2 (", round(100 * ve[min(2L, length(ve))], 1), "%)"),
                  colour = "Group" %L% "\u5206\u7ec4", title = "PCA") + .plot_theme()
  attr(p, "bio_plot_type") <- "pca_plot"
  attr(p, "bio_plot_data") <- scores
  attr(p, "bio_plot_source") <- list(prcomp = fit, variance_explained = ve,
                                       feature_count = nrow(x), transform = transform,
                                       feature_axis = match.arg(feature_axis),
                                       n_top_features = n_top_features, center = center, scale = scale.)
  p
}

#' Plot a UMAP or another two-dimensional embedding
#'
#' If \code{x} already has at least two columns, its first two columns are
#' treated as coordinates. For an expression matrix, the optional \code{uwot}
#' package is used to calculate UMAP.
#'
#' @param x A two-column embedding or an expression matrix.
#' @param metadata Optional data.frame with one row per observation.
#' @param group A metadata column name or vector used for colour.
#' @param method Label for the embedding, usually \code{"UMAP"}.
#' @param reduction Optional reduction name when \\code{x} is a Seurat or
#'   SingleCellExperiment object. The first available reduction is used when
#'   omitted.
#' @param feature_axis Orientation when \code{x} is an expression matrix.
#' @param input_type Explicitly choose coordinates or expression values. In
#'   \code{"auto"} mode, at most three numeric columns are treated as coordinates.
#' @param ... Passed to \code{uwot::umap} for calculated embeddings.
#' @return A \code{ggplot2} object.
#' @export
bio_plot_umap <- function(x, metadata = NULL, group = NULL, method = "UMAP",
                          reduction = NULL,
                          feature_axis = c("rows", "columns"),
                          input_type = c("auto", "embedding", "expression"), ...) {
  .require_ggplot2()
  input_type <- match.arg(input_type)
  embedding <- NULL
  if (inherits(x, "Seurat")) {
    reductions <- if (requireNamespace("SeuratObject", quietly = TRUE))
      tryCatch(SeuratObject::Reductions(x), error = function(e) character()) else character()
    red_name <- reduction %||% reductions[1L]
    red <- tryCatch(.slot_or(.slot_or(x, "reductions")[[red_name]], "cell.embeddings"),
                    error = function(e) NULL)
    if (!is.null(red)) {
      embedding <- as.matrix(red)[, seq_len(min(2L, ncol(red))), drop = FALSE]
      if (is.null(metadata)) metadata <- tryCatch(as.data.frame(.slot_or(x, "meta.data")), error = function(e) NULL)
    }
  } else if (inherits(x, "SingleCellExperiment") && requireNamespace("SingleCellExperiment", quietly = TRUE)) {
    reductions <- tryCatch(SingleCellExperiment::reducedDimNames(x), error = function(e) character())
    red_name <- reduction %||% reductions[1L]
    red <- tryCatch(SingleCellExperiment::reducedDim(x, red_name), error = function(e) NULL)
    if (!is.null(red)) {
      embedding <- as.matrix(red)[, seq_len(min(2L, ncol(red))), drop = FALSE]
      if (is.null(metadata) && requireNamespace("SummarizedExperiment", quietly = TRUE))
        metadata <- as.data.frame(SummarizedExperiment::colData(x))
    }
  } else if (is.data.frame(x)) {
    keep <- vapply(x, is.numeric, logical(1))
    if (input_type != "expression" && sum(keep) >= 2L &&
        (input_type == "embedding" || sum(keep) <= 3L)) embedding <- as.matrix(x[, which(keep)[seq_len(2L)], drop = FALSE])
  } else if (is.matrix(x) || inherits(x, "Matrix")) {
    z <- as.matrix(x)
    if (input_type != "expression" && ncol(z) >= 2L &&
        (input_type == "embedding" || ncol(z) <= 3L)) embedding <- z[, seq_len(2L), drop = FALSE]
  }
  if (is.null(embedding)) {
    if (input_type == "embedding") stop("No two-dimensional embedding was found.", call. = FALSE)
    if (!requireNamespace("uwot", quietly = TRUE)) {
      stop("Calculating UMAP from an expression matrix requires the optional package 'uwot'; alternatively supply a two-column embedding.", call. = FALSE)
    }
    z <- .plot_matrix(x, feature_axis, "none")
    embedding <- uwot::umap(t(z), ...)
  }
  if (ncol(embedding) < 2L || nrow(embedding) < 2L) stop("An embedding needs at least two rows and two coordinates.", call. = FALSE)
  if (any(!is.finite(embedding))) stop("Embedding coordinates must be finite.", call. = FALSE)
  md <- .plot_metadata(metadata, nrow(embedding), group, rownames(embedding))
  dat <- data.frame(UMAP1 = embedding[, 1L], UMAP2 = embedding[, 2L], md,
                    stringsAsFactors = FALSE, check.names = FALSE)
  p <- ggplot2::ggplot(dat, ggplot2::aes(x = UMAP1, y = UMAP2, colour = group)) +
    ggplot2::geom_point(size = 2.2, alpha = 0.85) +
    ggplot2::labs(x = paste0(method, "1"), y = paste0(method, "2"), colour = "Group" %L% "\u5206\u7ec4",
                  title = method) + .plot_theme()
  attr(p, "bio_plot_type") <- "embedding_plot"
  attr(p, "bio_plot_data") <- dat
  attr(p, "bio_plot_source") <- list(method = method, coordinates = embedding)
  p
}

#' Plot enrichment results as a dot/bubble plot
#'
#' Supports common clusterProfiler-style columns including \code{Description},
#' \code{GeneRatio}, \code{p.adjust}, \code{Count} and \code{NES}.
#'
#' @param x Enrichment result data.frame or compatible object.
#' @param top_n Number of rows to display, ordered by adjusted p-value.
#' @param term_col,ratio_col,p_col,count_col Optional column names.
#' @return A \code{ggplot2} object.
#' @export
bio_plot_enrichment <- function(x, top_n = 20, term_col = NULL, ratio_col = NULL,
                                p_col = NULL, count_col = NULL) {
  .require_ggplot2()
  if (length(top_n) != 1L || !is.numeric(top_n) || !is.finite(top_n) ||
      top_n < 1 || top_n != floor(top_n)) stop("top_n must be a positive whole number.", call. = FALSE)
  if (!is.data.frame(x)) {
    x <- tryCatch(as.data.frame(x), error = function(e) NULL)
  }
  if (is.null(x) || !nrow(x)) stop("x must be a non-empty enrichment result table.", call. = FALSE)
  pick <- function(value, aliases, required = TRUE) {
    value <- value %||% .find_col(x, aliases)
    if ((required && is.null(value)) || (!is.null(value) && !value %in% names(x))) stop("Could not find the required enrichment column.", call. = FALSE)
    value
  }
  term_col <- pick(term_col, c("Description", "description", "Term", "term", "ID"))
  ratio_col <- pick(ratio_col, c("GeneRatio", "geneRatio", "Ratio"), required = FALSE)
  p_col <- pick(p_col, c("p.adjust", "padj", "FDR", "qvalue", "pvalue"))
  count_col <- pick(count_col, c("Count", "count", "n_genes"), required = FALSE)
  ratio <- if (!is.null(ratio_col)) {
    v <- as.character(x[[ratio_col]])
    z <- suppressWarnings(as.numeric(v))
    frac <- grepl("^[0-9]+\\s*/\\s*[0-9]+$", v)
    z[frac] <- vapply(strsplit(gsub("\\s", "", v[frac]), "/", fixed = TRUE),
                       function(q) as.numeric(q[1L]) / as.numeric(q[2L]), numeric(1))
    z
  } else rep(NA_real_, nrow(x))
  pval <- suppressWarnings(as.numeric(x[[p_col]]))
  count <- if (!is.null(count_col)) suppressWarnings(as.numeric(x[[count_col]])) else ratio
  term <- as.character(x[[term_col]])
  id_col <- .find_col(x, .enrich_aliases$id)
  dat <- data.frame(term = term, ratio = ratio, padj = pval, count = count,
                    term_id = if (!is.null(id_col)) as.character(x[[id_col]]) else term,
                    stringsAsFactors = FALSE)
  if (any(!is.na(pval) & (!is.finite(pval) | pval < 0 | pval > 1))) stop("p values must be between zero and one.", call. = FALSE)
  dat$neglog10_p <- -log10(pmax(dat$padj, .Machine$double.xmin))
  dat <- dat[order(dat$padj, -dat$count, na.last = TRUE), , drop = FALSE]
  dat <- utils::head(dat, top_n)
  dat$term <- factor(dat$term, levels = rev(unique(dat$term)))
  xlab <- if (all(is.na(dat$ratio))) "Count" else "GeneRatio"
  dat$x_value <- if (all(is.na(dat$ratio))) dat$count else dat$ratio
  p <- ggplot2::ggplot(dat, ggplot2::aes(x = x_value, y = term, colour = neglog10_p, size = count)) +
    ggplot2::geom_point(alpha = 0.9, na.rm = TRUE) +
    ggplot2::scale_colour_viridis_c(option = "C", na.value = "grey70") +
    ggplot2::labs(x = xlab, y = NULL, colour = "-log10(p)", size = "Count",
                  title = "Enrichment dot plot" %L% "\u5bcc\u96c6\u6c14\u6ce1\u56fe") + .plot_theme()
  attr(p, "bio_plot_type") <- "enrichment_dotplot"
  attr(p, "bio_plot_data") <- dat
  attr(p, "bio_plot_source") <- list(term = term_col, ratio = ratio_col, p = p_col, count = count_col,
                                     id = id_col, p_floor = .Machine$double.xmin)
  p
}

#' Plot a bounded expression heatmap
#'
#' Rows are features and columns are samples. The most variable rows are shown
#' when the input contains more than \code{top_n} features.
#'
#' @param x Numeric matrix or data.frame.
#' @param metadata Optional sample metadata; its first column is used to facet
#'   sample columns when supplied.
#' @param feature_axis Orientation of features and samples.
#' @param top_n Maximum number of features to draw.
#' @param scale_rows If \code{TRUE}, z-score each feature before plotting.
#' @return A \code{ggplot2} object.
#' @export
bio_plot_heatmap <- function(x, metadata = NULL, feature_axis = c("rows", "columns"),
                             top_n = 50, scale_rows = TRUE) {
  .require_ggplot2()
  z <- .plot_matrix(x, feature_axis, "none")
  if (!is.numeric(top_n) || length(top_n) != 1L || is.na(top_n) ||
      top_n < 1 || top_n != floor(top_n)) stop("top_n must be a positive whole number.", call. = FALSE)
  if (nrow(z) > top_n) {
    v <- apply(z, 1L, stats::var, na.rm = TRUE)
    z <- z[order(v, decreasing = TRUE)[seq_len(top_n)], , drop = FALSE]
  }
  if (isTRUE(scale_rows)) {
    z <- t(scale(t(z)))
    z[!is.finite(z)] <- 0
  }
  dat <- expand.grid(feature = rownames(z) %||% paste0("feature_", seq_len(nrow(z))),
                     sample = colnames(z) %||% paste0("sample_", seq_len(ncol(z))),
                     stringsAsFactors = FALSE)
  dat$value <- as.vector(z)
  if (!is.null(metadata)) {
     md <- .plot_metadata(metadata, ncol(z), NULL, colnames(z))
     dat$sample_group <- rep(as.character(md$group), each = nrow(z))
  }
  p <- ggplot2::ggplot(dat, ggplot2::aes(x = sample, y = feature, fill = value)) +
    ggplot2::geom_tile() + ggplot2::scale_fill_gradient2(low = "#2166ac", mid = "white", high = "#b2182b") +
    ggplot2::labs(x = NULL, y = NULL, fill = if (scale_rows) "z-score" else "value", title = "Expression heatmap" %L% "\u8868\u8fbe\u70ed\u56fe") +
    .plot_theme() + ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
  if ("sample_group" %in% names(dat)) {
    p <- p + ggplot2::facet_grid(. ~ sample_group, scales = "free_x", space = "free_x")
  }
  attr(p, "bio_plot_type") <- "heatmap_like"
  attr(p, "bio_plot_data") <- dat
  attr(p, "bio_plot_source") <- list(feature_count = nrow(z), sample_count = ncol(z), scale_rows = scale_rows)
  p
}

#' Choose a common BioExplainR plot from an input object
#'
#' @param x Input object.
#' @param type One of \code{auto}, \code{pca}, \code{umap}, \code{enrichment},
#'   \code{heatmap} or \code{existing}.
#' @param ... Passed to the selected plotting function.
#' @return A \code{ggplot2} object.
#' @export
bio_plot <- function(x, type = c("auto", "pca", "umap", "enrichment", "heatmap", "existing"), ...) {
  type <- match.arg(type)
  if (type == "existing" || (type == "auto" && inherits(x, "ggplot"))) return(x)
  if (type == "auto") {
    type <- if (is.matrix(x) || inherits(x, "Matrix")) "pca" else if (is.data.frame(x) &&
      any(names(x) %in% c("Description", "GeneRatio", "p.adjust", "NES"))) "enrichment" else "heatmap"
  }
  switch(type,
         pca = bio_plot_pca(x, ...),
         umap = bio_plot_umap(x, ...),
         enrichment = bio_plot_enrichment(x, ...),
         heatmap = bio_plot_heatmap(x, ...),
         existing = x)
}
