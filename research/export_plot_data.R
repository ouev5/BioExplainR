# Export existing coordinates without rerunning or altering the experiment.
objects <- readRDS("research/cache/real_objects.rds")
dir.create("docs/submission_assets", recursive = TRUE, showWarnings = FALSE)
donor_levels <- unique(as.character(objects$metadata$cell))
donor_map <- stats::setNames(sprintf("D%02d", seq_along(donor_levels)), donor_levels)
pca <- data.frame(PC1 = objects$fit$x[, 1], PC2 = objects$fit$x[, 2],
                  treatment = objects$metadata$dex,
                  donor = unname(donor_map[as.character(objects$metadata$cell)]))
stopifnot(nrow(pca) == 8L)
utils::write.csv(pca, "docs/submission_assets/Figure_3_source.csv", row.names = FALSE)
umap <- SingleCellExperiment::reducedDim(objects$sce, "UMAP")
metadata <- as.data.frame(SummarizedExperiment::colData(objects$sce))
embedding <- data.frame(UMAP1 = umap[, 1], UMAP2 = umap[, 2], mito_qc = metadata$mito_qc)
stopifnot(nrow(embedding) == 2700L)
utils::write.csv(embedding, "docs/submission_assets/Figure_4_source.csv", row.names = FALSE)
cat("Existing PCA and UMAP coordinates exported without sample IDs or barcodes.\n")
