# Enrichment adapters (ORA and GSEA) --------------------------------------------

.enrich_aliases <- list(
  id = c("ID", "term_id", "pathway", "Term", "GO.ID"),
  description = c("Description", "description", "term_name", "Term", "pathway", "name"),
  p_raw = c("pvalue", "p.value", "pval", "P.value", "PValue"),
  p_adj = c("p.adjust", "padj", "FDR", "adj.P.Val", "p.adj", "fdr", "Adjusted.P.value"),
  qvalue = c("qvalue", "qvalues", "q.value"),
  count = c("Count", "count", "overlap_size", "intersection_size"),
  gene_ratio = c("GeneRatio"),
  bg_ratio = c("BgRatio"),
  genes = c("geneID", "genes", "intersection"),
  nes = c("NES", "nes"),
  es = c("enrichmentScore", "ES"),
  set_size = c("setSize", "size", "term_size"),
  leading_edge = c("core_enrichment", "leadingEdge", "leading_edge_genes"),
  leading_edge_stats = c("leading_edge")
)

.enrich_columns <- function(df) lapply(.enrich_aliases, function(a) .find_col(df, a))

.detect_enrichment_table <- function(x) {
  if (!is.data.frame(x)) return(FALSE)
  cols <- .enrich_columns(x)
  has_term <- !is.null(cols$description) || !is.null(cols$id)
  has_p <- !is.null(cols$p_adj) || !is.null(cols$p_raw)
  has_enrich_stat <- !is.null(cols$nes) || !is.null(cols$gene_ratio) || !is.null(cols$count) || !is.null(cols$set_size)
  has_term && has_p && has_enrich_stat && is.null(.find_col(x, .de_aliases$lfc))
}

.ratio_to_num <- function(x) {
  x <- as.character(x)
  vapply(strsplit(x, "/", fixed = TRUE), function(z) {
    z <- suppressWarnings(as.numeric(z))
    if (length(z) == 2 && !is.na(z[2]) && z[2] != 0) z[1] / z[2] else NA_real_
  }, numeric(1))
}

.adapt_enrichment_table <- function(x, meta = list(), n_top = 10, thresholds = list(padj = 0.05),
                                    p_adjust_method = NULL, analysis_type = NULL,
                                    source_class = class(x), source_package = NULL,
                                    source_status = NULL, extra_facts = list(),
                                    extra_uncertainty = character(), group_col = NULL, ...) {
  df <- as.data.frame(x, stringsAsFactors = FALSE)
  cols <- .enrich_columns(df)
  if (is.null(cols$description) && is.null(cols$id)) stop("No term/pathway column found.", call. = FALSE)
  is_gsea <- if (identical(analysis_type, "enrichment_gsea")) TRUE
             else if (identical(analysis_type, "enrichment_ora")) FALSE
             else !is.null(cols$nes)
  unc <- extra_uncertainty
  if (is.null(source_status)) {
    clusterprofiler_like <- all(c("ID", "Description", "p.adjust") %in% names(df))
    source_status <- if (clusterprofiler_like) "inferred_from_columns" else "unknown"
    source_package <- if (clusterprofiler_like) "clusterProfiler/DOSE" else NA_character_
    unc <- c(unc, if (clusterprofiler_like)
      "Column names resemble the as.data.frame() output of clusterProfiler/DOSE, but the source package is only inferred." %L%
        "\u5217\u540d\u4e0e clusterProfiler/DOSE \u7684 as.data.frame() \u8f93\u51fa\u76f8\u4f3c\uff0c\u4f46\u6765\u6e90\u5305\u4ec5\u4e3a\u63a8\u6d4b\u3002"
      else "The package that produced this enrichment analysis cannot be determined from its column names." %L%
        "\u65e0\u6cd5\u4ece\u5217\u540d\u786e\u5b9a\u5bcc\u96c6\u5206\u6790\u7684\u8f6f\u4ef6\u5305\u3002")
  }
  praw <- if (!is.null(cols$p_raw)) .numeric_column(df, cols$p_raw, probability = TRUE) else NULL
  padj <- if (!is.null(cols$p_adj)) .numeric_column(df, cols$p_adj, probability = TRUE) else NULL
  if (is.null(praw) && is.null(padj)) stop("No p-value column found (raw or adjusted).", call. = FALSE)
  basis <- "adjusted_column"
  if (is.null(padj)) {
    if (!is.null(p_adjust_method) && !is.null(praw)) {
      padj <- stats::p.adjust(praw, method = p_adjust_method)
      basis <- paste0("computed_", p_adjust_method)
      unc <- c(unc, paste0("Adjusted p-values were computed by BioExplainR from the raw p-values with p.adjust(method = '" %L% "\u6821\u6b63 p \u503c\u7531 BioExplainR \u7528 p.adjust(method = '", p_adjust_method,
                           "'); if the table contains only a pre-filtered subset of pathways, the result is unreliable." %L% "') \u4ece\u539f\u59cb p \u503c\u8ba1\u7b97\uff1b\u82e5\u8be5\u8868\u53ea\u5305\u542b\u90e8\u5206\u5df2\u7b5b\u9009\u901a\u8def\uff0c\u7ed3\u679c\u4e0d\u53ef\u9760\u3002"))
    } else {
      basis <- "raw_only"
      unc <- c(unc, "The enrichment table has no adjusted p-value; raw p-values were not treated as FDR and significance is labelled by raw p-value only." %L% "\u5bcc\u96c6\u8868\u6ca1\u6709\u6821\u6b63\u540e p \u503c\uff1b\u672a\u628a\u539f\u59cb p \u503c\u5f53\u4f5c FDR\uff0c\u663e\u8457\u6027\u53ea\u6309\u539f\u59cb p \u503c\u6807\u6ce8\u3002")
    }
  }
  alpha <- thresholds$padj %||% 0.05
  p_thr <- thresholds$p %||% 0.05
  n <- nrow(df)
  sig <- if (!is.null(padj)) !is.na(padj) & padj < alpha else !is.na(praw) & praw < p_thr
  facts <- list(
    n_terms = n,
    enrichment_method = if (is_gsea) "GSEA" else "ORA",
    p_value_basis = basis,
    significance_threshold = if (!is.null(padj)) alpha else p_thr,
    n_significant = sum(sig)
  )
  if (!is.null(padj)) facts$n_na_padj <- sum(is.na(padj))
  if (is_gsea && !is.null(cols$nes)) {
    nes <- .numeric_column(df, cols$nes)
    facts$n_positive_nes_significant <- sum(sig & nes > 0, na.rm = TRUE)
    facts$n_negative_nes_significant <- sum(sig & nes < 0, na.rm = TRUE)
    facts$nes_range <- if (any(!is.na(nes))) range(nes, na.rm = TRUE) else NA
  }
  if (!is_gsea) {
    if (!is.null(cols$count)) {
      cnt <- suppressWarnings(as.numeric(df[[cols$count]]))
      if (any(sig)) facts$count_range_significant <- range(cnt[sig], na.rm = TRUE)
    }
    if (!is.null(cols$bg_ratio) && n > 0) {
      bg <- as.character(df[[cols$bg_ratio]][1])
      facts$background_size_from_bgratio <- suppressWarnings(as.numeric(sub("^.*/", "", bg)))
    }
    if (!is.null(cols$gene_ratio) && n > 0) {
      gr <- as.character(df[[cols$gene_ratio]][1])
      facts$input_genes_mapped_from_generatio <- suppressWarnings(as.numeric(sub("^.*/", "", gr)))
    }
  }
  desc <- if (!is.null(cols$description)) as.character(df[[cols$description]]) else as.character(df[[cols$id]])
  gcol <- group_col %||% .find_col(df, c("Cluster", "cluster"))
  grp <- if (!is.null(gcol) && gcol %in% names(df)) .clean_id(df[[gcol]]) else NULL
  if (!is.null(group_col) && is.null(grp)) stop("group_col '", group_col, "' not found.", call. = FALSE)
  if (!is.null(grp)) {
    # compareCluster-style table: p.adjust is computed within each cluster upstream.
    obs <- sort(unique(grp[!is.na(grp)]))
    ngc <- extra_facts$n_input_genes_per_cluster
    facts$cluster_column <- gcol
    facts$n_clusters <- length(obs)
    facts$n_unused_cluster_levels <- if (is.factor(df[[gcol]])) sum(!levels(df[[gcol]]) %in% obs) else 0L
    facts$per_cluster <- lapply(stats::setNames(obs, obs), function(g) {
      i <- which(grp == g)
      o <- i[order((padj %||% praw)[i], na.last = NA)]
      list(n_terms = length(i), n_significant = sum(sig[i]),
           n_input_genes = if (!is.null(ngc[[g]])) ngc[[g]] else NULL,
           top_terms = .truncate_chr(utils::head(desc[o], 3), 60))
    })
    unc <- c(unc, "The result table has a Cluster column: significant counts are also summarised per cluster (per_cluster); each cluster has a different input gene list, so term counts cannot be used directly to compare strength between clusters." %L% "\u7ed3\u679c\u8868\u542b Cluster \u5217\uff1a\u663e\u8457\u6570\u91cf\u540c\u65f6\u6309 cluster \u5206\u522b\u6c47\u603b\uff08per_cluster\uff09\uff1b\u5404 cluster \u7684\u8f93\u5165\u57fa\u56e0\u5217\u8868\u4e0d\u540c\uff0c\u6761\u76ee\u6570\u91cf\u4e0d\u80fd\u76f4\u63a5\u4f5c\u4e3a cluster \u95f4\u5f3a\u5f31\u6bd4\u8f83\u3002",
             if (any(is.na(grp))) paste0(sum(is.na(grp)), " rows lack a Cluster label and are not counted in any cluster." %L% " \u884c\u7f3a\u5c11 Cluster \u6807\u7b7e\uff0c\u672a\u8ba1\u5165\u4efb\u4f55 cluster\u3002"))
  }
  facts <- c(facts, extra_facts[setdiff(names(extra_facts), "n_input_genes_per_cluster")])
  if (!is.null(extra_facts$n_input_genes_per_cluster)) facts$n_input_genes_per_cluster <- extra_facts$n_input_genes_per_cluster

  order_p <- padj %||% praw
  ord <- if (!is.null(order_p)) order(order_p, na.last = NA) else seq_len(n)
  ord <- utils::head(ord, n_top)
  top <- data.frame(term = .truncate_chr(desc[ord], 80), stringsAsFactors = FALSE)
  if (!is.null(grp)) top <- cbind(cluster = grp[ord], top, stringsAsFactors = FALSE)
  if (!is.null(cols$id) && !identical(cols$id, cols$description)) top$id <- as.character(df[[cols$id]][ord])
  if (!is_gsea) {
    if (!is.null(cols$count)) top$Count <- df[[cols$count]][ord]
    if (!is.null(cols$gene_ratio)) {
      top$GeneRatio <- as.character(df[[cols$gene_ratio]][ord])
      top$gene_ratio_value <- signif(.ratio_to_num(top$GeneRatio), 3)
    }
    if (!is.null(cols$bg_ratio)) top$BgRatio <- as.character(df[[cols$bg_ratio]][ord])
  } else {
    if (!is.null(cols$set_size)) top$setSize <- df[[cols$set_size]][ord]
    if (!is.null(cols$nes)) top$NES <- signif(suppressWarnings(as.numeric(df[[cols$nes]][ord])), 4)
    if (!is.null(cols$leading_edge_stats)) top$leading_edge <- .truncate_chr(df[[cols$leading_edge_stats]][ord], 60)
  }
  if (!is.null(praw)) top$pvalue <- signif(praw[ord], 4)
  if (!is.null(padj)) top$p.adjust <- signif(padj[ord], 4)
  gcol <- if (is_gsea) cols$leading_edge else cols$genes
  if (!is.null(gcol)) {
    g <- as.character(df[[gcol]][ord])
    top$genes_preview <- vapply(strsplit(g, "/", fixed = TRUE), function(z) {
      paste0(paste(utils::head(z, 8), collapse = "/"), if (length(z) > 8) paste0("/... (", length(z), " genes)") else "")
    }, character(1))
  }

  if (is_gsea) {
    unc <- c(unc,
      "The sign of the GSEA NES depends on the direction of the gene ranking metric (for example which group log2FC was computed against); a positive NES means the gene set concentrates at the top of the ranked list, which does not directly mean the pathway is activated." %L% "GSEA \u7684 NES \u6b63\u8d1f\u53d6\u51b3\u4e8e\u57fa\u56e0\u6392\u5e8f\u6307\u6807\u7684\u65b9\u5411\uff08\u4f8b\u5982 log2FC \u7531\u54ea\u7ec4\u76f8\u5bf9\u54ea\u7ec4\u8ba1\u7b97\uff09\uff1b\u6b63 NES \u8868\u793a\u57fa\u56e0\u96c6\u4e2d\u5728\u6392\u5e8f\u5217\u8868\u9876\u90e8\uff0c\u5e76\u4e0d\u76f4\u63a5\u7b49\u4e8e\u901a\u8def\u88ab\u6fc0\u6d3b\u3002",
      "Leading-edge genes are the subset driving the enrichment score; they do not mean that every gene in the pathway changed." %L% "leading-edge \u57fa\u56e0\u662f\u9a71\u52a8\u5bcc\u96c6\u5206\u6570\u7684\u5b50\u96c6\uff0c\u4e0d\u4ee3\u8868\u901a\u8def\u4e2d\u6240\u6709\u57fa\u56e0\u90fd\u53d1\u751f\u53d8\u5316\u3002")
  } else {
    unc <- c(unc,
      "ORA (over-representation analysis) only tests whether the overlap between the input gene list and a gene set exceeds chance; it has no 'activation/inhibition' direction, so a pathway cannot be called activated from it." %L% "ORA\uff08\u8fc7\u8868\u8fbe\u5206\u6790\uff09\u53ea\u68c0\u9a8c\u8f93\u5165\u57fa\u56e0\u5217\u8868\u4e0e\u57fa\u56e0\u96c6\u7684\u91cd\u53e0\u662f\u5426\u8d85\u51fa\u968f\u673a\u9884\u671f\uff0c\u672c\u8eab\u6ca1\u6709\u201c\u6fc0\u6d3b/\u6291\u5236\u201d\u65b9\u5411\uff0c\u4e0d\u80fd\u636e\u6b64\u8ba4\u5b9a\u901a\u8def\u6fc0\u6d3b\u3002",
      "ORA results depend on the choice of background gene set (universe); without a suitable background the p-values may be over- or under-estimated." %L% "ORA \u7ed3\u679c\u4f9d\u8d56\u80cc\u666f\u57fa\u56e0\u96c6\uff08universe\uff09\u7684\u9009\u62e9\uff1b\u672a\u6307\u5b9a\u5408\u9002\u80cc\u666f\u65f6 p \u503c\u53ef\u80fd\u88ab\u9ad8\u4f30\u6216\u4f4e\u4f30\u3002")
  }
  if (sum(sig) > 1) unc <- c(unc, "Several significant terms may share many genes (GO hierarchy redundancy) and should not be treated as mutually independent evidence." %L% "\u591a\u4e2a\u663e\u8457\u6761\u76ee\u53ef\u80fd\u5171\u4eab\u5927\u91cf\u57fa\u56e0\uff08GO \u5c42\u7ea7\u5197\u4f59\uff09\uff0c\u4e0d\u5e94\u88ab\u89c6\u4e3a\u76f8\u4e92\u72ec\u7acb\u7684\u8bc1\u636e\u3002")
  if (!is.null(meta$data_dependencies)) {
    unc <- c(unc, paste0("This enrichment result is derived from: " %L% "\u8be5\u5bcc\u96c6\u7ed3\u679c\u6d3e\u751f\u81ea\uff1a", paste(meta$data_dependencies, collapse = ", "),
                         "; it is derived evidence and not an independent validation of the upstream result." %L% "\uff1b\u5b83\u662f\u6d3e\u751f\u8bc1\u636e\uff0c\u4e0d\u6784\u6210\u5bf9\u4e0a\u6e38\u7ed3\u679c\u7684\u72ec\u7acb\u9a8c\u8bc1\u3002"))
  }
  new_bio_context(
    analysis_type = if (is_gsea) "enrichment_gsea" else "enrichment_ora",
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

.enrich_common_slots <- function(x, meta) {
  extra <- list()
  org <- .slot_or(x, "organism")
  if (!.is_blank(org) && !identical(org, "UNKNOWN")) {
    extra$organism <- as.character(org)[1]
    if (is.null(meta$species)) meta$species <- as.character(org)[1]
  }
  ont <- .slot_or(x, "ontology")
  if (!.is_blank(ont)) extra$ontology <- as.character(ont)[1]
  kt <- .slot_or(x, "keytype")
  if (!.is_blank(kt) && !identical(kt, "UNKNOWN")) {
    extra$keytype <- as.character(kt)[1]
    if (is.null(meta$gene_id_type)) meta$gene_id_type <- as.character(kt)[1]
  }
  pam <- .slot_or(x, "pAdjustMethod")
  if (!.is_blank(pam)) extra$p_adjust_method <- as.character(pam)[1]
  list(extra = extra, meta = meta)
}

.adapt_enrich_result <- function(x, meta = list(), n_top = 10, thresholds = list(), ...) {
  res <- .slot_or(x, "compareClusterResult") %||% .slot_or(x, "result")
  if (!is.data.frame(res)) stop("enrichResult has no 'result' data.frame slot.", call. = FALSE)
  cm <- .enrich_common_slots(x, meta)
  extra <- cm$extra
  pc <- .slot_or(x, "pvalueCutoff")
  if (!is.null(pc)) {
    extra$object_pvalue_cutoff <- pc
    if (!.user_set(thresholds, "padj")) thresholds$padj <- pc
  }
  qc <- .slot_or(x, "qvalueCutoff")
  if (!is.null(qc)) extra$object_qvalue_cutoff <- qc
  g <- .slot_or(x, "gene")
  if (!is.null(g)) extra$n_input_genes <- length(g)
  u <- .slot_or(x, "universe")
  if (!is.null(u)) extra$universe_size <- length(u)
  gcl <- .slot_or(x, "geneClusters")
  if (is.list(gcl) && length(gcl)) {
    extra$n_input_genes_per_cluster <- lapply(gcl, length)
    fn <- .slot_or(x, "fun")
    if (!.is_blank(fn)) extra$compare_cluster_fun <- as.character(fn)[1]
  }
  unc <- c("enrichResult@result contains all tested terms; printing the object shows only terms passing pvalueCutoff/qvalueCutoff, and the number of significant terms is recomputed with the p.adjust threshold." %L% "enrichResult@result \u5305\u542b\u5168\u90e8\u68c0\u9a8c\u6761\u76ee\uff1b\u5bf9\u8c61\u6253\u5370\u65f6\u53ea\u663e\u793a\u901a\u8fc7 pvalueCutoff/qvalueCutoff \u7684\u6761\u76ee\uff0c\u663e\u8457\u6570\u91cf\u4ee5 p.adjust \u9608\u503c\u91cd\u65b0\u8ba1\u7b97\u3002")
  if (is.null(u) || length(u) == 0) unc <- c(unc, "The object did not record the universe (background genes); the background may be all genes in the annotation database." %L% "\u5bf9\u8c61\u672a\u8bb0\u5f55 universe\uff08\u80cc\u666f\u57fa\u56e0\uff09\uff0c\u80cc\u666f\u53ef\u80fd\u662f\u6ce8\u91ca\u6570\u636e\u5e93\u4e2d\u7684\u5168\u90e8\u57fa\u56e0\u3002")
  if (!is.null(gcl) && is.list(gcl) && length(gcl)) {
    unc <- c(unc, "compareCluster: p.adjust is applied within each cluster; clusters have different numbers of input genes, so the results are not one family of tests." %L% "compareCluster\uff1ap.adjust \u5728\u6bcf\u4e2a cluster \u5185\u5206\u522b\u6821\u6b63\uff1b\u5404 cluster \u8f93\u5165\u57fa\u56e0\u6570\u4e0d\u540c\uff0c\u7ed3\u679c\u4e4b\u95f4\u4e0d\u662f\u540c\u4e00\u68c0\u9a8c\u65cf\u3002")
  }
  ctx <- .adapt_enrichment_table(res, meta = cm$meta, n_top = n_top, thresholds = thresholds,
                                 analysis_type = "enrichment_ora", source_class = class(x),
                                 source_package = attr(class(x), "package") %||% "DOSE/clusterProfiler",
                                 source_status = "verified_class", extra_facts = extra,
                                 extra_uncertainty = unc)
  ctx
}

.adapt_gsea_result <- function(x, meta = list(), n_top = 10, thresholds = list(), ...) {
  res <- .slot_or(x, "result")
  if (!is.data.frame(res)) stop("gseaResult has no 'result' data.frame slot.", call. = FALSE)
  cm <- .enrich_common_slots(x, meta)
  extra <- cm$extra
  st <- .slot_or(x, "setType")
  if (!.is_blank(st)) extra$set_type <- as.character(st)[1]
  params <- .slot_or(x, "params")
  if (is.list(params)) {
    keep <- intersect(names(params), c("pvalueCutoff", "pAdjustMethod", "minGSSize", "maxGSSize", "exponent", "eps", "nPerm"))
    extra$params <- lapply(params[keep], function(v) if (is.atomic(v) && length(v) <= 3) v else NULL)
    extra$params <- extra$params[!vapply(extra$params, is.null, logical(1))]
    if (!is.null(params$pvalueCutoff) && !.user_set(thresholds, "padj")) thresholds$padj <- params$pvalueCutoff
  }
  gl <- .slot_or(x, "geneList")
  if (is.numeric(gl)) {
    extra$ranked_list_length <- length(gl)
    extra$ranked_list_n_positive <- sum(gl > 0, na.rm = TRUE)
    extra$ranked_list_n_negative <- sum(gl < 0, na.rm = TRUE)
  }
  .adapt_enrichment_table(res, meta = cm$meta, n_top = n_top, thresholds = thresholds,
                          analysis_type = "enrichment_gsea", source_class = class(x),
                          source_package = attr(class(x), "package") %||% "DOSE/clusterProfiler",
                          source_status = "verified_class", extra_facts = extra)
}
