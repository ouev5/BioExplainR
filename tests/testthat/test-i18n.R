test_that("English is the default and Chinese can be selected explicitly", {
  de <- make_de(40)
  en <- bio_explain(de, use_llm = FALSE)
  zh <- bio_explain(de, use_llm = FALSE, language = "zh")

  expect_equal(en$language, "en")
  expect_equal(zh$language, "zh")
  expect_true(any(grepl("The result table has", en$local$data_facts, fixed = TRUE)))
  expect_true(any(grepl("结果表共", zh$local$data_facts, fixed = TRUE)))
  expect_true(any(grepl("log2FC describes", paste(unlist(en$local), collapse = " "), fixed = TRUE)))
  expect_true(any(grepl("统计", paste(unlist(zh$local), collapse = " "))))
})

test_that("diagnosis and reports use the requested language", {
  en_diag <- bio_explain_error("object 'missing_value' not found")
  zh_diag <- bio_explain_error("object 'missing_value' not found", language = "zh")
  expect_equal(en_diag$language, "en")
  expect_equal(zh_diag$language, "zh")
  expect_match(en_diag$title, "Object not found")
  expect_match(zh_diag$title, "找不到对象")

  de <- make_de(30)
  en_report <- bio_report(de, format = "html")
  zh_report <- bio_report(de, format = "html", language = "zh")
  expect_match(en_report, '<html lang="en">')
  expect_match(zh_report, '<html lang="zh-CN">')
  expect_match(en_report, "BioExplainR Analysis Explanation Report")
  expect_match(zh_report, "BioExplainR 分析解释报告")
})

test_that("Shiny language catalogue exposes both complete choices", {
  expect_equal(BioExplainR:::.app_language_choices, c(English = "en", "简体中文" = "zh"))
  expect_match(BioExplainR:::.app_t("app_title", "en"), "Local Analysis Workbench")
  expect_match(BioExplainR:::.app_t("app_title", "zh"), "本地分析工作台")
  expect_equal(BioExplainR:::.app_t("run_status", "en", "ok", 1.2, "x"),
               "Status: ok; elapsed: 1.2 s; objects created/modified: x")
})
