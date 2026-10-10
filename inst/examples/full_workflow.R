# Complete offline workflow with explicitly synthetic demonstration inputs.
library(BioExplainR)
bio_configure("local")

deg <- data.frame(gene = c("IL6", "TNF", "STAT3", "ACTB", "GAPDH"),
                  log2FoldChange = c(2, 1.5, -2, 0.1, -0.2),
                  pvalue = c(0.0001, 0.001, 0.002, 0.5, 0.8),
                  padj = c(0.001, 0.005, 0.007, 0.7, 0.9))
enrichment <- data.frame(ID = "GO:0006954", Description = "inflammatory response",
                         Count = 2, GeneRatio = "2/3", BgRatio = "100/10000", p.adjust = 0.02)
ex_deg <- bio_explain(deg, species = "Homo sapiens", contrast = "treated vs control")
ex_enrichment <- bio_explain(enrichment, species = "Homo sapiens", data_dependencies = "deg")
project <- bio_explain_project(bio_project(list(deg = ex_deg, enrichment = ex_enrichment),
                                          title = "Synthetic complete workflow"))

quiz <- bio_quiz(ex_deg, n = 8, form = "transfer")
quiz_score <- bio_grade(quiz, stats::setNames(quiz$key$answer, quiz$key$id))
benchmark <- bio_benchmark(list(deg = list(input = deg,
                                           expected = list(n_significant = 3, n_up = 2, n_down = 1))))

# Demonstration scores only. Replace with actual observations for a study.
scores <- data.frame(participant = paste0("synthetic_", 1:8), group = rep(c("control", "tool"), each = 4),
                     pre = c(3, 4, 5, 3, 3, 4, 5, 3), post = c(4, 4, 6, 5, 6, 7, 8, 7),
                     transfer = c(4, 3, 5, 4, 6, 6, 7, 5))
learning <- bio_evaluate_learning(scores, transfer = "transfer", reference = "control")
print(project)
print(benchmark)
print(learning)

out_dir <- getOption("bioexplainr.demo_dir", tempdir())
bio_report(list(project = project, student_quiz = quiz, benchmark = benchmark,
                 synthetic_learning_analysis = learning),
           file = file.path(out_dir, "full_workflow.html"), title = "Synthetic workflow demonstration")
bio_report(quiz, file = file.path(out_dir, "student_quiz.html"))
bio_report(list(quiz = quiz, grade = quiz_score), file = file.path(out_dir, "instructor_quiz.html"), show_answers = TRUE)
