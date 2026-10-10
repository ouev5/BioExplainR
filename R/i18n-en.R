# English text catalogues (the package default language) ---------------------------------
# The Chinese counterparts live next to the code that uses them (explain.R, diagnose.R).
# Both languages read the same computed facts; only wording differs.

.section_titles_en <- c(
  data_facts = "Data facts (computed deterministically in R)",
  statistical_meaning = "Statistical meaning",
  biological_interpretation = "Biological interpretation (verify against evidence)",
  uncertainty = "Uncertainty and limitations",
  cannot_conclude = "Conclusions that cannot be drawn",
  learning_questions = "Learning questions",
  concepts = "Concept cards"
)

.concept_cards_en <- list(
  pvalue = "p-value: the probability of observing a result at least as extreme as the current one if there were truly no difference; it is not an effect size and not the probability that the hypothesis is true.",
  padj = "Adjusted p-value (FDR/padj): controls the false discovery rate when thousands of genes are tested at once; for example padj < 0.05 means about 5% of the features called significant are expected to be false discoveries.",
  log2fc = "log2 fold change: the base-2 logarithm of the ratio of expression between two groups; 1 means about 2-fold higher, -1 means about half. The sign depends on the comparison order.",
  ora = "ORA (over-representation analysis): tests whether an input gene list overlaps a gene set more than expected by chance, using a hypergeometric/Fisher test.",
  gsea = "GSEA: tests, in a fully ranked gene list, whether the members of a gene set concentrate at the top or bottom; NES is the normalised enrichment score.",
  generatio = "GeneRatio: number of input genes in the pathway / number of input genes that could be annotated.",
  pseudoreplication = "Pseudoreplication: treating many cells from one sample as independent replicates underestimates variability and exaggerates significance.",
  qc = "QC metrics: nCount (total UMIs per cell), nFeature (genes detected) and percent.mt (mitochondrial fraction) are commonly used to flag low-quality cells or doublets.",
  umap = "UMAP/t-SNE: non-linear embeddings that preserve local neighbourhoods; distances between clusters and cluster sizes cannot be interpreted quantitatively.",
  pca = "PCA: projects high-dimensional expression onto orthogonal directions of maximal variance; the variance explained says how much total variation each principal component retains.",
  aes = "aes mapping: in ggplot, the rule that maps data columns to visual channels such as x, y, colour and size."
)

.section_titles_for <- function(language) if (identical(language, "zh")) .section_titles else .section_titles_en

.concept_cards_for <- function(language) if (identical(language, "zh")) .concept_cards else .concept_cards_en

# English counterpart of .explain_local_zh(); keep the fact references in sync.
.explain_local_en <- function(ctx) {
  f <- ctx$facts
  md <- ctx$metadata
  type <- ctx$analysis_type
  s <- list(data_facts = character(), statistical_meaning = character(),
            biological_interpretation = character(), uncertainty = ctx$uncertainty,
            cannot_conclude = character(), learning_questions = character())
  concepts <- character()
  context_line <- paste(c(
    if (!is.null(md$species)) paste0("Species: ", md$species),
    if (!is.null(md$tissue)) paste0("Tissue: ", md$tissue),
    if (!is.null(md$contrast)) paste0("Comparison: ", md$contrast),
    if (!is.null(md$design)) paste0("Design: ", md$design)), collapse = "; ")

  if (type %in% c("differential_expression", "markers")) {
    concepts <- c("pvalue", "padj", "log2fc")
    s$data_facts <- c(
      paste0("The result table has ", f$n_features, " features; the log2FC column is '", f$lfc_column, "'."),
      if (!is.na(f$adjusted_p_column) || grepl("^computed_", f$p_value_basis))
        paste0("With padj < ", f$padj_threshold, " and |log2FC| > ", f$lfc_threshold, ": ",
               f$n_significant, " significant (", f$n_up, " up, ", f$n_down, " down); ",
               f$n_na_padj, " features have NA padj."),
      if (identical(f$p_value_basis, "raw_only"))
        paste0("There is no adjusted p-value. Using raw p < ", f$raw_p_threshold, " only: ", f$n_raw_up,
               " up, ", f$n_raw_down, " down (no multiple-testing correction was applied, so these cannot be called FDR-significant)."),
      if (!is.null(f$lfc_range)) paste0("log2FC ranges from ", .fmt_num(f$lfc_range[1]), " to ",
                                        .fmt_num(f$lfc_range[2]), "; median ", .fmt_num(f$lfc_median), "."),
      if (nzchar(context_line)) paste0(context_line, ".")
    )
    s$statistical_meaning <- c(
      "log2FC describes the direction and size of a change, while the adjusted p-value describes statistical reliability under multiple testing; they are different dimensions and both must be considered.",
      "A gene with a very small p-value but a tiny log2FC is statistically reliable but may be biologically unimportant; conversely, a large log2FC with a non-significant padj may reflect low expression or high variability.",
      if (grepl("^computed_", f$p_value_basis)) "The adjusted p-values here were computed explicitly by BioExplainR from the raw p-values, which is only valid when the table contains all tested features."
    )
    if (length(f$per_cluster)) {
      pc <- vapply(names(f$per_cluster), function(k) {
        z <- f$per_cluster[[k]]
        paste0(f$group_column, "=", k, ": ", z$n_rows, " rows, ", z$n_significant, " significant (", z$n_up, " up, ", z$n_down, " down)")
      }, "")
      s$data_facts <- c(s$data_facts, paste0("Summary by ", f$group_column, " (based on ",
                        if (identical(f$per_cluster_significance_basis, "adjusted_p")) "adjusted p" else "raw p", "): ",
                        paste(utils::head(pc, 12), collapse = "; "), if (length(pc) > 12) " ..." else "", "."))
      s$cannot_conclude <- c(s$cannot_conclude, "Markers of each cluster are relative to all other cells; the same gene can appear in several clusters, so the total is not a count of independent genes.")
    }
    top <- ctx$top_features
    if (!is.null(top) && nrow(top)) {
      s$biological_interpretation <- c(
        paste0("The most significant features include: ", paste(utils::head(top$feature, 5), collapse = ", "),
               ". Look up the functional annotations of these genes (for example NCBI Gene, UniProt) before judging whether they relate to the experimental treatment."),
        "Differential expression only shows that expression level is associated with the grouping in this dataset; biological mechanisms need support from the literature, database evidence or experiments."
      )
    }
    s$cannot_conclude <- c("Do not rewrite 'significantly differentially expressed' as 'this gene caused the phenotype' or 'this pathway is activated'.",
                           "Do not describe genes that are not significant as 'unchanged'; the study may simply lack statistical power.",
                           if (identical(f$p_value_basis, "raw_only")) "Do not treat the number of genes with raw p < 0.05 as the number of significant genes under FDR control.")
    s$learning_questions <- c("How would the sign of log2FC change if the order of the compared groups were swapped?",
                              "Why must adjusted p-values be used when tens of thousands of genes are tested at once?",
                              "How would you describe a gene with a very small padj but |log2FC| = 0.1?")
  } else if (type %in% c("enrichment_ora", "enrichment_gsea")) {
    gsea <- type == "enrichment_gsea"
    concepts <- c(if (gsea) "gsea" else c("ora", "generatio"), "padj")
    s$data_facts <- c(
      paste0(f$n_terms, " terms in total (", f$enrichment_method, "); counting by ",
             if (identical(f$p_value_basis, "raw_only")) "raw p-value" else "adjusted p-value", " < ",
             f$significance_threshold, ", ", f$n_significant, " are significant."),
      if (gsea && !is.null(f$n_positive_nes_significant))
        paste0("Among significant terms, ", f$n_positive_nes_significant, " have NES > 0 and ",
               f$n_negative_nes_significant, " have NES < 0."),
      if (!is.null(f$universe_size)) paste0("Recorded background (universe) size: ", f$universe_size, "."),
      if (!is.null(f$background_size_from_bgratio)) paste0("Background size derived from the BgRatio denominator: ", f$background_size_from_bgratio,
                                                           if (!is.null(f$input_genes_mapped_from_generatio)) paste0("; annotated input genes derived from the GeneRatio denominator: ", f$input_genes_mapped_from_generatio) else "", "."),
      if (!is.null(f$count_range_significant)) paste0("Overlap gene count (Count) range of significant terms: ", f$count_range_significant[1], "-", f$count_range_significant[2], "."),
      if (!is.null(f$n_input_genes)) paste0("Number of input genes: ", f$n_input_genes, "."),
      if (!is.null(f$ontology)) paste0("Ontology/database: ", f$ontology, "."),
      if (nzchar(context_line)) paste0(context_line, ".")
    )
    s$statistical_meaning <- if (gsea) c(
      "GSEA uses a ranking of all genes rather than a thresholded gene list; NES is normalised for gene-set size.",
      "The sign of NES indicates that gene-set members concentrate at the top or bottom of the ranked list; the exact meaning depends on the direction of the ranking metric."
    ) else c(
      "ORA tests whether the overlap between the input genes and a gene set is larger than expected by chance; GeneRatio and Count describe the degree of overlap.",
      "Significance depends on the threshold used for the input list and on the background gene set; changing the threshold or the universe can change the result substantially."
    )
    top <- ctx$top_features
    if (!is.null(top) && nrow(top)) {
      s$biological_interpretation <- c(
        paste0("The most significant terms include: ", paste(utils::head(top$term, 5), collapse = "; "), "."),
        "These terms suggest that the input genes cluster in the corresponding functional categories; treat them as leads for biological hypotheses and judge them together with the core genes and literature evidence."
      )
    }
    s$cannot_conclude <- c(
      if (!gsea) "ORA results cannot show that a pathway is 'activated' or 'inhibited'." else "A positive NES cannot be equated directly with increased pathway activity.",
      "Several GO terms can overlap heavily; do not treat them as multiple independent pieces of evidence.",
      "Enrichment derived from the same differential gene list is derived evidence, not an independent validation of the differential expression result.")
    s$learning_questions <- c(
      "How do the inputs of ORA and GSEA differ, and which questions is each suited to answer?",
      "How might the result change if the background gene set were switched from 'whole genome' to 'genes detected in this experiment'?",
      "How can you tell whether two significant GO terms merely reflect the same set of genes?")
  } else if (type == "single_cell") {
    concepts <- c("qc", "umap", "pseudoreplication")
    qc_txt <- if (!is.null(f$qc)) vapply(names(f$qc), function(k) {
      q <- f$qc[[k]]$quantiles
      paste0(f$qc[[k]]$column, " median ", .fmt_num(q$median), " (range ", .fmt_num(q$min), "-", .fmt_num(q$max), ")")
    }, "") else NULL
    s$data_facts <- c(
      paste0(f$n_cells, " cells",
             if (!is.null(f$n_features_active_assay)) paste0(", ", f$n_features_active_assay, " features in the active assay '", f$active_assay, "'") else "",
             if (!is.null(f$n_features)) paste0(", ", f$n_features, " features") else "", "."),
      if (!is.null(f$assays)) paste0("Assays: ", paste(f$assays, collapse = ", "), "."),
      if (length(f$reductions)) paste0("Reductions: ", paste(f$reductions, collapse = ", "), "."),
      if (!is.null(f$n_clusters)) paste0("Cluster column '", f$cluster_column, "' has ", f$n_clusters, " clusters; cells per cluster range from ",
                                         f$cluster_size_range[1], " to ", f$cluster_size_range[2], "."),
      if (!is.null(f$n_samples)) paste0("Sample column '", f$sample_column, "' has ", f$n_samples, " samples/donors (names are not printed)."),
      if (length(qc_txt)) paste0("QC: ", paste(qc_txt, collapse = "; "), "."),
      if (nzchar(context_line)) paste0(context_line, ".")
    )
    s$statistical_meaning <- c(
      "Clusters are unsupervised groups based on expression similarity; the clustering resolution parameter changes the number of clusters.",
      "When comparing groups, the independent unit of replication is the sample/donor, not the cell.")
    s$biological_interpretation <- c(
      "The cell type of a cluster should be decided from the expression pattern of several known markers, together with tissue context and public atlases.",
      "A difference in cell proportions is only credible when it appears consistently across several biological replicates.")
    s$cannot_conclude <- c("Do not use the number of cells as the number of biological replicates when computing significance between groups.",
                           "Do not infer a developmental or lineage relationship merely because two clusters are close on a UMAP.",
                           "Do not decide a cell type from a single marker.")
    s$learning_questions <- c("Why can thousands of cells from one sample not be treated as thousands of independent replicates?",
                              "What might a cell with a very high percent.mt indicate?",
                              "What does it tell you if the number of clusters changes when the clustering resolution changes?")
  } else if (type == "cell_composition") {
    concepts <- c("pseudoreplication")
    s$data_facts <- c(
      paste0("Within-sample cell proportions were computed from ", f$n_cells_used, " cells, ", f$n_samples, " samples and ", f$n_clusters, " clusters; ",
             "cells per sample range from ", f$cells_per_sample_range[1], " to ", f$cells_per_sample_range[2], "."),
      if (!is.null(f$n_groups)) paste0("Number of groups: ", f$n_groups, "; samples per group: ",
                                       paste(names(f$samples_per_group), unlist(f$samples_per_group), sep = "=", collapse = ", "), "."),
      if (!is.null(f$n_cells_missing_sample) && (f$n_cells_missing_sample + f$n_cells_missing_cluster) > 0)
        paste0(f$n_cells_missing_sample, " cells lack a sample ID and ", f$n_cells_missing_cluster, " cells lack a cluster; they were not counted."),
      paste0("Composition test status: ", f$test_status, "."),
      if (!is.null(f$n_tests)) paste0(f$n_tests, " clusters were tested (", f$test_method, ", ", f$p_adjust_method,
                                      " adjustment); ", f$n_significant_adjusted, " have adjusted p < ", f$alpha, "."),
      if (nzchar(context_line)) paste0(context_line, "."))
    s$statistical_meaning <- c(
      "Cell proportions are computed per sample; when comparing groups the unit of replication is the sample, not the cell.",
      "Cluster proportions sum to 1, so a rise in one cluster's proportion lowers the others' relative proportions (compositional data).")
    s$biological_interpretation <- "Proportion changes can only be treated as biological leads when they point in the same direction across several independent biological replicates."
    s$cannot_conclude <- c("Do not use the number of cells as the number of replicates; with too few samples no between-group significance can be concluded.",
                           "A change in proportion is not the same as a change in absolute cell number.")
    s$learning_questions <- c("Why compute proportions per sample before comparing groups?",
                              "Why is a test unsuitable when each group has only 2 samples?")
  } else if (type == "summarized_experiment") {
    concepts <- c("pseudoreplication")
    asm <- f$assay_summaries
    s$data_facts <- c(
      paste0("SummarizedExperiment: ", f$n_features, " features x ", f$n_columns, " columns; assays: ", paste(f$assays, collapse = ", "), "."),
      if (!is.null(f$n_samples)) paste0("Sample column '", f$sample_column, "' has ", f$n_samples, " samples."),
      if (!is.null(f$n_groups)) paste0("Group column '", f$group_column, "' has ", f$n_groups, " groups; independent units per group: ",
                                       if (!is.null(f$units_per_group)) paste(names(f$units_per_group), unlist(f$units_per_group), sep = "=", collapse = ", ") else "omitted", "."),
      if (!is.null(f$n_batches)) paste0("Batch column '", f$batch_column, "' has ", f$n_batches, " batches",
                                        if (isTRUE(f$group_batch_confounded)) "; the group effect is not estimable in a fixed-effects model that includes batch" else "", "."),
      if (length(asm)) vapply(names(asm), function(k) {
        a <- asm[[k]]
        paste0("assay '", k, "': ", a$class, ", dimensions ", paste(a$dim, collapse = "x"), ", inspected by ", a$inspection,
               if (!is.null(a$sample_note)) " (sampled, not the full matrix)" else "")
      }, ""),
      if (nzchar(context_line)) paste0(context_line, "."))
    s$statistical_meaning <- c("A SummarizedExperiment is a container and contains no statistical test itself; its columns are usually samples/libraries and the design information comes from colData.",
                               "Before analysis, confirm whether the assay holds raw counts or normalised/log values; different models require different inputs.")
    s$cannot_conclude <- c("Do not infer differential expression results from the object alone.", "Do not treat the number of columns as the number of independent biological replicates unless a sample column confirms it.")
    s$learning_questions <- c("Which column of colData is the true unit of biological replication?", "Are the values in the assay counts, CPM or log values?")
  } else if (type == "plot") {
    concepts <- c("aes")
    pm <- ctx$plot_mapping
    aes_txt <- if (length(pm$global_aes)) paste(names(pm$global_aes), unlist(pm$global_aes), sep = " = ", collapse = ", ") else "(no global mapping)"
    s$data_facts <- c(
      paste0("ggplot object with ", f$n_layers, " layers: ", paste(f$geoms, collapse = ", "), "; coordinate system ", f$coord, ", facets ", f$facet, "."),
      paste0("Global aes mapping: ", aes_txt, "."),
      if (!is.null(f$n_data_rows)) paste0("The plot data have ", f$n_data_rows, " rows."),
      if (length(pm$labels)) paste0("Labels: ", paste(names(pm$labels), unlist(pm$labels), sep = "=", collapse = "; "), "."),
      if (!is.na(f$plot_type_guess)) paste0("Guessed plot type: ", f$plot_type_guess, " (a guess, not verified).")
    )
    guess <- f$plot_type_guess
    s$statistical_meaning <- switch(as.character(guess),
      volcano_plot = c("In a volcano plot each point is a gene: the x axis is log2FC (direction and size) and the y axis is -log10(p) (higher is more significant).",
                       "Confirm whether the y axis uses raw or adjusted p-values and what rule the threshold lines represent."),
      pca_plot = c("Distances between points in a PCA plot reflect the similarity of overall expression patterns; percentages in the axis labels are variance explained."),
      embedding_plot = c("UMAP/t-SNE plots preserve local neighbourhoods; distances between clusters and cluster areas cannot be compared quantitatively."),
      enrichment_dotplot = c("An enrichment dot plot usually puts GeneRatio/Count on the x axis, colour for p.adjust and point size for gene count."),
      heatmap_like = c("A heatmap maps the values of row features and column samples to colours; the colour gradient shows relative high and low, and its meaning depends on whether the input was scaled or transformed."),
      distribution_comparison = c("Box or violin plots show value distributions and overlap between groups; independent replicates and a formal statistical test are still required."),
      c("Check the aes mapping to see which data column each visual channel uses and how the geometries summarise the data."))
    if (identical(guess, "pca_plot") && !is.null(f$variance_explained)) {
      s$data_facts <- c(s$data_facts,
                        paste0("Variance explained computed by R: PC1 ",
                               round(100 * f$variance_explained[1L], 1), "%, PC2 ",
                               round(100 * f$variance_explained[min(2L, length(f$variance_explained))], 1), "%."))
      s$statistical_meaning <- c(s$statistical_meaning,
        "PCA coordinates reflect the main directions of variation in the data; the variance explained is computed by R from the input values.")
    }
    if (identical(guess, "embedding_plot") && !is.null(f$n_observations)) {
      s$data_facts <- c(s$data_facts,
                        paste0("The plot contains ", f$n_observations, " observations with ", f$n_coordinates, " coordinates each."))
    }
    s$biological_interpretation <- "A plot does not provide new statistical evidence by itself; its biological meaning depends on the underlying data object and the analysis design."
    s$cannot_conclude <- c("Do not draw a complete conclusion from the few labelled genes or colours in a plot.",
                           "Do not infer causality or mechanism directly from visual 'separation'.")
    s$learning_questions <- c("What does each point (or each geometric element) of this plot represent?",
                              "How would the plot's appearance change if the axis transformation or threshold lines were changed?")
  } else if (type == "pca") {
    concepts <- c("pca")
    ve <- f$variance_explained
    s$data_facts <- c(
      paste0(f$n_observations, " observations (usually samples), ", f$n_variables, " variables (usually genes), ", f$n_components, " principal components in total."),
      paste0("Variance explained by the first two components: PC1 ", round(100 * ve[1], 1), "%, PC2 ",
             if (length(ve) > 1) round(100 * ve[2], 1) else NA, "%."),
      paste0("Centered: ", f$centered, "; scaled: ", f$scaled, "."))
    s$statistical_meaning <- "A higher variance explained means that the component summarises more of the total variation, but it does not say whether the source of variation is biological or technical."
    s$biological_interpretation <- "Compare the distribution of samples on PC1/PC2 with group and batch information to judge whether the main variation comes from experimental factors."
    s$cannot_conclude <- c("Do not equate separation of samples directly with an effective treatment.", "Do not ignore the possibility that batch effects cause the separation.")
    s$learning_questions <- c("What should you do if PC1 mainly separates samples by sequencing batch?")
  } else {
    s$data_facts <- c(paste0("Object class: ", paste(ctx$source_class, collapse = "/"), "."),
                      if (!is.null(f$dim)) paste0("Dimensions: ", paste(f$dim, collapse = " x "), "."))
    s$statistical_meaning <- "This object has no dedicated interpretation rules; use analysis_type to specify a type or register a custom adapter."
    s$learning_questions <- "Which function produced this object, and what does each of its rows/columns represent?"
  }
  s <- lapply(s, function(v) unique(v[!is.na(v) & nzchar(v)]))
  s$concepts <- unlist(.concept_cards_en[concepts])
  s
}

# Offline error-diagnosis rule text (English). Keys match the rule ids in .error_rules().
.error_text_en <- list(
  package_missing = list(title = "R package not installed or version not satisfied",
    explain = "A required package is missing from the current R library, or a dependency version is not satisfied."),
  function_missing = list(title = "Function not found",
    explain = "The function name is misspelled, or the package that provides it has not been loaded (library())."),
  object_missing = list(title = "Object not found",
    explain = "The referenced variable does not exist in the current environment: the code that creates it may not have been run, the name may be misspelled, or it may live in a different scope inside a function."),
  column_missing = list(title = "Column, index or dimension does not exist",
    explain = "The column/row/element being accessed does not exist. Common causes are a result table missing a gene, pvalue or log2FC column, or an index out of range."),
  dimension_mismatch = list(title = "Dimensions or lengths do not match",
    explain = "The row/column counts of two objects do not match, for example the number of columns of the count matrix differs from the number of rows of the sample information, or an aes length differs from the data."),
  s4_slot_or_method = list(title = "Object class or S4 method/slot mismatch",
    explain = "The function received an object of a different class than expected (for example a data.frame treated as a Seurat/SummarizedExperiment object), or accessed a slot/assay that does not exist."),
  assay_or_layer_missing = list(title = "assay / layer / slot does not exist",
    explain = "The single-cell object has no requested assay, layer or reduction; a step may not have been run, or the Seurat v4/v5 API differs."),
  gene_id_mapping = list(title = "Gene IDs cannot be mapped",
    explain = "The input gene ID type (SYMBOL/ENTREZID/ENSEMBL) does not match the keyType expected by the annotation database or function, or the species is wrong."),
  factor_level_contrast = list(title = "Problem with the grouping variable, factor levels or comparison direction",
    explain = "A grouping factor level in the design matrix does not exist, has only one level, or is fully collinear with another variable; group names in the contrast may also be spelled inconsistently."),
  count_data_invalid = list(title = "Count data do not meet the method's requirements",
    explain = "DESeq2/edgeR and similar methods need raw integer counts; the input may be normalised, contain negative or missing values, or have all-zero rows."),
  na_nan_inf = list(title = "Missing or infinite values caused a failure",
    explain = "NA/NaN/Inf appeared during computation, commonly from log(0), division by zero, or missing values introduced by merging data."),
  type_mismatch = list(title = "Data type mismatch",
    explain = "The function expected numeric values but received character or factor values (for example numbers read as text when importing a table)."),
  argument_issue = list(title = "Function argument error",
    explain = "An argument name is misspelled, a required argument is missing, or an argument name changed after a package update."),
  file_path = list(title = "File path error",
    explain = "The file does not exist or the working directory is wrong."),
  memory = list(title = "Out of memory",
    explain = "The object is too large for the available memory; common when converting a sparse matrix to a dense matrix."),
  network = list(title = "Network or remote service error",
    explain = "Accessing a remote database/network resource failed."),
  unknown = list(title = "Unclassified error",
    explain = "This error did not match the offline rule base; investigate with the call stack, object summaries and the function documentation (?function_name).")
)

# English fix suggestions; code snippets are identical to the Chinese version.
.advice_en <- function(rule, msg, rec) {
  q <- .quoted(msg)
  env_names <- rec$environment_names %||% character()
  out <- list()
  add <- function(text, code = NULL) out[[length(out) + 1L]] <<- list(text = text, code = code)
  switch(rule$id,
    package_missing = {
      pkg <- if (!is.na(q)) q else "<pkg>"
      if (pkg %in% .bioc_packages) add(paste0("'", pkg, "' is a Bioconductor package; install it with BiocManager."),
                                       paste0('if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")\nBiocManager::install("', pkg, '")'))
      else add(paste0("Install the missing package '", pkg, "'."), paste0('install.packages("', pkg, '")'))
    },
    function_missing = {
      fn <- if (!is.na(q)) q else "<fun>"
      home <- .function_home[fn]
      if (!is.na(home)) add(paste0("The function ", fn, "() usually comes from the ", home, " package; load it first or call ", home, "::", fn, "()."),
                            paste0("library(", home, ")"))
      else add(paste0("Check the spelling of the function name ", fn, " and make sure the package that provides it is loaded with library()."),
               paste0('help.search("', fn, '")'))
    },
    object_missing = {
      obj <- if (!is.na(q)) q else "<object>"
      near <- if (length(env_names) && !is.na(q)) utils::head(env_names[utils::adist(obj, env_names) <= 2], 3) else character()
      if (length(near)) add(paste0("Objects with similar names exist in the environment: ", paste(near, collapse = ", "), "; check for a typo."))
      add("Make sure the code that creates the object has run (for example assign it first inside bio_record) and list existing objects with ls().", "ls()")
    },
    column_missing = add("Use names()/colnames()/dim() to inspect the actual column names and dimensions, and confirm that the capitalisation matches the source package (for example padj vs adj.P.Val).",
                         "names(res); dim(res)"),
    dimension_mismatch = add("Compare the dimensions and sample order of the related objects, for example ncol(counts) and nrow(coldata), and check that colnames(counts) and rownames(coldata) are identical and in the same order.",
                             "stopifnot(identical(colnames(counts), rownames(coldata)))"),
    s4_slot_or_method = add("Inspect the object class with class(x), isVirtualClass/methods::is() and str(x, max.level = 2); convert the object with the proper constructor if necessary.",
                            "class(x); methods::is(x)"),
    assay_or_layer_missing = add("List the assays/layers/reductions present in the object and confirm that the relevant steps (for example NormalizeData, RunPCA, RunUMAP) have been run.",
                                 "SeuratObject::Assays(obj); SeuratObject::Layers(obj); names(obj@reductions)"),
    gene_id_mapping = {
      add("Check the type of the input gene IDs (for example 'TP53' is a SYMBOL, '7157' is an ENTREZID, 'ENSG...' is an ENSEMBL ID) and set a matching keyType and species annotation package in the enrichment function.")
      add("Convert IDs with clusterProfiler::bitr() when needed, and report the fraction that could not be mapped.",
          'clusterProfiler::bitr(genes, fromType = "SYMBOL", toType = "ENTREZID", OrgDb = "org.Hs.eg.db")')
    },
    factor_level_contrast = {
      add("Check the levels of the grouping variable and the number of samples per group, and confirm that the group names in the contrast exactly match the levels.", "table(coldata$condition); levels(coldata$condition)")
      add("Set the reference group explicitly with relevel() if needed; note that this changes the direction of log2FC, so verify afterwards that the comparison direction still matches the research question.",
          'coldata$condition <- relevel(factor(coldata$condition), ref = "control")')
    },
    count_data_invalid = {
      add("Confirm that the input is un-normalised raw integer counts (not TPM/FPKM/log values).", "summary(as.vector(counts)); all(counts == round(counts))")
      add("Do not simply round() normalised data to silence the error: the code will run, but the assumptions of the statistical model are broken.")
    },
    na_nan_inf = add("Locate the step that produces NA/Inf (for example log(0)), count them with is.na()/is.finite(), then decide whether to filter or add a pseudocount, and record that treatment.",
                     "sum(!is.finite(as.matrix(x)))"),
    type_mismatch = add("Inspect column types with str(); if numbers were read as characters, convert them with as.numeric() and check whether NA values were introduced.", "str(x)"),
    argument_issue = add("Use args(function_name) or ?function_name to see the argument list of the installed version, and check the package version.",
                         if (!is.na(q)) paste0("args(", q, ")") else NULL),
    file_path = add("Check the path with getwd() and file.exists(); relative paths inside the project are recommended.", 'getwd(); file.exists("path/to/file")'),
    memory = add("Avoid converting sparse matrices to dense matrices, subset as needed, or run on a machine with more memory."),
    network = add("Check the network connection and proxy settings and retry later; record the database version and access time in the report."),
    add("Read the full call stack and start debugging from the innermost call to your own code; inspect the relevant input objects with str().")
  )
  out
}
