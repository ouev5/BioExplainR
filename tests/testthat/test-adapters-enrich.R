ora_table <- function() {
  data.frame(ID = paste0("GO:", 1:12), Description = paste("term", 1:12),
             GeneRatio = paste0(12:1, "/100"), BgRatio = paste0(200:189, "/18000"),
             pvalue = 10^-(12:1 / 2), p.adjust = pmin(1, 10^-(12:1 / 2) * 6), qvalue = 0.1,
             geneID = "IL6/TNF/CXCL8/IL1B/CCL2/JUN/FOS/EGR1/ATF3/SOCS3", Count = 12:1)
}

test_that("ORA table: counts and no activation claim", {
  tab <- ora_table()
  ctx <- bio_context(tab, n_top = 4)
  expect_false(any(grepl("[^\\x01-\\x7F]", ctx$uncertainty, perl = TRUE)))
  expect_true(any(grepl("activated", ctx$uncertainty)))
  ctx <- bio_context(tab, n_top = 4, language = "zh")
  expect_equal(ctx$analysis_type, "enrichment_ora")
  expect_equal(ctx$facts$n_terms, 12)
  expect_equal(ctx$facts$n_significant, sum(tab$p.adjust < 0.05))
  expect_equal(nrow(ctx$top_features), 4)
  expect_equal(ctx$facts$background_size_from_bgratio, 18000)
  expect_true(any(grepl("不能据此认定通路激活", ctx$uncertainty)))
  expect_true(all(c("Count", "GeneRatio", "p.adjust") %in% names(ctx$top_features)))
  # long gene lists are previewed, not sent in full
  expect_match(ctx$top_features$genes_preview[1], "10 genes")
})

test_that("GSEA table separates NES directions", {
  gs <- data.frame(ID = paste0("P", 1:6), Description = paste("pw", 1:6), setSize = 40,
                   enrichmentScore = 0.4, NES = c(2, 1.5, -1.8, -2.2, 0.5, -0.3),
                   pvalue = c(1e-4, 1e-3, 1e-3, 1e-5, 0.4, 0.6))
  gs$p.adjust <- p.adjust(gs$pvalue, "BH")
  gs$core_enrichment <- "A/B/C"
  ctx <- bio_context(gs, language = "zh")
  expect_equal(ctx$analysis_type, "enrichment_gsea")
  sig <- gs$p.adjust < 0.05
  expect_equal(ctx$facts$n_positive_nes_significant, sum(sig & gs$NES > 0))
  expect_equal(ctx$facts$n_negative_nes_significant, sum(sig & gs$NES < 0))
  expect_true("NES" %in% names(ctx$top_features))
  expect_true(any(grepl("排序", ctx$uncertainty)))
})

test_that("enrichment without adjusted p is labelled raw only", {
  tab <- ora_table()
  tab$p.adjust <- NULL
  ctx <- bio_context(tab)
  expect_equal(ctx$facts$p_value_basis, "raw_only")
  expect_equal(ctx$facts$n_significant, sum(tab$pvalue < 0.05))
})

test_that("enrichResult / gseaResult S4 objects use slots without DOSE", {
  setClass("enrichResult", representation(result = "data.frame", pvalueCutoff = "numeric",
                                          pAdjustMethod = "character", organism = "character",
                                          ontology = "character", gene = "character",
                                          universe = "character", keytype = "character"),
           where = globalenv())
  setClass("gseaResult", representation(result = "data.frame", setType = "character",
                                        organism = "character", params = "list", geneList = "numeric"),
           where = globalenv())
  on.exit({
    removeClass("enrichResult", where = globalenv())
    removeClass("gseaResult", where = globalenv())
  })
  er <- new("enrichResult", result = ora_table(), pvalueCutoff = 0.01, pAdjustMethod = "BH",
            organism = "Homo sapiens", ontology = "BP", gene = paste0("g", 1:80),
            universe = paste0("u", 1:5000), keytype = "SYMBOL")
  ctx <- bio_context(er)
  expect_equal(ctx$adapter, "enrich_result")
  expect_equal(ctx$source_status, "verified_class")
  expect_equal(ctx$facts$universe_size, 5000)
  expect_equal(ctx$facts$n_input_genes, 80)
  expect_equal(ctx$metadata$species, "Homo sapiens")
  # object's own cutoff used unless the user sets one
  expect_equal(ctx$facts$significance_threshold, 0.01)
  expect_equal(bio_context(er, thresholds = list(padj = 0.2))$facts$significance_threshold, 0.2)

  gs <- data.frame(ID = "P1", Description = "pw", setSize = 10, NES = 1.9, pvalue = 1e-4, p.adjust = 1e-3,
                   core_enrichment = "A/B")
  gr <- new("gseaResult", result = gs, setType = "BP", organism = "Mus musculus",
            params = list(pvalueCutoff = 0.05, pAdjustMethod = "BH", minGSSize = 10L),
            geneList = c(a = 2, b = 1, c = -1))
  g <- bio_context(gr)
  expect_equal(g$analysis_type, "enrichment_gsea")
  expect_equal(g$facts$ranked_list_length, 3)
})
