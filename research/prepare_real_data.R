# Run from the project root after installing BioExplainR and optional packages.
# Downloads are explicit; model requests are in a separate script.
suppressPackageStartupMessages(library(BioExplainR))
needed <- c("airway", "DESeq2", "limma", "edgeR", "SingleCellExperiment", "SeuratObject", "uwot")
stopifnot(all(vapply(needed, requireNamespace, logical(1), quietly = TRUE)))
dir.create("research/cache", recursive = TRUE, showWarnings = FALSE)
dir.create("research/results", recursive = TRUE, showWarnings = FALSE)
dir.create("research/results/figures", showWarnings = FALSE)
plain <- function(x) if (is.list(x) && !is.data.frame(x)) lapply(x, plain) else x
write_json <- function(x, name) jsonlite::write_json(plain(x), file.path("research/results", name),
                                                   pretty = TRUE, auto_unbox = TRUE, null = "null", digits = 10)
download <- function(url, file) {
  if (!file.exists(file)) utils::download.file(url, file, mode = "wb", quiet = TRUE)
  list(url = url, file = basename(file), sha256 = digest::digest(file = file, algo = "sha256"),
       checked_utc = format(Sys.time(), tz = "UTC", usetz = TRUE))
}
data_env <- new.env()
utils::data("airway", package = "airway", envir = data_env)
airway <- data_env$airway
counts <- SummarizedExperiment::assay(airway)
md <- as.data.frame(SummarizedExperiment::colData(airway))
md$dex <- stats::relevel(factor(md$dex), "untrt")
md$cell <- factor(md$cell)
keep <- rowSums(counts) >= 10
dds <- DESeq2::DESeqDataSetFromMatrix(counts[keep, ], md, design = ~ cell + dex)
dds <- DESeq2::DESeq(dds, quiet = TRUE)
res <- DESeq2::results(dds, contrast = c("dex", "trt", "untrt"), alpha = .05)
tab <- as.data.frame(res)
sig <- !is.na(tab$padj) & tab$padj < .05 & abs(tab$log2FoldChange) > 1
reference <- list(n_features = nrow(tab), n_significant = sum(sig),
                  n_up = sum(sig & tab$log2FoldChange > 0), n_down = sum(sig & tab$log2FoldChange < 0),
                  n_na_padj = sum(is.na(tab$padj)))
ctx <- bio_context(res, species = "Homo sapiens", tissue = "airway smooth muscle",
                   design = "~ cell + dex", contrast = "dexamethasone trt vs untrt", thresholds = list(padj = .05, lfc = 1))
stopifnot(all(vapply(names(reference), function(n) isTRUE(all.equal(ctx$facts[[n]], reference[[n]])), logical(1))))
vsd <- DESeq2::vst(dds, blind = FALSE)
expression <- SummarizedExperiment::assay(vsd)
metadata <- md[c("dex", "cell")]
pca <- bio_plot_pca(expression, metadata = metadata, group = "dex", n_top_features = 500)
fit <- attr(pca, "bio_plot_source")$prcomp
volcano <- ggplot2::ggplot(tab, ggplot2::aes(log2FoldChange, -log10(padj))) +
  ggplot2::geom_point(alpha = .3, size = .7, na.rm = TRUE) + ggplot2::theme_minimal() +
  ggplot2::labs(title = "airway: trt vs untrt", x = "log2 fold change", y = "-log10 adjusted p")
heat <- bio_plot_heatmap(expression, metadata = metadata["dex"], top_n = 30)

# Fit independent upstream methods to real counts; their significance counts are
# method-specific and are not required to agree with DESeq2.
design <- stats::model.matrix(~ cell + dex, md)
dge <- edgeR::DGEList(counts[keep, ])
dge <- edgeR::calcNormFactors(dge)
dge <- edgeR::estimateDisp(dge, design)
ql <- edgeR::glmQLFTest(edgeR::glmQLFit(dge, design), coef = "dextrt")
tags <- edgeR::topTags(ql, n = Inf)
voom <- limma::voom(dge, design, plot = FALSE)
lmfit <- limma::eBayes(limma::lmFit(voom, design))
limma_ctx <- bio_context(lmfit, coefficient = "dextrt", thresholds = list(padj = .05, lfc = 1))
edger_ctx <- bio_context(tags, thresholds = list(padj = .05, lfc = 1))

mapping_path <- "research/cache/Ensembl2Reactome.txt"
mapping_source <- download("https://reactome.org/download/current/Ensembl2Reactome.txt", mapping_path)
mapping <- utils::read.delim(mapping_path, header = FALSE, quote = "", stringsAsFactors = FALSE)
names(mapping) <- c("gene", "ID", "url", "Description", "evidence", "species")
mapping <- unique(mapping[mapping$species == "Homo sapiens" & mapping$gene %in% rownames(tab), ])
universe <- unique(mapping$gene)
selected <- intersect(rownames(tab)[sig], universe)
sets <- split(mapping$gene, mapping$ID)
sets <- lapply(sets, unique)
sets <- sets[lengths(sets) >= 10 & lengths(sets) <= 500]
ora <- do.call(rbind, lapply(names(sets), function(id) {
  genes <- sets[[id]]; overlap <- intersect(genes, selected)
  data.frame(ID = id, Description = mapping$Description[match(id, mapping$ID)],
             GeneRatio = paste0(length(overlap), "/", length(selected)),
             BgRatio = paste0(length(genes), "/", length(universe)), Count = length(overlap),
             pvalue = stats::phyper(length(overlap) - 1L, length(genes), length(universe) - length(genes),
                                    length(selected), lower.tail = FALSE),
             geneID = paste(overlap, collapse = "/"), stringsAsFactors = FALSE)
}))
ora$p.adjust <- stats::p.adjust(ora$pvalue, "BH")
ora <- ora[order(ora$p.adjust), ]
dot <- bio_plot_enrichment(ora, top_n = 15)

pbmc_file <- "research/cache/pbmc3k_filtered_gene_bc_matrices.tar.gz"
pbmc_source <- download("https://cf.10xgenomics.com/samples/cell-exp/1.1.0/pbmc3k/pbmc3k_filtered_gene_bc_matrices.tar.gz", pbmc_file)
utils::untar(pbmc_file, exdir = "research/cache")
pbmc_dir <- "research/cache/filtered_gene_bc_matrices/hg19"
pbmc <- Matrix::readMM(file.path(pbmc_dir, "matrix.mtx"))
genes <- utils::read.delim(file.path(pbmc_dir, "genes.tsv"), header = FALSE, stringsAsFactors = FALSE)
barcodes <- utils::read.delim(file.path(pbmc_dir, "barcodes.tsv"), header = FALSE, stringsAsFactors = FALSE)
rownames(pbmc) <- make.unique(genes$V2); colnames(pbmc) <- barcodes$V1
pbmc <- as(pbmc, "CsparseMatrix")
qc <- data.frame(nCount_RNA = Matrix::colSums(pbmc), nFeature_RNA = Matrix::colSums(pbmc > 0),
                 percent.mt = 100 * Matrix::colSums(pbmc[grepl("^MT-", rownames(pbmc)), ]) / Matrix::colSums(pbmc),
                 sample_id = "public_pbmc3k", row.names = colnames(pbmc))
qc$mito_qc <- ifelse(qc$percent.mt <= 5, "mt <= 5%", "mt > 5%")
sce <- SingleCellExperiment::SingleCellExperiment(assays = list(counts = pbmc), colData = qc)
seurat <- SeuratObject::CreateSeuratObject(pbmc, meta.data = qc)
sce_ctx <- bio_context(sce, sample_col = "sample_id", species = "Homo sapiens", tissue = "PBMC")
seurat_ctx <- bio_context(seurat, sample_col = "sample_id", species = "Homo sapiens", tissue = "PBMC")
stopifnot(sce_ctx$facts$n_cells == ncol(pbmc), seurat_ctx$facts$n_cells == ncol(pbmc),
          sce_ctx$facts$n_samples == 1, seurat_ctx$facts$n_samples == 1)
pbmc_log <- log1p(Matrix::t(Matrix::t(pbmc) / Matrix::colSums(pbmc)) * 1e4)
mu <- Matrix::rowMeans(pbmc_log)
variances <- Matrix::rowMeans(pbmc_log^2) - mu^2
variable <- order(variances, decreasing = TRUE)[1:1000]
pbmc_pca <- stats::prcomp(t(as.matrix(pbmc_log[variable, ])), rank. = 20)
set.seed(20261004)
umap <- uwot::umap(pbmc_pca$x[, 1:20], n_neighbors = 15, n_threads = 1, n_sgd_threads = 1, verbose = FALSE)
rownames(umap) <- colnames(pbmc)
colnames(umap) <- c("UMAP_1", "UMAP_2")
SingleCellExperiment::reducedDim(sce, "UMAP") <- umap
seurat[["umap"]] <- SeuratObject::CreateDimReducObject(umap, key = "UMAP_", assay = "RNA")
embedding <- bio_plot_umap(sce, reduction = "UMAP", group = "mito_qc")
embedding_seurat <- bio_plot_umap(seurat, reduction = "umap", group = "mito_qc")
stopifnot(nrow(embedding$data) == 2700, nrow(embedding_seurat$data) == 2700)

# Deliberately injected faults are challenge cases, not flaws in the dataset.
bad_volcano <- ggplot2::ggplot(tab, ggplot2::aes(-log2FoldChange, -log10(padj))) + ggplot2::geom_point(na.rm = TRUE)
bad_raw <- ggplot2::ggplot(tab, ggplot2::aes(log2FoldChange, -log10(pvalue))) + ggplot2::geom_point(na.rm = TRUE)
bad_pca <- pca; bad_pca$data$PC1[1] <- bad_pca$data$PC1[1] + 5
bad_label <- pca + ggplot2::labs(x = "PC1 (99.9%)")
bad_dot <- dot; bad_dot$data$count[1] <- bad_dot$data$count[1] + 1
bad_dot_colour <- dot; bad_dot_colour$data$neglog10_p[1] <- 0
plots <- list(volcano = volcano, reversed_direction = bad_volcano, raw_p_as_adjusted = bad_raw,
              pca = pca, pca_wrong_coordinate = bad_pca, pca_wrong_label = bad_label,
              enrichment = dot, enrichment_wrong_size = bad_dot, enrichment_wrong_colour = bad_dot_colour)
sources <- list(tab, tab, tab, expression, expression, expression, ora, ora, ora)
expected <- c("pass", "fail", "fail", "pass", "fail", "fail", "pass", "fail", "fail")
cross_checks <- lapply(seq_along(plots), function(i) bio_cross_check(plots[[i]], sources[[i]], allow_subset = TRUE))
cross_table <- data.frame(case = names(plots), expected = expected,
                          actual = vapply(cross_checks, function(x) x$status, ""), stringsAsFactors = FALSE)
stopifnot(all(cross_table$expected == cross_table$actual))
utils::write.csv(cross_table, "research/results/plot_challenges.csv", row.names = FALSE)
write_json(cross_checks, "plot_findings.json")

fix_good <- bio_validate_fix(quote({ md$dex <- relevel(factor(md$dex), ref = "untrt"); md }),
  inputs = list(md = md), invariants = list(inv_nrow(8), inv_factor_levels("dex", c("untrt", "trt"))))
fix_bad <- bio_validate_fix(quote({ md$dex <- relevel(factor(md$dex), ref = "trt"); md }),
  inputs = list(md = md), invariants = list(inv_nrow(8), inv_factor_levels("dex", c("untrt", "trt"))))
stopifnot(fix_good$status == "invariants_passed", fix_bad$status == "invariants_failed")
write_json(list(correct_reference = fix_good, reversed_reference = fix_bad), "fix_validation.json")

checks <- list(DESeq2 = ctx, limma = limma_ctx, edgeR = edger_ctx,
               SummarizedExperiment = bio_context(airway), SingleCellExperiment = sce_ctx, SeuratObject = seurat_ctx)
write_json(lapply(checks, function(c) list(class = c$source_class, status = c$source_status, facts = c$facts)), "compatibility.json")
ex <- bio_explain(res, use_llm = FALSE, thresholds = list(padj = .05, lfc = 1),
                  species = "Homo sapiens", contrast = "dexamethasone trt vs untrt", design = "~ cell + dex")
project <- bio_project(list(deg = ex, enrichment = bio_explain(ora, use_llm = FALSE),
                           volcano = bio_explain(volcano, use_llm = FALSE, cross_check = res)),
                       dependencies = list(enrichment = "deg", volcano = "deg"))
bio_report(bio_explain_project(project), file = "research/results/airway_report.html")
for (name in c("pca", "heat", "dot", "embedding", "volcano")) {
  p <- get(name)
  p <- p + ggplot2::theme(text = ggplot2::element_text(family = "Noto Sans CJK SC"))
  ggplot2::ggsave(file.path("research/results/figures", paste0(name, ".png")), p, width = 8, height = 5.5, dpi = 150)
}
manifest <- list(dataset = "airway / GSE52778", citation = "doi:10.1371/journal.pone.0099625",
                 airway_package = as.character(utils::packageVersion("airway")),
                 airway_data_sha256 = digest::digest(counts, algo = "sha256"),
                 original_features = nrow(counts), retained_features = nrow(tab), samples = ncol(counts), donors = 4,
                 filter = "rowSums(counts) >= 10", design = "~ cell + dex", contrast = "trt vs untrt",
                 thresholds = list(padj = .05, lfc = 1), reference = reference,
                 pca_variance = fit$sdev^2 / sum(fit$sdev^2),
                 reactome = mapping_source, ora_terms = nrow(ora), ora_significant = sum(ora$p.adjust < .05),
                 ora_universe = length(universe), ora_selected = length(selected),
                 pbmc = pbmc_source, pbmc_features = nrow(pbmc), pbmc_cells = ncol(pbmc), pbmc_samples = 1,
                 seed = 20261004, software = bio_dependency_provenance(c("BioExplainR", needed, "Matrix", "ggplot2")))
write_json(manifest, "data_manifest.json")
saveRDS(list(res = res, tab = tab, expression = expression, metadata = metadata, ora = ora, pca = pca,
             fit = fit, sce = sce, seurat = seurat, embedding = embedding, reference = reference,
             manifest = manifest), "research/cache/real_objects.rds")
cat("Real-data preparation and deterministic checks passed.\n")
print(reference)
