# Differential expression adapters ---------------------------------------------

.de_aliases <- list(
  lfc = c("log2FoldChange", "logFC", "log2FC", "avg_log2FC", "avg_logFC", "log2fc", "lfc"),
  p_raw = c("pvalue", "P.Value", "PValue", "p_val", "pval", "p.value", "p_value", "PValue"),
  p_adj = c("padj", "adj.P.Val", "FDR", "FWER", "p_val_adj", "p.adjust", "qvalue", "q_value", "qval", "adj_pval", "fdr"),
  gene = c("gene", "symbol", "SYMBOL", "gene_id", "gene_name", "Gene", "feature", "ID", "ensembl", "ENSEMBL"),
  mean = c("baseMean", "AveExpr", "logCPM"),
  stat = c("stat", "t", "F", "LR", "lfcSE")
)

.de_columns <- function(df) {
  lapply(.de_aliases, function(a) .find_col(df, a))
}

.detect_de_table <- function(x) {
  if (!is.data.frame(x)) return(FALSE)
  cols <- .de_columns(x)
  !is.null(cols$lfc) && (!is.null(cols$p_raw) || !is.null(cols$p_adj))
}

# Column signatures; they only produce a *suspected* producer.
.guess_de_producer <- function(df) {
  nm <- names(df)
  if (all(c("baseMean", "log2FoldChange", "pvalue", "padj") %in% nm)) return("DESeq2")
  if (all(c("logFC", "AveExpr", "P.Value", "adj.P.Val") %in% nm)) return("limma")
  if (all(c("logFC", "logCPM", "PValue") %in% nm)) return("edgeR")
  if (all(c("p_val", "avg_log2FC", "p_val_adj") %in% nm)) return("Seurat (FindMarkers)")
  NA_character_
}

.p_adjust_by <- function(p, g, method) {
  out <- p
  key <- ifelse(is.na(g), "(missing)", g)
  for (k in unique(key)) out[key == k] <- stats::p.adjust(p[key == k], method = method)
  out
}

# Per-cluster / per-group counts (marker tables, e.g. Seurat FindAllMarkers). Only
# observed group values are counted; unused factor levels and missing labels are
# reported separately.
.per_group_de <- function(df, gcol, grp, lfc, padj, praw, alpha, lfc_thr, p_thr, cols, n_top) {
  pv <- if (!is.null(padj)) padj else praw
  thr <- if (!is.null(padj)) alpha else p_thr
  levels_obs <- sort(unique(grp[!is.na(grp)]))
  per <- lapply(stats::setNames(levels_obs, levels_obs), function(g) {
    i <- which(grp == g)
    sig <- !is.na(pv[i]) & pv[i] < thr & !is.na(lfc[i])
    ord <- i[order(pv[i], -abs(lfc[i]), na.last = NA)]
    gene <- if (!is.null(cols$gene)) as.character(df[[cols$gene]]) else rownames(df)
    list(n_rows = length(i), n_significant = sum(sig & abs(lfc[i]) > lfc_thr),
         n_up = sum(sig & lfc[i] > lfc_thr), n_down = sum(sig & lfc[i] < -lfc_thr),
         top_features = .truncate_chr(utils::head(gene[ord], 3), 40))
  })
  unused <- if (is.factor(df[[gcol]])) sum(!levels(df[[gcol]]) %in% levels_obs) else 0L
  facts <- list(group_column = gcol, n_groups = length(levels_obs), per_cluster = per,
                n_rows_missing_group = sum(is.na(grp)), n_unused_group_levels = unused,
                per_cluster_significance_basis = if (!is.null(padj)) "adjusted_p" else "raw_p")
  unc <- c("The table has a cluster/group column: counts are also summarised per cluster (per_cluster); the overall count is the sum of the per-cluster row counts, and the same gene can appear in several clusters." %L% "\u8868\u542b cluster/\u5206\u7ec4\u5217\uff1a\u6570\u91cf\u540c\u65f6\u6309\u6bcf\u4e2a cluster \u5206\u522b\u6c47\u603b\uff08per_cluster\uff09\uff0c\u603b\u8ba1\u6570\u662f\u5404 cluster \u884c\u6570\u4e4b\u548c\uff0c\u540c\u4e00\u57fa\u56e0\u53ef\u5728\u591a\u4e2a cluster \u4e2d\u91cd\u590d\u51fa\u73b0\u3002",
           if (is.null(padj)) "There is no adjusted p-value, so the significant counts per cluster use raw p-values only." %L% "\u6ca1\u6709\u6821\u6b63 p \u503c\uff0c\u5404 cluster \u7684\u663e\u8457\u8ba1\u6570\u4ec5\u6309\u539f\u59cb p \u503c\u3002",
           if (any(is.na(grp))) paste0(sum(is.na(grp)), " rows lack a cluster label and are not counted in any cluster." %L% " \u884c\u7f3a\u5c11 cluster \u6807\u7b7e\uff0c\u672a\u8ba1\u5165\u4efb\u4f55 cluster\u3002"))
  list(facts = facts, uncertainty = unc)
}

.adapt_de_table <- function(x, meta = list(), n_top = 10, thresholds = list(padj = 0.05, lfc = 0, p = 0.05),
                            p_adjust_method = NULL, analysis_type = NULL,
                            source_class = class(x), source_package = NULL,
                            source_status = NULL, extra_facts = list(),
                            extra_uncertainty = character(), group_col = NULL, ...) {
  df <- as.data.frame(x, stringsAsFactors = FALSE)
  cols <- .de_columns(df)
  if (is.null(cols$lfc)) {
    stop("No log fold-change column found. Expected one of: ",
         paste(.de_aliases$lfc, collapse = ", "), call. = FALSE)
  }
  if (is.null(cols$p_raw) && is.null(cols$p_adj)) {
    stop("No p-value column found (raw or adjusted).", call. = FALSE)
  }
  unc <- extra_uncertainty
  guessed <- .guess_de_producer(df)
  if (is.null(source_status)) {
    source_status <- if (is.na(guessed)) "unknown" else "inferred_from_columns"
    source_package <- guessed
    if (!is.na(guessed)) {
      unc <- c(unc, paste0("Column names resemble output from " %L% "\u5217\u540d\u6a21\u5f0f\u4e0e ", guessed, ", but column names alone cannot confirm the source package (source status: inferred)." %L% " \u8f93\u51fa\u76f8\u4f3c\uff0c\u4f46\u4ec5\u51ed\u5217\u540d\u4e0d\u80fd\u786e\u8ba4\u6765\u6e90\u5305\uff08\u6765\u6e90\u72b6\u6001\uff1a\u63a8\u6d4b\uff09\u3002"))
    } else {
      unc <- c(unc, "The package that produced this table cannot be determined from its column names; supply it with the source_package argument." %L% "\u65e0\u6cd5\u4ece\u5217\u540d\u786e\u5b9a\u4ea7\u751f\u8be5\u8868\u7684\u8f6f\u4ef6\u5305\uff0c\u8bf7\u7528 source_package \u53c2\u6570\u8865\u5145\u3002")
    }
  }

  gcol <- group_col %||% .find_col(df, c("cluster", "Cluster"))
  grp <- if (!is.null(gcol) && gcol %in% names(df)) .clean_id(df[[gcol]]) else NULL
  if (!is.null(grp) && all(is.na(grp))) grp <- NULL
  if (!is.null(group_col) && is.null(grp)) stop("group_col '", group_col, "' not found or empty.", call. = FALSE)
  lfc <- .numeric_column(df, cols$lfc)
  praw <- if (!is.null(cols$p_raw)) .numeric_column(df, cols$p_raw, probability = TRUE) else NULL
  padj <- if (!is.null(cols$p_adj)) .numeric_column(df, cols$p_adj, probability = TRUE) else NULL
  basis <- NULL
  if (!is.null(padj)) {
    basis <- "adjusted_column"
    if (cols$p_adj %in% c("qvalue", "q_value", "qval")) {
      unc <- c(unc, paste0("Using q-value column '" %L% "\u4f7f\u7528 q-value \u5217 '", cols$p_adj, "' as the multiple-testing adjusted value; a q-value is defined differently from a BH-adjusted p-value." %L% "' \u4f5c\u4e3a\u591a\u91cd\u68c0\u9a8c\u6821\u6b63\u503c\uff1bq-value \u4e0e BH \u6821\u6b63 p \u503c\u5b9a\u4e49\u4e0d\u540c\u3002"))
    }
  } else if (!is.null(p_adjust_method)) {
    padj <- if (is.null(grp)) stats::p.adjust(praw, method = p_adjust_method) else .p_adjust_by(praw, grp, p_adjust_method)
    basis <- paste0("computed_", p_adjust_method)
    unc <- c(unc, paste0("The table has raw p-values only; as requested, BioExplainR computed adjusted p-values with p.adjust(method = '" %L% "\u8868\u4e2d\u53ea\u6709\u539f\u59cb p \u503c\uff1bBioExplainR \u6309\u7528\u6237\u8981\u6c42\u7528 p.adjust(method = '",
                         p_adjust_method, "')" %L% "') \u8ba1\u7b97\u4e86\u6821\u6b63 p \u503c",
                         if (!is.null(grp)) " (computed separately within each cluster/group)" %L% "\uff08\u5728\u6bcf\u4e2a cluster/\u5206\u7ec4\u5185\u5206\u522b\u8ba1\u7b97\uff09",
                         ". This assumes the table contains all tested features; if it was pre-filtered, the computed FDR will be too small." %L% "\u3002\u8fd9\u5047\u8bbe\u8be5\u8868\u5305\u542b\u5168\u90e8\u88ab\u68c0\u9a8c\u7684\u7279\u5f81\uff0c\u82e5\u8868\u5df2\u88ab\u9884\u5148\u7b5b\u9009\uff0c\u8ba1\u7b97\u51fa\u7684 FDR \u4f1a\u504f\u5c0f\u3002"))
  } else {
    basis <- "raw_only"
    unc <- c(unc, "The table has no adjusted p-value (FDR/padj). Raw p-values were not treated as FDR; significant counts are labelled 'raw p-value' only and multiple testing is not controlled. Set p_adjust_method = 'BH' to compute it explicitly." %L% "\u8868\u4e2d\u6ca1\u6709\u6821\u6b63\u540e p \u503c\uff08FDR/padj\uff09\u3002\u672a\u628a\u539f\u59cb p \u503c\u5f53\u4f5c FDR\uff1b\u663e\u8457\u6027\u8ba1\u6570\u4ec5\u4ee5\u201c\u539f\u59cb p \u503c\u201d\u6807\u6ce8\uff0c\u591a\u91cd\u68c0\u9a8c\u672a\u63a7\u5236\u3002\u53ef\u8bbe\u7f6e p_adjust_method = 'BH' \u663e\u5f0f\u8ba1\u7b97\u3002")
  }

  n <- nrow(df)
  alpha <- thresholds$padj %||% 0.05
  lfc_thr <- thresholds$lfc %||% 0
  p_thr <- thresholds$p %||% 0.05
  facts <- list(
    n_features = n,
    lfc_column = cols$lfc,
    p_value_column = cols$p_raw %||% NA_character_,
    adjusted_p_column = cols$p_adj %||% NA_character_,
    p_value_basis = basis,
    n_na_lfc = sum(is.na(lfc))
  )
  if (!is.null(praw)) {
    facts$n_na_pvalue <- sum(is.na(praw))
    facts$n_raw_p_below <- sum(praw < p_thr, na.rm = TRUE)
    facts$raw_p_threshold <- p_thr
  }
  if (!is.null(padj)) {
    sig <- !is.na(padj) & padj < alpha & !is.na(lfc)
    facts$n_tested <- sum(!is.na(padj))
    facts$n_na_padj <- sum(is.na(padj))
    facts$padj_threshold <- alpha
    facts$lfc_threshold <- lfc_thr
    facts$n_significant_any_lfc <- sum(sig)
    facts$n_up <- sum(sig & lfc > lfc_thr)
    facts$n_down <- sum(sig & lfc < -lfc_thr)
    facts$n_significant <- facts$n_up + facts$n_down
    facts$min_padj <- if (any(!is.na(padj))) min(padj, na.rm = TRUE) else NA_real_
  } else {
    sig_raw <- !is.na(praw) & praw < p_thr & !is.na(lfc)
    facts$n_raw_up <- sum(sig_raw & lfc > lfc_thr)
    facts$n_raw_down <- sum(sig_raw & lfc < -lfc_thr)
    facts$lfc_threshold <- lfc_thr
  }
  if (any(!is.na(lfc))) {
    facts$lfc_range <- range(lfc, na.rm = TRUE)
    facts$lfc_median <- stats::median(lfc, na.rm = TRUE)
  }
  if (!is.null(cols$mean)) facts$mean_expression_column <- cols$mean
  facts <- c(facts, extra_facts)
  if (!is.null(grp)) {
    pg <- .per_group_de(df, gcol, grp, lfc, padj, praw, alpha, lfc_thr, p_thr, cols, n_top)
    facts <- c(facts, pg$facts)
    unc <- c(unc, pg$uncertainty)
  }
  if (n > 0 && !is.null(padj) && facts$n_significant == 0) {
    unc <- c(unc, "No feature is significant at the current thresholds; this does not mean 'no biological difference' - the sample size or effect size may be insufficient." %L% "\u5728\u5f53\u524d\u9608\u503c\u4e0b\u6ca1\u6709\u663e\u8457\u7279\u5f81\uff1b\u8fd9\u4e0d\u7b49\u4e8e\u201c\u6ca1\u6709\u751f\u7269\u5b66\u5dee\u5f02\u201d\uff0c\u4e5f\u53ef\u80fd\u662f\u6837\u672c\u91cf\u6216\u6548\u5e94\u91cf\u4e0d\u8db3\u3002")
  }
  if (!is.null(padj) && facts$n_na_padj > 0 && identical(source_package, "DESeq2")) {
    unc <- c(unc, "In DESeq2 an NA padj is usually caused by independent filtering, all-zero counts or extreme outliers; these genes do not enter the FDR counts." %L% "DESeq2 \u4e2d padj \u4e3a NA \u5e38\u7531\u72ec\u7acb\u8fc7\u6ee4\u3001\u5168\u96f6\u8ba1\u6570\u6216\u6781\u7aef\u79bb\u7fa4\u503c\u5bfc\u81f4\uff0c\u8fd9\u4e9b\u57fa\u56e0\u672a\u53c2\u4e0e FDR \u8ba1\u6570\u3002")
  }

  # Top features: computed after the full-table counts above.
  feature <- if (!is.null(cols$gene)) as.character(df[[cols$gene]]) else rownames(df)
  feature <- feature %||% as.character(seq_len(n))
  order_p <- if (!is.null(padj)) padj else praw
  ord <- order(order_p, -abs(lfc), na.last = NA)
  ord <- utils::head(ord, n_top)
  top <- data.frame(feature = .truncate_chr(feature[ord], 60), log2fc = signif(lfc[ord], 4),
                    stringsAsFactors = FALSE)
  if (!is.null(praw)) top$pvalue <- signif(praw[ord], 4)
  if (!is.null(padj)) top$padj <- signif(padj[ord], 4)
  if (!is.null(cols$mean)) top[[cols$mean]] <- signif(suppressWarnings(as.numeric(df[[cols$mean]][ord])), 4)
  if (!is.null(grp)) top <- cbind(cluster = grp[ord], top, stringsAsFactors = FALSE)
  top$direction <- ifelse(top$log2fc > 0, "up", ifelse(top$log2fc < 0, "down", "none"))
  if (!is.null(padj)) top$passes_thresholds <- !is.na(top$padj) & top$padj < alpha & abs(top$log2fc) > lfc_thr

  if (is.null(meta$contrast)) {
    unc <- c(unc, "No comparison (contrast) was provided; the sign of log2FC depends on which group is the denominator/reference group." %L% "\u672a\u63d0\u4f9b\u6bd4\u8f83\u65b9\u5411\uff08contrast\uff09\uff1blog2FC \u7684\u6b63\u8d1f\u542b\u4e49\u53d6\u51b3\u4e8e\u54ea\u4e00\u7ec4\u4f5c\u4e3a\u5206\u6bcd/\u53c2\u8003\u7ec4\u3002")
  }
  new_bio_context(
    analysis_type = if (identical(analysis_type, "markers")) "markers" else "differential_expression",
    source_class = source_class,
    source_package = source_package %||% NA_character_,
    source_status = source_status,
    facts = facts,
    top_features = top,
    provenance = list(columns_used = cols[!vapply(cols, is.null, logical(1))]),
    uncertainty = unc,
    metadata = meta
  )
}

.adapt_deseq_results <- function(x, meta = list(), n_top = 10, thresholds = list(), ...) {
  df <- tryCatch(methods::as(x, "data.frame"), error = function(e) NULL)
  if (is.null(df)) df <- tryCatch(as.data.frame(x), error = function(e) NULL)
  if (is.null(df)) stop("Could not convert DESeqResults to data.frame; is S4Vectors installed?", call. = FALSE)
  extra <- list()
  unc <- character()
  # Description of columns carries the contrast, e.g.
  # "log2 fold change (MLE): condition treated vs untreated".
  desc <- tryCatch({
    mc <- if (requireNamespace("S4Vectors", quietly = TRUE)) S4Vectors::mcols(x) else NULL
    if (!is.null(mc)) as.character(mc$description) else NULL
  }, error = function(e) NULL)
  if (length(desc)) {
    lfc_desc <- grep("log2 fold change", desc, value = TRUE)[1]
    if (!is.na(lfc_desc)) {
      extra$deseq2_lfc_description <- lfc_desc
      if (is.null(meta$contrast)) meta$contrast <- sub("^.*:\\s*", "", lfc_desc)
    }
    if (any(grepl("shrunken|apeglm|ashr|normal", desc, ignore.case = TRUE))) {
      unc <- c(unc, "log2FC appears to be shrunken (shrinkage); shrunken effect sizes are more conservative and suit ranking and visualisation." %L% "log2FC \u4f3c\u4e4e\u7ecf\u8fc7\u6536\u7f29\uff08shrinkage\uff09\uff1b\u6536\u7f29\u540e\u7684\u6548\u5e94\u91cf\u66f4\u4fdd\u5b88\uff0c\u9002\u5408\u6392\u5e8f\u548c\u53ef\u89c6\u5316\u3002")
    }
  }
  md <- tryCatch(if (requireNamespace("S4Vectors", quietly = TRUE)) S4Vectors::metadata(x) else attr(x, "metadata"),
                 error = function(e) NULL)
  if (!is.null(md$alpha)) {
    extra$deseq2_alpha <- md$alpha
    if (!isTRUE(all.equal(md$alpha, thresholds$padj %||% 0.05))) {
      unc <- c(unc, paste0("Independent filtering in results() used alpha = " %L% "results() \u7684\u72ec\u7acb\u8fc7\u6ee4\u4f7f\u7528 alpha = ", md$alpha,
                           ", whereas this count uses a padj threshold of " %L% "\uff0c\u800c\u672c\u6b21\u8ba1\u6570\u4f7f\u7528 padj \u9608\u503c ", thresholds$padj %||% 0.05, "." %L% "\u3002"))
    }
  }
  if (!is.null(md$lfcThreshold) && md$lfcThreshold > 0) {
    extra$deseq2_lfcThreshold <- md$lfcThreshold
    unc <- c(unc, paste0("results() used lfcThreshold = " %L% "results() \u4f7f\u7528\u4e86 lfcThreshold = ", md$lfcThreshold, "; the p-value tests whether |log2FC| exceeds this threshold." %L% "\uff0cp \u503c\u68c0\u9a8c\u7684\u662f |log2FC| \u662f\u5426\u8d85\u8fc7\u8be5\u9608\u503c\u3002"))
  }
  .adapt_de_table(df, meta = meta, n_top = n_top, thresholds = thresholds,
                  source_class = class(x), source_package = "DESeq2",
                  source_status = "verified_class", extra_facts = extra,
                  extra_uncertainty = unc, ...)
}

.adapt_prcomp <- function(x, meta = list(), n_top = 10, ...) {
  sdev <- x$sdev
  ve <- sdev^2 / sum(sdev^2)
  k <- min(length(ve), 10)
  facts <- list(
    n_observations = nrow(x$x %||% matrix(nrow = 0, ncol = 0)),
    n_variables = nrow(x$rotation %||% matrix(nrow = 0, ncol = 0)),
    n_components = length(sdev),
    variance_explained = ve[seq_len(k)],
    cumulative_variance = cumsum(ve)[seq_len(k)],
    centered = !isFALSE(x$center),
    scaled = !isFALSE(x$scale)
  )
  # Top loadings for PC1 (variables are usually genes, not samples).
  top <- NULL
  if (!is.null(x$rotation) && !is.null(rownames(x$rotation))) {
    r <- x$rotation[, 1]
    o <- utils::head(order(-abs(r)), n_top)
    top <- data.frame(feature = .truncate_chr(rownames(x$rotation)[o], 60),
                      PC1_loading = signif(r[o], 4), stringsAsFactors = FALSE)
  }
  new_bio_context("pca", class(x), "stats", "verified_class", facts = facts,
                  top_features = top, metadata = meta,
                  uncertainty = c("Separation of samples on the principal components is not a biological mechanism; batch effects can also cause separation." %L%
                                    "\u6837\u672c\u5728\u4e3b\u6210\u5206\u4e0a\u7684\u5206\u79bb\u4e0d\u7b49\u4e8e\u751f\u7269\u5b66\u673a\u5236\uff0c\u6279\u6b21\u6548\u5e94\u4e5f\u53ef\u80fd\u9020\u6210\u5206\u79bb\u3002",
                                  "Sample coordinates and sample names were not sent; judge group separation together with the sample group information." %L%
                                    "\u672a\u53d1\u9001\u6837\u672c\u5750\u6807\u6216\u6837\u672c\u540d\u79f0\uff1b\u5206\u7ec4\u5206\u79bb\u9700\u7ed3\u5408\u6837\u672c\u5206\u7ec4\u4fe1\u606f\u5224\u65ad\u3002"))
}
