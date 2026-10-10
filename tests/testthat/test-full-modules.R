# Offline regression tests for cross-checks, claim validation, evidence mocks, adapters --------------------

jresp <- function(x) httr2::response(status_code = 200, headers = list(`Content-Type` = "application/json"),
                                     body = charToRaw(jsonlite::toJSON(x, auto_unbox = TRUE)))
tresp <- function(txt) httr2::response(status_code = 200, headers = list(`Content-Type` = "text/plain"), body = charToRaw(txt))

mock_ev <- function(req) {
  u <- req$url
  if (grepl("europepmc|ebi.ac.uk/europepmc", u) && grepl("/search", u))
    return(jresp(list(version = "6.9", resultList = list(result = list(list(source = "MED", id = "123", title = "IL6 in disease",
                                                         journalTitle = "J", pubYear = "2020"))))))
  if (grepl("QuickGO|/terms/", u)) return(jresp(list(results = list(list(id = "GO:0006954", name = "inflammatory response",
                                          aspect = "biological_process", definition = list(text = "A response."), isObsolete = FALSE)))))
  if (grepl("reactome", u)) return(jresp(list(stId = "R-HSA-69278", displayName = "Cell Cycle, Mitotic",
                                              speciesName = "Homo sapiens", schemaClass = "Pathway")))
  if (grepl("kegg", u)) return(tresp("ENTRY       hsa04110                    Pathway\nNAME        Cell cycle - Homo sapiens\n"))
  if (grepl("uniprot", u)) return(jresp(list(results = list(list(primaryAccession = "P05231", entryType = "UniProtKB reviewed (Swiss-Prot)",
                                              genes = list(list(geneName = list(value = "IL6"))),
                                              organism = list(scientificName = "Homo sapiens"))))))
  httr2::response(status_code = 404)
}

test_that("all five evidence protocols parse mocked responses, with cache and error handling", {
  skip_if_not_installed("httr2")
  bio_evidence_cache_clear()
  q <- list(europepmc = "IL6", go = "GO:0006954", reactome = "R-HSA-69278", kegg = "hsa04110", uniprot = "IL6")
  for (s in names(q)) {
    r <- httr2::with_mocked_responses(mock_ev, bio_fetch_evidence(q[[s]], s, retries = 0, mode = if (s == "uniprot") "gene" else "auto"))
    expect_length(r, 1); expect_true(inherits(r[[1]], "bio_evidence"))
    expect_false(attr(r, "retrieval")$from_cache)
    r2 <- bio_fetch_evidence(q[[s]], s, retries = 0, mode = if (s == "uniprot") "gene" else "auto")  # cached: no mock needed
    expect_true(attr(r2, "retrieval")$from_cache)
  }
  bad <- function(req) httr2::response(status_code = 200, headers = list(`Content-Type` = "application/json"), body = charToRaw("{\"x\":1}"))
  expect_error(httr2::with_mocked_responses(bad, bio_fetch_evidence("GO:0000001", "go", retries = 0, cache = FALSE)), "QuickGO|results")
  expect_warning(httr2::with_mocked_responses(bad, bio_fetch_evidence("GO:0000001", "go", retries = 0, cache = FALSE, on_error = "warn")))
})

test_that("bio_explain traces supplied vs retrieved evidence and needs explicit sources", {
  skip_if_not_installed("httr2")
  bio_evidence_cache_clear()
  de <- make_de(30)
  expect_error(bio_explain(de, use_llm = FALSE, evidence = "auto"), "evidence_sources")
  ev <- bio_evidence("note", id = "MY1", title = "t", claim = "c")
  ex0 <- bio_explain(de, use_llm = FALSE, evidence = ev)
  expect_equal(ex0$evidence_trace$origin, "supplied")
  ex <- httr2::with_mocked_responses(mock_ev, bio_explain(de, use_llm = FALSE, evidence = ev, evidence_sources = "uniprot",
                                                           evidence_args = list(retries = 0)))
  expect_true(all(c("supplied", "retrieved") %in% ex$evidence_trace$origin))
})

test_that("bio_validate_explanation checks explicit claims only", {
  de <- make_de(100)
  ex <- bio_explain(de, use_llm = FALSE)
  v0 <- bio_validate_explanation(ex)$validation
  expect_equal(v0$status, "unverified")
  n <- ex$context$facts$n_significant
  ok <- bio_validate_explanation(ex, list(list(id = "a", fact = "n_significant", value = n)))$validation
  expect_equal(ok$status, "pass")
  bad <- bio_validate_explanation(ex, list(list(fact = "n_significant", value = n + 5)))$validation
  expect_equal(bad$status, "fail")
  unk <- bio_validate_explanation(ex, list(list(fact = "no_such_fact", value = 1)))$validation
  expect_equal(unk$status, "fail")
  dir <- bio_validate_explanation(ex, list(list(fact = "n_up", direction = "down")))$validation
  expect_equal(dir$status, "fail")
  cite <- bio_validate_explanation(ex, list(list(fact = "n_up", value = ex$context$facts$n_up, evidence = "X9")))$validation
  expect_equal(cite$status, "fail")
  expect_true(grepl("not in the supplied", cite$findings$detail[cite$findings$check == "citation"]))
})

test_that("model claims are preserved and mismatches are flagged", {
  de <- make_de(100)
  cfg <- bio_config(protocol = "openai", base_url = "https://proxy.example/v1", model = "m", api_key = "k")
  n <- bio_context(de)$facts$n_significant
  txt <- jsonlite::toJSON(list(data_facts = list("x"), evidence_used = list("GHOST"),
                               claims = list(list(id = "c1", fact = "n_significant", value = n + 3), list(id = "c2", text = "prose only"))),
                          auto_unbox = TRUE)
  local_mocked_bindings(bio_llm_available = function(...) TRUE, bio_llm_chat = function(...)
    list(text = as.character(txt), model = "m", endpoint_host = "h", stop_reason = "stop", usage = list(), elapsed_sec = 0))
  ex <- bio_explain(de, config = cfg, use_llm = TRUE)
  expect_true(is.list(ex$llm$claims[[1]]) && identical(ex$llm$claims[[1]]$id, "c1"))
  expect_equal(ex$validation$status, "fail")
  expect_true("GHOST" %in% ex$llm_meta$unknown_evidence_ids)
})

make_volcano <- function(df, y = quote(-log10(padj)), x = quote(log2FoldChange)) {
  df$gene <- rownames(df)
  ggplot2::ggplot(df, ggplot2::aes(x = !!x, y = !!y, label = gene)) + ggplot2::geom_point()
}

test_that("bio_cross_check compares plotted values with the full source", {
  skip_if_not_installed("ggplot2")
  de <- make_de(60)
  expect_equal(bio_cross_check(make_volcano(de), de)$status, "pass")
  expect_equal(bio_cross_check(make_volcano(de, quote(-log10(pvalue))), de)$status, "fail")
  expect_equal(bio_cross_check(make_volcano(de, x = quote(-log2FoldChange)), de)$status, "fail")
  expect_equal(bio_cross_check(make_volcano(de, y = quote(padj)), de)$status, "fail")
  sub <- de[1:30, ]
  expect_equal(bio_cross_check(make_volcano(sub), de)$status, "fail")
  expect_equal(bio_cross_check(make_volcano(sub), de, allow_subset = TRUE)$status, "pass")
  de2 <- de; rownames(de2)[1] <- "OTHER"
  expect_equal(bio_cross_check(make_volcano(de2), de)$status, "fail")
  wrong <- de; wrong$log2FoldChange[10] <- 99
  expect_equal(bio_cross_check(make_volcano(wrong), de)$status, "fail")
  unrelated <- ggplot2::ggplot(data.frame(a = 1:5, b = 5:1), ggplot2::aes(a, b)) + ggplot2::geom_point()
  expect_equal(bio_cross_check(unrelated, de)$status, "not_checkable")
  broken <- ggplot2::ggplot(de, ggplot2::aes(nonexistent_col, y)) + ggplot2::geom_point()
  expect_equal(bio_cross_check(broken, de)$status, "not_checkable")
  expect_s3_class(bio_cross_check(make_volcano(de), de)$findings, "data.frame")
  ex <- bio_explain(make_volcano(de), use_llm = FALSE, cross_check = de)
  expect_equal(ex$cross_check$status, "pass")
})

test_that("cell proportions: samples, missing factor levels, insufficient repetitions", {
  md <- data.frame(sample = rep(c("s1", "s2", "s3", "s4"), each = 20),
                   cluster = factor(rep(c("A", "B"), 40), levels = c("A", "B", "UNUSED")),
                   group = rep(c("ctl", "trt"), each = 40), stringsAsFactors = FALSE)
  cp <- bio_cell_proportions(md, "sample", "cluster", "group", test = "wilcox")
  expect_equal(cp$design$n_samples, 4)
  expect_false("UNUSED" %in% cp$per_sample$cluster)
  ctx <- bio_context(cp, language = "zh")
  expect_equal(ctx$analysis_type, "cell_composition")
  ex <- bio_explain(ctx, use_llm = FALSE, language = "zh")
  expect_true(any(grepl("样本", ex$local$data_facts)))
  expect_false(identical(cp$status, "tested"))  # 2 samples/group is below the default minimum
})

test_that("batch nested within group follows model identifiability", {
  md <- data.frame(g = rep(c("a", "b"), each = 8), b = rep(c("b1", "b2", "b3", "b4"), each = 4))
  expect_true(.design_facts(md, group_col = "g", batch_col = "b")$facts$group_batch_confounded)
  md2 <- data.frame(g = rep(c("a", "b"), 8), b = rep(c("b1", "b2"), each = 8))
  expect_false(.design_facts(md2, group_col = "g", batch_col = "b")$facts$group_batch_confounded)
})

test_that("real SingleCellExperiment / SummarizedExperiment adapters work", {
  skip_if_not_installed("SingleCellExperiment")
  m <- matrix(rpois(200, 5), 20, 10, dimnames = list(paste0("g", 1:20), paste0("c", 1:10)))
  sce <- SingleCellExperiment::SingleCellExperiment(assays = list(counts = m),
           colData = S4Vectors::DataFrame(sample = rep(c("a", "b"), 5), cluster = rep(1:2, each = 5)))
  ctx <- bio_context(sce)
  expect_equal(ctx$analysis_type, "single_cell")
  se <- SummarizedExperiment::SummarizedExperiment(assays = list(counts = m),
          colData = S4Vectors::DataFrame(sample = rep(c("a", "b"), 5), condition = rep(c("x", "y"), 5)))
  cse <- bio_context(se, analysis_type = "summarized_experiment")
  expect_equal(cse$analysis_type, "summarized_experiment")
  ex <- bio_explain(cse, use_llm = FALSE)
  expect_true(any(grepl("SummarizedExperiment", ex$local$data_facts)))
})

test_that("sampled dense matrices label their n_na/fraction_zero", {
  big <- matrix(0, 400, 400)
  f <- .matrix_facts(big)
  expect_equal(f$inspection, "sampled_block")
  expect_true(!is.null(f$fraction_zero_sampled) && is.null(f[["fraction_zero"]]))
})
