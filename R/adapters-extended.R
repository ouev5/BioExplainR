# Extended adapters: limma, edgeR, SummarizedExperiment -----------------------------
#
# limma/edgeR/SummarizedExperiment objects are read through plain list/S4 slots
# or the documented accessors, never through heavy imports, and expression
# matrices are never densified: see .matrix_facts().

# Bounded facts about a matrix-like object --------------------------------------------
# Sparse Matrix objects use their stored slots (no dense conversion); dense or
# delayed matrices use the whole thing only when small, otherwise a strided
# block of at most ~2000 cells. Values and dimnames are never returned.
.matrix_facts <- function(m, max_values = 1e5, block = c(50L, 40L)) {
  d <- as.numeric(dim(m))
  out <- list(class = class(m)[1], dim = as.integer(d))
  total <- d[1] * d[2]
  sparse <- isS4(m) && methods::.hasSlot(m, "x") && tryCatch(methods::is(m, "sparseMatrix"), error = function(e) FALSE)
  if (sparse) {
    x <- utils::head(methods::slot(m, "x"), 1e6)
    out$inspection <- "sparse_slots"
    out$n_stored_values <- length(methods::slot(m, "x"))
    out$fraction_zero <- round(1 - out$n_stored_values / total, 4)
    out$n_na <- sum(is.na(x))
    out$n_na_scope <- if (length(x) < out$n_stored_values) "first_1e6_stored_values_only" else "all_stored_values"
    out$fraction_zero_scope <- "from stored-value count (explicit stored zeros counted as non-zero)"
    out$integer_like <- isTRUE(all(abs(x - round(x)) < 1e-8, na.rm = TRUE))
    out$nonzero_quantiles <- as.list(.q(x))
    out$values_inspected <- length(x)
    return(out)
  }
  v <- if (total <= max_values) {
    out$inspection <- "full"
    m
  } else {
    pick <- function(n, k) unique(round(seq(1, n, length.out = min(n, k))))
    out$inspection <- "sampled_block"
    m[pick(d[1], block[1]), pick(d[2], block[2]), drop = FALSE]
  }
  v <- suppressWarnings(as.numeric(as.matrix(v)))
  out$values_inspected <- length(v)
  if (length(v) && any(!is.na(v))) {
    out$value_quantiles <- as.list(.q(v))
    sfx <- if (identical(out$inspection, "full")) "" else "_sampled"
    out[[paste0("n_na", sfx)]] <- sum(is.na(v))
    out[[paste0("integer_like", sfx)]] <- isTRUE(all(abs(v - round(v)) < 1e-8, na.rm = TRUE))
    out[[paste0("fraction_zero", sfx)]] <- round(mean(v == 0, na.rm = TRUE), 4)
    if (nzchar(sfx)) out$sample_note <- "n_na/fraction_zero/integer_like are from a sampled block, not the full matrix"
  }
  out
}

# Sample / group / batch design facts ----------------------------------------------------
.group_aliases <- c("condition", "group", "treatment", "genotype", "phenotype", "status", "disease", "class")
.batch_aliases <- c("batch", "Batch", "run", "lane", "sequencing_batch", "plate")

.clean_id <- function(v) {
  v <- as.character(v)
  v[!is.na(v) & !nzchar(trimws(v))] <- NA_character_
  v
}

# Counts only observed levels (unused factor levels and missing IDs never count).
# Sample/batch names are never returned; group labels only when few.
.design_facts <- function(md, sample_col = NULL, group_col = NULL, batch_col = NULL, unit = "cells") {
  f <- list(); unc <- character()
  has <- function(col) !is.null(col) && col %in% names(md)
  g <- if (has(group_col)) .clean_id(md[[group_col]]) else NULL
  s <- if (has(sample_col)) .clean_id(md[[sample_col]]) else NULL
  if (!is.null(s)) {
    f$sample_column <- sample_col
    f$n_samples <- length(unique(s[!is.na(s)]))
    f[[paste0("n_", unit, "_missing_sample")]] <- sum(is.na(s))
    st <- table(s)
    f[[paste0(unit, "_per_sample_range")]] <- if (length(st)) as.integer(range(st)) else c(NA_integer_, NA_integer_)
    if (any(is.na(s))) unc <- c(unc, paste0(sum(is.na(s)),
                                             if (.is_zh()) paste0(" \u4e2a", if (unit == "cells") "\u7ec6\u80de" else "\u89c2\u6d4b", "\u7f3a\u5c11\u6837\u672c ID\uff0c\u672a\u8ba1\u5165\u6837\u672c\u6570\u3002")
                                             else paste0(if (unit == "cells") " cells" else " observations",
                                                         " lack a sample ID and are not counted in the number of samples.")))
  }
  if (!is.null(g)) {
    f$group_column <- group_col
    lv <- sort(unique(g[!is.na(g)]))
    f$n_groups <- length(lv)
    f[[paste0("n_", unit, "_missing_group")]] <- sum(is.na(g))
    if (!is.null(s)) {
      pairs <- unique(data.frame(s = s, g = g, stringsAsFactors = FALSE)[!is.na(s), ])
      multi <- sum(table(pairs$s) > 1)
      f$n_samples_in_multiple_groups <- multi
      if (multi) unc <- c(unc, paste0(multi, " samples map to more than one group label, so the sample-to-group assignment is ambiguous." %L% " \u4e2a\u6837\u672c\u5bf9\u5e94\u591a\u4e2a\u5206\u7ec4\u6807\u7b7e\uff0c\u5206\u7ec4\u4e0e\u6837\u672c\u7684\u5bf9\u5e94\u5173\u7cfb\u4e0d\u660e\u786e\u3002"))
      per <- table(pairs$g[!duplicated(pairs$s)])
      f$replicate_unit <- "sample"
    } else {
      per <- table(g)
      f$replicate_unit <- paste0("column/", unit, " (no sample column given; columns may not be independent donors)")
    }
    per <- per[names(per) %in% lv]
    f$units_per_group <- if (length(per) <= 10) as.list(stats::setNames(as.integer(per), names(per))) else NULL
    f$min_units_per_group <- if (length(per)) as.integer(min(per)) else NA_integer_
    if (length(per) && min(per) < 2) unc <- c(unc, "At least one group has only 1 independent unit, so within-group variability cannot be estimated for it." %L% "\u81f3\u5c11\u4e00\u4e2a\u5206\u7ec4\u53ea\u6709 1 \u4e2a\u72ec\u7acb\u5355\u4f4d\uff0c\u65e0\u6cd5\u4f30\u8ba1\u8be5\u7ec4\u7684\u7ec4\u5185\u53d8\u5f02\u3002")
  }
  if (has(batch_col)) {
    b <- .clean_id(md[[batch_col]])
    f$batch_column <- batch_col
    f$n_batches <- length(unique(b[!is.na(b)]))
    unc <- c(unc, "A batch is a technical grouping, not an independent biological replicate; the number of batches must not be used as the number of samples/donors." %L% "\u6279\u6b21\uff08batch\uff09\u662f\u6280\u672f\u5206\u7ec4\uff0c\u4e0d\u662f\u72ec\u7acb\u7684\u751f\u7269\u5b66\u91cd\u590d\uff1b\u4e0d\u80fd\u628a\u6279\u6b21\u6570\u5f53\u4f5c\u6837\u672c/\u4f9b\u4f53\u6570\u3002")
    if (!is.null(g) && f$n_batches >= 2 && f$n_groups >= 2) {
      tb <- table(g, b)
      ok <- !is.na(g) & !is.na(b)
      Xb <- stats::model.matrix(~ factor(b[ok]))
      Xgb <- stats::model.matrix(~ factor(b[ok]) + factor(g[ok]))
      # group effect is estimable (adjusting for batch) only if it adds n_groups - 1 independent columns
      f$group_batch_confounded <- qr(Xgb)$rank < qr(Xb)$rank + (length(unique(g[ok])) - 1)
      if (f$group_batch_confounded) unc <- c(unc, "The group effect is not estimable in a fixed-effects model that includes batch (rank deficiency: batches are fully nested within groups, or group and batch are collinear), so the group effect cannot be separated from the batch effect." %L% "\u5206\u7ec4\u6548\u5e94\u5728\u542b\u6279\u6b21\u7684\u56fa\u5b9a\u6548\u5e94\u6a21\u578b\u4e2d\u4e0d\u53ef\u4f30\u8ba1\uff08\u79e9\u4e8f\uff1a\u6279\u6b21\u5b8c\u5168\u5d4c\u5957\u5728\u5206\u7ec4\u5185\uff0c\u6216\u5206\u7ec4\u4e0e\u6279\u6b21\u5171\u7ebf\uff09\uff0c\u5206\u7ec4\u6548\u5e94\u65e0\u6cd5\u4e0e\u6279\u6b21\u6548\u5e94\u533a\u5206\u3002")
    }
  }
  list(facts = f, uncertainty = unc)
}

.first_col <- function(md, aliases) .find_col(md, aliases)

# limma MArrayLM -----------------------------------------------------------------------------
.pick_coefficient <- function(nm, coefficient, kind) {
  n <- length(nm)
  if (is.null(coefficient)) {
    if (n == 1) return(1L)
    stop(kind, " contains ", n, " coefficients/contrasts (", paste(shQuote(nm), collapse = ", "),
         "); choose one explicitly with coefficient = <name or index>.", call. = FALSE)
  }
  if (length(coefficient) != 1) stop("coefficient must be a single name or index.", call. = FALSE)
  if (is.numeric(coefficient)) {
    if (is.na(coefficient) || coefficient < 1 || coefficient > n || coefficient != floor(coefficient)) {
      stop("coefficient index must be between 1 and ", n, ".", call. = FALSE)
    }
    return(as.integer(coefficient))
  }
  i <- match(as.character(coefficient), nm)
  if (is.na(i)) stop("Unknown coefficient '", coefficient, "'. Available: ", paste(shQuote(nm), collapse = ", "), call. = FALSE)
  i
}

.marraylm_table <- function(x, coefficient = NULL) {
  co <- x$coefficients
  if (is.null(co)) stop("MArrayLM has no 'coefficients'.", call. = FALSE)
  co <- as.matrix(co)
  nm <- colnames(co) %||% paste0("coef", seq_len(ncol(co)))
  j <- .pick_coefficient(nm, coefficient, "MArrayLM")
  pv <- x$p.value
  if (is.null(pv)) stop("MArrayLM has no 'p.value': run limma::eBayes() on the fit first.", call. = FALSE)
  pv <- as.matrix(pv)
  ids <- rownames(co)
  if (is.data.frame(x$genes)) {
    gc <- .find_col(x$genes, c("ID", "Symbol", "SYMBOL", "gene", "GeneID", "ENSEMBL"))
    if (!is.null(gc)) ids <- as.character(x$genes[[gc]])
  }
  df <- data.frame(gene = ids %||% as.character(seq_len(nrow(co))), logFC = unname(co[, j]),
                   AveExpr = if (!is.null(x$Amean)) unname(as.numeric(x$Amean)) else NA_real_,
                   P.Value = unname(pv[, j]), stringsAsFactors = FALSE)
  if (!is.null(x$t)) df$t <- unname(as.matrix(x$t)[, j])
  list(table = df, coefficient = nm[j], n_coefficients = length(nm), coefficient_names = nm)
}

.adapt_marray_lm <- function(x, meta = list(), n_top = 10, thresholds = list(), p_adjust_method = NULL,
                             coefficient = NULL, ...) {
  coefficient <- coefficient %||% meta$coefficient
  r <- .marraylm_table(x, coefficient)
  df <- r$table
  if (all(is.na(df$AveExpr))) df$AveExpr <- NULL
  extra <- list(limma_coefficient = r$coefficient, limma_n_coefficients_in_fit = r$n_coefficients,
                limma_ebayes_applied = TRUE)
  dft <- x$df.total
  if (is.numeric(dft)) extra$limma_df_total_range <- signif(range(dft, na.rm = TRUE), 4)
  unc <- c(paste0("The limma result was taken from coefficient/contrast '" %L% "limma \u7ed3\u679c\u53d6\u81ea\u7cfb\u6570/\u5bf9\u6bd4 '", r$coefficient, "'; the direction of logFC is determined by the design matrix and contrast definition." %L% "'\uff1blogFC \u7684\u65b9\u5411\u7531\u8bbe\u8ba1\u77e9\u9635\u548c\u5bf9\u6bd4\u5b9a\u4e49\u51b3\u5b9a\u3002"),
           "Adjusted p-values were computed by BioExplainR with BH over all fitted features (the same as the limma::topTable default); the MArrayLM contains all tested features." %L% "\u6821\u6b63\u540e p \u503c\u7531 BioExplainR \u5728\u62df\u5408\u7684\u5168\u90e8\u7279\u5f81\u4e0a\u6309 BH \u8ba1\u7b97\uff08\u4e0e limma::topTable \u9ed8\u8ba4\u4e00\u81f4\uff09\uff1bMArrayLM \u5305\u542b\u5168\u90e8\u88ab\u68c0\u9a8c\u7279\u5f81\u3002")
  if (r$n_coefficients > 1) unc <- c(unc, paste0("This fit has " %L% "\u8be5\u62df\u5408\u5171\u6709 ", r$n_coefficients, " coefficients/contrasts; only the selected one is explained." %L% " \u4e2a\u7cfb\u6570/\u5bf9\u6bd4\uff0c\u4ec5\u89e3\u91ca\u6240\u9009\u7684\u4e00\u4e2a\u3002"))
  if (grepl("intercept", r$coefficient, ignore.case = TRUE)) {
    unc <- c(unc, "The selected coefficient is the intercept, which tests whether the baseline level is 0 and is not a between-group comparison." %L% "\u6240\u9009\u7cfb\u6570\u662f\u622a\u8ddd\u9879\uff0c\u68c0\u9a8c\u7684\u662f\u57fa\u7ebf\u6c34\u5e73\u662f\u5426\u4e3a 0\uff0c\u4e0d\u662f\u7ec4\u95f4\u6bd4\u8f83\u3002")
  }
  meta$coefficient <- r$coefficient
  .adapt_de_table(df, meta = meta, n_top = n_top, thresholds = thresholds,
                  p_adjust_method = p_adjust_method %||% "BH", analysis_type = "differential_expression",
                  source_class = class(x), source_package = "limma", source_status = "verified_class",
                  extra_facts = extra, extra_uncertainty = unc)
}

# edgeR TopTags / DGEExact / DGELRT ------------------------------------------------------------
.edger_table <- function(x) {
  tab <- tryCatch(x$table, error = function(e) NULL)
  if (!is.data.frame(tab)) stop("edgeR result has no 'table' data.frame.", call. = FALSE)
  tab
}

.adapt_edger <- function(x, meta = list(), n_top = 10, thresholds = list(), p_adjust_method = NULL, ...) {
  tab <- .edger_table(x)
  cls <- if (inherits(x, "TopTags")) "TopTags" else if (inherits(x, "DGELRT")) "DGELRT" else "DGEExact"
  if (!"logFC" %in% names(tab)) {
    multi <- grep("^logFC", names(tab), value = TRUE)
    stop(cls, " has no single 'logFC' column",
         if (length(multi)) paste0(" (found ", paste(multi, collapse = ", "), ": a multi-coefficient test)"),
         "; re-run the test with a single coef or contrast.", call. = FALSE)
  }
  extra <- list(edger_class = cls, edger_table_rows = nrow(tab))
  unc <- character()
  cmp <- tryCatch(x$comparison, error = function(e) NULL)
  if (!is.null(cmp)) extra$edger_comparison <- paste(as.character(cmp), collapse = " vs ")
  if (cls == "DGEExact" && length(cmp) == 2 && is.null(meta$contrast)) meta$contrast <- paste(cmp[2], "vs", cmp[1])
  if (cls == "DGELRT") unc <- c(unc, "What a DGELRT tests is determined by coef/contrast (see edger_comparison); the direction of logFC depends on that contrast." %L% "DGELRT \u7684\u68c0\u9a8c\u5bf9\u8c61\u7531 coef/contrast \u51b3\u5b9a\uff08\u89c1 edger_comparison\uff09\uff1blogFC \u65b9\u5411\u53d6\u51b3\u4e8e\u8be5\u5bf9\u6bd4\u3002")
  adj <- NULL
  if (cls == "TopTags") {
    am <- tryCatch(as.character(x$adjust.method)[1], error = function(e) NA_character_)
    extra$edger_adjust_method <- am
    adj <- intersect(c("FDR", "FWER"), names(tab))
    if (length(adj)) {
      unc <- c(unc, paste0("Using the '" %L% "\u4f7f\u7528 TopTags \u81ea\u5e26\u7684 '", adj[1], "' column of the TopTags (adjust.method = " %L% "' \u5217\uff08adjust.method = ", am,
                           "; computed by edgeR over all genes when topTags() was called)." %L% "\uff0c\u7531 edgeR \u5728 topTags() \u8c03\u7528\u65f6\u5bf9\u5168\u90e8\u57fa\u56e0\u8ba1\u7b97\uff09\u3002"),
               "The TopTags may have been truncated by topTags(n = ); the counts cover only the rows in this table, and it cannot be confirmed that they are all genes." %L% "TopTags \u53ef\u80fd\u88ab topTags(n = ) \u622a\u65ad\uff0c\u8ba1\u6570\u53ea\u8986\u76d6\u6b64\u8868\u4e2d\u7684\u884c\uff0c\u65e0\u6cd5\u786e\u8ba4\u662f\u5426\u4e3a\u5168\u90e8\u57fa\u56e0\u3002")
      p_adjust_method <- NULL
    } else {
      unc <- c(unc, "The TopTags has no FDR/FWER column; BH is computed over the existing rows, and the FDR is too small if the table was truncated." %L% "TopTags \u6ca1\u6709 FDR/FWER \u5217\uff1bBH \u5728\u73b0\u6709\u884c\u4e0a\u8ba1\u7b97\uff0c\u82e5\u8be5\u8868\u88ab\u622a\u65ad\u5219 FDR \u504f\u5c0f\u3002")
    }
  } else {
    unc <- c(unc, "The table of a DGEExact/DGELRT contains all tested genes but no adjusted p-value; BioExplainR computed adjusted p-values explicitly over all rows." %L% "DGEExact/DGELRT \u7684 table \u542b\u5168\u90e8\u88ab\u68c0\u9a8c\u57fa\u56e0\u4f46\u6ca1\u6709\u6821\u6b63 p \u503c\uff1bBioExplainR \u5728\u5168\u90e8\u884c\u4e0a\u663e\u5f0f\u8ba1\u7b97\u4e86\u6821\u6b63 p \u503c\u3002")
  }
  if (!length(adj)) p_adjust_method <- p_adjust_method %||% "BH"
  tab <- tab[intersect(c("logFC", "logCPM", "PValue", "FDR", "FWER"), names(tab))]
  tab <- cbind(gene = rownames(tab) %||% as.character(seq_len(nrow(tab))), tab, stringsAsFactors = FALSE)
  rownames(tab) <- NULL
  if (!is.null(x$genes) && is.data.frame(x$genes) && nrow(x$genes) == nrow(tab)) {
    gc <- .find_col(x$genes, c("Symbol", "SYMBOL", "gene_name", "GeneID"))
    if (!is.null(gc)) tab$gene <- as.character(x$genes[[gc]])
  }
  .adapt_de_table(tab, meta = meta, n_top = n_top, thresholds = thresholds,
                  p_adjust_method = p_adjust_method, analysis_type = "differential_expression",
                  source_class = class(x), source_package = "edgeR", source_status = "verified_class",
                  extra_facts = extra, extra_uncertainty = unc)
}

# SummarizedExperiment (non-single-cell) ----------------------------------------------------------
.adapt_se <- function(x, meta = list(), n_top = 10, sample_col = NULL, group_col = NULL, batch_col = NULL, ...) {
  if (!requireNamespace("SummarizedExperiment", quietly = TRUE)) {
    ctx <- .adapt_generic(x, meta = meta)
    ctx$uncertainty <- c(ctx$uncertainty, "SummarizedExperiment must be installed to read the assay, rowData and colData." %L% "\u9700\u8981\u5b89\u88c5 SummarizedExperiment \u624d\u80fd\u8bfb\u53d6 assay\u3001rowData \u548c colData\u3002")
    ctx$source_package <- "SummarizedExperiment"; ctx$source_status <- "verified_class"
    return(ctx)
  }
  cd <- as.data.frame(SummarizedExperiment::colData(x), stringsAsFactors = FALSE)
  rd <- tryCatch(as.data.frame(SummarizedExperiment::rowData(x), stringsAsFactors = FALSE), error = function(e) NULL)
  sample_col <- sample_col %||% .first_col(cd, .sample_aliases)
  group_col <- group_col %||% .first_col(cd, .group_aliases)
  batch_col <- batch_col %||% .first_col(cd, .batch_aliases)
  des <- .design_facts(cd, sample_col, group_col, batch_col, unit = "columns")
  facts <- c(list(n_features = nrow(x), n_columns = ncol(x), assays = SummarizedExperiment::assayNames(x)), des$facts)
  facts$colData_variables <- vapply(names(cd), function(n) class(cd[[n]])[1], "")[seq_len(min(ncol(cd), 20))]
  if (!is.null(rd)) facts$rowData_columns <- utils::head(names(rd), 20)
  facts$assay_summaries <- lapply(stats::setNames(seq_along(SummarizedExperiment::assayNames(x)), SummarizedExperiment::assayNames(x)), function(i) {
    tryCatch(.matrix_facts(SummarizedExperiment::assay(x, i, withDimnames = FALSE)), error = function(e) list(error = conditionMessage(e)))
  })
  unc <- c(des$uncertainty,
           "Columns are usually samples/libraries, but a library is not necessarily an independent donor; unless a sample column is supplied, the number of columns must not be used as the number of biological replicates." %L% "\u5217\uff08columns\uff09\u901a\u5e38\u662f\u6837\u672c/\u6587\u5e93\uff0c\u4f46\u6587\u5e93\u4e0d\u4e00\u5b9a\u662f\u72ec\u7acb\u4f9b\u4f53\uff1b\u9664\u975e\u63d0\u4f9b\u6837\u672c\u5217\uff0c\u4e0d\u80fd\u628a\u5217\u6570\u5f53\u4f5c\u751f\u7269\u5b66\u91cd\u590d\u6570\u3002",
           "Only a limited subset of the assay values was inspected (stored slots for sparse matrices, at most one sampled block for dense matrices); this is not a full check of the values." %L% "assay \u6570\u503c\u53ea\u68c0\u67e5\u4e86\u6709\u9650\u5b50\u96c6\uff08\u7a00\u758f\u77e9\u9635\u8bfb\u53d6\u5b58\u50a8\u69fd\u4f4d\uff0c\u7a20\u5bc6\u77e9\u9635\u6700\u591a\u62bd\u6837\u4e00\u4e2a\u5c0f\u5757\uff09\uff0c\u4e0d\u662f\u5b8c\u6574\u6570\u503c\u6838\u67e5\u3002",
           if (is.null(group_col)) "No group column (such as condition/group) was identified, so the experimental design cannot be summarised." %L% "\u672a\u8bc6\u522b\u5230\u5206\u7ec4\u5217\uff08\u5982 condition/group\uff09\uff0c\u65e0\u6cd5\u603b\u7ed3\u5b9e\u9a8c\u8bbe\u8ba1\u3002",
           if (is.null(sample_col)) "No sample/donor column was identified, so the number of replicates is unknown." %L% "\u672a\u8bc6\u522b\u5230\u6837\u672c/\u4f9b\u4f53\u5217\uff0c\u91cd\u590d\u6570\u672a\u77e5\u3002")
  new_bio_context("summarized_experiment", class(x), "SummarizedExperiment", "verified_class",
                  facts = facts, metadata = meta, uncertainty = unc)
}

# Biobase ExpressionSet -------------------------------------------------------
.adapt_expression_set <- function(x, meta = list(), n_top = 10, group_col = NULL,
                                  sample_col = NULL, batch_col = NULL, ...) {
  if (!requireNamespace("Biobase", quietly = TRUE)) {
    stop("ExpressionSet input requires the optional package 'Biobase'.", call. = FALSE)
  }
  assay <- Biobase::exprs(x)
  pheno <- as.data.frame(Biobase::pData(x), stringsAsFactors = FALSE)
  sample_col <- sample_col %||% .first_col(pheno, .sample_aliases)
  group_col <- group_col %||% .first_col(pheno, .group_aliases)
  batch_col <- batch_col %||% .first_col(pheno, .batch_aliases)
  design <- .design_facts(pheno, sample_col, group_col, batch_col, unit = "samples")
  facts <- c(list(n_features = nrow(assay), n_samples = ncol(assay),
                  pheno_columns = utils::head(names(pheno), 20),
                  assay_summary = .matrix_facts(assay)), design$facts)
  uncertainty <- c(
    design$uncertainty,
    "ExpressionSet assay values were summarised without inferring a differential-expression design; group labels do not establish a valid contrast or biological replication."
  )
  new_bio_context("expression_set", class(x), "Biobase", "verified_class",
                  facts = facts, metadata = meta, uncertainty = uncertainty,
                  adapter = "expression_set")
}

# Table behind a source object, for plot cross-checks (full table, transient) ------------------------
.source_table <- function(x, coefficient = NULL) {
  if (inherits(x, "MArrayLM")) {
    t <- .marraylm_table(x, coefficient)$table
    t$adj.P.Val <- stats::p.adjust(t$P.Value, "BH")
    return(t)
  }
  if (inherits(x, c("TopTags", "DGEExact", "DGELRT"))) {
    t <- .edger_table(x)
    if (!"gene" %in% names(t) && !is.null(rownames(t))) t$gene <- rownames(t)
    if (!any(c("FDR", "FWER") %in% names(t)) && "PValue" %in% names(t)) t$FDR <- stats::p.adjust(t$PValue, "BH")
    return(t)
  }
  if (inherits(x, "DESeqResults") || isS4(x)) {
    df <- tryCatch(methods::as(x, "data.frame"), error = function(e) tryCatch(as.data.frame(x), error = function(e2) NULL))
    if (is.data.frame(df)) return(df)
  }
  if (is.data.frame(x)) return(x)
  if (is.matrix(x)) return(as.data.frame(x))
  NULL
}
