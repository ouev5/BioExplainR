# Hand-computable engineering fixtures; no model provider or research data.
pkgload::load_all(".", quiet = TRUE)
bio_configure("local")
workspace <- new.env(parent = globalenv())
workspace$fixture_de <- data.frame(log2FoldChange = c(2, -2, .1), padj = c(.01, .02, .8))
for (language in c("en", "zh")) {
  ctx <- bio_context(workspace$fixture_de, language = language, scope = list(species = "human"))
  ev <- bio_evidence("Local", "fixture", title = "<script>window.untrustedEvidence=true</script>",
    scope = ctx$scope, role = "experimental_support", content = "Fixed engineering excerpt")
  ex <- bio_explain(ctx, use_llm = FALSE, language = language, evidence = ev)
  ex <- bio_validate_claims(ex, list(list(id = "fixture_count", fact = "n_features", value = 3L,
    scope = ctx$scope, evidence_refs = ev$id)))
  assign(paste0("checked_", language), ex, envir = workspace)
}
rna <- matrix(1:6, 3, dimnames = list(c("g1", "g2", "g3"), c("PRIVATE_SAMPLE1", "PRIVATE_SAMPLE2")))
workspace$fixture_mae <- MultiAssayExperiment::MultiAssayExperiment(experiments = list(rna = rna))
workspace$miniacc_project <- readRDS("research/results/miniacc_installed_review/project.rds")
workspace$fixture_expression <- matrix(seq_len(24), 6, dimnames = list(paste0("g", 1:6), paste0("s", 1:4)))
options(shiny.sanitize.errors = FALSE)
bio_run_app(envir = workspace, port = as.integer(Sys.getenv("BIOEXPLAINR_ACCEPTANCE_PORT")), launch.browser = FALSE)
