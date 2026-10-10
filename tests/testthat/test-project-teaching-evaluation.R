test_that("projects order dependencies, reject cycles and retain compact results", {
  deg <- data.frame(log2FoldChange = c(2, -2, 0.1), padj = c(0.01, 0.02, 0.9))
  enr <- data.frame(ID = "GO:0006954", Count = 2, p.adjust = 0.01)
  project <- bio_project(list(enrichment = enr, deg = deg), dependencies = list(enrichment = "deg"))
  expect_equal(names(project$items), c("deg", "enrichment"))
  expect_equal(project$dependencies$from, "deg")
  expect_equal(project$items$deg$context$facts$n_significant, 2)
  expect_error(bio_project(list(a = deg, b = deg), dependencies = list(a = "b", b = "a")), "cycle")
  expect_error(bio_project(list(a = deg), dependencies = list(a = "missing")), "Unknown dependencies")
  run <- bio_record(matrix(1:12, 3))
  expect_null(bio_project(list(run = run))$items$run$value)
  ex_en <- bio_explain_project(project)
  expect_false(grepl("[^\\x01-\\x7F]", paste(ex_en$interpretation$local, collapse = " "), perl = TRUE))
  expect_false(grepl("[^\\x01-\\x7F]", bio_report(ex_en), perl = TRUE))
  ex <- bio_explain_project(project, language = "zh")
  expect_match(paste(ex$interpretation$local, collapse = " "), "派生")
  expect_match(bio_report(ex, language = "zh"), "跨分析项目摘要")
  expect_error(bio_explain_project(project, language = "fr"), "language")
})

test_that("quiz grading uses explicit answer IDs and student reports omit rationale", {
  quiz <- bio_quiz(topics = "single_cell", n = 2, form = "transfer")
  expect_equal(nrow(quiz$items), 2)
  grade <- bio_grade(quiz, stats::setNames(quiz$key$answer, quiz$key$id))
  expect_equal(grade$score, 2)
  expect_equal(grade$percent, 100)
  partial <- bio_grade(quiz, stats::setNames("A", quiz$key$id[1]))
  expect_equal(partial$score, 0)
  expect_error(bio_grade(quiz, c(no_item = "B")), "Unknown item")
  expect_false(grepl(quiz$key$rationale[1], bio_report(quiz), fixed = TRUE))
  expect_true(grepl(quiz$key$rationale[1], bio_report(quiz, show_answers = TRUE), fixed = TRUE))
  ex <- bio_explain(data.frame(log2FoldChange = c(2, -1), padj = c(0.01, 0.9)), use_llm = FALSE)
  q <- bio_quiz(ex, n = 1)
  expect_equal(q$key$answer[q$key$id == "DATA01"], "1")
  expect_equal(nrow(bio_review_rubric()), 8)
  expect_false(any(grepl("[^\\x01-\\x7F]", unlist(bio_question_bank()), perl = TRUE)))
  expect_false(any(grepl("[^\\x01-\\x7F]", bio_review_rubric()$criterion, perl = TRUE)))
  bank_zh <- bio_question_bank(language = "zh")
  expect_true(all(grepl("[^\\x01-\\x7F]", bank_zh$question, perl = TRUE)))
  expect_identical(bank_zh$answer, bio_question_bank()$answer)
  expect_identical(bank_zh$id, bio_question_bank()$id)
  expect_true(all(grepl("[^\\x01-\\x7F]", bio_review_rubric(language = "zh")$criterion, perl = TRUE)))
  quiz_zh <- bio_quiz(topics = "single_cell", n = 2, form = "transfer", language = "zh")
  expect_identical(quiz_zh$key$answer, quiz$key$answer)
  expect_identical(quiz_zh$language, "zh")
  expect_error(bio_quiz(language = "fr"), "language")
  expect_error(bio_question_bank(language = "fr"), "language")
  expect_error(bio_review_rubric(language = "fr"), "language")
})

test_that("benchmarks distinguish correct facts, mismatches and failed methods", {
  x <- data.frame(log2FoldChange = c(2, -2, 0.1), padj = c(0.01, 0.02, 0.9))
  cases <- list(example = list(input = x, expected = list(n_significant = 2, n_up = 1)))
  methods <- list(local = function(x, ...) bio_explain(x, use_llm = FALSE),
                  wrong = function(x, ...) list(facts = list(n_significant = 8, n_up = 1)),
                  fail = function(x, ...) stop("expected method error"))
  benchmark <- bio_benchmark(cases, methods)
  expect_equal(benchmark$summary$accuracy, c(1, 0.5, 0))
  expect_equal(benchmark$summary$failed_runs, c(0, 0, 1))
  expect_equal(nrow(benchmark$findings), 6)
  expect_match(bio_report(benchmark, language = "zh"), "解释准确性评测")
})

test_that("learning analysis computes gains and omits participant identifiers", {
  data <- data.frame(participant = paste0("PRIVATE_ID_", 1:8), group = rep(c("control", "tool"), each = 4),
    pre = c(10, 12, 11, 13, 10, 12, 11, 13), post = c(11, 12, 13, 14, 14, 17, 16, 19),
    transfer = c(10, 11, 12, 10, 15, 14, 17, 16))
  evaluation <- bio_evaluate_learning(data, transfer = "transfer", reference = "control")
  expected <- mean(data$post[5:8] - data$pre[5:8]) - mean(data$post[1:4] - data$pre[1:4])
  expect_equal(evaluation$findings$difference[1], expected)
  expect_true(evaluation$findings$ci_lower[1] < expected)
  expect_true(evaluation$findings$ci_upper[1] > expected)
  expect_false(grepl("PRIVATE_ID", as.character(jsonlite::toJSON(evaluation, auto_unbox = TRUE, force = TRUE))))
  expect_error(bio_evaluate_learning(rbind(data, data[1, ])), "unique")
  data$post[1] <- NA
  evaluation <- bio_evaluate_learning(data)
  expect_equal(sum(evaluation$summary$missing), 1)
  expect_match(bio_report(evaluation, language = "zh"), "教学效果分析")
})

test_that("fix benchmarks count only explicitly checked semantics", {
  skip_if_not_installed("callr")
  cases <- list(
    checked = list(expr = quote(x + 1), inputs = list(x = 2),
                   invariants = list(bio_invariant("expected", function(result, inputs) result == 3))),
    unchecked = list(expr = quote(1 + 1)),
    wrong = list(expr = quote(x + 2), inputs = list(x = 2),
                 invariants = list(bio_invariant("expected", function(result, inputs) result == 3))))
  result <- bio_benchmark_fixes(cases)
  expect_equal(result$summary$runtime_success_rate, 1)
  expect_equal(result$summary$semantic_success_rate, 0.5)
  expect_equal(result$summary$unverified_cases, 1)
})

test_that("expert ratings omit rater IDs and report exact agreement honestly", {
  ratings <- data.frame(item = rep(c("one", "two"), each = 2), rater = rep(c("PRIVATE_EXPERT_A", "PRIVATE_EXPERT_B"), 2),
                         dimension = "numeric_accuracy", score = c(2, 2, 1, 2))
  result <- bio_evaluate_experts(ratings)
  expect_equal(result$summary$exact_agreement, 0.5)
  expect_equal(result$summary$mean, 1.75)
  expect_false(grepl("PRIVATE_EXPERT", as.character(jsonlite::toJSON(result, force = TRUE))))
  expect_error(bio_evaluate_experts(rbind(ratings, ratings[1, ])), "Duplicate")
  ratings$score[1] <- 3
  expect_error(bio_evaluate_experts(ratings), "range")
})

test_that("study planning and stratified randomization preserve explicit assumptions", {
  plan <- bio_plan_learning_study(effect = 0.5, attrition = 0.1)
  expect_true(plan$recruit_per_group >= plan$required_per_group)
  expect_equal(plan$total_recruit, 2 * plan$recruit_per_group)
  set.seed(90)
  before <- .Random.seed
  participants <- paste0("P", 1:12)
  strata <- rep(c("novice", "experienced"), each = 6)
  a <- bio_randomize_learning_study(participants, strata, seed = 5)
  expect_identical(.Random.seed, before)
  expect_identical(a, bio_randomize_learning_study(participants, strata, seed = 5))
  expect_true(all(table(a$stratum, a$group) == 3))
  expect_error(bio_randomize_learning_study(c("same", "same")), "unique")
})
