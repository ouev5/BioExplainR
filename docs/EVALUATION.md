# 评测与教学研究流程

本包提供文档最后阶段所需的软件工具。软件测试、外部评分者评价和正式学习效果研究是三个独立终点。
测试通过不代表教学有效；当前项目保存的是外部评分的匿名聚合结果，没有正式学生学习实验数据，也没有报告虚构的效果量。

## 解释准确性

使用 `bio_benchmark(cases, methods)` 固定输入和参考事实。参考数值应通过独立 R 计算或人工审核建立。
同一批案例可以比较本地规则、同一基础模型的直接问答、对象摘要、摘要加证据和完整系统。
每种方法用独立函数传入，记录模型版本、输入预算、提示文本、用时与费用。
返回逐事实匹配、错误、准确率。自动匹配不替代生物学质量评价。

```r
cases <- list(case1 = list(
  input = deg,
  expected = list(n_significant = sum(deg$padj < 0.05 & abs(deg$log2FoldChange) > 1, na.rm = TRUE)),
  args = list(thresholds = list(padj = 0.05, lfc = 1))))
benchmark <- bio_benchmark(cases)
bio_report(benchmark, file = "benchmark.html")
```

## 错误修复

`bio_benchmark_fixes()` 对显式候选代码在独立 R 进程中运行，分别计算运行成功率与语义检查成功率。
病例应包含真实触发调用、已知根因和研究目标。语义不变量至少覆盖比较方向、设计、特征数量、输出类型及数值范围。
没有不变量的成功运行计为未验证；不要将它计入语义成功率。
自动化工具目前计算运行与已指定的语义指标。定位准确率和原因解释正确率须用专家标注的根因另行评分。

## 外部评分者评价

`bio_review_rubric()` 提供数字、统计概念、生物学支持、可追溯性、不确定性、可读性、错误定位和语义保持八个维度。
`bio_evaluate_experts(ratings)` 汇总盲法评分，输出每项均值、评分变异和完全一致比例。
完全一致比例不等同于 Cohen/Fleiss kappa。保留独立的原始评分记录以便计算适合研究设计的可靠性指标。

## 正式学习实验

可用 `bio_plan_learning_study(effect = 0.5)` 做基于预试验效应的样本量规划，
`bio_randomize_learning_study(participants, strata, seed)` 实现可复现的分层两组分配。
分配表保留参与者 ID 供本地实验管理，不应提供给盲法评阅者。

1. 预先注册主要终点、研究假设、排除规则、样本量和统计方法，按基础能力分层随机分组。
2. 两组使用相同数据和操作时间；对照组使用原始 R 输出，实验组使用解释报告。
3. `bio_quiz(form = "pre")` 与 `form = "post"` 提供不同题序；迁移测验应同时更换输入数据和实验背景。
4. `bio_report(quiz)` 隐藏答案。教师报告可显式使用 `show_answers = TRUE`。`bio_grade()` 按答案 ID 评分。
5. 增加不使用工具的新数据迁移任务和延迟测验，评阅者对分组盲法。
6. 将实际成绩交给 `bio_evaluate_learning()`：输出变化量组间差异、Welch 置信区间、Hedges' g 和多终点 BH 校正值。

## 数据格式

教学观察表：`participant, group, pre, post`，可增加 `delayed, transfer`。
专家评分表：`item, rater, dimension, score`。
参与者/评分者标识仅用于本地唯一性核对，返回结果与报告不保存这些标识。
数据缺失会按终点报告并排除，不自动填补。单个参与者成绩行、没有独立重复或零变异的情况不能产生可靠推断。

包内 `inst/examples/full_workflow.R` 使用明确标注的合成数据演示工作流；不是临床数据，也不是实际教学研究结果。

## 当前采集材料

`research/study_materials/` 提供 30 个匿名任务提示、30 个去来源化真实解释案例、外部评分者八维度 0-2 评分表、功能感知工作簿、五类任务卡和可复现随机化方案。答案密钥单独保存，不进入盲法案例压缩包。正式学习实验的用时、SUS、信任校准和认知负荷字段为空；这些材料不能替代伦理审批、知情同意或实际参与者采集。
