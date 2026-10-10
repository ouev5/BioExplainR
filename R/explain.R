# Explanations -------------------------------------------------------------------

.section_names <- c("data_facts", "statistical_meaning", "biological_interpretation",
                    "uncertainty", "cannot_conclude", "learning_questions")

.section_titles <- c(
  data_facts = "\u6570\u636e\u4e8b\u5b9e\uff08\u7531 R \u786e\u5b9a\u6027\u8ba1\u7b97\uff09",
  statistical_meaning = "\u7edf\u8ba1\u542b\u4e49",
  biological_interpretation = "\u751f\u7269\u5b66\u89e3\u91ca\uff08\u9700\u7ed3\u5408\u8bc1\u636e\u6838\u67e5\uff09",
  uncertainty = "\u4e0d\u786e\u5b9a\u6027\u4e0e\u9650\u5236",
  cannot_conclude = "\u4e0d\u80fd\u636e\u6b64\u63a8\u51fa\u7684\u7ed3\u8bba",
  learning_questions = "\u5b66\u4e60\u95ee\u9898",
  concepts = "\u6982\u5ff5\u5361\u7247"
)

.concept_cards <- list(
  pvalue = "p \u503c\uff1a\u5728\u201c\u6ca1\u6709\u771f\u5b9e\u5dee\u5f02\u201d\u7684\u5047\u8bbe\u4e0b\uff0c\u89c2\u5bdf\u5230\u5f53\u524d\u6216\u66f4\u6781\u7aef\u7ed3\u679c\u7684\u6982\u7387\uff1b\u4e0d\u662f\u6548\u5e94\u5927\u5c0f\uff0c\u4e5f\u4e0d\u662f\u5047\u8bbe\u4e3a\u771f\u7684\u6982\u7387\u3002",
  padj = "\u6821\u6b63\u540e p \u503c\uff08FDR/padj\uff09\uff1a\u540c\u65f6\u68c0\u9a8c\u6210\u5343\u4e0a\u4e07\u4e2a\u57fa\u56e0\u65f6\uff0c\u7528\u4e8e\u63a7\u5236\u5047\u53d1\u73b0\u6bd4\u4f8b\u7684\u6307\u6807\uff0c\u4f8b\u5982 padj < 0.05 \u8868\u793a\u5728\u8be5\u9608\u503c\u4e0b\u9884\u671f\u5047\u53d1\u73b0\u6bd4\u4f8b\u7ea6 5%\u3002",
  log2fc = "log2 fold change\uff1a\u4e24\u7ec4\u8868\u8fbe\u91cf\u4e4b\u6bd4\u53d6\u4ee5 2 \u4e3a\u5e95\u7684\u5bf9\u6570\uff1b1 \u8868\u793a\u7ea6 2 \u500d\uff0c-1 \u8868\u793a\u7ea6\u4e00\u534a\u3002\u6b63\u8d1f\u65b9\u5411\u53d6\u51b3\u4e8e\u6bd4\u8f83\u987a\u5e8f\u3002",
  ora = "ORA\uff08\u8fc7\u8868\u8fbe\u5206\u6790\uff09\uff1a\u68c0\u9a8c\u8f93\u5165\u57fa\u56e0\u5217\u8868\u5728\u67d0\u57fa\u56e0\u96c6\u4e2d\u662f\u5426\u6bd4\u968f\u673a\u671f\u671b\u51fa\u73b0\u5f97\u66f4\u591a\uff0c\u4f7f\u7528\u8d85\u51e0\u4f55/Fisher \u68c0\u9a8c\u3002",
  gsea = "GSEA\uff1a\u5728\u6309\u67d0\u6307\u6807\u6392\u5e8f\u7684\u5168\u90e8\u57fa\u56e0\u5217\u8868\u4e2d\uff0c\u68c0\u9a8c\u57fa\u56e0\u96c6\u6210\u5458\u662f\u5426\u96c6\u4e2d\u5728\u5217\u8868\u9876\u90e8\u6216\u5e95\u90e8\uff1bNES \u662f\u6807\u51c6\u5316\u5bcc\u96c6\u5206\u6570\u3002",
  generatio = "GeneRatio\uff1a\u8f93\u5165\u57fa\u56e0\u4e2d\u843d\u5165\u8be5\u901a\u8def\u7684\u57fa\u56e0\u6570 / \u80fd\u88ab\u6ce8\u91ca\u7684\u8f93\u5165\u57fa\u56e0\u6570\u3002",
  pseudoreplication = "\u4f2a\u91cd\u590d\uff1a\u628a\u540c\u4e00\u6837\u672c\u7684\u591a\u4e2a\u7ec6\u80de\u5f53\u4f5c\u72ec\u7acb\u91cd\u590d\uff0c\u4f1a\u4f4e\u4f30\u53d8\u5f02\u5e76\u5938\u5927\u663e\u8457\u6027\u3002",
  qc = "QC \u6307\u6807\uff1anCount\uff08\u6bcf\u4e2a\u7ec6\u80de UMI \u603b\u6570\uff09\u3001nFeature\uff08\u68c0\u6d4b\u5230\u7684\u57fa\u56e0\u6570\uff09\u3001percent.mt\uff08\u7ebf\u7c92\u4f53\u57fa\u56e0\u6bd4\u4f8b\uff09\u5e38\u7528\u4e8e\u8bc6\u522b\u4f4e\u8d28\u91cf\u7ec6\u80de\u6216\u53cc\u7ec6\u80de\u3002",
  umap = "UMAP/t-SNE\uff1a\u975e\u7ebf\u6027\u964d\u7ef4\u53ef\u89c6\u5316\uff0c\u4fdd\u7559\u5c40\u90e8\u90bb\u8fd1\u5173\u7cfb\uff0c\u4f46\u7c07\u95f4\u8ddd\u79bb\u4e0e\u7c07\u5927\u5c0f\u4e0d\u53ef\u5b9a\u91cf\u89e3\u8bfb\u3002",
  pca = "PCA\uff1a\u5c06\u9ad8\u7ef4\u8868\u8fbe\u6570\u636e\u6295\u5f71\u5230\u65b9\u5dee\u6700\u5927\u7684\u82e5\u5e72\u6b63\u4ea4\u65b9\u5411\uff1b\u65b9\u5dee\u89e3\u91ca\u7387\u8bf4\u660e\u6bcf\u4e2a\u4e3b\u6210\u5206\u4fdd\u7559\u4e86\u591a\u5c11\u603b\u4f53\u53d8\u5f02\u3002",
  aes = "aes \u6620\u5c04\uff1aggplot \u4e2d\u628a\u6570\u636e\u5217\u6620\u5c04\u5230 x\u3001y\u3001\u989c\u8272\u3001\u5927\u5c0f\u7b49\u89c6\u89c9\u901a\u9053\u7684\u89c4\u5219\u3002"
)

.explain_local <- function(ctx, language = NULL) {
  language <- .check_language(language %||% ctx$language %||% .default_language)
  if (identical(language, "zh")) .explain_local_zh(ctx) else .explain_local_en(ctx)
}

.explain_local_zh <- function(ctx) {
  f <- ctx$facts
  md <- ctx$metadata
  type <- ctx$analysis_type
  s <- list(data_facts = character(), statistical_meaning = character(),
            biological_interpretation = character(), uncertainty = ctx$uncertainty,
            cannot_conclude = character(), learning_questions = character())
  concepts <- character()
  context_line <- paste(c(
    if (!is.null(md$species)) paste0("\u7269\u79cd\uff1a", md$species),
    if (!is.null(md$tissue)) paste0("\u7ec4\u7ec7\uff1a", md$tissue),
    if (!is.null(md$contrast)) paste0("\u6bd4\u8f83\uff1a", md$contrast),
    if (!is.null(md$design)) paste0("\u8bbe\u8ba1\uff1a", md$design)), collapse = "\uff1b")

  if (type %in% c("differential_expression", "markers")) {
    concepts <- c("pvalue", "padj", "log2fc")
    s$data_facts <- c(
      paste0("\u7ed3\u679c\u8868\u5171 ", f$n_features, " \u4e2a\u7279\u5f81\uff1blog2FC \u5217\u4e3a '", f$lfc_column, "'\u3002"),
      if (!is.na(f$adjusted_p_column) || grepl("^computed_", f$p_value_basis))
        paste0("\u5728 padj < ", f$padj_threshold, " \u4e14 |log2FC| > ", f$lfc_threshold, " \u7684\u6761\u4ef6\u4e0b\uff1a\u663e\u8457 ",
               f$n_significant, " \u4e2a\uff0c\u5176\u4e2d\u4e0a\u8c03 ", f$n_up, " \u4e2a\u3001\u4e0b\u8c03 ", f$n_down, " \u4e2a\uff1b",
               "padj \u4e3a NA \u7684\u7279\u5f81 ", f$n_na_padj, " \u4e2a\u3002"),
      if (identical(f$p_value_basis, "raw_only"))
        paste0("\u6ca1\u6709\u6821\u6b63\u540e p \u503c\u3002\u4ec5\u6309\u539f\u59cb p < ", f$raw_p_threshold, "\uff1a\u4e0a\u8c03 ", f$n_raw_up, " \u4e2a\u3001\u4e0b\u8c03 ",
               f$n_raw_down, " \u4e2a\uff08\u672a\u8fdb\u884c\u591a\u91cd\u68c0\u9a8c\u6821\u6b63\uff0c\u4e0d\u80fd\u79f0\u4e3a FDR \u663e\u8457\uff09\u3002"),
      if (!is.null(f$lfc_range)) paste0("log2FC \u8303\u56f4 ", .fmt_num(f$lfc_range[1]), " \u5230 ",
                                        .fmt_num(f$lfc_range[2]), "\uff0c\u4e2d\u4f4d\u6570 ", .fmt_num(f$lfc_median), "\u3002"),
      if (nzchar(context_line)) paste0(context_line, "\u3002")
    )
    s$statistical_meaning <- c(
      "log2FC \u63cf\u8ff0\u53d8\u5316\u65b9\u5411\u548c\u5927\u5c0f\uff0c\u6821\u6b63\u540e p \u503c\u63cf\u8ff0\u5728\u591a\u91cd\u68c0\u9a8c\u4e0b\u7ed3\u679c\u7684\u7edf\u8ba1\u53ef\u9760\u6027\uff1b\u4e8c\u8005\u662f\u4e0d\u540c\u7ef4\u5ea6\uff0c\u9700\u8981\u540c\u65f6\u770b\u3002",
      "p \u503c\u5f88\u5c0f\u4f46 log2FC \u5f88\u5c0f\u7684\u57fa\u56e0\uff0c\u7edf\u8ba1\u4e0a\u53ef\u9760\u4f46\u6548\u5e94\u53ef\u80fd\u5728\u751f\u7269\u5b66\u4e0a\u4e0d\u91cd\u8981\uff1b\u53cd\u4e4b\uff0c\u5927 log2FC \u4f46 padj \u4e0d\u663e\u8457\u53ef\u80fd\u6765\u81ea\u4f4e\u8868\u8fbe\u6216\u9ad8\u53d8\u5f02\u3002",
      if (grepl("^computed_", f$p_value_basis)) "\u672c\u6b21\u6821\u6b63 p \u503c\u662f\u7531 BioExplainR \u6839\u636e\u539f\u59cb p \u503c\u663e\u5f0f\u8ba1\u7b97\u7684\uff0c\u4ec5\u5f53\u8868\u683c\u5305\u542b\u5168\u90e8\u68c0\u9a8c\u7279\u5f81\u65f6\u6210\u7acb\u3002"
    )
    if (length(f$per_cluster)) {
      pc <- vapply(names(f$per_cluster), function(k) {
        z <- f$per_cluster[[k]]
        paste0(f$group_column, "=", k, "\uff1a", z$n_rows, " \u884c\uff0c\u663e\u8457 ", z$n_significant, "\uff08\u4e0a\u8c03 ", z$n_up, "\u3001\u4e0b\u8c03 ", z$n_down, "\uff09")
      }, "")
      s$data_facts <- c(s$data_facts, paste0("\u6309 ", f$group_column, " \u5206\u522b\u6c47\u603b\uff08\u4f9d\u636e ",
                        if (identical(f$per_cluster_significance_basis, "adjusted_p")) "\u6821\u6b63 p" else "\u539f\u59cb p", "\uff09\uff1a",
                        paste(utils::head(pc, 12), collapse = "\uff1b"), if (length(pc) > 12) "\u2026\u2026" else "", "\u3002"))
      s$cannot_conclude <- c(s$cannot_conclude, "\u5404 cluster \u7684 marker \u662f\u76f8\u5bf9\u4e8e\u5176\u4f59\u7ec6\u80de\u7684\u6bd4\u8f83\uff0c\u540c\u4e00\u57fa\u56e0\u53ef\u5728\u591a\u4e2a cluster \u51fa\u73b0\uff0c\u603b\u8ba1\u6570\u4e0d\u662f\u72ec\u7acb\u57fa\u56e0\u6570\u3002")
    }
    top <- ctx$top_features
    if (!is.null(top) && nrow(top)) {
      s$biological_interpretation <- c(
        paste0("\u6700\u663e\u8457\u7684\u7279\u5f81\u5305\u62ec\uff1a", paste(utils::head(top$feature, 5), collapse = "\u3001"),
               "\u3002\u53ef\u4ee5\u67e5\u9605\u8fd9\u4e9b\u57fa\u56e0\u7684\u529f\u80fd\u6ce8\u91ca\uff08\u4f8b\u5982 NCBI Gene\u3001UniProt\uff09\uff0c\u518d\u5224\u65ad\u662f\u5426\u4e0e\u5b9e\u9a8c\u5904\u7406\u76f8\u5173\u3002"),
        "\u5dee\u5f02\u8868\u8fbe\u53ea\u8bf4\u660e\u5728\u672c\u6570\u636e\u4e2d\u8868\u8fbe\u6c34\u5e73\u4e0e\u5206\u7ec4\u76f8\u5173\uff1b\u751f\u7269\u5b66\u673a\u5236\u9700\u8981\u6587\u732e\u3001\u6570\u636e\u5e93\u8bc1\u636e\u6216\u5b9e\u9a8c\u9a8c\u8bc1\u652f\u6301\u3002"
      )
    }
    s$cannot_conclude <- c("\u4e0d\u80fd\u628a\u201c\u663e\u8457\u5dee\u5f02\u8868\u8fbe\u201d\u76f4\u63a5\u5199\u6210\u201c\u8be5\u57fa\u56e0\u5bfc\u81f4\u4e86\u8868\u578b\u201d\u6216\u201c\u8be5\u901a\u8def\u88ab\u6fc0\u6d3b\u201d\u3002",
                           "\u4e0d\u80fd\u628a\u672a\u8fbe\u5230\u663e\u8457\u7684\u57fa\u56e0\u8bf4\u6210\u201c\u6ca1\u6709\u53d8\u5316\u201d\uff1b\u53ef\u80fd\u53ea\u662f\u7edf\u8ba1\u529f\u6548\u4e0d\u8db3\u3002",
                           if (identical(f$p_value_basis, "raw_only")) "\u4e0d\u80fd\u628a\u539f\u59cb p < 0.05 \u7684\u57fa\u56e0\u6570\u91cf\u5f53\u4f5c FDR \u63a7\u5236\u4e0b\u7684\u663e\u8457\u57fa\u56e0\u6570\u3002")
    s$learning_questions <- c("\u5982\u679c\u4ea4\u6362\u6bd4\u8f83\u7ec4\u7684\u987a\u5e8f\uff0clog2FC \u7684\u7b26\u53f7\u4f1a\u600e\u6837\u53d8\u5316\uff1f",
                              "\u4e3a\u4ec0\u4e48\u5728\u6570\u4e07\u4e2a\u57fa\u56e0\u540c\u65f6\u68c0\u9a8c\u65f6\u9700\u8981\u4f7f\u7528\u6821\u6b63\u540e\u7684 p \u503c\uff1f",
                              "\u4e00\u4e2a padj \u5f88\u5c0f\u4f46 |log2FC| = 0.1 \u7684\u57fa\u56e0\uff0c\u4f60\u4f1a\u5982\u4f55\u63cf\u8ff0\u5b83\uff1f")
  } else if (type %in% c("enrichment_ora", "enrichment_gsea")) {
    gsea <- type == "enrichment_gsea"
    concepts <- c(if (gsea) "gsea" else c("ora", "generatio"), "padj")
    s$data_facts <- c(
      paste0("\u5171 ", f$n_terms, " \u4e2a\u6761\u76ee\uff08", f$enrichment_method, "\uff09\uff1b\u6309 ",
             if (identical(f$p_value_basis, "raw_only")) "\u539f\u59cb p \u503c" else "\u6821\u6b63 p \u503c", " < ",
             f$significance_threshold, " \u8ba1\u6570\uff0c\u663e\u8457 ", f$n_significant, " \u4e2a\u3002"),
      if (gsea && !is.null(f$n_positive_nes_significant))
        paste0("\u663e\u8457\u6761\u76ee\u4e2d NES > 0 \u7684 ", f$n_positive_nes_significant, " \u4e2a\uff0cNES < 0 \u7684 ",
               f$n_negative_nes_significant, " \u4e2a\u3002"),
      if (!is.null(f$universe_size)) paste0("\u5bf9\u8c61\u8bb0\u5f55\u7684\u80cc\u666f\u57fa\u56e0\uff08universe\uff09\u6570\u91cf\uff1a", f$universe_size, "\u3002"),
      if (!is.null(f$background_size_from_bgratio)) paste0("\u7531 BgRatio \u5206\u6bcd\u5f97\u5230\u7684\u80cc\u666f\u57fa\u56e0\u6570\uff1a", f$background_size_from_bgratio,
                                                           if (!is.null(f$input_genes_mapped_from_generatio)) paste0("\uff1b\u7531 GeneRatio \u5206\u6bcd\u5f97\u5230\u7684\u53ef\u6ce8\u91ca\u8f93\u5165\u57fa\u56e0\u6570\uff1a", f$input_genes_mapped_from_generatio) else "", "\u3002"),
      if (!is.null(f$count_range_significant)) paste0("\u663e\u8457\u6761\u76ee\u7684\u91cd\u53e0\u57fa\u56e0\u6570\uff08Count\uff09\u8303\u56f4\uff1a", f$count_range_significant[1], "\u2013", f$count_range_significant[2], "\u3002"),
      if (!is.null(f$n_input_genes)) paste0("\u8f93\u5165\u57fa\u56e0\u6570\u91cf\uff1a", f$n_input_genes, "\u3002"),
      if (!is.null(f$ontology)) paste0("\u672c\u4f53/\u6570\u636e\u5e93\uff1a", f$ontology, "\u3002"),
      if (nzchar(context_line)) paste0(context_line, "\u3002")
    )
    s$statistical_meaning <- if (gsea) c(
      "GSEA \u4f7f\u7528\u5168\u90e8\u57fa\u56e0\u7684\u6392\u5e8f\uff0c\u800c\u4e0d\u662f\u9608\u503c\u7b5b\u9009\u7684\u57fa\u56e0\u5217\u8868\uff1bNES \u5df2\u5bf9\u57fa\u56e0\u96c6\u5927\u5c0f\u505a\u4e86\u6807\u51c6\u5316\u3002",
      "NES \u7684\u6b63\u8d1f\u8868\u793a\u57fa\u56e0\u96c6\u6210\u5458\u96c6\u4e2d\u5728\u6392\u5e8f\u5217\u8868\u7684\u9876\u7aef\u6216\u5e95\u7aef\uff0c\u5177\u4f53\u542b\u4e49\u53d6\u51b3\u4e8e\u6392\u5e8f\u6307\u6807\u7684\u65b9\u5411\u3002"
    ) else c(
      "ORA \u68c0\u9a8c\u8f93\u5165\u57fa\u56e0\u4e0e\u67d0\u57fa\u56e0\u96c6\u7684\u91cd\u53e0\u662f\u5426\u663e\u8457\u591a\u4e8e\u968f\u673a\u671f\u671b\uff1bGeneRatio \u548c Count \u63cf\u8ff0\u91cd\u53e0\u7a0b\u5ea6\u3002",
      "\u663e\u8457\u6027\u4f9d\u8d56\u8f93\u5165\u5217\u8868\u7684\u9608\u503c\u548c\u80cc\u666f\u57fa\u56e0\u96c6\uff0c\u6539\u53d8\u9608\u503c\u6216 universe \u53ef\u80fd\u663e\u8457\u6539\u53d8\u7ed3\u679c\u3002"
    )
    top <- ctx$top_features
    if (!is.null(top) && nrow(top)) {
      s$biological_interpretation <- c(
        paste0("\u6700\u663e\u8457\u7684\u6761\u76ee\u5305\u62ec\uff1a", paste(utils::head(top$term, 5), collapse = "\uff1b"), "\u3002"),
        "\u8fd9\u4e9b\u6761\u76ee\u63d0\u793a\u8f93\u5165\u57fa\u56e0\u5728\u76f8\u5e94\u529f\u80fd\u7c7b\u522b\u4e2d\u805a\u96c6\uff0c\u53ef\u4f5c\u4e3a\u751f\u7269\u5b66\u5047\u8bbe\u7684\u7ebf\u7d22\uff0c\u9700\u7ed3\u5408\u6838\u5fc3\u57fa\u56e0\u548c\u6587\u732e\u8bc1\u636e\u5224\u65ad\u3002"
      )
    }
    s$cannot_conclude <- c(
      if (!gsea) "ORA \u7ed3\u679c\u4e0d\u80fd\u8bf4\u660e\u901a\u8def\u88ab\u201c\u6fc0\u6d3b\u201d\u6216\u201c\u6291\u5236\u201d\u3002" else "\u6b63 NES \u4e0d\u80fd\u76f4\u63a5\u7b49\u540c\u4e8e\u901a\u8def\u6d3b\u6027\u5347\u9ad8\u3002",
      "\u591a\u4e2a GO \u6761\u76ee\u53ef\u80fd\u9ad8\u5ea6\u91cd\u53e0\uff0c\u4e0d\u80fd\u628a\u5b83\u4eec\u5f53\u4f5c\u591a\u6761\u72ec\u7acb\u8bc1\u636e\u3002",
      "\u7531\u540c\u4e00\u5dee\u5f02\u57fa\u56e0\u5217\u8868\u5f97\u5230\u7684\u5bcc\u96c6\u7ed3\u679c\u662f\u6d3e\u751f\u8bc1\u636e\uff0c\u4e0d\u662f\u5bf9\u5dee\u5f02\u8868\u8fbe\u7ed3\u679c\u7684\u72ec\u7acb\u9a8c\u8bc1\u3002")
    s$learning_questions <- c(
      "ORA \u4e0e GSEA \u7684\u8f93\u5165\u6709\u4ec0\u4e48\u4e0d\u540c\uff1f\u5404\u81ea\u9002\u5408\u56de\u7b54\u4ec0\u4e48\u95ee\u9898\uff1f",
      "\u5982\u679c\u628a\u80cc\u666f\u57fa\u56e0\u96c6\u4ece\u201c\u5168\u57fa\u56e0\u7ec4\u201d\u6362\u6210\u201c\u672c\u5b9e\u9a8c\u68c0\u6d4b\u5230\u7684\u57fa\u56e0\u201d\uff0c\u7ed3\u679c\u53ef\u80fd\u5982\u4f55\u53d8\u5316\uff1f",
      "\u5982\u4f55\u5224\u65ad\u4e24\u4e2a\u663e\u8457 GO \u6761\u76ee\u662f\u5426\u53ea\u662f\u540c\u4e00\u6279\u57fa\u56e0\u7684\u91cd\u590d\u4f53\u73b0\uff1f")
  } else if (type == "single_cell") {
    concepts <- c("qc", "umap", "pseudoreplication")
    qc_txt <- if (!is.null(f$qc)) vapply(names(f$qc), function(k) {
      q <- f$qc[[k]]$quantiles
      paste0(f$qc[[k]]$column, " \u4e2d\u4f4d\u6570 ", .fmt_num(q$median), "\uff08\u8303\u56f4 ", .fmt_num(q$min), "\u2013", .fmt_num(q$max), "\uff09")
    }, "") else NULL
    s$data_facts <- c(
      paste0("\u5171 ", f$n_cells, " \u4e2a\u7ec6\u80de",
             if (!is.null(f$n_features_active_assay)) paste0("\uff0c\u6d3b\u8dc3 assay '", f$active_assay, "' \u4e2d ", f$n_features_active_assay, " \u4e2a\u7279\u5f81") else "",
             if (!is.null(f$n_features)) paste0("\uff0c", f$n_features, " \u4e2a\u7279\u5f81") else "", "\u3002"),
      if (!is.null(f$assays)) paste0("assay\uff1a", paste(f$assays, collapse = ", "), "\u3002"),
      if (length(f$reductions)) paste0("\u964d\u7ef4\u7ed3\u679c\uff1a", paste(f$reductions, collapse = ", "), "\u3002"),
      if (!is.null(f$n_clusters)) paste0("cluster \u5217 '", f$cluster_column, "' \u5171 ", f$n_clusters, " \u4e2a\u7fa4\uff0c\u7ec6\u80de\u6570\u8303\u56f4 ",
                                         f$cluster_size_range[1], "\u2013", f$cluster_size_range[2], "\u3002"),
      if (!is.null(f$n_samples)) paste0("\u6837\u672c\u5217 '", f$sample_column, "' \u5171 ", f$n_samples, " \u4e2a\u6837\u672c/\u4f9b\u4f53\uff08\u540d\u79f0\u672a\u8f93\u51fa\uff09\u3002"),
      if (length(qc_txt)) paste0("QC\uff1a", paste(qc_txt, collapse = "\uff1b"), "\u3002"),
      if (nzchar(context_line)) paste0(context_line, "\u3002")
    )
    s$statistical_meaning <- c(
      "cluster \u662f\u57fa\u4e8e\u8868\u8fbe\u76f8\u4f3c\u6027\u7684\u65e0\u76d1\u7763\u5206\u7ec4\uff0c\u805a\u7c7b\u5206\u8fa8\u7387\u53c2\u6570\u4f1a\u6539\u53d8 cluster \u6570\u91cf\u3002",
      "\u6bd4\u8f83\u7ec4\u95f4\u5dee\u5f02\u65f6\uff0c\u72ec\u7acb\u91cd\u590d\u7684\u5355\u4f4d\u662f\u6837\u672c/\u4f9b\u4f53\uff0c\u800c\u4e0d\u662f\u7ec6\u80de\u3002")
    s$biological_interpretation <- c(
      "cluster \u7684\u7ec6\u80de\u7c7b\u578b\u9700\u8981\u4f9d\u636e\u591a\u4e2a\u5df2\u77e5 marker \u7684\u8868\u8fbe\u6a21\u5f0f\u5224\u65ad\uff0c\u5e76\u53c2\u8003\u7ec4\u7ec7\u80cc\u666f\u548c\u516c\u5171\u56fe\u8c31\u3002",
      "\u7ec6\u80de\u6bd4\u4f8b\u5dee\u5f02\u53ea\u6709\u5728\u591a\u4e2a\u751f\u7269\u5b66\u91cd\u590d\u4e2d\u4e00\u81f4\u51fa\u73b0\u65f6\u624d\u8f83\u53ef\u4fe1\u3002")
    s$cannot_conclude <- c("\u4e0d\u80fd\u628a\u7ec6\u80de\u6570\u5f53\u4f5c\u751f\u7269\u5b66\u91cd\u590d\u6570\u6765\u8ba1\u7b97\u7ec4\u95f4\u663e\u8457\u6027\u3002",
                           "\u4e0d\u80fd\u4ec5\u51ed UMAP \u4e0a\u4e24\u4e2a\u7fa4\u9760\u8fd1\u5c31\u63a8\u65ad\u5b83\u4eec\u5b58\u5728\u53d1\u80b2\u6216\u8c31\u7cfb\u5173\u7cfb\u3002",
                           "\u4e0d\u80fd\u4ec5\u51ed\u5355\u4e2a marker \u786e\u5b9a\u7ec6\u80de\u7c7b\u578b\u3002")
    s$learning_questions <- c("\u4e3a\u4ec0\u4e48\u540c\u4e00\u6837\u672c\u4e2d\u7684\u6570\u5343\u4e2a\u7ec6\u80de\u4e0d\u80fd\u88ab\u89c6\u4e3a\u6570\u5343\u4e2a\u72ec\u7acb\u91cd\u590d\uff1f",
                              "percent.mt \u5f88\u9ad8\u7684\u7ec6\u80de\u53ef\u80fd\u610f\u5473\u7740\u4ec0\u4e48\uff1f",
                              "\u6539\u53d8\u805a\u7c7b\u5206\u8fa8\u7387\u540e cluster \u6570\u91cf\u53d8\u5316\uff0c\u8bf4\u660e\u4e86\u4ec0\u4e48\uff1f")
  } else if (type == "cell_composition") {
    concepts <- c("pseudoreplication")
    s$data_facts <- c(
      paste0("\u4f7f\u7528 ", f$n_cells_used, " \u4e2a\u7ec6\u80de\u3001", f$n_samples, " \u4e2a\u6837\u672c\u3001", f$n_clusters, " \u4e2a cluster \u8ba1\u7b97\u6837\u672c\u5185\u7ec6\u80de\u6bd4\u4f8b\uff1b",
             "\u6bcf\u4e2a\u6837\u672c\u7684\u7ec6\u80de\u6570\u8303\u56f4 ", f$cells_per_sample_range[1], "\u2013", f$cells_per_sample_range[2], "\u3002"),
      if (!is.null(f$n_groups)) paste0("\u5206\u7ec4\u6570 ", f$n_groups, "\uff1b\u6bcf\u7ec4\u6837\u672c\u6570\uff1a",
                                       paste(names(f$samples_per_group), unlist(f$samples_per_group), sep = "=", collapse = "\u3001"), "\u3002"),
      if (!is.null(f$n_cells_missing_sample) && (f$n_cells_missing_sample + f$n_cells_missing_cluster) > 0)
        paste0("\u7f3a\u5c11\u6837\u672c ID \u7684\u7ec6\u80de ", f$n_cells_missing_sample, " \u4e2a\uff0c\u7f3a\u5c11 cluster \u7684\u7ec6\u80de ", f$n_cells_missing_cluster, " \u4e2a\uff0c\u672a\u8ba1\u5165\u3002"),
      paste0("\u7ec4\u6210\u68c0\u9a8c\u72b6\u6001\uff1a", f$test_status, "\u3002"),
      if (!is.null(f$n_tests)) paste0("\u5171\u68c0\u9a8c ", f$n_tests, " \u4e2a cluster\uff08", f$test_method, "\uff0c", f$p_adjust_method,
                                      " \u6821\u6b63\uff09\uff0c\u6821\u6b63\u540e p < ", f$alpha, " \u7684\u6709 ", f$n_significant_adjusted, " \u4e2a\u3002"),
      if (nzchar(context_line)) paste0(context_line, "\u3002"))
    s$statistical_meaning <- c(
      "\u7ec6\u80de\u6bd4\u4f8b\u4ee5\u6837\u672c\u4e3a\u5355\u4f4d\u8ba1\u7b97\uff0c\u6bd4\u8f83\u7ec4\u95f4\u5dee\u5f02\u65f6\u91cd\u590d\u5355\u4f4d\u662f\u6837\u672c\u800c\u4e0d\u662f\u7ec6\u80de\u3002",
      "\u5404 cluster \u6bd4\u4f8b\u4e4b\u548c\u4e3a 1\uff0c\u4e00\u4e2a cluster \u6bd4\u4f8b\u4e0a\u5347\u4f1a\u4f7f\u5176\u4ed6 cluster \u6bd4\u4f8b\u76f8\u5bf9\u4e0b\u964d\uff08\u7ec4\u6210\u6027\u6570\u636e\uff09\u3002")
    s$biological_interpretation <- "\u53ea\u6709\u5728\u591a\u4e2a\u72ec\u7acb\u751f\u7269\u5b66\u91cd\u590d\u4e2d\u65b9\u5411\u4e00\u81f4\u7684\u6bd4\u4f8b\u53d8\u5316\u624d\u53ef\u4f5c\u4e3a\u751f\u7269\u5b66\u7ebf\u7d22\u3002"
    s$cannot_conclude <- c("\u4e0d\u80fd\u628a\u7ec6\u80de\u6570\u5f53\u4f5c\u91cd\u590d\u6570\uff1b\u6837\u672c\u6570\u4e0d\u8db3\u65f6\u4e0d\u80fd\u505a\u7ec4\u95f4\u663e\u8457\u6027\u7ed3\u8bba\u3002",
                           "\u6bd4\u4f8b\u53d8\u5316\u4e0d\u7b49\u4e8e\u7edd\u5bf9\u7ec6\u80de\u6570\u91cf\u53d8\u5316\u3002")
    s$learning_questions <- c("\u4e3a\u4ec0\u4e48\u8981\u5148\u6309\u6837\u672c\u8ba1\u7b97\u6bd4\u4f8b\uff0c\u518d\u6bd4\u8f83\u7ec4\u95f4\u5dee\u5f02\uff1f",
                              "\u6bcf\u7ec4\u53ea\u6709 2 \u4e2a\u6837\u672c\u65f6\uff0c\u4e3a\u4ec0\u4e48\u4e0d\u9002\u5408\u505a\u68c0\u9a8c\uff1f")
  } else if (type == "summarized_experiment") {
    concepts <- c("pseudoreplication")
    asm <- f$assay_summaries
    s$data_facts <- c(
      paste0("SummarizedExperiment\uff1a", f$n_features, " \u4e2a\u7279\u5f81 \u00d7 ", f$n_columns, " \u5217\uff1bassay\uff1a", paste(f$assays, collapse = ", "), "\u3002"),
      if (!is.null(f$n_samples)) paste0("\u6837\u672c\u5217 '", f$sample_column, "' \u5171 ", f$n_samples, " \u4e2a\u6837\u672c\u3002"),
      if (!is.null(f$n_groups)) paste0("\u5206\u7ec4\u5217 '", f$group_column, "' \u5171 ", f$n_groups, " \u4e2a\u5206\u7ec4\uff1b\u6bcf\u7ec4\u72ec\u7acb\u5355\u4f4d\uff1a",
                                       if (!is.null(f$units_per_group)) paste(names(f$units_per_group), unlist(f$units_per_group), sep = "=", collapse = "\u3001") else "\u7565", "\u3002"),
      if (!is.null(f$n_batches)) paste0("\u6279\u6b21\u5217 '", f$batch_column, "' \u5171 ", f$n_batches, " \u4e2a\u6279\u6b21",
                                        if (isTRUE(f$group_batch_confounded)) "\uff1b\u5206\u7ec4\u6548\u5e94\u5728\u542b\u6279\u6b21\u7684\u56fa\u5b9a\u6548\u5e94\u6a21\u578b\u4e2d\u4e0d\u53ef\u4f30\u8ba1" else "", "\u3002"),
      if (length(asm)) vapply(names(asm), function(k) {
        a <- asm[[k]]
        paste0("assay '", k, "'\uff1a", a$class, "\uff0c\u7ef4\u5ea6 ", paste(a$dim, collapse = "\u00d7"), "\uff0c\u68c0\u67e5\u65b9\u5f0f ", a$inspection,
               if (!is.null(a$sample_note)) "\uff08\u62bd\u6837\uff0c\u975e\u5b8c\u6574\u77e9\u9635\uff09" else "")
      }, ""),
      if (nzchar(context_line)) paste0(context_line, "\u3002"))
    s$statistical_meaning <- c("SummarizedExperiment \u662f\u5bb9\u5668\uff0c\u672c\u8eab\u4e0d\u542b\u7edf\u8ba1\u68c0\u9a8c\uff1b\u5176\u5217\u901a\u5e38\u662f\u6837\u672c/\u6587\u5e93\uff0c\u8bbe\u8ba1\u4fe1\u606f\u6765\u81ea colData\u3002",
                               "\u5206\u6790\u524d\u5e94\u786e\u8ba4 assay \u662f\u539f\u59cb\u8ba1\u6570\u8fd8\u662f\u5df2\u6807\u51c6\u5316/\u5bf9\u6570\u503c\uff0c\u4e0d\u540c\u6a21\u578b\u7684\u8f93\u5165\u8981\u6c42\u4e0d\u540c\u3002")
    s$cannot_conclude <- c("\u4e0d\u80fd\u4ec5\u51ed\u5bf9\u8c61\u63a8\u65ad\u5dee\u5f02\u8868\u8fbe\u7ed3\u679c\u3002", "\u4e0d\u80fd\u628a\u5217\u6570\u5f53\u4f5c\u72ec\u7acb\u751f\u7269\u5b66\u91cd\u590d\u6570\uff0c\u9664\u975e\u6837\u672c\u5217\u786e\u8ba4\u3002")
    s$learning_questions <- c("colData \u4e2d\u54ea\u4e00\u5217\u624d\u662f\u771f\u6b63\u7684\u751f\u7269\u5b66\u91cd\u590d\u5355\u4f4d\uff1f", "assay \u4e2d\u7684\u6570\u503c\u662f\u8ba1\u6570\u3001CPM \u8fd8\u662f\u5bf9\u6570\u503c\uff1f")
  } else if (type == "plot") {
    concepts <- c("aes")
    pm <- ctx$plot_mapping
    aes_txt <- if (length(pm$global_aes)) paste(names(pm$global_aes), unlist(pm$global_aes), sep = " = ", collapse = "\uff0c") else "\uff08\u5168\u5c40\u65e0\u6620\u5c04\uff09"
    s$data_facts <- c(
      paste0("ggplot \u5bf9\u8c61\uff0c", f$n_layers, " \u4e2a\u56fe\u5c42\uff1a", paste(f$geoms, collapse = ", "), "\uff1b\u5750\u6807\u7cfb ", f$coord, "\uff0c\u5206\u9762 ", f$facet, "\u3002"),
      paste0("\u5168\u5c40 aes \u6620\u5c04\uff1a", aes_txt, "\u3002"),
      if (!is.null(f$n_data_rows)) paste0("\u7ed8\u56fe\u6570\u636e\u5171 ", f$n_data_rows, " \u884c\u3002"),
      if (length(pm$labels)) paste0("\u6807\u7b7e\uff1a", paste(names(pm$labels), unlist(pm$labels), sep = "=", collapse = "\uff1b"), "\u3002"),
      if (!is.na(f$plot_type_guess)) paste0("\u63a8\u6d4b\u56fe\u5f62\u7c7b\u578b\uff1a", f$plot_type_guess, "\uff08\u63a8\u6d4b\uff0c\u672a\u6838\u5b9e\uff09\u3002")
    )
    guess <- f$plot_type_guess
    s$statistical_meaning <- switch(as.character(guess),
      volcano_plot = c("\u706b\u5c71\u56fe\u4e2d\u6bcf\u4e2a\u70b9\u662f\u4e00\u4e2a\u57fa\u56e0\uff1a\u6a2a\u8f74\u4e3a log2FC\uff08\u65b9\u5411\u4e0e\u5927\u5c0f\uff09\uff0c\u7eb5\u8f74\u4e3a -log10(p)\uff08\u8d8a\u9ad8\u8d8a\u663e\u8457\uff09\u3002",
                       "\u9700\u786e\u8ba4\u7eb5\u8f74\u4f7f\u7528\u7684\u662f\u539f\u59cb p \u503c\u8fd8\u662f\u6821\u6b63\u540e p \u503c\uff0c\u4ee5\u53ca\u9608\u503c\u7ebf\u4ee3\u8868\u7684\u89c4\u5219\u3002"),
      pca_plot = c("PCA \u56fe\u4e2d\u70b9\u4e4b\u95f4\u7684\u8ddd\u79bb\u53cd\u6620\u6574\u4f53\u8868\u8fbe\u6a21\u5f0f\u7684\u76f8\u4f3c\u5ea6\uff1b\u5750\u6807\u8f74\u6807\u7b7e\u4e2d\u7684\u767e\u5206\u6bd4\u4e3a\u65b9\u5dee\u89e3\u91ca\u7387\u3002"),
      embedding_plot = c("UMAP/t-SNE \u56fe\u4fdd\u7559\u5c40\u90e8\u90bb\u8fd1\u5173\u7cfb\uff0c\u7c07\u95f4\u8ddd\u79bb\u4e0e\u7c07\u9762\u79ef\u4e0d\u53ef\u5b9a\u91cf\u6bd4\u8f83\u3002"),
       enrichment_dotplot = c("\u5bcc\u96c6\u70b9\u56fe\u901a\u5e38\u7528\u6a2a\u8f74\u8868\u793a GeneRatio/Count\uff0c\u989c\u8272\u8868\u793a p.adjust\uff0c\u70b9\u5927\u5c0f\u8868\u793a\u57fa\u56e0\u6570\u3002"),
       heatmap_like = c("\u70ed\u56fe\u628a\u884c\u7279\u5f81\u548c\u5217\u6837\u672c\u7684\u6570\u503c\u6620\u5c04\u4e3a\u989c\u8272\uff1b\u989c\u8272\u68af\u5ea6\u663e\u793a\u76f8\u5bf9\u9ad8\u4f4e\uff0c\u5177\u4f53\u542b\u4e49\u53d6\u51b3\u4e8e\u8f93\u5165\u662f\u5426\u5df2\u6807\u51c6\u5316\u6216\u53d8\u6362\u3002"),
       distribution_comparison = c("\u7bb1\u7ebf\u56fe\u6216\u5c0f\u63d0\u7434\u56fe\u663e\u793a\u6570\u503c\u5206\u5e03\u548c\u7ec4\u95f4\u91cd\u53e0\uff0c\u4ecd\u9700\u7ed3\u5408\u72ec\u7acb\u91cd\u590d\u548c\u6b63\u5f0f\u7edf\u8ba1\u68c0\u9a8c\u3002"),
       c("\u8bf7\u5bf9\u7167 aes \u6620\u5c04\u7406\u89e3\u6bcf\u4e2a\u89c6\u89c9\u901a\u9053\u5bf9\u5e94\u7684\u6570\u636e\u5217\uff0c\u4ee5\u53ca\u51e0\u4f55\u5bf9\u8c61\u5982\u4f55\u6c47\u603b\u6570\u636e\u3002"))
    if (identical(guess, "pca_plot") && !is.null(f$variance_explained)) {
      s$data_facts <- c(s$data_facts,
                        paste0("\u7531 R \u8ba1\u7b97\u7684\u65b9\u5dee\u89e3\u91ca\u7387\uff1aPC1 ",
                               round(100 * f$variance_explained[1L], 1), "%\uff0cPC2 ",
                               round(100 * f$variance_explained[min(2L, length(f$variance_explained))], 1), "%\u3002"))
      s$statistical_meaning <- c(s$statistical_meaning,
        "PCA \u5750\u6807\u53cd\u6620\u6574\u4f53\u6570\u636e\u7684\u4e3b\u8981\u53d8\u5f02\u65b9\u5411\uff1b\u65b9\u5dee\u89e3\u91ca\u7387\u7531 R \u4ece\u8f93\u5165\u6570\u503c\u8ba1\u7b97\u3002")
    }
    if (identical(guess, "embedding_plot") && !is.null(f$n_observations)) {
      s$data_facts <- c(s$data_facts,
                        paste0("\u56fe\u4e2d\u5305\u542b ", f$n_observations, " \u4e2a\u89c2\u6d4b\uff0c\u6bcf\u4e2a\u89c2\u6d4b\u6709 ", f$n_coordinates, " \u4e2a\u5750\u6807\u3002"))
    }
    s$biological_interpretation <- "\u56fe\u5f62\u672c\u8eab\u4e0d\u63d0\u4f9b\u65b0\u7684\u7edf\u8ba1\u8bc1\u636e\uff1b\u5176\u751f\u7269\u5b66\u542b\u4e49\u53d6\u51b3\u4e8e\u5e95\u5c42\u6570\u636e\u5bf9\u8c61\u4e0e\u5206\u6790\u8bbe\u8ba1\u3002"
    s$cannot_conclude <- c("\u4e0d\u80fd\u53ea\u6839\u636e\u56fe\u4e2d\u6807\u6ce8\u7684\u5c11\u6570\u57fa\u56e0\u6216\u989c\u8272\u5f97\u51fa\u5b8c\u6574\u7ed3\u8bba\u3002",
                           "\u4e0d\u80fd\u4ece\u89c6\u89c9\u4e0a\u7684\u201c\u5206\u79bb\u201d\u76f4\u63a5\u63a8\u65ad\u56e0\u679c\u6216\u673a\u5236\u3002")
    s$learning_questions <- c("\u8fd9\u5f20\u56fe\u7684\u6bcf\u4e2a\u70b9\uff08\u6216\u6bcf\u4e2a\u51e0\u4f55\u5143\u7d20\uff09\u4ee3\u8868\u4ec0\u4e48\uff1f",
                              "\u5982\u679c\u6539\u53d8\u5750\u6807\u8f74\u53d8\u6362\u6216\u9608\u503c\u7ebf\uff0c\u56fe\u7684\u89c2\u611f\u4f1a\u600e\u6837\u53d8\u5316\uff1f")
  } else if (type == "pca") {
    concepts <- c("pca")
    ve <- f$variance_explained
    s$data_facts <- c(
      paste0(f$n_observations, " \u4e2a\u89c2\u6d4b\uff08\u901a\u5e38\u662f\u6837\u672c\uff09\u3001", f$n_variables, " \u4e2a\u53d8\u91cf\uff08\u901a\u5e38\u662f\u57fa\u56e0\uff09\uff0c\u5171 ", f$n_components, " \u4e2a\u4e3b\u6210\u5206\u3002"),
      paste0("\u524d\u4e24\u4e2a\u4e3b\u6210\u5206\u65b9\u5dee\u89e3\u91ca\u7387\uff1aPC1 ", round(100 * ve[1], 1), "%\uff0cPC2 ",
             if (length(ve) > 1) round(100 * ve[2], 1) else NA, "%\u3002"),
      paste0("\u4e2d\u5fc3\u5316\uff1a", f$centered, "\uff1b\u6807\u51c6\u5316\uff1a", f$scaled, "\u3002"))
    s$statistical_meaning <- "\u65b9\u5dee\u89e3\u91ca\u7387\u8d8a\u9ad8\uff0c\u8bf4\u660e\u8be5\u4e3b\u6210\u5206\u6982\u62ec\u7684\u603b\u4f53\u53d8\u5f02\u8d8a\u591a\uff1b\u4f46\u5b83\u4e0d\u8bf4\u660e\u53d8\u5f02\u6765\u6e90\u662f\u751f\u7269\u5b66\u8fd8\u662f\u6280\u672f\u56e0\u7d20\u3002"
    s$biological_interpretation <- "\u9700\u5c06\u6837\u672c\u5728 PC1/PC2 \u4e0a\u7684\u5206\u5e03\u4e0e\u5206\u7ec4\u3001\u6279\u6b21\u4fe1\u606f\u5bf9\u7167\uff0c\u5224\u65ad\u4e3b\u8981\u53d8\u5f02\u662f\u5426\u6765\u81ea\u5b9e\u9a8c\u56e0\u7d20\u3002"
    s$cannot_conclude <- c("\u4e0d\u80fd\u628a\u6837\u672c\u5206\u79bb\u76f4\u63a5\u7b49\u540c\u4e8e\u5904\u7406\u6709\u6548\u3002", "\u4e0d\u80fd\u5ffd\u7565\u6279\u6b21\u6548\u5e94\u5bfc\u81f4\u5206\u79bb\u7684\u53ef\u80fd\u6027\u3002")
    s$learning_questions <- c("\u5982\u679c PC1 \u4e3b\u8981\u6309\u6d4b\u5e8f\u6279\u6b21\u5206\u5f00\u6837\u672c\uff0c\u5e94\u8be5\u600e\u4e48\u529e\uff1f")
  } else {
    s$data_facts <- c(paste0("\u5bf9\u8c61\u7c7b\u522b\uff1a", paste(ctx$source_class, collapse = "/"), "\u3002"),
                      if (!is.null(f$dim)) paste0("\u7ef4\u5ea6\uff1a", paste(f$dim, collapse = " \u00d7 "), "\u3002"))
    s$statistical_meaning <- "\u8be5\u5bf9\u8c61\u6ca1\u6709\u4e13\u7528\u89e3\u91ca\u89c4\u5219\uff1b\u5efa\u8bae\u4f7f\u7528 analysis_type \u6307\u5b9a\u7c7b\u578b\u6216\u6ce8\u518c\u81ea\u5b9a\u4e49\u9002\u914d\u5668\u3002"
    s$learning_questions <- "\u8fd9\u4e2a\u5bf9\u8c61\u662f\u7531\u54ea\u4e2a\u51fd\u6570\u4ea7\u751f\u7684\uff1f\u5b83\u7684\u6bcf\u4e00\u884c/\u6bcf\u4e00\u5217\u4ee3\u8868\u4ec0\u4e48\uff1f"
  }
  s <- lapply(s, function(v) unique(v[!is.na(v) & nzchar(v)]))
  s$concepts <- unlist(.concept_cards[concepts])
  s
}

.llm_system_prompt <- function(language = "en", level = "beginner") {
  language <- .check_language(language)
  lang <- if (identical(language, "zh")) "Simplified Chinese (\u7b80\u4f53\u4e2d\u6587)" else "English"
  paste0(
    "You are a bioinformatics teaching assistant. Write in ", lang, " for a ", level, " audience. ",
    "All prose strings in the JSON must be in ", lang, "; keep JSON keys, gene symbols and ids unchanged.\n",
    "Rules:\n",
    "1. All numbers (counts, thresholds, p-values, fold changes) must come from the provided JSON facts. ",
    "Never compute, estimate or invent new statistics.\n",
    "2. Separate data facts, statistical meaning, biological interpretation, uncertainty, and conclusions that cannot be drawn.\n",
    "3. Biological statements are hypotheses unless supported by the supplied evidence list; cite evidence by its id. ",
    "Do not invent references, database IDs, gene functions you are unsure of, or clinical claims.\n",
    "4. Respect the uncertainty notes (e.g. raw vs adjusted p-values, ORA has no activation direction, cells are not replicates).\n",
    "Return ONLY a JSON object with keys: data_facts, statistical_meaning, biological_interpretation, ",
    "uncertainty, cannot_conclude, learning_questions (each an array of short strings), evidence_used (array of evidence ids), ",
    "and claims: an array of objects {\"id\", \"text\", \"fact\" (path into the facts JSON), \"value\" (a single number or string), \"evidence\" (array of evidence ids)} for every statistical fact you state. ",
    "Use one claim per scalar value; numeric arrays can be referenced with 1-based paths such as variance_explained.1. ",
    "Copy numeric claim values exactly from the JSON, without rounding; prose may use approximate values. ",
    "Keep each section concise (up to 3 short strings) so the required claims fit the output budget. ",
    "Do not attach an up/down direction to a positive count; direction is only appropriate for signed effects."
  )
}

.llm_user_prompt <- function(payload, evidence = NULL, question = NULL) {
  policy <- bio_payload_policy()
  ev <- if (length(evidence)) {
    lapply(evidence, function(e) {
      z <- list(id = e$id %||% NULL, source = e$source %||% NULL,
                title = e$title %||% NULL, claim = e$claim %||% NULL,
                url = e$url %||% NULL, scope = e$scope %||% list(),
                role = e$role %||% NULL, content_type = e$content_type %||% NULL)
      if (!is.null(e$content)) z$content <- e$content
      .payload_sanitize(z, policy)
    })
  } else list()
  paste0(
    "Analysis context (computed deterministically in R; summary only, no raw data):\n",
    .json(payload, pretty = TRUE), "\n\n",
    "User-supplied evidence (may be empty):\n", .json(ev, pretty = TRUE), "\n\n",
    if (!.is_blank(question)) paste0("Learner question: ", .sensitive_value(question), "\n\n") else "",
    "Produce the JSON explanation now."
  )
}

.extension_local <- function(ctx, language) {
  if (!ctx$analysis_type %in% c("multi_assay", "spatial", "docking")) return(NULL)
  f <- ctx$facts
  .local_language(language)
  s <- stats::setNames(rep(list(character()), length(.section_names)), .section_names)
  s$uncertainty <- ctx$uncertainty
  if (ctx$analysis_type == "multi_assay") {
    s$data_facts <- paste0("Modalities: " %L% "\u6a21\u6001\u6570\uff1a", f$n_modalities,
      "; primary units: " %L% "\uff1b\u4e3b\u8981\u5355\u4f4d\u6570\uff1a", f$n_primary_units,
      "; alignment: " %L% "\uff1b\u5bf9\u9f50\u72b6\u6001\uff1a", f$alignment_status, ".")
    s$statistical_meaning <- "Each assay has its own context and sample map; missing modalities do not create independent replication." %L%
      "\u6bcf\u4e2a assay \u4fdd\u7559\u72ec\u7acb context \u548c\u6837\u672c\u6620\u5c04\uff1b\u7f3a\u5931\u6a21\u6001\u4e0d\u4f1a\u4ea7\u751f\u72ec\u7acb\u91cd\u590d\u3002"
  } else if (ctx$analysis_type == "spatial") {
    s$data_facts <- paste0("Spatial observations: " %L% "\u7a7a\u95f4\u89c2\u6d4b\u6570\uff1a", f$n_spots,
      "; sections: " %L% "\uff1b\u5207\u7247\u6570\uff1a", f$n_sections,
      "; coordinate units: " %L% "\uff1b\u5750\u6807\u5355\u4f4d\uff1a", f$coordinate_units, ".")
    s$statistical_meaning <- "Coordinates are measured positions; spots and sections are not automatically independent donors. Tissue coverage requires a mask and denominator." %L%
      "\u5750\u6807\u662f\u6d4b\u91cf\u4f4d\u7f6e\uff1bspot \u548c\u5207\u7247\u4e0d\u81ea\u52a8\u7b49\u4e8e\u72ec\u7acb\u4f9b\u4f53\uff1b\u7ec4\u7ec7\u8986\u76d6\u7387\u9700\u8981 mask \u548c\u5206\u6bcd\u3002"
  } else {
    s$data_facts <- paste0("Docking poses: " %L% "\u5bf9\u63a5 pose \u6570\uff1a", f$n_poses,
      "; receptors: " %L% "\uff1b\u53d7\u4f53\u6570\uff1a", f$n_receptors,
      "; ligands: " %L% "\uff1b\u914d\u4f53\u6570\uff1a", f$n_ligands, ".")
    s$statistical_meaning <- "Engine scores are computational outputs on a declared scale; they are not measured affinity or a significance test." %L%
      "\u5f15\u64ce score \u662f\u7279\u5b9a\u5c3a\u5ea6\u4e0b\u7684\u8ba1\u7b97\u8f93\u51fa\uff0c\u4e0d\u662f\u5b9e\u6d4b\u4eb2\u548c\u529b\u6216\u663e\u8457\u6027\u68c0\u9a8c\u3002"
  }
  s$cannot_conclude <- "These summaries do not establish causal mechanisms or independent scientific validation." %L%
    "\u8fd9\u4e9b\u6458\u8981\u4e0d\u80fd\u786e\u7acb\u56e0\u679c\u673a\u5236\u6216\u72ec\u7acb\u79d1\u5b66\u9a8c\u8bc1\u3002"
  s
}

#' Explain an analysis object
#'
#' Builds (or reuses) a \code{\link{bio_context}}, produces a deterministic
#' local explanation and, if a model is configured and \code{use_llm} allows
#' it, asks the model to organise the language from a bounded JSON summary.
#' Model text is stored separately from the R-computed facts and is
#' \strong{not} numerically verified.
#'
#' @param x Analysis object or \code{bio_context}.
#' @param config A \code{\link{bio_config}}; default is the active one.
#' @param use_llm \code{NA} (default) uses the model only if one is fully
#'   configured; \code{TRUE} requires it; \code{FALSE} stays offline.
#' @param language Output language: \code{"en"} (English, the default when
#'   \code{NULL} and the configuration does not say otherwise) or \code{"zh"}
#'   (Simplified Chinese, opt-in). It selects the local templates, the section
#'   titles and the language requested from the model. Computed facts are
#'   identical in both languages. Any other value is an error. When \code{x}
#'   is an existing \code{bio_context}, its uncertainty notes keep the language
#'   it was built with (a warning is raised on mismatch).
#' @param level Audience level, e.g. \code{"beginner"}, \code{"undergraduate"}.
#' @param question Optional learner question passed to the model.
#' @param evidence Optional list of \code{\link{bio_evidence}} objects (or
#'   \code{"registered"} to use all registered evidence).
#' @param max_top Maximum top rows sent to the model.
#' @param cross_check Optional source object; when \code{x} is a plot, runs \code{\link{bio_cross_check}}.
#' @param evidence_sources Explicit live sources (e.g. \code{"europepmc"}); only then is the network used.
#' @param evidence_args Extra arguments for \code{\link{bio_evidence_for_context}}.
#' @param allow_subset Passed to \code{bio_cross_check}.
#' @param payload_policy Optional explicit payload policy.
#' @param run_id Optional manifest run identifier.
#' @param ... Passed to \code{\link{bio_context}} (e.g. \code{species},
#'   \code{contrast}, \code{analysis_type}, \code{thresholds}).
#' @return Object of class \code{bio_explanation} with \code{context},
#'   \code{local}, \code{llm}, \code{llm_meta}, \code{evidence} and
#'   \code{verification}.
#' @export
#' @examples
#' de <- data.frame(log2FoldChange = c(2.1, -1.5, 0.2, 3),
#'                  pvalue = c(1e-5, 1e-3, 0.5, 0.01), padj = c(4e-4, 0.01, 0.8, 0.06),
#'                  row.names = c("IL6", "SOX2", "ACTB", "CXCL8"))
#' ex <- bio_explain(de, use_llm = FALSE, contrast = "treated vs control")
#' ex
bio_explain <- function(x, config = NULL, use_llm = NA, language = NULL, level = "beginner",
                        question = NULL, evidence = NULL, max_top = 10, cross_check = NULL,
                        evidence_sources = NULL, evidence_args = list(), allow_subset = FALSE,
                        payload_policy = NULL, run_id = NULL, ...) {
  config <- config %||% bio_get_config()
  language <- .resolve_language(language, config)
  .local_language(language)
  cc <- NULL
  if (!is.null(cross_check)) {
    cc <- if (inherits(cross_check, "bio_cross_check")) cross_check else
      bio_cross_check(x, cross_check, allow_subset = allow_subset)
  }
  ctx <- if (inherits(x, "bio_context")) x else bio_context(x, language = language, ...)
  if (inherits(x, "bio_context") && !identical(ctx$language %||% "en", language)) {
    warning("The supplied bio_context was built with language = '", ctx$language %||% "en",
            "' but language = '", language, "' was requested; its uncertainty notes keep the original language. ",
            "Rebuild it with bio_context(..., language = '", language, "') for consistent output.", call. = FALSE)
  }
  auto <- identical(evidence, "auto")
  if (auto && is.null(evidence_sources))
    stop("evidence = 'auto' needs explicit evidence_sources (e.g. 'europepmc'); no network access happens by default.", call. = FALSE)
  # Supplying evidence_sources is an explicit opt-in to retrieve additional
  # evidence, even when the caller also supplied local evidence objects.
  if (!is.null(evidence_sources)) auto <- TRUE
  if (identical(evidence, "auto")) evidence <- NULL
  if (identical(evidence, "registered")) evidence <- bio_evidence_list()
  if (inherits(evidence, "bio_evidence")) evidence <- list(evidence)
  if (!is.null(evidence) && length(evidence) && !all(vapply(evidence, inherits, logical(1), what = "bio_evidence")))
    stop("evidence must be a bio_evidence object or a list of bio_evidence objects.", call. = FALSE)
  supplied <- evidence
  retrieved <- NULL; retrieval <- NULL
  if (auto) {
    retrieved <- do.call(bio_evidence_for_context, c(list(ctx, sources = evidence_sources), evidence_args))
    retrieval <- list(log = attr(retrieved, "retrieval"), errors = attr(retrieved, "errors"), skipped = attr(retrieved, "skipped"))
    retrieved <- lapply(unclass(retrieved)[seq_along(retrieved)], function(e) { e$origin <- "retrieved"; e })
  }
  supplied <- lapply(supplied, function(e) { e$origin <- e$origin %||% "supplied"; e })
  evidence <- c(supplied, retrieved)
  if (!length(evidence)) evidence <- NULL
  trace <- if (length(evidence)) data.frame(
    id = vapply(evidence, function(e) as.character(e$id), ""),
    source = vapply(evidence, function(e) as.character(e$source %||% NA), ""),
    origin = vapply(evidence, function(e) e$origin, ""), stringsAsFactors = FALSE) else NULL
  local <- .extension_local(ctx, language) %||% .explain_local(ctx, language)
  avail <- bio_llm_available(config)
  if (isTRUE(use_llm) && !avail) {
    stop("use_llm = TRUE but no model is usable: ", bio_llm_available(config, reason = TRUE), call. = FALSE)
  }
  want <- if (is.na(use_llm)) avail else isTRUE(use_llm)
  llm <- NULL
  llm_meta <- list(used = FALSE, reason = if (!want) bio_llm_available(config, reason = TRUE) else NULL)
  if (want) {
    payload <- bio_context_payload(ctx, max_top = max_top,
      policy = payload_policy %||% bio_payload_policy(max_top = max_top))
    if (!is.null(cc)) payload$cross_check <- list(status = cc$status, findings = cc$findings[c("check", "status")])
    attr(payload, "payload_hash") <- .hash_object(payload)
    res <- bio_llm_chat(config, .llm_system_prompt(language, level),
                        bio_redact(.llm_user_prompt(payload, evidence, question)))
    parsed <- .parse_model_json(res$text)
    llm <- if (!is.null(parsed)) {
      o <- lapply(parsed[intersect(c(.section_names, "evidence_used"), names(parsed))],
                  function(v) as.character(unlist(v)))
      if (is.list(parsed$claims)) o$claims <- unname(lapply(parsed$claims, function(cl) if (is.list(cl)) cl else list(text = as.character(cl))))
      o
    } else list(free_text = res$text)
    llm_meta <- list(used = TRUE, protocol = config$protocol, preset = config$preset,
                     model_requested = config$model, model_reported = res$model,
                     endpoint_host = res$endpoint_host, stop_reason = res$stop_reason,
                     usage = res$usage, elapsed_sec = res$elapsed_sec,
                     structured = !is.null(parsed), time = .now(),
                      payload_chars = nchar(.json(payload)), payload_hash = attr(payload, "payload_hash"),
                       policy_id = attr(payload, "policy_id"), request_hash = res$request_hash,
                       response_hash = res$response_hash, request_bytes = res$request_bytes,
                       request_hash_scope = res$request_hash_scope, response_hash_scope = res$response_hash_scope)
    if (length(llm$evidence_used)) {
      known <- if (length(evidence)) vapply(evidence, function(e) e$id, "") else character()
      llm_meta$unknown_evidence_ids <- setdiff(llm$evidence_used, known)
    }
  }
  ex <- structure(list(
    context = ctx, local = local, llm = llm, llm_meta = llm_meta,
    evidence = evidence, evidence_trace = trace, evidence_retrieval = retrieval, cross_check = cc, level = level, language = language,
    verification = list(
      facts = "computed deterministically in R from the full input",
      llm_text = if (is.null(llm)) "not used" else "model-generated prose; not numerically verified by BioExplainR"
    ),
     created = .now()
  ), class = "bio_explanation")
   ex$manifest <- bio_context_manifest(ctx, payload = if (exists("payload", inherits = FALSE)) payload else NULL,
                                      run_id = run_id, status = if (want) "executed" else "not_run",
                                      request_hash = if (want) llm_meta$request_hash else NULL,
                                      response_hash = if (want) llm_meta$response_hash else NULL,
                                      model_requested = if (want) config$model else NULL,
                                      model_reported = if (want) llm_meta$model_reported else NULL,
                                      provider_host = if (want) llm_meta$endpoint_host else NULL,
                                      usage = if (want) llm_meta$usage else NULL,
                                       elapsed_sec = if (want) llm_meta$elapsed_sec else NULL,
                                       request_bytes = if (want) llm_meta$request_bytes else NULL,
                                       request_hash_scope = if (want) llm_meta$request_hash_scope else NULL,
                                       response_hash_scope = if (want) llm_meta$response_hash_scope else NULL)
  if (!is.null(llm)) ex <- bio_validate_claims(ex)
  ex
}

# Like .extract_json, but keeps arrays of objects (claims) as lists of lists.
.parse_model_json <- function(text) {
  if (.is_blank(text)) return(NULL)
  t <- gsub("^\\s*```(json)?\\s*|\\s*```\\s*$", "", text)
  ps <- function(z) tryCatch(jsonlite::fromJSON(z, simplifyVector = FALSE), error = function(e) NULL)
  parsed <- ps(t)
  if (is.null(parsed)) {
    a <- regexpr("\\{", text); b <- max(gregexpr("\\}", text)[[1]])
    if (a > 0 && b > a) parsed <- ps(substr(text, a, b))
  }
  if (is.list(parsed) && !is.null(names(parsed))) parsed else NULL
}

#' @export
print.bio_explanation <- function(x, ...) {
  ctx <- x$context
  lang <- x$language %||% .default_language
  if (!lang %in% .languages) lang <- .default_language
  titles <- .section_titles_for(lang)
  zh <- identical(lang, "zh")
  cat(if (zh) "== BioExplainR \u89e3\u91ca\uff1a" else "== BioExplainR explanation: ",
      ctx$analysis_type, " (", paste(ctx$source_class, collapse = "/"), ") ==\n", sep = "")
  show <- function(sec, title) {
    v <- sec
    if (length(v)) {
      cat("\n## ", title, "\n", sep = "")
      for (i in v) cat("- ", i, "\n", sep = "")
    }
  }
  for (n in .section_names) show(x$local[[n]], titles[[n]])
  if (length(x$local$concepts)) show(x$local$concepts, titles[["concepts"]])
  if (!is.null(x$llm)) {
    if (zh) cat("\n== \u6a21\u578b\u751f\u6210\u7684\u89e3\u91ca\uff08", x$llm_meta$model_requested, "\uff1b\u672a\u7ecf\u6570\u503c\u6838\u9a8c\uff09==\n", sep = "")
    else cat("\n== Model-generated explanation (", x$llm_meta$model_requested, "; numbers not verified) ==\n", sep = "")
    for (n in setdiff(names(x$llm), "claims")) show(x$llm[[n]], if (n %in% names(titles)) titles[[n]] else n)
  } else {
    if (zh) cat("\n[\u6a21\u578b\u672a\u4f7f\u7528\uff1a", x$llm_meta$reason %||% "", "]\n", sep = "")
    else cat("\n[Model not used: ", x$llm_meta$reason %||% "", "]\n", sep = "")
  }
  if (!is.null(x$cross_check)) cat("\n[plot cross-check: ", x$cross_check$status, "]\n", sep = "")
  if (!is.null(x$validation)) cat("[claim validation: ", x$validation$status, " - consistency with computed facts only]\n", sep = "")
  invisible(x)
}
