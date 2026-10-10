# BioExplainR 功能与研究路线

## 当前基线（2026-10-05 W00）

恢复系统 R 4.3.3/Bioconductor 3.18 后，源码检查为 531 项（530 pass、1 skip、0 fail/warning），包检查 Status: OK。当前索引为 `research/results/current_manifest.json`；120 案例/480 facts 的 1,080 请求、4,320 评分，以及双模型各 480/480、五数据集 5/5 均来自保存结果离线核对。当前/历史审计及精确环境见 [REPRODUCTION](REPRODUCTION.md)。后续执行 [增强任务卡](ENHANCEMENT_TASKS.md) W01；已有接口清单见 [W01_INTERFACE_INVENTORY](W01_INTERFACE_INVENTORY.md)。

## 文档五阶段的对应实现

| 阶段 | 已提供的软件功能 | 验证方式 |
|---|---|---|
| 1 对象解释 | 确定性事实提取、差异表达/富集/单细胞/PCA/图表/实验对象适配、本地解释、HTML 报告 | 独立数值参考、真实上游对象与离线回归测试 |
| 2 证据约束 | Europe PMC、GO、Reactome、KEGG、UniProt 检索、缓存、来源链接/访问时间、用户证据与提供者接口 | 各协议模拟响应与实际公共端点请求 |
| 3 主动调试 | 错误现场调用栈、警告、对象摘要、离线分类、模型辅助诊断、独立 R 进程修复检查 | 原始栈捕获、隔离执行、语义不变量和失败用例 |
| 4 跨结果整合 | 项目依赖图、来源一致性、图表/源结果核对、派生证据提示、项目级解释与报告 | 依赖环检测、方向与数值不一致案例、端到端项目示例 |
| 5 教学评估 | 概念题库、前后/迁移/延迟测验表、独立评分、专家量表、数值/修复基准、样本量规划、分层随机、效果量与置信区间 | 软件单元测试；实际专家和学生实验尚需收集 |

## 支持的输入

- DESeq2 `DESeqResults` 及普通差异表达表。
- limma `MArrayLM`（多系数须选择一个）与 `topTable()` 结果。
- edgeR `TopTags`、`DGEExact`、`DGELRT`（单一比较）。
- clusterProfiler/DOSE 风格表及 `enrichResult`、`gseaResult`、`compareClusterResult`。
- SeuratObject、SingleCellExperiment、SummarizedExperiment，单细胞元数据与分样本组成分析。
- ggplot、prcomp 及稀疏/大型矩阵的有界结构摘要。

## 已知边界

- 包解释已有分析结果，不替代完整的原始数据处理和统计建模流程。
- 图表交叉核对包括可解析火山图，以及 BioExplainR 生成的 PCA 和富集气泡图；复杂自定义/多点图层返回无法核查。检查的是标度与坐标变换前的映射值。
- 模型声明验证核查显式事实路径、数值、方向及已提供证据 ID；自由文本的所有生物学陈述没有全面自动验证。
- 文献命中和术语定义不是结论支持度评估；没有自动执行所有文章的全文审读或判定证据等级。
- 同一输入派生的多个结果不构成独立验证，跨组学因果机制不能从方向一致自动推出。
- 包、本地模板和 Shiny 默认 English，`language = "zh"` 或界面选项切换中文。
- 细胞比例检验在独立样本层面进行，成分数据、配对设计、重复测量、协变量与多组比较仍应结合适合的统计模型。
- 通过指定语义不变量只证明这些条件满足，独立 R 进程也不是操作系统级沙箱。
- 完整版本兼容矩阵、真实用户长期使用、专家研究和学生对照实验是后续持续验证工作。

## 使用入口与下一阶段

面向初级研究员的主要入口是 `bio_run_app()` 本地浏览器工作台。它把模型设置、R 环境、
运行记录、工作区对象、自然语言解释和常用图形放在同一个会话中；教学题库和学习评估接口
仍然保留，但不是工作台的主流程。常用图形接口包括 `bio_plot_pca()`、`bio_plot_umap()`、
`bio_plot_enrichment()` 和 `bio_plot_heatmap()`。

## 后续优先级

1. 当前保存公开数据验证覆盖 airway、PBMC3k、pasilla、ALL、bladderbatch；继续扩展独立来源、上游版本、空对象、超大对象和复杂设计。
2. 已实现 PCA/富集图核对与工作台源对象选择；继续扩展 marker 图、多图层、坐标变换、裁剪和最终视觉语义核查。
3. 更严格的生物学证据匹配、全文检索和结论支持评分。
4. 配对/重复测量教学研究与细胞组成模型；英文教学材料和可视化评分面板。
5. 按 docs/EVALUATION.md 执行真正的专家盲评及本科生随机对照、迁移和延迟测验。

## 工作台当前边界

- `bio_run_app()` 需要额外安装 `shiny`；从表达矩阵计算 UMAP 还需要 `uwot`。
- 工作台显示的是值安全的对象摘要和包调用参数表达式；字符参数会省略，完整代码只保留在当前 R 会话记录中。
- 浏览器执行代码与普通 R 控制台具有同样的文件和网络权限。工作台适合本机交互分析，不是操作系统级代码沙箱。
- 论文评测应分别报告离线规则解释、模型组织文本、图形解释和实际用户任务的结果，不能把模型可用性等同于解释准确性。

## Historical：2026-10-04 完成记录

- 0.3.1 修复 Shiny 启动、工作区/页面配置隔离和图形回写，加入元数据、分组和源结果选择。
- Shiny/httpuv/uwot 在当前用户态 R 环境均可用；Playwright 实际页面流程、DeepSeek 页面解释和 HTML 下载通过。
- 真实对象验证覆盖 DESeq2 1.42.0、limma 3.58.1、edgeR 4.0.16、SeuratObject 5.0.1、SCE 1.24.0。
- DeepSeek 54 次主实验请求及摘要、证据、验证和图形核对消融完成，原始数据与结果见 `research/`。
- 论文初稿完成；完整版本矩阵、独立专家与真实用户实验、实际部署其他工具的共同任务对照仍未完成。

## Historical：2026-10-04 第二阶段研究基础设施

- `research/run_common_task_benchmark.R` 已提供统一 fact-path 评分，支持确定性参考、保存响应 replay、用户配置的 OpenAI-compatible 模型和显式 CLI 代码代理；未配置在线模型时只运行离线方法。
- `research/run_compatibility_matrix.R` 已对当前实际安装的 DESeq2、limma、edgeR、SummarizedExperiment、SingleCellExperiment、SeuratObject、ggplot2 和 uwot 版本生成矩阵；这不是所有上游版本的兼容性证明。
- `research/run_complex_plot_checks.R` 已覆盖分面、坐标裁剪和多点图层边界，结果为预设的 pass/fail/not_checkable；复杂图形的人工视觉语义评审仍需独立完成。
- 服务器 R 4.3.3 已通过 `tools/ensure-server-r-dev.sh` 固定开发依赖；`xfun=0.53` 与 `roxygen2=7.3.1` 可共同加载。
