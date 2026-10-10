test_that("Shiny analysis details expose local payload and verification sections", {
  skip_if_not_installed("shiny")
  env <- new.env()
  env$fixture <- data.frame(log2FoldChange = c(2, -2, .1), padj = c(.01, .02, .8))
  app <- BioExplainR:::.bio_app(env)
  shiny::testServer(app, {
    session$setInputs(analysis_object = "fixture", use_llm = FALSE, source_object = "",
      language = "en", padj = .05, lfc = 0, p_adjust = "none", level = "beginner",
      species = "", tissue = "", contrast = "", question = "", allow_subset = FALSE,
      analyze_object = 1)
    session$flushReact()
    html <- paste(as.character(output$analysis_sections$html), collapse = "")
    expect_match(html, "payload_preview", fixed = TRUE)
    expect_match(html, "runtime_manifest", fixed = TRUE)
    expect_match(html, "computed deterministically in R", fixed = TRUE)
  })
})
