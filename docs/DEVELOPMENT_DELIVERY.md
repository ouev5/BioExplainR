# 0.4.0.9000 开发交付说明

**最新正式研究交付：`BioExplainR-development-delivery-0.4.0.9000-r13.zip`（2026-10-09）。** 当前主稿[v0.10](paper_cn_v4/README.md)配套[4页4表研究增补](research_followup_v1/README.md)已导出。新增共同任务360运行/1,800评分、真实HTTP与独立评分器，A549候选不可估计的完整模型及ASM峰/参考坐标核实。完整性入口`research/results/w00_baseline/continuation-formal-delivery-audit-result.json`，当前索引baseline-11；原2,905保护文件及r1–r12保留。下面r12零调用为其准备时点记录。

**最新交接包入口：`BioExplainR-development-delivery-0.4.0.9000-r12.zip`（2026-10-09）。** 当前稿仍为 [v0.10](paper_cn_v4/README.md)，新增保存共同任务／机制准备方案、5项已获取公开输入、依赖与下载失败/中断日志及 `common_performance_checkpoint_v1/checkpoint.json`。**准备部分尚无新模型调用、性能评分或机制拟合**；本地模型/runtime/库在临时目录，ZIP只保留其校验值与复现脚本，半包不进入交付。完整性入口 `research/results/w00_baseline/followup-delivery-audit-result.json`，当前索引 baseline-10；本次根交接独立索引，旧r1–r11保留。

**上一轮已完成交付：`BioExplainR-development-delivery-0.4.0.9000-r11.zip`。** v0.10 为12 页主稿＋18 页补充、25 项图表正文对应，以及 GSE146017 因子干预和 GSE94335 多供体响应重分析。该包纳入两个结果目录的模型/数值/报告/配对证据与 `biology-*` 日志，原始 TPM 的下载命令与完整校验值保存于包内 `excluded_inputs`。原完整性入口 `research/results/w00_baseline/biology-delivery-audit-result.json`（对应当时树，后续文档修订不倒改r11）。

本轮继续使用历史已验收 R 源码包；本地交付不代表外部上传。GitHub 按负责人要求暂停；r1–r11 保留。以下为各轮历史范围。

|历史包|当时内容|原完整性记录（`research/results/w00_baseline/`）|
|---|---|---|
|r10|v0.9.1 交接文字补充|`handoff-delivery-audit-result.json`|
|r9|v0.9.1 全部 21 项图表正文对应|`revision-links-delivery-audit-result.json`|
|r8|v0.9、六工具比较、SPARCL1 固定候选与单细胞系外部实验|`revision-delivery-audit-result.json`|

r7 历史包用于审阅当时开发实现和中文稿，**不是正式 release 或投稿完成证明**。当时中文稿v0.8入口为`paper_cn_v1/`，历史稿v0.7及模型记录来自0.3.1并保留；新契约、ledger、MAE/Spatial和可靠性修复来自0.4.0.9000。已纳入miniACC公开开发案例、45项airway新数值核对和15个开发场景。专家评价后置，用户体验/学习增益研究deferred，稿件文末仅预留补充位置。

入口：`BioExplainR-development-delivery-0.4.0.9000-r7.zip`；包含新中文论文、8合图/32子图PDF、9份外置CSV/XLSX、论文复现工具与本轮案例/页面日志，以及原有开发审阅内容。r1–r6和旧投稿包保留；r6的598成员仅对应当时树。论文独立附件包为`BioExplainR-中文论文-v0.8-图表附件.zip`。仅需你本人完成的事项见`USER_ACTIONS_REQUIRED.md`。

## 开发版安装及最小流程

```r
install.packages(c("httr2", "jsonlite", "digest"))
install.packages("BioExplainR_0.4.0.9000.tar.gz", repos = NULL, type = "source")
library(BioExplainR)
ctx <- bio_context(data.frame(log2FoldChange = c(2, -2, .1), padj = c(.01, .02, .8)),
                   scope = list(comparison_id = "treated_vs_control"))
ex <- bio_explain(ctx, use_llm = FALSE)
ex <- bio_validate_claims(ex, list(list(id = "c1", fact = "n_significant", value = 2L,
                                      scope = ctx$scope)))
bio_report(ex, file = "offline-report.html")
```

可选上游对象依赖使用 `BiocManager::install(c("MultiAssayExperiment", "SpatialExperiment"))` 安装。本轮实际版本为 R 4.3.3/Bioc 3.18，MAE 1.28.0、SpatialExperiment 1.12.0；更广版本矩阵仍须实际 CI 运行。

## 相对历史指南的变化

- `bio_explain()` 的默认模型输入完整保留可发送 facts，完整 facts 超出预算明确报错；旧 `bio_context_payload(ctx, max_top, max_chars, include_features)` 保留 bounded 兼容行为，`fact_mode="chunked"` 记录缩减字段。
- `bio_validate_claims(ex, claims, policy, relations=NULL)` 在原字段之外保存 typed/evidence findings、ledger、legacy_status；失败不再被旧数值检查的 pass 掩盖。计数精确比较，缺 scope/unit/reference 保留 unknown/unverified。模型 prose 未映射时总状态最多 partial。
- 可记录 evidence pair 的 supports/contradicts/definition_only/irrelevant/unknown；合法 citation 不代表支持成立，model/user relation 不成为 expert gold。
- MAE 记录各 child context/facts 与样本 ID alignment；SpatialExperiment 记录坐标范围/单位/section，不发送坐标表或原始图像，也不凭空产生 mask/覆盖率。
- 样本映射记录模态覆盖、两两交集和完整/未测量病例数；`bio_validate_project_relations()` 核对显式特征、作用域、比较方向及有限非零效应符号。方向一致不表示显著性、因果或独立证据。
- docking 仅为通用表格 parser/provenance audit，真实科学主案例尚未完成。
- Shiny分析页增加`bio_project`专用解释与覆盖/关系展示；绘图页可下载Cairo矢量PDF，生成失败清空旧图及下载入口。

`BioExplainR-user-guide.docx` 保留历史 0.3.1 指南；新增接口请以本补充说明、`DATA_CONTRACTS.md`、`MIGRATION.md` 和安装包帮助为准。完整审阅问题与验证范围见 `implementation_records/CONTINUATION_REVIEW.md`。

## 审计

ZIP内manifest保存每成员大小/SHA-256，排除自身及外层ZIP。当前稿审计为 `paper_cn_v4/audit.json`，增补审计在`research_followup_v1/`，当前交付完整性为 `continuation-formal-delivery-audit-result.json`。r12/r11/r7/r6/r5 原结果分别保留为 `followup-delivery-audit-result.json`、`biology-delivery-audit-result.json`、`paper-cn-delivery-audit-result.json`、`review-delivery-audit-result.json`、`continuation-delivery-audit-result.json`。详细交接为 `implementation_records/FORMAL_FOLLOWUP_CONTINUATION.md` 及原研究记录。

```sh
python3 research/package_submission.py --audit docs/paper_cn_v4/audit.json --output docs/BioExplainR-development-delivery-0.4.0.9000-r13.zip --verify-only --result research/results/w00_baseline/delivery-recheck-new.json
Rscript --vanilla inst/fixtures/contracts/validate_fixtures.R
python3 research/test_frozen_benchmark.py
python3 research/multiomics/test_audit_miniacc.py
```

最终投稿仍需真实作者单位/通讯地址/CRediT/基金/利益冲突/许可/伦理、人工排版审阅、独立研究、干净环境第三方复现和真实公开 repository/release/DOI。
