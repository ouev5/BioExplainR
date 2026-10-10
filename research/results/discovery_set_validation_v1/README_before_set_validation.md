# BioExplainR

当前生物学主线论文：[中文v0.11与补充](docs/paper_cn_v5/README.md)（11页主稿＋12页补充）；[问题与后续验证](docs/paper_cn_v5/ISSUES.md)。54基因跨四背景响应，固定12候选中11可测在13供体重复，主线PER2暴露条件相关差异。
历史软件论文：[中文v0.10与独立补充](docs/paper_cn_v4/README.md)；[六工具比较表](docs/paper_cn_v4/tables/Table_1.csv)。
全部11图/14表（25项）的正文引出、结果与结论对应见[图表对应清单](docs/paper_cn_v4/figure_table_links.json)。
正文聚焦完整事实、科学范围、分项核对、项目溯源四项贡献，详细技术方法移至补充。
[SPARCL1公开发现案例](research/discovery/README.md)包含固定候选、外部GEO实验和Python/R独立重算。
新增多供体与因子干预重分析：16个配对供体均上调，组间响应差与三项候选交互未获支持；详见[后续检验记录](docs/implementation_records/CANDIDATE_FOLLOWUP_CONTINUATION.md)。
正式后续研究：[共同任务与机制增补](docs/research_followup_v1/README.md)（360运行/1,800评分；A549候选不可估计；ASM峰坐标/独立复核），Word/PDF/HTML与完整结果已保存。
代码MIT许可，[引用元数据](CITATION.cff)、[发布/DOI实际状态](docs/RELEASE_ARCHIVE.md)。

面向初级生物信息学研究员的 R 包（开发版 v0.4.0.9000；0.3.1 为历史基线）：读取已有的 R 分析对象和图表，
**先由 R 确定性地计算统计事实**，再给出分层的 English 解释；可选地调用你自己配置的
大语言模型（OpenAI 兼容协议或 Anthropic Messages 协议）来组织语言；同时记录 R 代码
运行过程、诊断错误，并在独立 R 进程中按用户指定的语义不变量检查修复代码。

> 软件支持从对象解释到教学评测的完整工作流。不同上游包的全部版本组合仍需持续兼容性测试，
> 教学效果需要实际专家和学生实验验证；内置合成示例不是研究结果。
> 包内不包含任何真实 API key，也不内置任何“默认模型”。

## 设计原则

```
确定性解析 (bio_context) → 证据 (bio_evidence) → 模型组织语言 (bio_explain, 可选)
          → 验证 (bio_validate_fix) → 报告 (bio_report)
```

- 数量、方向、阈值、FDR、细胞数等**只由 R 计算**；模型不能替代统计计算，模型文本被标记为“未经数值核验”。
- 解释分为：数据事实、统计含义、生物学解释、不确定性、不能推出的结论、学习问题，以及概念卡片。
- 普通 data.frame **不会仅凭列名被断言**为某个包的输出：来源状态为 `verified_class`（类可确认）、
  `user_declared`（用户声明）、`inferred_from_columns`（推测）或 `unknown`。
- 只有原始 p 值时**不会**把它当作校正后 p 值；可显式设置 `p_adjust_method = "BH"` 计算，并在不确定性中说明。
- 模型解释默认完整保留可发送的统计 facts，超过显式预算时报错；预览行可缩减，不发送完整表达矩阵、细胞条码、样本/患者名称或 API key。

## 安装

2026-10-07 开发进展：新增样本覆盖/两两交集统计和显式跨结果方向检查；公开 TCGA-ACC `miniACC` 案例已运行并保存，详见 [案例与结果](research/multiomics/README.md)。用户体验研究暂不开展，专家评价安排在工程与案例准备完成后。

```r
# 依赖：httr2, jsonlite, digest（必需）；callr, ggplot2, testthat 等为可选
install.packages(c("httr2", "jsonlite", "digest", "callr"))
# 在本仓库目录下：
install.packages(".", repos = NULL, type = "source")
# 或 R CMD INSTALL .
```

可选依赖（只在需要对应功能时安装；普通结果表用法保持轻量）：

| 功能 | 可选包 |
|---|---|
| 独立进程验证修复 `bio_validate_fix()` | `callr` |
| ggplot 图表解析 | `ggplot2`（`rlang` 用于读取 aes） |
| 本地浏览器工作台 | `shiny` |
| 从表达矩阵计算 UMAP | `uwot`（已有 UMAP 坐标时不需要） |
| `DESeqResults` 的 contrast 描述/metadata | `S4Vectors`（随 DESeq2 安装） |
| Seurat 对象更完整的 assay/layer 信息 | `SeuratObject` |
| SingleCellExperiment 的 colData/assay/降维 | `SummarizedExperiment`, `SingleCellExperiment` |
| 多模态和空间对象摘要 | `MultiAssayExperiment`, `SpatialExperiment` |
| 测试 | `testthat`, `withr` |

`enrichResult` / `gseaResult` 通过 S4 槽位读取，无需加载 DOSE/clusterProfiler。

### 初学者先学的 10 个函数

`bio_configure()`、`bio_context()`、`bio_explain()`、`bio_report()`、`bio_record()`、
`bio_explain_error()`、`bio_suggest_fix()`、`bio_validate_fix()`、`bio_project()` 和
`bio_run_app()` 覆盖最小工作流。其余函数按证据、图形、适配器、运行环境和教学扩展分组，
完整参数请查看 `?函数名` 或 `docs/BioExplainR-user-guide.docx`。

历史 DOCX 指南对应 0.3.1；当前开发新增接口、发送策略和验证状态变化见
[`docs/DEVELOPMENT_DELIVERY.md`](docs/DEVELOPMENT_DELIVERY.md) 和
[`docs/MIGRATION.md`](docs/MIGRATION.md)。本轮边界审阅/修复与实际验证见
[`docs/implementation_records/CONTINUATION_REVIEW.md`](docs/implementation_records/CONTINUATION_REVIEW.md)。

## 快速开始（离线、无需 key）

```r
library(BioExplainR)
bio_configure("local")            # 显式本地模式，不联网

ex <- bio_explain(deg_table,      # data.frame / DESeqResults / enrichResult / Seurat / ggplot ...
                   species = "Homo sapiens", contrast = "treated vs control",
                   thresholds = list(padj = 0.05, lfc = 1))
ex                                # layered English explanation by default
bio_explain(deg_table, language = "zh", use_llm = FALSE)  # opt-in 简体中文
ex$context$facts                  # R 计算的统计事实
bio_report(list(deg = ex), file = "report.html")
```

## 本地浏览器工作台

如果希望把模型设置、R 环境、运行记录和结果解释放在同一个页面中，可以安装可选的
`shiny` 后启动本地工作台：

```r
install.packages("shiny")
library(BioExplainR)
bio_run_app()
```

默认监听 `127.0.0.1`，只接受本机连接。若将 `host` 改为 `0.0.0.0` 或公网 IP，应由部署者自行配置认证、TLS 和反向代理；Shiny 不是多租户隔离。不同浏览器连接的工作区可分开，但仍共享 R 进程的包、网络和文件权限。

函数会在本机启动一个 Shiny 页面并尝试打开默认浏览器。页面包含：

- 模型预设、服务地址、模型 ID、API key 环境变量、超时和重试设置；
- 当前 R 版本、已加载包、已安装包、搜索路径和当前工作区对象摘要；
- 经过 `bio_record_code()` 记录的代码、警告、错误、返回值类型、创建对象和实际包调用；
- 对工作区对象进行初级研究员水平的 English 自然语言分析，并可切换为简体中文；
- PCA、UMAP/嵌入、富集气泡图和表达热图，以及 HTML 报告下载；生成图形保存回当前工作区，可选择源对象核对。

浏览器中的代码不会由模型自动生成或自动执行。用户点击执行后，代码在当前 Shiny 会话环境中
运行并通过 `bio_record_code()` 保存记录；模型只接收 BioExplainR 生成的有界摘要。脚本用户也
可以直接使用以下接口：

```r
rec <- bio_record_code("res <- your_analysis(); res")
bio_object_inventory()
bio_runtime_info()
bio_package_usage()

pca <- bio_plot_pca(expression_matrix, metadata = sample_info, group = "condition")
heatmap <- bio_plot_heatmap(expression_matrix, top_n = 50)
dotplot <- bio_plot_enrichment(enrichment_table, top_n = 20)
embedding <- bio_plot_umap(umap_coordinates, metadata = cell_metadata, group = "cluster")
```

`bio_plot_pca()`、`bio_plot_umap()`、`bio_plot_enrichment()` 和 `bio_plot_heatmap()` 返回带有
有限绘图数据和来源信息的 `ggplot2` 对象，可继续修改主题或交给 `bio_context()` 解读。
PCA 的方差解释率由 R 计算；UMAP 的坐标距离、颜色分离和热图颜色都不能单独证明生物学机制。

离线、完整工作流与真实对象示例：

```r
source(system.file("examples", "offline_demo.R", package = "BioExplainR"))
source(system.file("examples", "full_workflow.R", package = "BioExplainR"))
# 使用已安装的真实 DESeq2/limma/edgeR/SeuratObject/SCE 处理合成数据：
source(system.file("examples", "real_objects.R", package = "BioExplainR"))
```

## 配置模型：URL、key、模型名均由用户提供

key 建议放在环境变量（如 `~/.Renviron`），不要写入脚本：

```
# ~/.Renviron 示例（请替换为你自己的值）
OPENAI_API_KEY=你的key
ANTHROPIC_API_KEY=你的key
BIOEXPLAINR_API_KEY=代理或兼容服务的key
```

### OpenAI 兼容协议（OpenAI / DeepSeek / 自建代理 / 网关）

```r
# 自定义代理 + 自定义模型 ID：base_url 带不带 /v1 都可以，不会重复拼接 /v1
bio_configure("openai_compatible",
              base_url    = "https://your-proxy.example.com/v1",
              api_key_env = "BIOEXPLAINR_API_KEY",
              model       = "your-model-id")

# 也可以给出完整端点 URL（原样使用）
bio_configure("openai_compatible",
              endpoint = "https://your-gateway.example.com/custom/path/chat/completions",
              model = "your-model-id")

# 预设只决定连接方式；模型名必须自己填写
bio_configure("deepseek", model = "你在 DeepSeek 控制台看到的模型名")
bio_configure("openai",   model = "你账号可用的模型名")

# 2026-10-04 真实实验使用的显式配置；key 由 DEEPSEEK_API_KEY 环境变量读取
cfg <- bio_config("deepseek", base_url = "https://api.deepseek.com", model = "deepseek-flash",
                  api_key_env = "DEEPSEEK_API_KEY", json_mode = TRUE, max_tokens = 5000,
                  extra_body = list(thinking = list(type = "disabled")))
```

### Anthropic Messages 协议

```r
bio_configure("anthropic", model = "你账号可用的 Claude 模型 ID")
# 走代理：
bio_configure("anthropic", base_url = "https://your-proxy.example.com",
              api_key_env = "MY_PROXY_KEY", model = "your-model-id")
```

### 本地模型（Ollama）

```r
bio_configure("ollama", model = "qwen2.5:7b")   # 默认 http://localhost:11434/v1，无需 key
```

### 其他

```r
bio_presets()                      # 查看预设（不含密钥）
bio_register_preset("my_gw", protocol = "openai", base_url = "https://gw.example/v1",
                    api_key_env = "MY_GW_KEY")
bio_get_config()                   # 打印时 key 被遮蔽
bio_llm_available()                # 是否可调用及原因
bio_explain(x, use_llm = TRUE)     # 强制使用模型（不可用时报错）
bio_explain(x, use_llm = FALSE)    # 强制离线
```

环境变量回退：`BIOEXPLAINR_BASE_URL`、`BIOEXPLAINR_MODEL`、`BIOEXPLAINR_PROTOCOL`、
`BIOEXPLAINR_API_KEY`。请求带超时（`timeout`），仅对 408/429/5xx 等瞬时错误有限次重试
（`max_retries`）。BioExplainR 的运行模型与开发本包时所用的工具无关，完全由你配置。

模型错误诊断默认省略完整代码，调用栈中的字符串常量会被移除。需要代码结构时，
可使用 `bio_explain_error(run, use_llm = TRUE, include_code = TRUE)`，字符串常量仍会省略。
用户主动填写的背景、备注和问题会发送给所配置模型，应只填写解释所需的信息。

## 主要接口

| 接口 | 作用 |
|---|---|
| `bio_config()` / `bio_configure()` / `bio_get_config()` | 显式或全局模型配置；预设与自定义 URL/key/模型 |
| `bio_context()` | 对象 → 可检查的中间表示（事实、前若干行、图形映射、来源状态、不确定性、用户背景） |
| `bio_context_payload()` | 发给模型的有界、脱敏 JSON 摘要 |
| `bio_explain()` | 本地规则解释 + 可选模型解释（结构化 JSON，分节） |
| `bio_record({ ... })` | 在调用者环境执行代码，保留副作用与返回值；记录警告、错误、出错现场调用栈、对象摘要和版本 |
| `bio_last_error()`, `bio_explain_error()`, `bio_suggest_fix()` | 离线错误分类与**未验证**修复建议；可选模型诊断（不会自动执行代码） |
| `bio_validate_fix()` + `inv_*()` / `bio_invariant()` | 在独立 R 进程中运行**显式给出**的修复表达式，检查输出结构与语义不变量 |
| `bio_evidence()`, `bio_evidence_register()`, `bio_register_evidence_provider()` | 用户提供的可追溯证据；`bio_fetch_evidence()` 显式检索公共来源 |
| `bio_dependency_provenance()` | 依赖包版本与来源（CRAN/Bioconductor/GitHub） |
| `bio_report()` | Markdown / 基础 HTML 报告（无需 Quarto），转义 HTML，不含密钥与原始矩阵 |
| `bio_register_adapter()` | 扩展新的对象类型 |

### 支持的对象

- 差异表达表：DESeq2 / limma `topTable` / edgeR `topTags` / Seurat `FindMarkers` 常见列名；`DESeqResults`。
- 富集：clusterProfiler 风格表格；`enrichResult`（ORA）、`gseaResult`（GSEA），两者分开解释。
- 单细胞：`Seurat`、`SingleCellExperiment`（可选依赖），或用 `analysis_type = "single_cell"` 声明的细胞元数据表。
- `ggplot` 图：数据摘要、aes、图层、分面、标签、标度，以及“推测”的图形类型（火山图、PCA、UMAP 等）。
- `prcomp` PCA 结果；其他对象给出通用结构摘要（矩阵只给维度与数值分布，不给行列名）。

多系数 limma 拟合需显式选择 `coefficient`。对被截断的 `TopTags` 只统计已提供行，
不会声称恢复了完整检验结果。大型与稀疏矩阵采用有界检查，避免为了摘要转成完整稠密矩阵。

## 证据、验证与项目整合

```r
# 显式检索公共数据库，不使用你的模型 key
go <- bio_fetch_evidence("GO:0006954", source = "go")
literature <- bio_fetch_evidence("IL6 inflammatory response", source = "europepmc", limit = 3)
protein <- bio_fetch_evidence("IL6", source = "uniprot", organism = "Homo sapiens", limit = 1)
ex <- bio_explain(deg_table, evidence = c(go, literature, protein))

# 图表与完整源结果核对，而非只读取图标题
ex_plot <- bio_explain(volcano_plot, cross_check = deg_table)
ex_plot$cross_check

# 结构化模型声明中的事实值与引用 ID 检查
bio_validate_explanation(ex)

# 派生关系在报告中明确展示
project <- bio_project(list(deg = ex, enrichment = enrichment_result, plot = ex_plot),
                       dependencies = list(enrichment = "deg", plot = "deg"))
project <- bio_explain_project(project)  # 默认离线
bio_report(project, file = "project.html")
bio_report(project, file = "project.qmd") # 可选：quarto render project.qmd
```

公共检索支持 Europe PMC、QuickGO、Reactome、KEGG、UniProt，并有会话缓存、超时和有限重试。
文献检索命中、通路定义、基因功能注释是不同证据，不能自动推导出本实验的通路激活或因果机制。
没有显式事实引用的自由文本保持未验证状态；检查通过只覆盖实际核对过的声明。
PCA 和富集图可由 `bio_cross_check()` 与源结果核对，富集图显示子集时需明确 `allow_subset = TRUE`。
PCA 数组可用 `variance_explained.1` 等声明路径，有界顶部表可用 `top_features.1.log2fc`。

## 教学与评测

```r
quiz <- bio_quiz(ex, n = 8, form = "transfer")
bio_report(quiz, file = "student_quiz.html")              # 不显示答案
bio_report(quiz, file = "teacher_quiz.html", show_answers = TRUE)
assessment <- bio_grade(quiz, submitted_answers)           # 命名向量，名称为题目 ID
bio_review_rubric()                                       # 专家评分标准
expert_summary <- bio_evaluate_experts(expert_ratings)
learning <- bio_evaluate_learning(actual_scores, reference = "control",
                                  delayed = "delayed", transfer = "transfer")
```

`bio_benchmark()` 对独立参考事实评测不同解释方法，`bio_benchmark_fixes()` 分开统计运行成功和语义保持。
学习效果分析报告组间变化差异、置信区间与 Hedges' g；专家评价和学生实验须使用实际采集数据。
实验流程和表结构见 [docs/EVALUATION.md](docs/EVALUATION.md)。

### 运行记录与修复验证

```r
run <- bio_record({
  dds <- DESeq2::DESeq(dds)
  res <- DESeq2::results(dds, contrast = c("condition", "treated", "control"))
}, purpose = "treated vs control 差异表达")
bio_explain_error(run)        # 错误类别、位置、调用栈、相关对象
bio_suggest_fix(run)          # 建议均标记为 unverified

v <- bio_validate_fix(
  quote({ coldata$condition <- relevel(factor(coldata$condition), ref = "control"); coldata }),
  inputs = list(coldata = coldata),
  invariants = list(inv_factor_levels("condition", c("control", "treated")),
                    inv_same_nrow_as_input("coldata")))
v$status   # runtime_failed / runtime_only / invariants_failed / invariants_passed
```

- 没有给出不变量时，即使运行成功，状态也只是 `runtime_only`，**不算已验证**。
- `invariants_passed` 只表示通过了你列出的检查，不代表整体分析结论正确。
- 独立 R 进程**不是操作系统级安全沙箱**：代码仍可读写文件、访问网络。模型生成的代码从不自动执行。
- 未经 `bio_record()` 运行的代码，事后无法恢复其调用栈和中间对象。

## 测试

```sh
R --vanilla --slave -e 'testthat::test_local(".")'
```

测试全部离线：模型调用通过 `httr2::with_mocked_responses()` 模拟，覆盖两种协议的请求构造与响应解析、
配置与 URL 规范化、密钥遮蔽、确定性计数与原始/校正 p 值、隐私摘要、错误栈捕获、报告与独立进程验证状态。
测试与示例不会访问真实付费模型端点。

## 文档

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)：模块结构与数据流
- [docs/ROADMAP.md](docs/ROADMAP.md)：已实现能力、限制与后续计划
- [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md)：需求摘要
- [docs/EVALUATION.md](docs/EVALUATION.md)：专家评价、前后测、迁移与延迟测验流程
- [docs/INSTALLATION.md](docs/INSTALLATION.md)：标准安装、服务器 R 环境和模型接入
- [docs/WEB_APP.md](docs/WEB_APP.md)：本地浏览器工作台的安装、工作流和边界
- [research/README.md](research/README.md)：五数据集、规模主实验、双模型共同任务及历史实验入口
- [docs/PAPER_DRAFT.md](docs/PAPER_DRAFT.md)：含实际结果、相关工具比较和局限的中文论文初稿
- [docs/paper_cn_v2/README.md](docs/paper_cn_v2/README.md)：当前中文v0.9（9页主稿/16页补充）、工具比较及外部候选实验
- [docs/paper_cn_v4/README.md](docs/paper_cn_v4/README.md)：当前v0.10（12页主稿/18页补充），全部25项图表正文对应及候选后续检验；v0.9.1/v0.9/v0.8为历史稿
- [docs/REPRODUCTION.md](docs/REPRODUCTION.md)：W00 恢复环境、当前/历史审计、版本及文件哈希清单
- [docs/DATA_CONTRACTS.md](docs/DATA_CONTRACTS.md)、[docs/MIGRATION.md](docs/MIGRATION.md)：W01–W04 数据契约、兼容和版本策略
- [docs/W01_INTERFACE_INVENTORY.md](docs/W01_INTERFACE_INVENTORY.md)：现有 74 个导出接口与 legacy 对象，供兼容检查
- [docs/W13_RELEASE_CHECKLIST.md](docs/W13_RELEASE_CHECKLIST.md)：复现、CI、投稿包和作者材料清单

2026-10-05 W00 基线及后续开发检查：历史基线 531 项；当前开发版源码检查 561 项（560 通过、1 跳过），`R CMD check` 为 `Status: OK`。新功能和离线研究入口不改变已保存的 0.3.1 科学结果。
当前保存主实验为 120 个程序生成案例、480 个唯一目标事实、3 种方法×3 轮，共 1,080 次请求、4,320 条评分；双模型各 480/480 匹配，公开数据 5/5 pass。54 请求/225 评分的六案例实验保留为 historical。
结果与源码入口为 [current_manifest.json](research/results/current_manifest.json)，默认审计 current，旧结果用 `--args --mode=historical`。本轮仅离线核对保存模型结果；事实匹配不能代表全文、科学推理准确率或用户收益。

## 许可证

MIT
