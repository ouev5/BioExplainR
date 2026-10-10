# Real, offline-compatible tests of related R packages and an external dataset.
# No external model key is used. The local mock endpoint is only a transport test.
suppressPackageStartupMessages({
  library(BioExplainR)
  library(DESeq2)
  library(SingleCellExperiment)
  library(ggplot2)
})
.libPaths(c("/tmp/opencode/related-R-library", "/tmp/opencode/related-system/usr/lib/R/site-library", .libPaths()))
dir.create("research/results/related_tools", recursive = TRUE, showWarnings = FALSE)
d <- readRDS("research/cache/real_objects.rds")
out <- list()
add <- function(package, task, status, detail, elapsed = NA_real_, version = NA_character_) {
  out[[length(out) + 1L]] <<- data.frame(package, task, status, detail, elapsed_sec = elapsed,
                                           version, stringsAsFactors = FALSE)
}
timed <- function(expr) {
  started <- Sys.time()
  value <- tryCatch(list(value = force(expr), error = NULL), error = function(e) list(value = NULL, error = conditionMessage(e)))
  value$elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  value
}

# Keep the transport replay self-contained.  The previous version assumed that
# a separately started mock server was still running, which made a fresh run
# report connection failures rather than testing either installed client.
replay_mock <- NULL
if (requireNamespace("processx", quietly = TRUE)) {
  replay_mock <- processx::process$new(
    "node", c("research/related_mock.cjs"),
    stdout = "/tmp/opencode/related-replay.log",
    stderr = "/tmp/opencode/related-replay.log",
    supervise = TRUE
  )
  on.exit({
    if (!is.null(replay_mock) && replay_mock$is_alive()) replay_mock$kill()
  }, add = TRUE)
  for (attempt in seq_len(30L)) {
    if (!replay_mock$is_alive()) break
    probe <- tryCatch({
      con <- socketConnection("127.0.0.1", 18979, open = "r+b", blocking = TRUE, timeout = 0.2)
      close(con)
      TRUE
    }, error = function(e) FALSE, warning = function(w) {
      invokeRestart("muffleWarning")
      FALSE
    })
    if (probe) break
    Sys.sleep(0.1)
  }
  if (!replay_mock$is_alive()) stop("Local replay server exited before client tests")
} else {
  warning("processx unavailable; transport replay will be marked unavailable")
}

# iSEE: initialize a real SingleCellExperiment containing the saved PBMC UMAP.
if (requireNamespace("iSEE", quietly = TRUE)) {
  i <- timed(iSEE::iSEE(d$sce, initial = list(
    iSEE::ReducedDimensionPlot(Type = "UMAP", ColorBy = "Column data", ColorByColumnData = "mito_qc")
  ), runLocal = FALSE))
  add("iSEE", "Initialize SCE with UMAP and QC color mapping", if (is.null(i$error)) "pass" else "fail",
      if (is.null(i$error)) paste(class(i$value), collapse = "/") else i$error, i$elapsed,
      as.character(packageVersion("iSEE")))
} else add("iSEE", "Initialize SCE with UMAP and QC color mapping", "not_installed", "package unavailable")

# GPTCelltype: create a real marker table from PBMC count-derived cluster contrasts.
if (requireNamespace("GPTCelltype", quietly = TRUE)) {
  set.seed(20261004)
  x <- SummarizedExperiment::assay(d$sce, "counts")
  cells <- sample(seq_len(ncol(x)), min(900L, ncol(x)))
  normalized <- Matrix::t(Matrix::t(x) / Matrix::colSums(x)) * 1e4
  logx <- log1p(normalized)
  variance <- Matrix::rowMeans(logx^2) - Matrix::rowMeans(logx)^2
  variable <- order(variance, decreasing = TRUE)[seq_len(1000)]
  pc <- stats::prcomp(t(as.matrix(logx[variable, cells])), rank. = 5)$x[, 1:5]
  clusters <- stats::kmeans(pc, centers = 3, nstart = 5)$cluster
  marker_rows <- lapply(sort(unique(clusters)), function(k) {
    inside <- cells[clusters == k]; outside <- cells[clusters != k]
    score <- log2((Matrix::rowMeans(normalized[, inside, drop = FALSE]) + 1) /
                  (Matrix::rowMeans(normalized[, outside, drop = FALSE]) + 1))
    ids <- order(score, decreasing = TRUE)[seq_len(10)]
    data.frame(gene = rownames(x)[ids], cluster = k, avg_log2FC = score[ids], stringsAsFactors = FALSE)
  })
  markers <- do.call(rbind, marker_rows)
  prompt <- GPTCelltype::gptcelltype(markers, tissuename = "PBMC", model = "saved-response", topgenenumber = 10)
  jsonlite::write_json(list(n_cells_sampled = length(cells), n_clusters = length(unique(clusters)), marker_rows = nrow(markers),
                            prompt_chars = nchar(prompt), prompt = prompt),
                       "research/results/related_tools/gptcelltype_prompt.json", pretty = TRUE, auto_unbox = TRUE)
  add("GPTCelltype", "Build cell-type prompt from real PBMC marker table", "pass",
      paste0("clusters=", length(unique(clusters)), "; marker_rows=", nrow(markers), "; no API request"), 0,
      as.character(packageVersion("GPTCelltype")))
} else add("GPTCelltype", "Build cell-type prompt from real PBMC marker table", "not_installed", "package unavailable")

# Six saved facts-only responses are replayed through both real installed clients.
replay <- list()
if (requireNamespace("ellmer", quietly = TRUE)) {
  prompts <- list.files("research/results/model", pattern = "__facts_only__1__prompt.json$", full.names = TRUE)
  for (file in prompts) for (client in c("ellmer", "BioExplainR")) {
    prompt <- jsonlite::read_json(file)
    expected <- jsonlite::read_json(sub("__prompt.json$", ".json", file))$response$text
    e <- timed({
      if (client == "ellmer") {
        chat <- suppressWarnings(ellmer::chat_openai_compatible("http://127.0.0.1:18979/v1", api_key = "local-replay",
                           system_prompt = prompt$system, model = "saved-response", echo = "none"))
        chat$chat(prompt$user)
      } else {
        cfg <- bio_config("openai", base_url = "http://127.0.0.1:18979/v1", api_key = "local-replay",
                           model = "saved-response", max_tokens = 5000, json_mode = TRUE)
        bio_llm_chat(cfg, prompt$system, prompt$user)$text
      }
    })
    replay[[length(replay)+1]] <- data.frame(client, case = sub("__.*$", "", basename(file)),
      success = is.null(e$error), identical_response = is.null(e$error) && identical(as.character(e$value), expected),
      elapsed_sec = e$elapsed, error = if (is.null(e$error)) NA_character_ else e$error)
  }
  replay <- do.call(rbind, replay)
  utils::write.csv(replay, "research/results/related_tools/transport_replay.csv", row.names = FALSE)
  add("ellmer", "Six saved responses through local OpenAI-compatible transport", if (nrow(replay) == 12L && all(replay$identical_response)) "pass" else "fail",
      paste0(sum(replay$identical_response), "/", nrow(replay), " client calls preserve response text; no live inference"), NA_real_,
      as.character(packageVersion("ellmer")))
} else add("ellmer", "OpenAI-compatible local request/response parsing", "not_installed", "package unavailable")

# External pasilla data: independent real RNA-seq object and DESeq2/BioExplainR facts.
pasilla_dir <- "research/cache/pasilla/inst/extdata"
counts <- utils::read.delim(file.path(pasilla_dir, "pasilla_gene_counts.tsv"), row.names = 1, check.names = FALSE)
annotation <- utils::read.csv(file.path(pasilla_dir, "pasilla_sample_annotation.csv"), row.names = 1, check.names = FALSE)
rownames(annotation) <- sub("fb$", "", rownames(annotation))
annotation <- annotation[colnames(counts), , drop = FALSE]
annotation$condition <- factor(annotation$condition, levels = c("untreated", "treated"))
annotation$type <- factor(annotation$type)
dds <- DESeq2::DESeqDataSetFromMatrix(round(as.matrix(counts)), annotation, design = ~ type + condition)
dds <- DESeq2::DESeq(dds, quiet = TRUE)
pasilla_res <- DESeq2::results(dds, contrast = c("condition", "treated", "untreated"))
pasilla_ctx <- bio_context(pasilla_res, species = "Drosophila melanogaster", tissue = "cell culture",
                           design = "~ type + condition", contrast = "treated vs untreated",
                           thresholds = list(padj = .05, lfc = 1))
pasilla_facts <- list(n_samples = ncol(counts), n_features = nrow(counts),
                      n_significant = pasilla_ctx$facts$n_significant,
                      n_up = pasilla_ctx$facts$n_up, n_down = pasilla_ctx$facts$n_down,
                      n_na_padj = pasilla_ctx$facts$n_na_padj,
                      n_features_after_filter = sum(rowSums(counts) >= 10))
tab <- as.data.frame(pasilla_res)
checks <- list()
for (alpha in c(.01, .05, .1)) for (lfc in c(0, 1)) {
  ctx <- bio_context(pasilla_res, thresholds = list(padj = alpha, lfc = lfc))
  sig <- !is.na(tab$padj) & tab$padj < alpha & abs(tab$log2FoldChange) > lfc
  reference <- c(n_features = nrow(tab), n_significant = sum(sig), n_up = sum(sig & tab$log2FoldChange > 0),
                 n_down = sum(sig & tab$log2FoldChange < 0), n_na_padj = sum(is.na(tab$padj)))
  for (fact in names(reference)) checks[[length(checks)+1]] <- data.frame(alpha, lfc, fact,
      expected = reference[[fact]], actual = ctx$facts[[fact]], pass = reference[[fact]] == ctx$facts[[fact]])
}
utils::write.csv(do.call(rbind, checks), "research/results/related_tools/pasilla_fact_checks.csv", row.names = FALSE)
stopifnot(all(do.call(rbind, checks)$pass))
pasilla_vst <- DESeq2::vst(dds, blind = FALSE)
pasilla_pca <- bio_plot_pca(SummarizedExperiment::assay(pasilla_vst), metadata = annotation, group = "condition", n_top_features = 500)
pc <- attr(pasilla_pca, "bio_plot_source")$prcomp
utils::write.csv(data.frame(PC1 = pc$x[,1], PC2 = pc$x[,2], condition = annotation$condition, type = annotation$type),
                 "research/results/related_tools/pasilla_pca.csv", row.names = FALSE)
utils::write.csv(data.frame(log2FC = tab$log2FoldChange, padj = tab$padj),
                 "research/results/related_tools/pasilla_volcano.csv", row.names = FALSE)
pasilla_facts$pca_variance <- pc$sdev^2 / sum(pc$sdev^2)
pasilla_facts$archive_sha256 <- digest::digest(file = "research/cache/pasilla_1.30.0.tar.gz", algo = "sha256")
jsonlite::write_json(list(dataset = "pasilla", counts_dim = dim(counts), facts = pasilla_facts,
                          package_versions = c(pasilla = "1.30.0 data archive", DESeq2 = as.character(packageVersion("DESeq2")),
                                               BioExplainR = as.character(packageVersion("BioExplainR")))),
                     "research/results/related_tools/pasilla_test.json", pretty = TRUE, auto_unbox = TRUE)
add("BioExplainR + DESeq2", "Independent pasilla count matrix and DESeq2 fact extraction", "pass",
    paste0("features=", nrow(counts), "; samples=", ncol(counts), "; significant=", pasilla_facts$n_significant, "; 30/30 facts match"), NA_real_,
    as.character(packageVersion("BioExplainR")))

results <- do.call(rbind, out)
utils::write.csv(results, "research/results/related_tools/related_tool_tests.csv", row.names = FALSE)
jsonlite::write_json(list(test_date = format(Sys.time(), tz = "UTC", usetz = TRUE),
                          independent_dataset = "pasilla 1.30.0 archive",
                          api_key_used = FALSE, tests = results),
                     "research/results/related_tools/related_tool_tests.json", pretty = TRUE, auto_unbox = TRUE)
print(results)
capture.output(sessionInfo(), file = "research/results/related_tools/test_session.txt")
packages <- c("iSEE", "GPTCelltype", "ellmer", "btw")
utils::write.csv(data.frame(package = packages,
  installed = vapply(packages, requireNamespace, logical(1), quietly = TRUE),
  version = vapply(packages, function(p) if (requireNamespace(p, quietly=TRUE)) as.character(packageVersion(p)) else NA_character_, "")),
  "research/results/related_tools/final_install_status.csv", row.names=FALSE)

browser_test <- function() {
  job <- callr::r_bg(function(paths, root) {
    .libPaths(paths)
    sce <- readRDS(file.path(root, "research/cache/real_objects.rds"))$sce
    app <- iSEE::iSEE(sce, initial=list(iSEE::ReducedDimensionPlot(Type="UMAP",ColorBy="Column data",ColorByColumnData="mito_qc")), runLocal=FALSE)
    shiny::runApp(app, host="127.0.0.1",port=18980,launch.browser=FALSE)
  }, args=list(.libPaths(), getwd()), stdout="/tmp/opencode/related-isee.log",stderr="/tmp/opencode/related-isee.log")
  on.exit(job$kill(), add=TRUE)
  status <- system("NODE_PATH=/tmp/opencode/node_modules node research/related_browser.cjs")
  stopifnot(status == 0)
}
browser_test()
