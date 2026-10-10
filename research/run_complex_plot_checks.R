# Complex plot cross-check smoke tests.  These are controlled mappings, not a
# visual quality benchmark.  Facets and coordinate clipping should be checked
# on pre-transform data; multiple unrelated point layers remain not_checkable.
suppressPackageStartupMessages({
  library(BioExplainR)
  library(ggplot2)
})
dir.create("research/results/complex_plot", recursive = TRUE, showWarnings = FALSE)
d <- readRDS("research/cache/real_objects.rds")
tab <- d$tab
tab$facet_group <- ifelse(seq_len(nrow(tab)) %% 2, "A", "B")
tab$gene <- rownames(tab)
correct <- ggplot(tab, aes(log2FoldChange, -log10(padj), label = gene, colour = facet_group)) +
  geom_point(na.rm = TRUE) + facet_wrap(~facet_group) + coord_cartesian(xlim = c(-3, 3))
wrong_raw <- ggplot(tab, aes(log2FoldChange, -log10(pvalue), label = gene, colour = facet_group)) +
  geom_point(na.rm = TRUE) + facet_wrap(~facet_group)
multi_layer <- ggplot(tab, aes(log2FoldChange, -log10(padj), label = gene)) +
  geom_point(na.rm = TRUE) + geom_point(data = head(tab, 10), colour = "red", na.rm = TRUE)
cases <- list(
  facet_and_clip = list(plot = correct, expected = "pass"),
  raw_p_in_facets = list(plot = wrong_raw, expected = "fail"),
  multiple_point_layers = list(plot = multi_layer, expected = "not_checkable")
)
rows <- lapply(names(cases), function(name) {
  actual <- bio_cross_check(cases[[name]]$plot, tab, allow_subset = TRUE)
  data.frame(case = name, expected = cases[[name]]$expected, actual = actual$status,
             findings = paste(actual$findings$check, actual$findings$status, sep = ":", collapse = ";"),
             stringsAsFactors = FALSE)
})
result <- do.call(rbind, rows)
stopifnot(all(result$expected == result$actual))
write.csv(result, "research/results/complex_plot/complex_plot_checks.csv", row.names = FALSE)
findings <- lapply(names(cases), function(name) {
  checked <- bio_cross_check(cases[[name]]$plot, tab, allow_subset = TRUE)
  list(status = checked$status, findings = checked$findings, allow_subset = checked$allow_subset,
       note = checked$note)
})
names(findings) <- names(cases)
jsonlite::write_json(findings, "research/results/complex_plot/complex_plot_findings.json", pretty = TRUE, auto_unbox = TRUE)
print(result)
