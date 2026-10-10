suppressPackageStartupMessages(library(ggplot2))
scores <- read.csv("research/results/fact_scores.csv")
calls <- read.csv("research/results/model_calls.csv")
summary <- read.csv("research/results/ablation_summary.csv")
by_case <- aggregate(cbind(correct, answered) ~ case + method, scores, sum)
by_case$expected <- as.numeric(table(interaction(scores$case, scores$method))[interaction(by_case$case, by_case$method)])
by_case$accuracy <- by_case$correct / by_case$expected
utils::write.csv(by_case, "research/results/case_summary.csv", row.names = FALSE)
citations <- aggregate(cbind(citations, unknown_citations) ~ method, calls, sum)
utils::write.csv(citations, "research/results/citation_summary.csv", row.names = FALSE)
mutations <- read.csv("research/results/validation_ablation.csv")
validation <- as.data.frame(table(mutations$mutation, mutations$with_validator))
validation <- validation[validation$Freq > 0, ]
names(validation) <- c("mutation", "status", "n")
utils::write.csv(validation, "research/results/validation_summary.csv", row.names = FALSE)
rate <- summary
rate$method <- factor(rate$method, levels = c("direct_bounded", "facts_only", "facts_evidence"),
                       labels = c("Bounded R output", "R facts", "R facts + evidence"))
p <- ggplot(rate, aes(method, accuracy, fill = method)) + geom_col(width = .6) +
  geom_text(aes(label = paste0(correct, "/", expected)), vjust = -.6, size = 4) +
  scale_fill_manual(values = c("#bf4d45", "#288675", "#d09a24")) +
  scale_y_continuous(limits = c(0, 1.1), breaks = seq(0, 1, .2), labels = function(x) paste0(100*x, "%")) +
  labs(x = NULL, y = "Requested-fact accuracy") + theme_minimal(base_size = 12) +
  theme(legend.position = "none", panel.grid.major.x = element_blank())
ggsave("research/results/figures/ablation_accuracy.png", p, width = 7, height = 4.5, dpi = 180)
cost <- lapply(unique(calls$method), function(method) {
  files <- list.files("research/results/model", pattern = paste0("__", method, "__[1-3]\\.json$"), full.names = TRUE)
  responses <- lapply(files, jsonlite::read_json)
  hit <- sum(vapply(responses, function(r) r$response$usage$prompt_cache_hit_tokens, numeric(1)))
  miss <- sum(vapply(responses, function(r) r$response$usage$prompt_cache_miss_tokens, numeric(1)))
  completion <- sum(vapply(responses, function(r) r$response$usage$completion_tokens, numeric(1)))
  data.frame(method = method, input_cache_hit = hit, input_cache_miss = miss, output = completion,
             estimated_usd = (hit * .003 + miss * .15 + completion * .6) / 1e6)
})
cost <- do.call(rbind, cost)
utils::write.csv(cost, "research/results/cost_estimate.csv", row.names = FALSE)
jsonlite::write_json(list(
  score_unit = "25 requested scalar facts per method, repeated across 3 calls each = 75 evaluations; dependent observations",
  tolerance = "relative 1e-6 for nonzero numeric facts; absolute 1e-6 at zero; exact string match",
  main_requests = nrow(calls), main_successes = sum(calls$success), structured = sum(calls$structured),
  summary = summary, by_case = by_case, citations = citations, validation = validation, cost = cost,
  cost_basis = "DeepSeek published off-peak USD per million tokens: cache hit 0.003, cache miss 0.15, output 0.6; not an invoice",
  main_model_generation = "See the original per-call prompt/response files. Cached responses may be revalidated by later code; generated text is preserved.",
  independent_datasets = 2, human_participants = 0, independent_expert_raters = 0),
  "research/results/paper_metrics.json", pretty = TRUE, auto_unbox = TRUE, digits = 10)
cat("Paper metrics and figure generated.\n")
print(cost)
