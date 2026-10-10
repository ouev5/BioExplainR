# Assessment materials and deterministic grading.

#' Bioinformatics concept question bank
#'
#' Items cover independent interpretation, not model-answer popularity.
#' Forms can be used for pre/post tests, transfer tests or delayed assessment.
#' Answers are kept separately by \code{bio_quiz()} and omitted from student
#' reports unless the instructor requests them.
#'
#' @param topics Optional topic filter.
#' @param language \code{"en"} (default) or \code{"zh"}: language of the
#'   question text, options and rationales. Item IDs, topics and answer keys do
#'   not depend on the language. \code{NULL} uses the active configuration.
#' @return Data frame with item ID, topic, prompt, options, answer and rationale.
#' @export
bio_question_bank <- function(topics = NULL, language = NULL) {
  language <- .resolve_language(language, .pkg_env$config)
  .local_language(language)
  bank <- data.frame(
    id = sprintf("Q%02d", seq_len(16)),
    topic = rep(c("differential_expression", "enrichment", "pca", "single_cell", "debugging", "evidence", "plot", "ai_judgment"), each = 2),
    question = c(
      "log2FC = 1 means the treated group is expressed at about how many times the reference group?",
      "If only the raw p < 0.05, can a feature be called significant under FDR control?",
      "What does a significant ORA enrichment most directly support?",
      "How should a positive NES in GSEA be interpreted?",
      "Can group separation in a PCA alone prove the biological mechanism of the treatment?",
      "What does PC1 explaining 40% of the variance mean?",
      "What is usually the independent unit of replication in single-cell between-group comparisons?",
      "What is the most reasonable interpretation of two clusters lying close together on a UMAP?",
      "A fix runs but the comparison direction is reversed. How should it be judged?",
      "What is the main purpose of recording with bio_record() before an error occurs?",
      "Does an enrichment computed from the same differential gene list constitute independent validation?",
      "Can a pathway definition in a database prove that the pathway is activated in this dataset?",
      "What does the x axis of a volcano plot usually represent?",
      "As -log10(p) gets higher, how does the p-value usually change?",
      "When a number in a model explanation disagrees with the R facts, what should be done first?",
      "When no semantic invariants were supplied, how can a fix that runs successfully be labelled?"
    ) %L% c(
      "log2FC = 1 \u8868\u793a\u5904\u7406\u7ec4\u76f8\u5bf9\u53c2\u8003\u7ec4\u7ea6\u51e0\u500d\u8868\u8fbe\uff1f",
      "\u53ea\u6709\u539f\u59cb p < 0.05 \u65f6\uff0c\u80fd\u5426\u79f0\u4e3a FDR \u63a7\u5236\u4e0b\u663e\u8457\uff1f",
      "ORA \u5bcc\u96c6\u663e\u8457\u6700\u76f4\u63a5\u652f\u6301\u54ea\u79cd\u7ed3\u8bba\uff1f",
      "GSEA \u7684\u6b63 NES \u5e94\u5982\u4f55\u89e3\u91ca\uff1f",
      "PCA \u4e2d\u7ec4\u95f4\u5206\u79bb\u80fd\u5426\u5355\u72ec\u8bc1\u660e\u5904\u7406\u7684\u751f\u7269\u5b66\u673a\u5236\uff1f",
      "PC1 \u89e3\u91ca 40% \u65b9\u5dee\u662f\u4ec0\u4e48\u610f\u601d\uff1f",
      "\u5355\u7ec6\u80de\u7ec4\u95f4\u6bd4\u8f83\u7684\u72ec\u7acb\u91cd\u590d\u5355\u4f4d\u901a\u5e38\u662f\u4ec0\u4e48\uff1f",
      "UMAP \u4e24\u4e2a cluster \u9760\u8fd1\u6700\u5408\u7406\u7684\u89e3\u91ca\u662f\u4ec0\u4e48\uff1f",
      "\u4fee\u590d\u4ee3\u7801\u80fd\u8fd0\u884c\u4f46\u6bd4\u8f83\u65b9\u5411\u53cd\u4e86\uff0c\u5e94\u5982\u4f55\u5224\u65ad\uff1f",
      "\u62a5\u9519\u524d\u7528 bio_record() \u8bb0\u5f55\u7684\u4e3b\u8981\u4f5c\u7528\u662f\u4ec0\u4e48\uff1f",
      "\u7531\u540c\u4e00\u5dee\u5f02\u57fa\u56e0\u5217\u8868\u8ba1\u7b97\u7684\u5bcc\u96c6\u662f\u5426\u6784\u6210\u72ec\u7acb\u9a8c\u8bc1\uff1f",
      "\u6570\u636e\u5e93\u4e2d\u4e00\u4e2a\u901a\u8def\u7684\u5b9a\u4e49\u80fd\u5426\u8bc1\u660e\u8be5\u901a\u8def\u5728\u672c\u6570\u636e\u4e2d\u6fc0\u6d3b\uff1f",
      "\u706b\u5c71\u56fe\u6a2a\u8f74\u901a\u5e38\u8868\u793a\u4ec0\u4e48\uff1f",
      "-log10(p) \u8d8a\u9ad8\uff0cp \u503c\u901a\u5e38\u600e\u6837\u53d8\u5316\uff1f",
      "\u6a21\u578b\u89e3\u91ca\u4e2d\u7684\u6570\u91cf\u4e0e R \u4e8b\u5b9e\u4e0d\u4e00\u81f4\uff0c\u9996\u5148\u5e94\u600e\u6837\u5904\u7406\uff1f",
      "\u6ca1\u6709\u63d0\u4f9b\u8bed\u4e49\u4e0d\u53d8\u91cf\u65f6\uff0c\u8fd0\u884c\u6210\u529f\u7684\u4fee\u590d\u53ef\u6807\u8bb0\u4e3a\u4ec0\u4e48\uff1f"
    ),
    options = c(
      "A:2-fold | B:1-fold | C:10-fold | D:cannot be interpreted", "A:Yes | B:No",
      "A:The pathway is necessarily activated | B:Input genes are over-represented in the set | C:The causal mechanism is confirmed",
      "A:Definitely activated | B:Concentrated at the top of the ranking; depends on the ranking direction | C:Definitely suppressed",
      "A:Yes | B:No; it may be driven by batch and other factors",
      "A:40% of genes are significant | B:This component summarises 40% of the total variation | C:Treatment success rate is 40%",
      "A:Each cell | B:Sample or donor | C:Each UMI",
      "A:Truly spatially adjacent | B:Expression profiles are locally similar | C:Cell lineage is proven",
      "A:Correct fix | B:Runs successfully but fails the semantic check",
      "A:Automatically changes the statistical design | B:Preserves the failing call stack and context",
      "A:Yes | B:No; it is derived evidence", "A:Yes | B:No; evidence from this dataset is still required",
      "A:Effect size and direction | B:Sample size | C:Causal probability", "A:Increases | B:Decreases | C:Unchanged",
      "A:Use smoother wording | B:Check against the input facts and flag the inconsistency",
      "A:Fully verified | B:runtime_only | C:Causality holds"
    ) %L% c(
      "A:2\u500d | B:1\u500d | C:10\u500d | D:\u4e0d\u80fd\u89e3\u91ca", "A:\u53ef\u4ee5 | B:\u4e0d\u53ef\u4ee5",
      "A:\u901a\u8def\u5fc5\u7136\u6fc0\u6d3b | B:\u8f93\u5165\u57fa\u56e0\u5728\u8be5\u96c6\u5408\u4e2d\u8fc7\u5ea6\u51fa\u73b0 | C:\u56e0\u679c\u673a\u5236\u5df2\u8bc1\u5b9e",
      "A:\u4e00\u5b9a\u6fc0\u6d3b | B:\u96c6\u4e2d\u4e8e\u6392\u5e8f\u9876\u90e8\uff0c\u53d6\u51b3\u4e8e\u6392\u5e8f\u65b9\u5411 | C:\u4e00\u5b9a\u6291\u5236",
      "A:\u53ef\u4ee5 | B:\u4e0d\u53ef\u4ee5\uff0c\u53ef\u80fd\u53d7\u6279\u6b21\u7b49\u56e0\u7d20\u5f71\u54cd",
      "A:40%\u7684\u57fa\u56e0\u663e\u8457 | B:\u8be5\u4e3b\u6210\u5206\u6982\u62ec40%\u7684\u603b\u4f53\u53d8\u5f02 | C:\u5904\u7406\u6210\u529f\u738740%",
      "A:\u6bcf\u4e2a\u7ec6\u80de | B:\u6837\u672c\u6216\u4f9b\u4f53 | C:\u6bcf\u4e2aUMI",
      "A:\u771f\u5b9e\u7a7a\u95f4\u76f8\u90bb | B:\u8868\u8fbe\u8868\u793a\u5177\u6709\u5c40\u90e8\u76f8\u4f3c\u6027 | C:\u5df2\u8bc1\u660e\u7ec6\u80de\u8c31\u7cfb",
      "A:\u6b63\u786e\u4fee\u590d | B:\u8fd0\u884c\u6210\u529f\u4f46\u8bed\u4e49\u68c0\u67e5\u5931\u8d25",
      "A:\u81ea\u52a8\u6539\u53d8\u7edf\u8ba1\u8bbe\u8ba1 | B:\u4fdd\u7559\u9519\u8bef\u73b0\u573a\u8c03\u7528\u6808\u4e0e\u4e0a\u4e0b\u6587",
      "A:\u662f | B:\u4e0d\u662f\uff0c\u5b83\u662f\u6d3e\u751f\u8bc1\u636e", "A:\u80fd | B:\u4e0d\u80fd\uff0c\u4ecd\u9700\u672c\u6570\u636e\u8bc1\u636e",
      "A:\u6548\u5e94\u91cf\u53ca\u65b9\u5411 | B:\u6837\u672c\u6570 | C:\u56e0\u679c\u6982\u7387", "A:\u53d8\u5927 | B:\u53d8\u5c0f | C:\u4e0d\u53d8",
      "A:\u91c7\u7528\u66f4\u6d41\u7545\u7684\u6587\u5b57 | B:\u6838\u5bf9\u8f93\u5165\u4e8b\u5b9e\u5e76\u6807\u8bb0\u4e0d\u4e00\u81f4",
      "A:\u5168\u9762\u9a8c\u8bc1\u901a\u8fc7 | B:runtime_only | C:\u56e0\u679c\u5173\u7cfb\u6210\u7acb"
    ),
    answer = c("A", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", "A", "B", "B", "B"),
    rationale = c(
      "2^1 = 2; the direction depends on the comparison order.", "A raw p-value does not control for multiple testing.",
      "ORA is a gene-overlap test with no inherent direction of activation.", "The sign of NES depends on the gene-ranking metric.",
      "Separation can be produced by batch effects.", "Variance explained describes overall variation, not the proportion of significant genes.",
      "Cells are nested within samples and cannot replace independent donor replicates.", "Local proximity on a UMAP is not physical space or lineage.",
      "Run status and comparison-direction preservation are different checks.", "A handler can save the error context before the stack unwinds.",
      "Derived evidence shares its data with the upstream result.", "A pathway definition is a knowledge fact, not a measurement of activity in this experiment.",
      "The x axis is usually log2FC and describes the change in expression.", "The negative logarithm increases as p decreases.",
      "A model must not replace traceable statistical facts.", "Without specified semantic checks only the run status can be confirmed."
    ) %L% c(
      "2^1 = 2\uff0c\u65b9\u5411\u4f9d\u8d56\u6bd4\u8f83\u987a\u5e8f\u3002", "\u539f\u59cb p \u503c\u6ca1\u6709\u63a7\u5236\u591a\u91cd\u68c0\u9a8c\u3002",
      "ORA \u662f\u57fa\u56e0\u91cd\u53e0\u68c0\u9a8c\uff0c\u65e0\u56fa\u6709\u6fc0\u6d3b\u65b9\u5411\u3002", "NES \u6b63\u8d1f\u4f9d\u8d56\u57fa\u56e0\u6392\u5e8f\u6307\u6807\u3002",
      "\u5206\u79bb\u53ef\u4ee5\u7531\u6279\u6b21\u6548\u5e94\u4ea7\u751f\u3002", "\u65b9\u5dee\u89e3\u91ca\u7387\u63cf\u8ff0\u603b\u4f53\u53d8\u5f02\u800c\u975e\u663e\u8457\u57fa\u56e0\u6bd4\u4f8b\u3002",
      "\u7ec6\u80de\u5d4c\u5957\u4e8e\u6837\u672c\uff0c\u4e0d\u80fd\u66ff\u4ee3\u72ec\u7acb\u4f9b\u4f53\u91cd\u590d\u3002", "UMAP \u5c40\u90e8\u90bb\u8fd1\u5e76\u975e\u7269\u7406\u7a7a\u95f4\u6216\u8c31\u7cfb\u3002",
      "\u8fd0\u884c\u72b6\u6001\u4e0e\u6bd4\u8f83\u65b9\u5411\u4fdd\u6301\u662f\u4e0d\u540c\u7684\u68c0\u67e5\u3002", "\u8c03\u7528\u5904\u7406\u5668\u53ef\u5728\u6808\u5c55\u5f00\u524d\u4fdd\u5b58\u9519\u8bef\u73b0\u573a\u3002",
      "\u6d3e\u751f\u8bc1\u636e\u4e0e\u4e0a\u6e38\u5171\u4eab\u6570\u636e\u3002", "\u901a\u8def\u5b9a\u4e49\u662f\u77e5\u8bc6\u4e8b\u5b9e\uff0c\u4e0d\u662f\u672c\u5b9e\u9a8c\u7684\u6d3b\u6027\u6d4b\u91cf\u3002",
      "\u6a2a\u8f74\u5e38\u4e3a log2FC\uff0c\u63cf\u8ff0\u8868\u8fbe\u53d8\u5316\u3002", "\u8d1f\u5bf9\u6570\u968f p \u51cf\u5c0f\u800c\u589e\u5927\u3002",
      "\u6a21\u578b\u4e0d\u5f97\u66ff\u4ee3\u53ef\u8ffd\u6eaf\u7edf\u8ba1\u4e8b\u5b9e\u3002", "\u672a\u6307\u5b9a\u8bed\u4e49\u68c0\u67e5\u53ea\u80fd\u786e\u8ba4\u8fd0\u884c\u72b6\u6001\u3002"
    ),
    stringsAsFactors = FALSE
  )
  if (!is.null(topics)) bank <- bank[bank$topic %in% topics, , drop = FALSE]
  bank
}

#' Create a student assessment form
#'
#' @param x Optional analysis object or explanation. Adds one numeric
#'   interpretation item anchored to the object's facts when possible.
#' @param topics Topic filter for the concept bank.
#' @param n Number of concept questions (deterministic selection).
#' @param form Form label, such as pre, post, transfer or delayed. These labels
#'   select reproducibly different item orders; instructors should use novel
#'   analysis objects for transfer assessment.
#' @param language \code{"en"} (default) or \code{"zh"}: language of the quiz
#'   text. Item selection and answer keys do not depend on it.
#' @return A \code{bio_quiz} containing student items and a separate answer key.
#' @export
bio_quiz <- function(x = NULL, topics = NULL, n = 8, form = "pre", language = NULL) {
  language <- .resolve_language(language, .pkg_env$config)
  .local_language(language)
  bank <- bio_question_bank(topics, language = language)
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n < 1 || n != floor(n)) stop("n must be a positive integer.", call. = FALSE)
  offsets <- c(pre = 0, post = 3, transfer = 7, delayed = 11)
  offset <- if (form %in% names(offsets)) offsets[[form]] else 0
  if (nrow(bank)) bank <- bank[((seq_len(nrow(bank)) - 1 + offset) %% nrow(bank)) + 1, , drop = FALSE]
  bank <- utils::head(bank, n)
  if (!nrow(bank)) stop("No questions match topics.", call. = FALSE)
  if (!is.null(x)) {
    ctx <- if (inherits(x, "bio_explanation")) x$context else bio_context(x, language = language)
    fact <- ctx$facts$n_significant
    if (!is.null(fact)) {
      bank <- rbind(bank, data.frame(id = "DATA01", topic = ctx$analysis_type,
        question = "Given the supplied object and recorded thresholds, how many features or terms are significant?" %L%
          "\u6839\u636e\u6240\u63d0\u4f9b\u5bf9\u8c61\u548c\u8bb0\u5f55\u9608\u503c\uff0c\u663e\u8457\u7279\u5f81\u6216\u6761\u76ee\u7684\u6570\u91cf\u662f\u591a\u5c11\uff1f",
        options = "numeric answer", answer = as.character(fact),
        rationale = "Read n_significant, which is computed deterministically from the full input, rather than counting only the truncated top rows." %L%
          "\u5e94\u76f4\u63a5\u8bfb\u53d6\u5b8c\u6574\u8f93\u5165\u786e\u5b9a\u6027\u8ba1\u7b97\u7684 n_significant\uff0c\u4e0d\u80fd\u53ea\u6570\u622a\u65ad\u540e\u7684\u9876\u90e8\u884c\u3002",
        stringsAsFactors = FALSE))
    }
  }
  structure(list(form = form, items = bank[c("id", "topic", "question", "options")],
                 key = bank[c("id", "answer", "rationale")], created = .now(), language = language),
            class = "bio_quiz")
}

#' Grade an assessment with an explicit answer key
#'
#' @param quiz A \code{bio_quiz}.
#' @param answers Named character vector indexed by item ID, or a data frame
#'   containing \code{id} and \code{answer}.
#' @return A \code{bio_assessment} with per-item correctness and score.
#' @export
bio_grade <- function(quiz, answers) {
  stopifnot(inherits(quiz, "bio_quiz"))
  if (is.data.frame(answers)) answers <- stats::setNames(as.character(answers$answer), answers$id)
  if (is.null(names(answers)) || anyDuplicated(names(answers))) stop("answers must have unique item IDs.", call. = FALSE)
  if (length(setdiff(names(answers), quiz$key$id))) stop("Unknown item IDs in answers.", call. = FALSE)
  submitted <- as.character(answers[quiz$key$id])
  correct <- !is.na(submitted) & toupper(trimws(submitted)) == toupper(trimws(quiz$key$answer))
  items <- data.frame(id = quiz$key$id, answer = submitted, expected = quiz$key$answer,
                      correct = correct, stringsAsFactors = FALSE)
  structure(list(form = quiz$form, items = items, score = sum(correct), total = length(correct),
                 percent = 100 * mean(correct)), class = "bio_assessment")
}

#' Expert review rubric for result explanations
#'
#' Each dimension is rated 0 (incorrect/missing), 1 (partial) or 2 (correct and
#' traceable). Ratings require domain experts; the rubric does not substitute
#' model self-evaluation for expert assessment.
#'
#' @param language \code{"en"} (default) or \code{"zh"}: language of the
#'   criterion descriptions. Dimension names and score limits are unchanged.
#' @return Data frame of dimensions, anchors and score limits.
#' @export
bio_review_rubric <- function(language = NULL) {
  language <- .resolve_language(language, .pkg_env$config)
  .local_language(language)
  data.frame(
    dimension = c("numeric_accuracy", "statistical_concepts", "biological_support", "traceability",
                  "uncertainty", "readability", "error_localization", "semantic_preservation"),
    criterion = c(
      "Counts, thresholds and direction match the input", "Correctly distinguishes effect size, p-value and FDR",
      "The explanation is backed by a database or literature", "Conclusions trace back to facts or sources",
      "States limitations and the conclusions that cannot be drawn", "A learner can understand it independently",
      "Locates the call that actually triggered the error",
      "Research purpose, design and comparison direction are preserved after the fix"
    ) %L% c("\u6570\u91cf\u3001\u9608\u503c\u3001\u65b9\u5411\u4e0e\u8f93\u5165\u4e00\u81f4", "\u6b63\u786e\u533a\u5206\u6548\u5e94\u91cf\u3001p\u503c\u4e0eFDR", "\u89e3\u91ca\u6709\u6570\u636e\u5e93\u6216\u6587\u732e\u4f9d\u636e",
                  "\u7ed3\u8bba\u80fd\u56de\u5230\u4e8b\u5b9e\u6216\u6765\u6e90", "\u660e\u786e\u9650\u5236\u4e0e\u4e0d\u80fd\u63a8\u51fa\u7684\u7ed3\u8bba", "\u5b66\u4e60\u8005\u80fd\u72ec\u7acb\u7406\u89e3",
                  "\u5b9a\u4f4d\u771f\u6b63\u89e6\u53d1\u9519\u8bef\u7684\u8c03\u7528", "\u4fee\u590d\u540e\u7814\u7a76\u76ee\u7684\u3001\u8bbe\u8ba1\u4e0e\u6bd4\u8f83\u65b9\u5411\u4fdd\u6301"),
    minimum = 0L, maximum = 2L, stringsAsFactors = FALSE
  )
}

#' @export
print.bio_quiz <- function(x, ...) {
  cat("<bio_quiz> ", x$form, " | ", nrow(x$items), " items\n", sep = "")
  print(x$items, row.names = FALSE)
  invisible(x)
}

#' @export
print.bio_assessment <- function(x, ...) {
  cat("<bio_assessment> ", x$form, ": ", x$score, "/", x$total, " (", round(x$percent, 1), "%)\n", sep = "")
  invisible(x)
}
