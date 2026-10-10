# Single-cell adapters (Seurat / SingleCellExperiment / cell metadata) -------------

.qc_aliases <- list(
  n_counts = c("nCount_RNA", "total", "sum", "nUMI", "total_counts"),
  n_features = c("nFeature_RNA", "detected", "nGene", "n_genes_by_counts"),
  pct_mt = c("percent.mt", "percent_mito", "subsets_Mito_percent", "pct_counts_mt", "percent.mito", "mito_percent")
)
.sample_aliases <- c("sample", "sample_id", "orig.ident", "donor", "donor_id", "patient",
                     "patient_id", "individual", "subject", "Sample")
.cluster_aliases <- c("seurat_clusters", "cluster", "clusters", "label", "celltype",
                      "cell_type", "leiden", "louvain")

.q <- function(v) {
  v <- suppressWarnings(as.numeric(v))
  if (!any(!is.na(v))) return(NULL)
  q <- stats::quantile(v, c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE, names = FALSE)
  stats::setNames(signif(q, 4), c("min", "q25", "median", "q75", "max"))
}

# Summarise per-cell metadata without exposing barcodes or sample names. Only
# observed levels are counted: unused factor levels and missing IDs are not
# clusters/samples (missing ones are reported as counts). Batch is a technical
# grouping and is never counted as a replicate.
.summarize_cell_meta <- function(md, cluster_col = NULL, sample_col = NULL, n_top = 10,
                                 group_col = NULL, batch_col = NULL) {
  md <- as.data.frame(md, stringsAsFactors = FALSE)
  facts <- list(n_cells = nrow(md))
  qc <- list()
  for (k in names(.qc_aliases)) {
    col <- .find_col(md, .qc_aliases[[k]])
    if (!is.null(col)) qc[[k]] <- list(column = col, quantiles = as.list(.q(md[[col]])))
  }
  if (length(qc)) facts$qc <- qc
  cluster_col <- cluster_col %||% .find_col(md, .cluster_aliases)
  top <- NULL
  if (!is.null(cluster_col) && cluster_col %in% names(md)) {
    cl <- .clean_id(md[[cluster_col]])
    tab <- sort(table(cl), decreasing = TRUE)
    facts$cluster_column <- cluster_col
    facts$n_clusters <- length(tab)
    facts$n_cells_missing_cluster <- sum(is.na(cl))
    if (is.factor(md[[cluster_col]])) facts$n_unused_cluster_levels <- sum(!levels(md[[cluster_col]]) %in% names(tab))
    facts$cluster_size_range <- if (length(tab)) as.integer(range(tab)) else c(NA_integer_, NA_integer_)
    top <- data.frame(cluster = .truncate_chr(names(tab), 40), n_cells = as.integer(tab),
                      fraction = round(as.numeric(tab) / sum(tab), 4), stringsAsFactors = FALSE)
    top <- utils::head(top, n_top)
  }
  sample_col <- sample_col %||% .find_col(md, .sample_aliases)
  group_col <- group_col %||% NULL
  batch_col <- batch_col %||% .find_col(md, .batch_aliases)
  des <- .design_facts(md, sample_col, group_col, batch_col, unit = "cells")
  facts <- c(facts, des$facts)
  if (!is.null(sample_col) && sample_col %in% names(md) && !is.null(cluster_col) && cluster_col %in% names(md)) {
    ct <- table(.clean_id(md[[cluster_col]]), .clean_id(md[[sample_col]]))
    facts$n_clusters_present_in_one_sample_only <- sum(rowSums(ct > 0) == 1)
  }
  list(facts = facts, top = top, uncertainty = des$uncertainty)
}

.sc_uncertainty <- function(facts) {
  u <- c("The number of cells is not the number of biological replicates; samples/donors are the independent units of replication. Treating cells as replicates in single-cell differential analysis easily yields false positives (pseudoreplication)." %L% "\u7ec6\u80de\u6570\u4e0d\u7b49\u4e8e\u751f\u7269\u5b66\u91cd\u590d\u6570\uff1b\u6837\u672c/\u4f9b\u4f53\u624d\u662f\u72ec\u7acb\u91cd\u590d\u5355\u4f4d\u3002\u5355\u7ec6\u80de\u5dee\u5f02\u5206\u6790\u82e5\u628a\u7ec6\u80de\u5f53\u91cd\u590d\uff0c\u5bb9\u6613\u4ea7\u751f\u5047\u9633\u6027\uff08\u4f2a\u91cd\u590d\u95ee\u9898\uff09\u3002",
         "Distances on a UMAP/t-SNE do not represent true spatial distances; the layout depends on parameters and cannot by itself prove cell lineage." %L% "UMAP/t-SNE \u4e0a\u7684\u8ddd\u79bb\u4e0d\u4ee3\u8868\u771f\u5b9e\u7a7a\u95f4\u8ddd\u79bb\uff0c\u56fe\u5f62\u7ed3\u6784\u53d7\u53c2\u6570\u5f71\u54cd\uff0c\u4e0d\u80fd\u5355\u72ec\u8bc1\u660e\u7ec6\u80de\u8c31\u7cfb\u3002",
         "Cluster numbers have no biological meaning by themselves; cell-type annotation should rely on a combination of several markers and tissue context." %L% "cluster \u7f16\u53f7\u672c\u8eab\u6ca1\u6709\u751f\u7269\u5b66\u542b\u4e49\uff1b\u7ec6\u80de\u7c7b\u578b\u6ce8\u91ca\u5e94\u57fa\u4e8e\u591a\u4e2a marker \u7684\u7ec4\u5408\u5e76\u7ed3\u5408\u7ec4\u7ec7\u80cc\u666f\u3002")
  if (is.null(facts$n_samples)) {
    u <- c(u, "No sample/donor column was identified, so the number of biological replicates cannot be judged; provide a sample or donor column in the metadata." %L% "\u672a\u8bc6\u522b\u5230\u6837\u672c/\u4f9b\u4f53\u5217\uff0c\u65e0\u6cd5\u5224\u65ad\u751f\u7269\u5b66\u91cd\u590d\u6570\uff1b\u8bf7\u5728 metadata \u4e2d\u63d0\u4f9b sample \u6216 donor \u5217\u3002")
  } else if (facts$n_samples < 3) {
    u <- c(u, paste0("Only " %L% "\u4ec5\u8bc6\u522b\u5230 ", facts$n_samples, " samples were identified; the statistical power for between-group comparison is very limited." %L% " \u4e2a\u6837\u672c\uff1b\u7ec4\u95f4\u6bd4\u8f83\u7684\u7edf\u8ba1\u63a8\u65ad\u80fd\u529b\u975e\u5e38\u6709\u9650\u3002"))
  }
  if (is.null(facts$qc)) u <- c(u, "No common QC metric column (nCount/nFeature/percent.mt) was found, so quality control cannot be assessed." %L% "\u672a\u627e\u5230\u5e38\u89c1 QC \u6307\u6807\u5217\uff08nCount/nFeature/percent.mt\uff09\uff0c\u65e0\u6cd5\u8bc4\u4f30\u8d28\u63a7\u3002")
  u
}

.adapt_seurat <- function(x, meta = list(), n_top = 10, cluster_col = NULL, sample_col = NULL,
                          group_col = NULL, batch_col = NULL, ...) {
  # Works on Seurat v4 (Assay, @counts/@data slots) and v5 (Assay5, layers).
  # SeuratObject accessors (Layers(), VariableFeatures(), Idents()) are used when
  # installed; assay matrices are never extracted.
  has_so <- requireNamespace("SeuratObject", quietly = TRUE)
  md <- .slot_or(x, "meta.data")
  if (is.null(md)) stop("Seurat object has no meta.data slot.", call. = FALSE)
  md <- as.data.frame(md, stringsAsFactors = FALSE)
  idents_used <- FALSE
  if (is.null(cluster_col) && is.null(.find_col(md, .cluster_aliases)) && has_so) {
    id <- tryCatch(as.character(SeuratObject::Idents(x)), error = function(e) NULL)
    if (length(id) == nrow(md)) { md$active.ident <- id; cluster_col <- "active.ident"; idents_used <- TRUE }
  }
  s <- .summarize_cell_meta(md, cluster_col, sample_col, n_top, group_col, batch_col)
  facts <- s$facts
  assays <- .slot_or(x, "assays")
  assay_class <- NA_character_
  if (is.list(assays)) {
    facts$assays <- names(assays)
    facts$active_assay <- as.character(.slot_or(x, "active.assay") %||% NA)
    a <- tryCatch(assays[[facts$active_assay]], error = function(e) NULL)
    if (!is.null(a)) assay_class <- class(a)[1]
    feat <- tryCatch(as.integer(dim(a)[1]), error = function(e) NA_integer_)
    if (length(feat) == 0 || is.na(feat)) {
      feat <- tryCatch({
        cnt <- .slot_or(a, "counts")
        if (!is.null(cnt)) nrow(cnt) else NA_integer_
      }, error = function(e) NA_integer_)
    }
    facts$n_features_active_assay <- as.integer(feat %||% NA_integer_)
    facts$assay_class <- assay_class
    facts$layers_or_slots <- if (has_so) tryCatch(SeuratObject::Layers(x), error = function(e) NULL)
    if (is.null(facts$layers_or_slots) && !is.null(a)) {
      lay <- .slot_or(a, "layers")
      facts$layers_or_slots <- if (is.list(lay)) names(lay) else NULL
    }
  }
  if (idents_used) facts$cluster_source <- "Idents(object) (no cluster column in meta.data)"
  red <- .slot_or(x, "reductions")
  if (is.list(red)) {
    facts$reductions <- names(red)
    facts$reduction_dims <- vapply(red, function(r) {
      emb <- .slot_or(r, "cell.embeddings")
      if (is.null(emb)) NA_integer_ else ncol(emb)
    }, integer(1))
  }
  gr <- .slot_or(x, "graphs")
  if (is.list(gr) && length(gr)) facts$graphs <- names(gr)
  vf <- tryCatch(if (has_so) length(SeuratObject::VariableFeatures(x)) else NULL, error = function(e) NULL)
  if (!is.null(vf)) facts$n_variable_features <- vf
  ver <- .slot_or(x, "version")
  unc <- c(.sc_uncertainty(facts), s$uncertainty)
  if (!has_so) unc <- c(unc, "SeuratObject is not installed; some assay information is read directly from object slots and may be incomplete." %L% "\u672a\u5b89\u88c5 SeuratObject\uff0c\u90e8\u5206 assay \u4fe1\u606f\u901a\u8fc7\u5bf9\u8c61\u69fd\u4f4d\u76f4\u63a5\u8bfb\u53d6\uff0c\u53ef\u80fd\u4e0d\u5b8c\u6574\u3002")
  new_bio_context("single_cell", class(x), "Seurat/SeuratObject", "verified_class",
                  facts = facts, top_features = s$top, metadata = meta, uncertainty = unc,
                  provenance = list(object_version = if (!is.null(ver)) as.character(ver) else NA_character_,
                                    seuratobject_available = has_so, assay_class = assay_class))
}

.adapt_sce <- function(x, meta = list(), n_top = 10, cluster_col = NULL, sample_col = NULL,
                       group_col = NULL, batch_col = NULL, ...) {
  if (!requireNamespace("SummarizedExperiment", quietly = TRUE)) {
    ctx <- .adapt_generic(x, meta = meta)
    ctx$analysis_type <- "single_cell"
    ctx$uncertainty <- c(ctx$uncertainty, "SummarizedExperiment/SingleCellExperiment must be installed to read the colData, assays and reductions." %L% "\u9700\u8981\u5b89\u88c5 SummarizedExperiment/SingleCellExperiment \u624d\u80fd\u8bfb\u53d6 colData\u3001assay \u548c\u964d\u7ef4\u4fe1\u606f\u3002")
    ctx$source_package <- "SingleCellExperiment"
    ctx$source_status <- "verified_class"
    return(ctx)
  }
  cd <- as.data.frame(SummarizedExperiment::colData(x), stringsAsFactors = FALSE)
  s <- .summarize_cell_meta(cd, cluster_col, sample_col, n_top, group_col, batch_col)
  facts <- s$facts
  facts$n_features <- nrow(x)
  facts$assays <- SummarizedExperiment::assayNames(x)
  facts$assay_summaries <- lapply(stats::setNames(seq_along(facts$assays), facts$assays), function(i) {
    tryCatch(.matrix_facts(SummarizedExperiment::assay(x, i, withDimnames = FALSE)), error = function(e) list(error = conditionMessage(e)))
  })
  if (requireNamespace("SingleCellExperiment", quietly = TRUE)) {
    rd <- SingleCellExperiment::reducedDimNames(x)
    facts$reductions <- rd
    if (length(rd)) {
      facts$reduction_dims <- vapply(rd, function(n) ncol(SingleCellExperiment::reducedDim(x, n)), integer(1))
    }
    facts$alt_experiments <- tryCatch(SingleCellExperiment::altExpNames(x), error = function(e) NULL)
  }
  new_bio_context("single_cell", class(x), "SingleCellExperiment", "verified_class",
                  facts = facts, top_features = s$top, metadata = meta,
                  uncertainty = c(.sc_uncertainty(facts), s$uncertainty,
                                  "Only a limited subset of the assay values was inspected (stored slots for sparse matrices, at most one sampled block for dense matrices)." %L%
                                    "assay \u6570\u503c\u53ea\u68c0\u67e5\u4e86\u6709\u9650\u5b50\u96c6\uff08\u7a00\u758f\u77e9\u9635\u8bfb\u53d6\u5b58\u50a8\u69fd\u4f4d\uff0c\u7a20\u5bc6\u77e9\u9635\u6700\u591a\u62bd\u6837\u4e00\u4e2a\u5c0f\u5757\uff09\u3002"))
}

.adapt_cell_metadata <- function(x, meta = list(), n_top = 10, cluster_col = NULL, sample_col = NULL,
                                 group_col = NULL, batch_col = NULL, ...) {
  if (!is.data.frame(x)) stop("analysis_type = 'single_cell' for non-Seurat/SCE input expects a per-cell metadata data.frame.", call. = FALSE)
  s <- .summarize_cell_meta(x, cluster_col, sample_col, n_top, group_col, batch_col)
  new_bio_context("single_cell", class(x), NA_character_, "user_declared",
                  facts = s$facts, top_features = s$top, metadata = meta,
                  uncertainty = c("The input is a user-declared single-cell metadata table, so only QC, cluster and sample counts can be summarised." %L% "\u8f93\u5165\u662f\u7528\u6237\u58f0\u660e\u7684\u5355\u7ec6\u80de\u5143\u6570\u636e\u8868\uff0c\u4ec5\u80fd\u603b\u7ed3 QC\u3001cluster \u4e0e\u6837\u672c\u6570\u91cf\u3002",
                                  .sc_uncertainty(s$facts), s$uncertainty))
}
