# Sample-level cell composition ---------------------------------------------------------

.cell_meta <- function(x) {
  if (is.data.frame(x)) return(x)
  if (inherits(x, "Seurat") || !is.null(.slot_or(x, "meta.data"))) {
    md <- .slot_or(x, "meta.data")
    if (is.data.frame(md)) return(md)
  }
  if (inherits(x, "SummarizedExperiment") && requireNamespace("SummarizedExperiment", quietly = TRUE)) {
    return(as.data.frame(SummarizedExperiment::colData(x), stringsAsFactors = FALSE))
  }
  stop("x must be a per-cell metadata data.frame, a Seurat object or a SingleCellExperiment.", call. = FALSE)
}

#' Cell-type composition at the sample level
#'
#' Computes, for every biological sample, the proportion of its cells in each
#' cluster / cell type, summarises proportions by group, and (only if requested
#' and only when there are enough independent samples) tests group differences
#' \emph{across sample proportions}. Cells are never the replicate unit:
#' tests use one value per sample, so there is no cell-level pseudoreplication.
#'
#' Cells with a missing sample ID or missing cluster are excluded and counted.
#' Only observed clusters are used (unused factor levels are ignored). A sample
#' that carries more than one group label is excluded and reported. If a group
#' has fewer than \code{min_samples_per_group} samples, or there are fewer than
#' two groups, \code{tests} contains no p-values and \code{status} is
#' \code{"insufficient_replicates"} (rather than a fabricated result). Exact
#' two-group Wilcoxon tests with few samples cannot reach small p-values; the
#' smallest attainable p is reported. Proportions of one sample sum to 1, so
#' clusters are not independent of each other (compositional data); results
#' describe association with the declared group only, not cause.
#'
#' @param x Per-cell metadata \code{data.frame}, \code{Seurat} object or
#'   \code{SingleCellExperiment}.
#' @param sample_col Column holding the biological sample/donor ID (the
#'   independent unit; batch or library is not a replicate).
#' @param cluster_col Column holding cluster / cell type.
#' @param group_col Optional column with the declared condition per sample.
#' @param anonymize Replace sample IDs by labels \code{S01, S02, ...} (default).
#'   With \code{FALSE}, real IDs appear in \code{per_sample}; they are still never
#'   put in the context/explanation facts.
#' @param test \code{"none"} (default), \code{"wilcox"} (rank-sum for two
#'   groups, Kruskal-Wallis for more) or \code{"t"} (Welch t-test for two groups).
#' @param p_adjust_method Passed to \code{\link[stats]{p.adjust}} across clusters.
#' @param alpha Significance level for counting adjusted p-values.
#' @param min_samples_per_group Minimum samples per group to run a test.
#' @param language \code{"en"} (default) or \code{"zh"}: language of the
#'   generated notes. Computed values do not depend on it.
#' @return A \code{bio_cell_proportions} list: \code{per_sample} (long table),
#'   \code{group_summary}, \code{tests} (or \code{NULL}), \code{design}
#'   (counts, exclusions, replicate counts), \code{status}, \code{notes}.
#'   \code{bio_context()} and \code{bio_explain()} accept it directly.
#' @export
#' @examples
#' set.seed(1)
#' md <- data.frame(donor = rep(paste0("d", 1:6), c(100, 80, 120, 90, 60, 150)),
#'                  type = sample(c("T", "B", "Mono"), 600, TRUE),
#'                  arm = rep(c("ctrl", "trt"), each = 3)[rep(1:6, c(100, 80, 120, 90, 60, 150))])
#' cp <- bio_cell_proportions(md, "donor", "type", "arm", test = "wilcox")
#' cp$design$samples_per_group
#' cp$status
bio_cell_proportions <- function(x, sample_col, cluster_col, group_col = NULL, anonymize = TRUE,
                                 test = c("none", "wilcox", "t"), p_adjust_method = "BH", alpha = 0.05,
                                 min_samples_per_group = 3, language = NULL) {
  language <- .resolve_language(language, .pkg_env$config)
  .local_language(language)
  test <- match.arg(test)
  md <- .cell_meta(x)
  need <- c(sample_col, cluster_col, group_col)
  miss <- setdiff(need, names(md))
  if (length(miss)) stop("Column(s) not found in metadata: ", paste(miss, collapse = ", "), call. = FALSE)
  if (!p_adjust_method %in% stats::p.adjust.methods) stop("Unknown p_adjust_method.", call. = FALSE)
  s <- .clean_id(md[[sample_col]]); cl <- .clean_id(md[[cluster_col]])
  g <- if (!is.null(group_col)) .clean_id(md[[group_col]]) else rep(NA_character_, nrow(md))
  unused <- if (is.factor(md[[cluster_col]])) sum(table(md[[cluster_col]]) == 0) else 0L
  n_in <- nrow(md)
  miss_s <- sum(is.na(s)); miss_c <- sum(is.na(s) == FALSE & is.na(cl))
  # sample -> group (declared label); conflicting labels exclude the sample
  sg <- unique(data.frame(s = s, g = g, stringsAsFactors = FALSE)[!is.na(s) & !is.na(g), ])
  conflict <- unique(sg$s[duplicated(sg$s)])
  if (length(conflict)) warning(length(conflict), " sample(s) carry more than one group label and were excluded.", call. = FALSE)
  keep <- !is.na(s) & !is.na(cl) & !(s %in% conflict)
  if (!any(keep)) stop("No cells left after excluding missing sample/cluster IDs.", call. = FALSE)
  ct <- table(s[keep], cl[keep])
  total <- rowSums(ct)
  smp <- rownames(ct)
  grp <- if (!is.null(group_col)) sg$g[match(smp, sg$s)] else rep(NA_character_, length(smp))
  ord <- order(grp, smp, na.last = TRUE)
  smp <- smp[ord]; grp <- grp[ord]; ct <- ct[smp, , drop = FALSE]; total <- total[smp]
  label <- if (anonymize) sprintf(paste0("S%0", max(2, nchar(length(smp))), "d"), seq_along(smp)) else smp
  prop <- ct / total
  clusters <- colnames(ct)
  ps <- data.frame(sample = rep(label, times = length(clusters)), group = rep(grp, times = length(clusters)),
                   cluster = rep(clusters, each = length(smp)), n_cells = as.integer(ct),
                   total_cells = rep(as.integer(total), times = length(clusters)),
                   proportion = as.numeric(prop), stringsAsFactors = FALSE)
  has_g <- !is.null(group_col) && any(!is.na(grp))
  gsum <- NULL
  if (has_g) {
    d <- ps[!is.na(ps$group), ]
    key <- paste(d$group, d$cluster, sep = "\r")
    gsum <- do.call(rbind, lapply(split(d, factor(key, levels = unique(key))), function(z) data.frame(
      group = z$group[1], cluster = z$cluster[1], n_samples = nrow(z), mean_proportion = mean(z$proportion),
      median_proportion = stats::median(z$proportion),
      sd_proportion = if (nrow(z) > 1) stats::sd(z$proportion) else NA_real_,
      min_proportion = min(z$proportion), max_proportion = max(z$proportion), stringsAsFactors = FALSE)))
    rownames(gsum) <- NULL
  }
  per_group <- if (has_g) table(grp[!is.na(grp)]) else NULL
  design <- list(
    n_cells_input = n_in, n_cells_used = sum(ct), n_cells_missing_sample = miss_s,
    n_cells_missing_cluster = miss_c, n_samples = length(smp),
    n_samples_excluded_multiple_groups = length(conflict),
    n_samples_without_group = if (!is.null(group_col)) sum(is.na(grp)) else NA_integer_,
    n_clusters = length(clusters), n_unused_cluster_levels = unused,
    n_groups = if (has_g) length(per_group) else 0L,
    samples_per_group = if (has_g) as.list(stats::setNames(as.integer(per_group), names(per_group))) else NULL,
    cells_per_sample_range = as.integer(range(total)),
    cells_per_sample_ratio = round(max(total) / min(total), 2),
    replicate_unit = "sample",
    n_biological_replicates = if (has_g) sum(per_group) else length(smp))
  notes <- c("The independent unit of replication is the sample (sample_col), not the cell; all comparisons use one proportion per sample." %L%
               "\u72ec\u7acb\u91cd\u590d\u5355\u4f4d\u662f\u6837\u672c\uff08sample_col\uff09\uff0c\u4e0d\u662f\u7ec6\u80de\uff1b\u6240\u6709\u6bd4\u8f83\u90fd\u57fa\u4e8e\u6bcf\u4e2a\u6837\u672c\u4e00\u4e2a\u6bd4\u4f8b\u503c\u3002",
             "Cluster proportions within one sample sum to 1 (compositional data), so a rise in one cluster's proportion lowers the others' relative proportions." %L%
               "\u540c\u4e00\u6837\u672c\u5185\u5404 cluster \u6bd4\u4f8b\u4e4b\u548c\u4e3a 1\uff08\u6210\u5206\u6570\u636e\uff09\uff0c\u4e00\u4e2a cluster \u6bd4\u4f8b\u5347\u9ad8\u4f1a\u4f7f\u5176\u4ed6 cluster \u6bd4\u4f8b\u76f8\u5bf9\u964d\u4f4e\u3002",
             "Proportion differences only describe an association with the declared groups; causality or mechanism cannot be inferred from them." %L%
               "\u6bd4\u4f8b\u5dee\u5f02\u53ea\u63cf\u8ff0\u4e0e\u6240\u58f0\u660e\u5206\u7ec4\u7684\u5173\u8054\uff0c\u4e0d\u80fd\u636e\u6b64\u63a8\u65ad\u56e0\u679c\u6216\u673a\u5236\u3002",
             if (miss_s) paste0(miss_s, " cells lack a sample ID and were excluded." %L% " \u4e2a\u7ec6\u80de\u7f3a\u5c11\u6837\u672c ID\uff0c\u5df2\u6392\u9664\u3002"),
             if (miss_c) paste0(miss_c, " cells lack a cluster label and were excluded." %L% " \u4e2a\u7ec6\u80de\u7f3a\u5c11 cluster \u6807\u7b7e\uff0c\u5df2\u6392\u9664\u3002"),
             if (design$cells_per_sample_ratio >= 5) "The total number of cells differs greatly between samples (max/min >= 5), so proportion estimates from small samples are noisier." %L%
               "\u5404\u6837\u672c\u7684\u7ec6\u80de\u603b\u6570\u5dee\u5f02\u5f88\u5927\uff08\u6700\u5927/\u6700\u5c0f >= 5\uff09\uff0c\u5c0f\u6837\u672c\u7684\u6bd4\u4f8b\u4f30\u8ba1\u566a\u58f0\u66f4\u5927\u3002")
  tests <- NULL; status <- "descriptive_only"
  if (test != "none") {
    why <- if (!has_g) "There is no usable group_col, so a between-group test cannot be run." %L% "\u6ca1\u6709\u53ef\u7528\u7684 group_col\uff0c\u65e0\u6cd5\u8fdb\u884c\u7ec4\u95f4\u68c0\u9a8c\u3002"
      else if (length(per_group) < 2) "Fewer than 2 valid groups." %L% "\u6709\u6548\u5206\u7ec4\u5c11\u4e8e 2 \u4e2a\u3002"
      else if (any(per_group < min_samples_per_group))
        paste0("At least one group has fewer independent samples than " %L% "\u81f3\u5c11\u4e00\u4e2a\u5206\u7ec4\u7684\u72ec\u7acb\u6837\u672c\u6570\u5c11\u4e8e ", min_samples_per_group,
               " (samples per group: " %L% "\uff08\u5404\u7ec4\u6837\u672c\u6570\uff1a",
               paste(names(per_group), per_group, sep = "=", collapse = if (.is_zh()) "\uff0c" else ", "), ")." %L% "\uff09\u3002")
    if (test == "t" && has_g && length(per_group) != 2) why <- "The t-test supports exactly two groups." %L% "t \u68c0\u9a8c\u53ea\u652f\u6301\u4e24\u4e2a\u5206\u7ec4\u3002"
    if (!is.null(why)) {
      status <- "insufficient_replicates"
      notes <- c(notes, paste0("No inferential test was run and no p-values are provided: " %L% "\u672a\u8fdb\u884c\u63a8\u65ad\u68c0\u9a8c\uff0c\u4e0d\u63d0\u4f9b p \u503c\uff1a", why))
    } else {
      status <- "tested"
      lv <- names(per_group)
      rows <- lapply(clusters, function(cu) {
        z <- ps[ps$cluster == cu & !is.na(ps$group), ]
        if (length(lv) == 2) {
          a <- z$proportion[z$group == lv[1]]; b <- z$proportion[z$group == lv[2]]
          r <- tryCatch(suppressWarnings(if (test == "wilcox") stats::wilcox.test(b, a) else stats::t.test(b, a)),
                        error = function(e) NULL)
          data.frame(cluster = cu, test = if (test == "wilcox") "Wilcoxon rank-sum" else "Welch t",
                     statistic = if (is.null(r)) NA_real_ else unname(r$statistic),
                     p_value = if (is.null(r)) NA_real_ else r$p.value,
                     difference_in_mean = mean(b) - mean(a), stringsAsFactors = FALSE)
        } else {
          r <- tryCatch(stats::kruskal.test(proportion ~ factor(group), data = z), error = function(e) NULL)
          data.frame(cluster = cu, test = "Kruskal-Wallis", statistic = if (is.null(r)) NA_real_ else unname(r$statistic),
                     p_value = if (is.null(r)) NA_real_ else r$p.value, difference_in_mean = NA_real_, stringsAsFactors = FALSE)
        }
      })
      tests <- do.call(rbind, rows)
      tests$p_adjusted <- stats::p.adjust(tests$p_value, method = p_adjust_method)
      tests$p_adjust_method <- p_adjust_method
      tests <- tests[order(tests$p_adjusted, tests$p_value), ]; rownames(tests) <- NULL
      notes <- c(notes, paste0("The test is run on per-sample proportions (samples per group: " %L% "\u68c0\u9a8c\u5728\u6837\u672c\u6bd4\u4f8b\u4e0a\u8fdb\u884c\uff08\u6bcf\u7ec4\u6837\u672c\u6570\uff1a",
                               paste(names(per_group), per_group, sep = "=", collapse = if (.is_zh()) "\uff0c" else ", "),
                               if (.is_zh()) paste0("\uff09\uff0cp \u503c\u5df2\u5728 ", length(clusters), " \u4e2a cluster \u95f4\u7528 ", p_adjust_method, " \u6821\u6b63\u3002")
                               else paste0("); p-values were adjusted across ", length(clusters), " clusters with ", p_adjust_method, ".")),
                 if (length(lv) == 2 && test == "wilcox") {
                   mp <- 2 / choose(sum(per_group), per_group[[1]])
                   if (mp > alpha) paste0("Very few samples: the smallest possible two-sided p-value of the exact Wilcoxon test is " %L% "\u6837\u672c\u6570\u5f88\u5c11\uff1a\u7cbe\u786e Wilcoxon \u68c0\u9a8c\u7684\u6700\u5c0f\u53ef\u80fd\u53cc\u4fa7 p \u503c\u4e3a ", signif(mp, 3),
                                          ", which cannot reach alpha = " %L% "\uff0c\u65e0\u6cd5\u8fbe\u5230 alpha = ", alpha, "." %L% "\u3002")
                 },
                 "The direction of the difference is the mean proportion of the later group minus that of the earlier group (difference_in_mean; groups are in alphabetical order)." %L%
                   "\u5dee\u5f02\u65b9\u5411\u4ee5\u540e\u4e00\u4e2a\u5206\u7ec4\u51cf\u524d\u4e00\u4e2a\u5206\u7ec4\u7684\u5e73\u5747\u6bd4\u4f8b\u8868\u793a\uff08difference_in_mean\uff0c\u5206\u7ec4\u6309\u5b57\u6bcd\u987a\u5e8f\uff09\u3002")
      design$alpha <- alpha
    }
  }
  structure(list(per_sample = ps, group_summary = gsum, tests = tests, design = design, status = status,
                 notes = Filter(Negate(is.null), notes), test = test, p_adjust_method = p_adjust_method,
                 alpha = alpha, anonymized = anonymize), class = "bio_cell_proportions")
}

#' @export
print.bio_cell_proportions <- function(x, ...) {
  d <- x$design
  cat("<bio_cell_proportions> ", d$n_samples, " samples, ", d$n_clusters, " clusters, ", d$n_cells_used,
      " cells used (", d$n_cells_missing_sample, " without sample ID, ", d$n_cells_missing_cluster,
      " without cluster)\n", sep = "")
  if (!is.null(d$samples_per_group)) cat("  samples per group:", paste(names(d$samples_per_group), unlist(d$samples_per_group), sep = "=", collapse = ", "), "\n")
  cat("  status:", x$status, "\n")
  if (!is.null(x$tests)) print(utils::head(x$tests, 5), row.names = FALSE, digits = 3)
  for (n in x$notes) cat("  - ", n, "\n", sep = "")
  invisible(x)
}

.adapt_cell_proportions <- function(x, meta = list(), n_top = 10, thresholds = list(), ...) {
  d <- x$design
  facts <- list(
    n_cells_used = d$n_cells_used, n_samples = d$n_samples, n_biological_replicates = d$n_biological_replicates,
    n_groups = d$n_groups, samples_per_group = d$samples_per_group, n_clusters = d$n_clusters,
    n_cells_missing_sample = d$n_cells_missing_sample, n_cells_missing_cluster = d$n_cells_missing_cluster,
    cells_per_sample_range = d$cells_per_sample_range, replicate_unit = d$replicate_unit,
    test_status = x$status, anonymized_samples = x$anonymized)
  top <- NULL
  if (!is.null(x$tests)) {
    facts$test_method <- x$tests$test[1]
    facts$p_adjust_method <- x$p_adjust_method
    facts$alpha <- x$alpha
    facts$n_tests <- sum(!is.na(x$tests$p_value))
    facts$n_significant_adjusted <- sum(x$tests$p_adjusted < x$alpha, na.rm = TRUE)
    top <- utils::head(x$tests[c("cluster", "difference_in_mean", "p_value", "p_adjusted")], n_top)
    top[-1] <- lapply(top[-1], signif, digits = 4)
  } else {
    ps <- x$per_sample
    top <- do.call(rbind, lapply(split(ps, ps$cluster), function(z) data.frame(
      cluster = z$cluster[1], mean_proportion = signif(mean(z$proportion), 4),
      min_proportion = signif(min(z$proportion), 4), max_proportion = signif(max(z$proportion), 4),
      stringsAsFactors = FALSE)))
    top <- utils::head(top[order(-top$mean_proportion), ], n_top); rownames(top) <- NULL
  }
  new_bio_context("cell_composition", class(x), "BioExplainR", "verified_class", facts = facts,
                  top_features = top, metadata = meta, uncertainty = x$notes)
}
