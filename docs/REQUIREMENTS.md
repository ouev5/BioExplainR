# BioExplainR 原型需求

来源：用户提供的 `bioinformatics_ai_interpretation_review.docx`（2026-10-03）。
本文件是开发需求摘要；原始文档保存在同目录。包名暂定 BioExplainR。

## 定位与架构

面向生物信息学学习者，解释已有 R 分析对象和图表，记录运行上下文并诊断错误。
采用“确定性解析 → 证据 → LLM 组织语言 → 验证 → 报告”的模块化结构。
R 负责计算数量、方向、阈值、FDR 等事实，模型不得替代统计计算。
解释分为数据事实、统计含义、生物学解释、不确定性、不能推出的结论和学习问题。

## 用户补充的模型配置需求

- 用户能够自己提供 API base URL、API key、模型名称。
- 支持 OpenAI-compatible chat completions 和 Anthropic Messages 协议。
- 提供常见服务的连接预设和可扩展的注册接口；预设不含真实密钥。
- 自定义代理地址与自定义模型 ID 应是正式支持的用法。
- key 优先由环境变量读取；不得写入包源码、报告或普通打印输出。
- 包的运行模型独立于开发时使用的 Claude Code 模型。
- 无 key 时仍能进行对象解析、执行记录和本地规则解释，示例和测试无需联网。

## 统一中间表示

保留 analysis_type、source_class、source_package、来源可信状态、统计事实、
top_features、plot_mapping、provenance、uncertainty，以及用户补充的物种、
组织、基因 ID、实验设计、比较方向、背景基因、筛选阈值和数据依赖。
普通 data.frame 不能仅凭列名就断言是某个包的输出。
默认发送摘要，不发送完整表达矩阵、患者标识或原始样本名称。

## 第一版对象适配

- 差异表达结果表：DESeq2/limma/edgeR 的常见列；DESeqResults 适配。
  明确 adjusted p value 与原始 p value；统计显著、上调、下调和缺失值数量。
- 富集结果表和 enrichResult/gseaResult：ORA 与 GSEA 分开，保留 Count、
  GeneRatio、p.adjust、NES、leading-edge。ORA 不可据此认定通路激活。
- Seurat / SingleCellExperiment：通过可选依赖访问器提取维度、QC、assay、
  降维、cluster 和样本摘要；不能将细胞数当作生物学重复数。
- ggplot：提取 data 摘要、aes、layer、facet 和 labels。
- 不支持的对象有明确的通用摘要或可扩展适配器入口。
- 重型 Bioconductor/Seurat 依赖放在 Suggests，普通结果表用法应保持轻量。

## 拟议公开接口

- bio_configure() / bio_config()：全局及显式配置；URL/key/model 可覆盖预设。
- bio_context()：对象解析和可检查的中间表示。
- bio_explain()：本地解释与可选 LLM 解释，分层语言，默认 English；可通过 `language = "zh"` 切换简体中文。
- bio_record({ ... })：在调用处理器中先捕获错误现场栈，再由 tryCatch 收束；
  保存表达式、警告、错误、对象摘要与版本。不恢复未预先记录的历史。
- bio_last_error()、bio_explain_error()、bio_suggest_fix()。
- bio_validate_fix()：用户显式传入修复表达式，在隔离 R 进程验证，
  对对象结构和用户指定的语义不变量作检查；仅运行成功不能算语义已验证。
- bio_report()：项目级 Markdown 和基础 HTML 报告，包含参数、版本、模型和来源。
- 证据对象/注册入口：第一版接受用户提供的可追溯来源，数据库自动检索留可扩展接口。

## 交付物与验证

标准可安装 R 包：DESCRIPTION、NAMESPACE、LICENSE、R/、man/、tests/、
中文 README、离线可运行示例、架构和开发路线文档。
联网调用默认不在自动测试中发生。测试重点为配置、确定性数字、隐私摘要、
记录错误栈、两种 API 协议的 mock、报告以及隔离验证的语义状态。
说明第一版已实现的能力、需要可选依赖的适配器和后续数据库/高级图表功能。
不声称尚未执行的测试通过，不声称建议代码已验证。
