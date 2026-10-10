# Exercise the built/checked package, not pkgload's development namespace.
library(BioExplainR, lib.loc = "research/results/w00_baseline/BioExplainR.Rcheck")
out <- "research/results/w00_baseline"
bio_configure("local")
de <- data.frame(log2FoldChange = c(2, -2, 0.1), padj = c(0.01, 0.02, 0.8),
                 row.names = c("IL6", "CXCL8", "ACTB"))
ctx <- bio_context(de, contrast = "treated vs control")
ex <- bio_explain(ctx, use_llm = FALSE)
checked <- bio_validate_explanation(ex, claims = list(list(id = "legacy_1", fact = "n_significant", value = 2)))
stopifnot(ctx$facts$n_significant == 2, ctx$facts$n_up == 1, ctx$facts$n_down == 1,
          identical(checked$validation$status, "pass"), !ex$llm_meta$used,
          inherits(checked, "bio_explanation"), is.null(ctx$schema_version))
ev <- bio_evidence("Local", "fixture", claim = "User-supplied fixture", type = "other")
project <- bio_project(list(result = checked), metadata = list(purpose = "W00 software smoke"))
project <- bio_explain_project(project, use_llm = FALSE)
bio_report(project, file = file.path(out, "offline-report.html"))
shapes <- list(package_version = as.character(packageVersion("BioExplainR")),
               purpose = "Small hand-computable software smoke, not a research result",
               context = names(ctx), context_provenance = names(ctx$provenance),
               payload = names(bio_context_payload(ctx)), explanation = names(checked),
               llm_meta_local = names(ex$llm_meta), validation = names(checked$validation),
               validation_findings = names(checked$validation$findings),
               evidence = names(ev), project = names(project))
jsonlite::write_json(shapes, file.path(out, "legacy_object_shapes.json"), auto_unbox = TRUE, pretty = TRUE)
jsonlite::write_json(unclass(ctx), file.path(out, "offline-context.json"), auto_unbox = TRUE,
                     pretty = TRUE, na = "null", null = "null")
cat("Checked installed package offline: significant=2, up=1, down=1, legacy claim pass, report written.\n")
