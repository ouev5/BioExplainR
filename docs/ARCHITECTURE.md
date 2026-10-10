# BioExplainR 架构（v0.3.1）

## 数据流

```
R 对象 ──► 适配器 (R/adapters-*.R) ──► bio_context（中间表示）
                                         │
                ┌────────────────────────┼─────────────────────────┐
                ▼                        ▼                         ▼
     本地规则解释 (.explain_local)   bio_context_payload()      bio_report()
                                    （有界、脱敏 JSON）
                                         │
                                         ▼
                         bio_build_request() → httr2 → bio_parse_response()
                         （OpenAI 兼容 / Anthropic Messages）
```

本地浏览器工作台是上述接口的可选使用入口：

```
bio_run_app()
  ├─ 模型配置与密钥环境变量状态
  ├─ bio_runtime_info() / bio_object_inventory()
  ├─ bio_record_code() ──► bio_records() / bio_package_usage()
  ├─ bio_explain() ──► 中文分层解释
  └─ bio_plot_pca()/bio_plot_umap()/bio_plot_enrichment()/bio_plot_heatmap()
```

工作台每个浏览器会话都有自己的工作区副本。用户点击代码执行后，代码在
该会话的 R 环境中运行；模型只接收 `bio_context_payload()` 生成的摘要，
不会自动生成或执行代码。

页面模型配置、记录和图形也归当前连接；R 进程的已加载包与文件/网络权限仍共享。
生成图形保存回工作区，可选择源对象调用 `bio_cross_check()`；支持 PCA 和富集图的特定数值核对。

```
bio_record({ ... }) ─► withCallingHandlers（出错现场捕获 sys.calls()）
                     ─► tryCatch（收束）─► bio_record 对象
                     ─► bio_explain_error() / bio_suggest_fix()（离线规则；可选模型，结果未验证）
用户显式修复表达式 + 命名输入 + 不变量 ─► bio_validate_fix() ─► callr 子进程 ─► 状态
```

## 模块

| 文件 | 职责 |
|---|---|
| `R/config.R` | 连接预设、`bio_config` 对象、环境变量解析、端点 URL 规范化、密钥遮蔽 |
| `R/context.R` | `bio_context` 构造、适配器注册与选择、`bio_context_payload` |
| `R/adapters-de.R` | 差异表达表、`DESeqResults`、`prcomp` |
| `R/adapters-enrich.R` | ORA/GSEA 表格、`enrichResult`、`gseaResult`（通过 S4 槽位读取） |
| `R/adapters-sc.R` | `Seurat`、`SingleCellExperiment`、细胞元数据表 |
| `R/adapters-plot-generic.R` | `ggplot` 语义、通用回退 |
| `R/explain.R` | 本地分层解释模板、模型提示、`bio_explain` |
| `R/llm.R` | 请求构造（超时、有限重试）、响应解析、JSON 提取 |
| `R/record.R` | `bio_record` 与历史记录 |
| `R/diagnose.R` | 离线错误分类、建议、可选模型诊断 |
| `R/validate.R` | 不变量与 `bio_validate_fix` |
| `R/evidence.R` | 证据对象、证据提供者扩展点、依赖来源 |
| `R/report.R` | 块结构 → Markdown/HTML 渲染（HTML 转义、密钥过滤） |
| `R/runtime.R` | R 版本、已安装/已加载包、工作区对象和包/函数参数使用摘要 |
| `R/plots.R` | PCA、UMAP/嵌入、富集气泡图和表达热图的 R 侧计算 |
| `R/shiny-app.R` | 可选本地浏览器工作台；模型设置、代码、解释、图形和报告下载 |
| `R/adapters-extended.R` | limma/edgeR/实验对象、有界矩阵与样本设计事实 |
| `R/evidence-live.R` | 五类公共证据协议、缓存、超时与可追溯来源 |
| `R/explanation-validation.R` | 显式数值、方向、事实路径及引用 ID 核查 |
| `R/plot-cross-check.R` | 图形映射值与完整源结果交叉核对 |
| `R/cell-proportions.R` | 独立样本层面的细胞组成摘要与检验 |
| `R/project.R` | 项目依赖图、来源一致性与跨结果解释 |
| `R/teaching.R` | 题库、试卷、答案隔离、确定性评分和专家量表 |
| `R/evaluation.R` | 数值/修复基准、专家/学习成绩分析、样本量与随机分配 |

## 中间表示 `bio_context`

| 字段 | 内容 |
|---|---|
| `analysis_type` | `differential_expression`、`enrichment_ora`、`enrichment_gsea`、`single_cell`、`plot`、`pca`、`generic` 等 |
| `source_class` / `source_package` / `source_status` | 来源及可信状态：`verified_class` / `user_declared` / `inferred_from_columns` / `unknown` |
| `facts` | 由完整输入计算的统计事实（数量、阈值、方向、NA 数、p 值依据等） |
| `top_features` | 截断后的少量行（截断发生在计数之后） |
| `plot_mapping` | ggplot 的数据摘要、aes、图层、分面、标签、标度 |
| `provenance` | 适配器、阈值、参数、时间、BioExplainR 版本、输入结构摘要 |
| `uncertainty` | 来源与统计上的限制说明 |
| `metadata` | 用户提供：物种、组织、基因 ID 类型、设计、比较方向、背景基因、数据依赖、备注 |

## 隐私与安全约定

- 发送给模型的只有 `bio_context_payload()`：事实、少量顶部行（基因/通路/cluster 名称）、图形映射、用户背景和不确定性；
  按 `max_chars` 截断。不含矩阵数值、行列名（可能是样本名）、细胞条码、样本/供体名称。
- `bio_config` 中的字面量 key 存于闭包中；打印、`as.list()`、报告只显示来源（如 `env:OPENAI_API_KEY`）。
  报告输出最后再经 `bio_redact()` 过滤已知密钥和类密钥字符串。
- 模型生成的代码只作为文本保存；`bio_validate_fix()` 只运行用户显式传入的表达式。
- `callr` 子进程隔离会话状态，但不是操作系统级沙箱。

## 扩展点

- `bio_register_adapter(name, detect, extract, analysis_types)`：新对象类型。
- `bio_plot_*()`：可复用的常用图形构建器，返回带来源属性的 `ggplot2` 对象。
- `bio_register_preset()`：新的连接预设。
- `bio_register_evidence_provider(name, fn)`：本地或机构数据库检索；五类公共检索可按名称直接调用。
- `bio_invariant(name, fn)`：自定义语义检查。
