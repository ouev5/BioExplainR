suppressPackageStartupMessages(library(BioExplainR))
d <- readRDS("research/cache/real_objects.rds")
workspace <- new.env()
workspace$airway_result <- d$res
workspace$airway_expression <- d$expression
workspace$airway_metadata <- d$metadata
workspace$reactome_result <- d$ora
workspace$pbmc_sce <- d$sce
workspace$pbmc_seurat <- d$seurat
workspace$airway_pca <- d$pca
if (nzchar(Sys.getenv("DEEPSEEK_API_KEY"))) {
  bio_configure("deepseek", model = "deepseek-flash", api_key_env = "DEEPSEEK_API_KEY",
                max_tokens = 5000, timeout = 120, json_mode = TRUE,
                extra_body = list(thinking = list(type = "disabled")))
} else bio_configure("local")
port <- as.integer(Sys.getenv("BIOEXPLAINR_PORT", "3876"))
bio_run_app(envir = workspace, port = port, launch.browser = FALSE)
