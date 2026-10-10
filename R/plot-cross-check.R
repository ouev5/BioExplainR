# Plot vs. source-table cross-check ----------------------------------------------------------------

.cc_finding <- function(check, status, detail) {
  data.frame(check = check, status = status, detail = detail, stringsAsFactors = FALSE)
}

.cc_result <- function(findings, plot_columns = NULL, allow_subset = FALSE) {
  st <- findings$status
  status <- if ("fail" %in% st) "fail" else if ("not_checkable" %in% st) "not_checkable" else "pass"
  structure(list(status = status, findings = findings, allow_subset = allow_subset,
                 note = "A pass only means the plotted numbers match the supplied table; it says nothing about scientific correctness."),
            class = "bio_cross_check")
}

.cc_same <- function(a, b, tol) {
  a <- as.numeric(a); b <- as.numeric(b)
  ok <- (is.na(a) & is.na(b)) | (is.infinite(a) & is.infinite(b) & sign(a) == sign(b))
  fin <- !is.na(a) & !is.na(b) & is.finite(a) & is.finite(b)
  ok[fin] <- abs(a[fin] - b[fin]) <= tol
  ok
}

.cc_layer_xy <- function(plot) {
  layers <- plot$layers
  out <- NULL
  for (l in layers) {
    geom <- class(l$geom)[1]
    if (!geom %in% c("GeomPoint", "GeomText", "GeomLabel")) next
    map <- if (isFALSE(l$inherit.aes)) l$mapping else {
      m <- plot$mapping
      for (n in names(l$mapping)) m[[n]] <- l$mapping[[n]]
      m
    }
    if (is.null(map$x) || is.null(map$y)) next
    data <- if (is.data.frame(l$data)) l$data else plot$data
    if (!is.data.frame(data)) next
    ev <- function(q) tryCatch(rlang::eval_tidy(q, data), error = function(e) e)
    x <- ev(map$x); y <- ev(map$y)
    lab <- if (!is.null(map$label)) ev(map$label) else NULL
    out <- list(x = x, y = y, label = lab, data = data, geom = geom, mapping = map,
                x_expr = rlang::as_label(map$x), y_expr = rlang::as_label(map$y))
    break
  }
  out
}

#' Cross-check a plot against its source result
#'
#' Evaluates the x/y aesthetics of the first point layer (using layer data or
#' the inherited mapping) and compares the plotted values with the full
#' fold-change and p-value columns of \code{source}. Rows are paired by gene
#' identifiers when both sides have them, otherwise by position when the row
#' counts are identical. Plots that cannot be interpreted are reported as
#' \code{"not_checkable"}, never as passes.
#' BioExplainR PCA plots can also be checked against a \code{prcomp} object or
#' their expression matrix; enrichment dot plots are checked by term ID,
#' ratio/count and p-value colour. Checks concern data before scale/coordinate
#' transformations and do not verify every rendered pixel or scientific claim.
#'
#' @param plot A ggplot object.
#' @param source A DE result, enrichment table, PCA fit or expression matrix.
#' @param allow_subset If \code{TRUE}, a plot showing a subset of the source
#'   genes (matched by ID) is accepted; otherwise missing genes fail.
#' @param tolerance Absolute numeric tolerance.
#' @param coefficient Coefficient for multi-coefficient limma fits.
#' @param metadata,group Optional sample metadata and grouping for PCA checks.
#' @return List of class \code{bio_cross_check} with \code{status}
#'   (\code{"pass"}, \code{"fail"}, \code{"not_checkable"}) and
#'   \code{findings} (data.frame).
#' @export
bio_cross_check <- function(plot, source, allow_subset = FALSE, tolerance = 1e-6, coefficient = NULL,
                           metadata = NULL, group = NULL) {
  nc <- function(msg, chk = "checkable") .cc_result(.cc_finding(chk, "not_checkable", msg), allow_subset = allow_subset)
  if (!inherits(plot, "ggplot")) return(nc("plot is not a ggplot object"))
  built <- tryCatch(ggplot2::ggplot_build(plot), error = function(e) e)
  if (inherits(built, "error")) return(nc(paste("ggplot_build failed:", conditionMessage(built)), "plot_build"))
  if (sum(vapply(plot$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1))) > 1L)
    return(nc("multiple point layers require separate source pairing", "plot_layers"))
  type <- attr(plot, "bio_plot_type")
  if (identical(type, "pca_plot")) return(.cc_pca(plot, source, metadata, group, tolerance))
  if (identical(type, "enrichment_dotplot")) return(.cc_enrichment(plot, source, allow_subset, tolerance))
  tab <- tryCatch(.source_table(source, coefficient), error = function(e) e)
  if (inherits(tab, "error")) return(nc(paste("source table unavailable:", conditionMessage(tab)), "source"))
  if (!is.data.frame(tab)) return(nc("source has no table that can be compared", "source"))
  cols <- .de_columns(tab)
  if (is.null(cols$lfc) || (is.null(cols$p_raw) && is.null(cols$p_adj)))
    return(nc("source table has no recognisable fold-change and p-value columns", "source"))
  xy <- .cc_layer_xy(plot)
  if (is.null(xy)) return(nc("no point layer with x and y aesthetics and data frame", "plot_mapping"))
  if (inherits(xy$x, "error") || inherits(xy$y, "error") || !is.numeric(xy$x) || !is.numeric(xy$y))
    return(nc("x/y aesthetics could not be evaluated to numeric values (e.g. computed stats or non-numeric)", "plot_mapping"))

  src_id <- if (!is.null(cols$gene)) as.character(tab[[cols$gene]]) else if (.has_rn(tab)) rownames(tab) else NULL
  pd <- xy$data
  plot_id <- NULL
  if (!is.null(xy$label) && !inherits(xy$label, "error") && length(xy$label) == length(xy$x)) plot_id <- as.character(xy$label)
  pc <- .find_col(pd, .de_aliases$gene)
  if (is.null(plot_id) || !any(plot_id %in% src_id)) {
    if (!is.null(pc)) plot_id <- as.character(pd[[pc]])
    else if (.has_rn(pd)) plot_id <- rownames(pd)
  }
  if (length(xy$x) != length(xy$y)) return(nc("x and y have different lengths", "plot_mapping"))
  lfc <- as.numeric(tab[[cols$lfc]])
  f <- list()
  n_plot <- length(xy$x)
  paired <- NULL
  if (!is.null(src_id) && !is.null(plot_id) && length(plot_id) == n_plot && any(plot_id %in% src_id)) {
    if (anyDuplicated(src_id[!is.na(src_id)]) || anyDuplicated(plot_id[!is.na(plot_id)]))
      return(nc("duplicate gene IDs prevent an unambiguous pairing", "pairing"))
    idx <- match(plot_id, src_id)
    unknown <- sum(is.na(idx))
    if (unknown) f$unk <- .cc_finding("ids_in_source", "fail", paste(unknown, "plotted feature(s) are not in the source table"))
    missing <- length(src_id) - sum(!is.na(unique(idx)))
    if (missing && !allow_subset) f$mis <- .cc_finding("all_source_genes_plotted", "fail",
                                                      paste(missing, "source feature(s) are not plotted (use allow_subset = TRUE if intended)"))
    else if (missing) f$mis <- .cc_finding("all_source_genes_plotted", "pass", paste("subset accepted;", missing, "source feature(s) not plotted"))
    else f$mis <- .cc_finding("all_source_genes_plotted", "pass", "every source feature is plotted")
    paired <- which(!is.na(idx))
    sidx <- idx[paired]
    pairing <- "gene_id"
  } else if (!is.null(src_id) && !is.null(plot_id) && length(plot_id) == n_plot) {
    return(nc("plot identifiers do not overlap the source table; plot appears unrelated", "pairing"))
  } else if (n_plot == nrow(tab)) {
    paired <- seq_len(n_plot); sidx <- paired; pairing <- "row_order"
    f$pair <- .cc_finding("pairing", "pass", "no gene IDs on the plot; rows paired by position (same row count)")
  } else if (!is.null(src_id) && is.null(plot_id) || n_plot != nrow(tab)) {
    return(nc(paste0("no gene identifiers on the plot and row counts differ (plot ", n_plot, ", source ", nrow(tab),
                     "); rows cannot be paired", if (allow_subset) " (subset cannot be verified without IDs)" else ""), "pairing"))
  }
  if (!length(paired)) return(nc("no rows could be paired", "pairing"))
  px <- xy$x[paired]; py <- xy$y[paired]
  sl <- lfc[sidx]
  if (all(.cc_same(px, sl, tolerance))) {
    f$x <- .cc_finding("x_axis", "pass", paste0("x (", xy$x_expr, ") equals the fold-change column '", cols$lfc, "'"))
  } else if (all(.cc_same(px, -sl, tolerance))) {
    f$x <- .cc_finding("x_axis", "fail", paste0("x (", xy$x_expr, ") equals the NEGATED fold-change column '", cols$lfc, "'"))
  } else {
    f$x <- .cc_finding("x_axis", "fail", paste0("x (", xy$x_expr, ") does not match the fold-change column '", cols$lfc, "'"))
  }
  cand <- list()
  if (!is.null(cols$p_adj)) { p <- as.numeric(tab[[cols$p_adj]])[sidx]
    cand[[paste0("-log10(", cols$p_adj, ") [adjusted p]")]] <- -log10(p)
    cand[[paste0(cols$p_adj, " [adjusted p, untransformed]")]] <- p }
  if (!is.null(cols$p_raw)) { p <- as.numeric(tab[[cols$p_raw]])[sidx]
    cand[[paste0("-log10(", cols$p_raw, ") [raw p]")]] <- -log10(p)
    cand[[paste0(cols$p_raw, " [raw p, untransformed]")]] <- p }
  hit <- names(cand)[vapply(cand, function(v) all(.cc_same(py, v, tolerance)), NA)]
  if (length(hit)) {
    raw_only_hit <- !is.null(cols$p_adj) && all(grepl("raw p", hit))
    untransformed <- all(grepl("untransformed", hit))
    f$y <- .cc_finding("y_axis", if (raw_only_hit || untransformed) "fail" else "pass",
      paste0("y (", xy$y_expr, ") equals ", hit[1],
             if (raw_only_hit) "; the source also has an adjusted p column, so the plot shows RAW p-values"
             else if (untransformed) "; a volcano y axis is normally -log10(p)" else ""))
  } else {
    f$y <- .cc_finding("y_axis", "fail", paste0("y (", xy$y_expr, ") does not match any p-value column (raw/adjusted, -log10 or plain)"))
  }
  if (identical(pairing, "row_order") && f$x$status == "fail")
    f$x$detail <- paste0(f$x$detail, "; rows were paired by position only")
  fd <- do.call(rbind, unname(f))
  .cc_result(fd, allow_subset = allow_subset)
}

.cc_pca <- function(plot, source, metadata, group, tolerance) {
  nc <- function(msg) .cc_result(.cc_finding("pca_source", "not_checkable", msg))
  info <- attr(plot, "bio_plot_source")
  fit <- if (inherits(source, "prcomp")) source else tryCatch({
    ref <- bio_plot_pca(source, metadata = metadata, group = group,
                        feature_axis = info$feature_axis %||% "rows",
                        transform = info$transform %||% "none", center = info$center %||% TRUE,
                        scale. = info$scale %||% FALSE, n_top_features = info$n_top_features %||% 500)
    attr(ref, "bio_plot_source")$prcomp
  }, error = function(e) e)
  if (inherits(fit, "error") || is.null(fit$x) || ncol(fit$x) < 2L)
    return(nc("source must contain PCA scores or permit independent PCA recomputation"))
  xy <- .cc_layer_xy(plot)
  if (is.null(xy) || !is.numeric(xy$x) || !is.numeric(xy$y)) return(nc("PCA aesthetics are not numeric"))
  if (length(xy$x) != nrow(fit$x)) return(.cc_result(.cc_finding("observations", "fail", "PCA observation counts differ")))
  idx <- seq_len(nrow(fit$x))
  if (.has_rn(xy$data) && !is.null(rownames(fit$x))) {
    if (anyDuplicated(rownames(xy$data)) || anyDuplicated(rownames(fit$x))) return(nc("duplicate observation IDs"))
    idx <- match(rownames(xy$data), rownames(fit$x))
    if (anyNA(idx)) return(.cc_result(.cc_finding("observations", "fail", "PCA observation IDs differ")))
  }
  ve <- fit$sdev^2 / sum(fit$sdev^2)
  status <- function(ok) if (isTRUE(ok)) "pass" else "fail"
  fd <- list(.cc_finding("scores", status(all(.cc_same(xy$x, fit$x[idx, 1L], tolerance)) &&
                                           all(.cc_same(xy$y, fit$x[idx, 2L], tolerance))),
                         "PC1/PC2 aesthetics compared with independently supplied/recomputed PCA scores"),
             .cc_finding("variance", status(length(info$variance_explained) == length(ve) &&
                                              all(.cc_same(info$variance_explained, ve, tolerance))),
                         "stored explained variance compared with source eigenvalues"))
  for (i in 1:2) {
    lab <- plot$labels[[c("x", "y")[i]]]
    expected <- paste0("PC", i, " (", round(100 * ve[i], 1), "%)")
    fd[[length(fd) + 1L]] <- .cc_finding(paste0("PC", i, "_label"), status(identical(lab, expected)),
                                        paste("expected axis label:", expected))
  }
  if (!is.null(metadata)) {
    md <- tryCatch(.plot_metadata(metadata, nrow(fit$x), group, rownames(fit$x)), error = function(e) e)
    actual <- tryCatch(rlang::eval_tidy(xy$mapping$colour, xy$data), error = function(e) NULL)
    ok <- !inherits(md, "error") && length(actual) == nrow(md) &&
      identical(as.character(actual), as.character(md$group[idx]))
    fd[[length(fd) + 1L]] <- .cc_finding("groups", status(ok), "point colour groups compared with source metadata")
  }
  .cc_result(do.call(rbind, fd))
}

.cc_enrichment <- function(plot, source, allow_subset, tolerance) {
  nc <- function(msg) .cc_result(.cc_finding("enrichment_source", "not_checkable", msg), allow_subset = allow_subset)
  tab <- tryCatch(as.data.frame(source), error = function(e) NULL)
  if (is.null(tab) || !nrow(tab)) return(nc("no enrichment source table"))
  xy <- .cc_layer_xy(plot); info <- attr(plot, "bio_plot_source")
  if (is.null(xy) || !is.numeric(xy$x) || !"term_id" %in% names(xy$data)) return(nc("no numeric point mapping with term IDs"))
  id_col <- info$id %||% info$term
  required <- unique(c(id_col, info$term, info$ratio, info$p, info$count))
  if (!all(required %in% names(tab))) return(nc("source is missing the recorded enrichment columns"))
  ids <- as.character(tab[[id_col]]); plotted <- as.character(xy$data$term_id)
  if (anyNA(ids) || anyNA(plotted) || anyDuplicated(ids) || anyDuplicated(plotted)) return(nc("term IDs must be unique and non-missing"))
  idx <- match(plotted, ids)
  if (anyNA(idx)) return(.cc_result(.cc_finding("term_ids", "fail", "plotted term IDs absent from source"), allow_subset = allow_subset))
  stat <- function(ok) if (isTRUE(ok)) "pass" else "fail"
  fd <- list(.cc_finding("coverage", stat(allow_subset || length(idx) == nrow(tab)),
                         paste(length(idx), "of", nrow(tab), "source terms plotted")))
  ratio <- if (!is.null(info$ratio)) {
    values <- as.character(tab[[info$ratio]][idx])
    r <- suppressWarnings(as.numeric(values)); frac <- grepl("/", values, fixed = TRUE)
    r[frac] <- .ratio_to_num(values[frac]); r
  } else rep(NA_real_, length(idx))
  count <- if (!is.null(info$count)) suppressWarnings(as.numeric(tab[[info$count]][idx])) else ratio
  expected_x <- if (all(is.na(ratio))) count else ratio
  fd[[length(fd) + 1L]] <- .cc_finding("x_axis", stat(all(.cc_same(xy$x, expected_x, tolerance))), "ratio/count checked against source")
  fd[[length(fd) + 1L]] <- .cc_finding("term_labels", stat(identical(as.character(xy$y), as.character(tab[[info$term]][idx]))), "term labels paired by term ID")
  for (aes in c("colour", "size")) {
    actual <- tryCatch(rlang::eval_tidy(xy$mapping[[aes]], xy$data), error = function(e) NULL)
    expected <- if (aes == "size") count else -log10(pmax(as.numeric(tab[[info$p]][idx]), info$p_floor %||% .Machine$double.xmin))
    fd[[length(fd) + 1L]] <- .cc_finding(aes, stat(is.numeric(actual) && length(actual) == length(expected) &&
                                                  all(.cc_same(actual, expected, tolerance))),
                                        if (aes == "size") "point size checked against Count" else paste("colour checked against -log10", info$p))
  }
  .cc_result(do.call(rbind, fd), allow_subset = allow_subset)
}

.has_rn <- function(df) is.character(attr(df, "row.names")) && !is.null(rownames(df))

#' @export
print.bio_cross_check <- function(x, ...) {
  cat("== bio_cross_check: ", x$status, " ==\n", sep = "")
  print(x$findings, row.names = FALSE)
  invisible(x)
}
