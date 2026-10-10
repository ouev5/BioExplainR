# 真实数据实验与复现

2026-10-09正式共同任务/受体/ChIP分析已完成：增补`../docs/research_followup_v1/README.md`，360运行/1,800评分，结果`results/common_performance_v4/`；A549候选过滤不可估计`discovery_mechanism_fit_v4/`；ASM18峰文件与坐标/窗口独立复核`discovery_chip_v1/`、`discovery_chip_analysis_v1/`。本地r13/baseline-11，失败/中断另保留。

当前稿为 **v0.10（12 页主稿/18 页补充）**，入口 `../docs/paper_cn_v4/README.md`；11 图/14 表＝25 项正文对应见同目录 `figure_table_links.json`。GSE146017 三候选交互均未通过 Holm；核对原表供体映射后 GSE94335 的 7/7 非哮喘及 9/9 致死性哮喘供体均上调、组间响应差未获支持。新结果目录 `results/discovery_context_v1/`、`results/discovery_donors_v1/`，研究日志 `biology-*`。10-09 续接交付 r11 / baseline-9，GitHub 仍暂停。

历史 v0.9.1（10 页/16 页）21 项正文对应见 `../docs/paper_cn_v3/FIGURE_TABLE_REVIEW.md`，实际文稿/网页日志 `revision-links-*`。

历史 v0.9 稿见 `../docs/paper_cn_v2/README.md`：主稿9页、独立补充16页，六工具任务比较和固定SPARCL1候选的外部实验。案例入口`discovery/README.md`、`results/discovery_sparcl1_v1/`；当时源码/包日志为`results/w00_baseline/revision-*`，审阅包r8。下文旧稿/历史实验仍保留各自日期与范围。

本目录保存实际运行的实验脚本、原始提示/模型响应、逐事实评分、图形核对、浏览器测试和论文结果。当前结果索引为 `results/current_manifest.json`；2026-10-03 六案例实验、precision pilot 与早期共同任务为 historical，2026-10-05 规模结果为当前机制实验。外部评价仅保存匿名聚合记录。

## 当前入口

| 内容 | 当前路径与实际规模 |
|---|---|
| 主实验 | `results/main_scale_480/`：120 cases、480 facts、3 输入×3 重复；1,080 请求、4,320 scores |
| 双模型共同任务 | `results/common_task_scale_480/`：StepFun/DeepSeek 各 480/480；600 case-method 行包含 240 模型请求及未配置/缺失条件 |
| 公开数据 | `results/public_datasets/dataset_tests.json`：airway、PBMC3k、pasilla、ALL、bladderbatch，5/5 保存状态 pass |
| 独立数值参考 | `results/related_tools/pasilla_fact_checks.csv`：30/30 |
| 固定候选外部培养实验 | `results/discovery_sparcl1_v1/`：单 HASM1 细胞系，10 数组，Python/R 12 项复核 |
| 候选因子干预 | `results/discovery_context_v1/`：GSE146017 4 供体/31 文库，三交互阴性，原始计数/完整模型/报告/ledger |
| 候选多供体响应 | `results/discovery_donors_v1/`：GSE94335 7＋9 配对供体，原表配对证据、TPM/效应/精确检验，R 21 项数值复核 |
| 外部评价 | `results/human_evaluation/`：720 外部评分、150 功能评分的聚合表；原评分不在项目中 |
| W00 本轮验证 | `results/w00_baseline/`：历史基线 531 checks（530 pass/1 skip）、包检查 OK、当前/历史离线审计、文稿审计及 hash |
| 开发续接验证（10-05） | `results/w00_baseline/acceptance-*`：648 checks（647 pass/1 skip）、check OK、HTTP/Shiny/bwrap/API；`continuation-*` 保存环境和早期记录 |
| 公开案例与新增接口（10-07） | `results/w00_baseline/improvement-*`：677 checks（676 pass/1 skip）、check OK；`results/miniacc_development_v1/` 为 miniACC 开发案例及 Python 数值复核 |
| 最新工程审阅（10-08） | `results/w00_baseline/review-*`：677 checks（676 pass/1 skip）、check OK、安装接口/历史API、HTTP/Shiny/bwrap；`results/miniacc_installed_review/` 为真实安装包重跑 |
| 后续工程 | `../docs/implementation_records/`：W01–W08 契约/可靠性/适配和产品集成；W09/W12 离线评测入口 |

环境定义、复核命令和结果边界见 [REPRODUCTION](../docs/REPRODUCTION.md)；接续契约见 [DATA_CONTRACTS](../docs/DATA_CONTRACTS.md) 和 [W01 接口清单](../docs/W01_INTERFACE_INVENTORY.md)。原结果目录按索引归类，未迁移或覆盖。

## 数据

- airway 1.22.0 / GEO GSE52778：4 个供体细胞系、各有处理/对照，共 8 个 RNA-seq 文库。原始 63,677 个特征，经 `rowSums(counts) >= 10` 保留 22,369 个。设计为 `~ cell + dex`。
- 10x PBMC3k：1 个公开健康供体、2,700 个细胞、32,738 个特征。用于稀疏矩阵、QC、SCE、SeuratObject v5 和 UMAP 兼容性测试，不进行供体层面的组间推断。
- Reactome `Ensembl2Reactome.txt`：公开映射快照，SHA-256 和下载地址在 `results/data_manifest.json`。ORA 使用被检测且有注释的基因背景，检验 10-500 基因的通路，并对所有入选通路作 BH 校正。
- Europe PMC：显式检索 PMID 24926665。只将命中文献作为可追溯来源，不把题名或命中记录当作全文支持判定。

大型下载与真实 R 对象放在 `cache/`（Git 忽略），可由脚本重建。Reactome 当前下载地址会更新，复现相同结果应保留具有相同 SHA-256 的映射文件；不能把重新下载的新快照当作同一输入。

## 安装

```r
install.packages(c("httr2", "jsonlite", "ggplot2", "callr", "shiny", "uwot", "digest", "SeuratObject", "BiocManager"))
BiocManager::install(c("airway", "DESeq2", "limma", "edgeR", "SingleCellExperiment", "SummarizedExperiment"))
```

```sh
R CMD INSTALL .
R --vanilla --slave -f research/prepare_real_data.R
```

本轮服务器已恢复系统 R 4.3.3/Bioconductor 3.18，`bash tools/server-R` 可回退系统 R；实际安装版本及恢复脚本见复现说明。大型研究数据与相近工具依赖的重建另按各 runner 的来源记录执行。

## 历史六案例模型实验

运行前在当前终端提供 `DEEPSEEK_API_KEY` 环境变量，密钥不要写进脚本或提示文件。

```sh
R --vanilla --slave -f research/run_model_experiments.R
R --vanilla --slave -f research/summarize_results.R
```

配置：OpenAI-compatible，`https://api.deepseek.com`，`deepseek-flash`，请求关闭 thinking，temperature 0，JSON mode，输出上限 5,000 tokens，timeout 120 秒、瞬时错误最多重试 1 次。供应商返回的 model 字段为 `deepseek-flash`，没有不可变的模型快照编号。

此为 historical：6 个案例、3 个方法、每种组合 3 次，共 54 次调用；25 个目标标量事实，每种方法 75 次评分。当前主实验位于 `main_scale_480/`，不从根目录评分文件取分母。方法分别是有界 R 原始输出、R 汇总事实、R 事实加检索证据。完整 120 行真实结果子集单独报告；原始基线不使用代码执行工具，不能代表所有能执行 R 的代理。

历史脚本默认复用 `results/model/` 中存在的响应并重新验证。现有原响应/提示保留；新研究使用新的显式运行目录和冻结协议，不移动或覆盖旧结果。`pilot_precision/` 是早期 PCA 舍入/截断预实验，不混入当前主实验。

## 历史/辅助核对与消融

- `plot_challenges.csv`：3 张正确图和 6 个人工植入的方向、p 值、PCA 坐标/标签、富集大小/颜色错误。
- `validation_ablation.csv`：在同样的模型响应上注入 4 类错误及仅引用路径、没有值的声明，共 90 项挑战。此为受控机制测试，不是自然发生的模型幻觉率。
- `fix_validation.json`：正确参考水平与反转参考水平都能运行，但只有前者通过声明的不变量。
- `compatibility.json`：实际版本的真实数据对象适配结果，不是全部上游版本兼容矩阵。

## 浏览器工具（历史记录保留）

```sh
R --vanilla --slave -f research/launch_workbench.R
# 在另一个终端中，先安装测试工具（不属于 R 包依赖）：
npm install --prefix /tmp/opencode playwright pngjs
NODE_PATH=/tmp/opencode/node_modules node research/browser_smoke.cjs
# 启动服务器的 R 进程已有模型 key 时，可显式加入在线测试：
BIOEXPLAINR_LIVE_MODEL=1 NODE_PATH=/tmp/opencode/node_modules node research/browser_smoke.cjs
```

浏览器脚本使用 `/usr/bin/google-chrome`，默认地址 `http://127.0.0.1:3876`，可通过 `BIOEXPLAINR_URL` 覆盖。检查真实对象解释、代码执行、PCA 图像像素、生成对象回写、源结果核对、报告下载、双会话对象隔离和移动端横向溢出。结果和截图在 `results/browser/`。

## 论文

正文在 `../docs/PAPER_DRAFT.md`，另提供 `../docs/BioExplainR-paper-draft.docx`、自包含 HTML 和 PDF。
`results/paper_metrics.json` 和逐项 CSV 是数字来源。成本是按实际 tokens 和公开价格的估计，不是账单；当前保存的是外部评分聚合结果，不是正式用户实验或教学效果研究。

当前稿件为面向英文方法期刊组织的中文 v0.7，全部图表集中于主稿或补充材料附录并在正文引用。另提供 `../docs/BioExplainR-supplementary.docx` 和 `../docs/submission_assets/` 中的 4 个正文组合图 PDF、3 个补充组合图 PDF、每个 panel 的独立矢量文件、正文表 1-8、补充表 S1-S5 及原始记录压缩包。表 8 保留 120 案例/480 目标事实的 4,320 条逐事实评分。五数据集测试矩阵保存在 `results/public_datasets/`；pasilla 是独立数值事实基准，ALL 与 bladderbatch 是 ExpressionSet 对象/设计字段摘要；多模型共同任务为 120 案例/480 事实的机制性比较，外部评价是聚合描述统计，不等同于正式用户实验。旧 `render_architecture.cjs` 对应历史 v0.2 图，不再用于当前稿件。

第二阶段研究基础设施：

- `run_common_task_benchmark.R` 使用统一 fact-path 评分，支持 BioExplainR R 事实参考、保存响应 replay、用户配置的 OpenAI-compatible 模型和显式 CLI 代码代理。默认离线运行；在线调用必须显式设置 `BIOEXPLAINR_COMMON_TASK_LIVE=1`。
- `run_compatibility_matrix.R` 汇总当前已安装上游包和保存的真实对象验证；缺失版本记为 `not_installed`，结果不是完整上游版本矩阵。
- `run_complex_plot_checks.R` 覆盖分面、坐标裁剪和多点图层的受控核对挑战；它检查映射值，不替代人工视觉语义评审。
- `tools/ensure-server-r-dev.sh` 固定服务器临时开发库中的 `xfun=0.53`，以兼容现有 `roxygen2`；不要求升级 R 主版本。

共同任务框架的结果保存在 `results/common_task/`。其中原有的 6 个共享案例、25 个目标事实只是一次模型协议/事实传递基线，不是 BioExplainR 的功能清单。为测试规模，`generate_common_task_scale_benchmark.R` 生成了 120 个可复现案例、480 个目标事实，覆盖差异表达、富集、PCA、单细胞对象、细胞组成和通用表格摘要；生成内容由 BioExplainR 的确定性 adapter 计算，属于协议/序列化压力测试，不是新的生物学证据或泛化性能研究。

2026-10-05 的规模测试结果保存在 `results/common_task_scale_480/`：StepFun `step-5-preview` 和 DeepSeek `deepseek-flash` 均为 480/480 有回答、480/480 严格匹配，准确率和覆盖率均为 100%。此前 PCA 四位舍入问题通过研究 runner 的 17 位 JSON 与小数字符串协议解决；历史 0.3.1 包内 `.json()` 为 digits=10，开发版 W02 后已统一 17 位精度并有实际 HTTP body 核验。最终两模型请求均关闭 `response_format=json_object`。W00 未重跑在线调用。

导出需要 Pandoc、python-docx、matplotlib、openpyxl；排版审计还需要 PyMuPDF 与 Pillow。先从已保存 R 对象导出坐标，再从规模主实验逐项结果生成图表：

```sh
R --vanilla --slave -f research/export_plot_data.R
python3 research/export_submission_assets.py
python3 research/export_paper.py
libreoffice -env:UserInstallation=file:///tmp/bioexplainr-paper-lo --headless --convert-to pdf --outdir docs docs/BioExplainR-paper-draft.docx docs/BioExplainR-supplementary.docx
python3 research/audit_submission.py
```

本轮使用系统 Pandoc 3.1.3；Python 审计使用 `/tmp/opencode/paper-venv/bin/python`，依赖精确记录见复现说明。当前主稿为 7 个图形元素、13 个可编辑表、PDF 65 页；补充材料为 2 个图形元素、4 个表、PDF 10 页。13 个 Excel 为主表 1–8 和 S1–S5；表 1/表 8 为横向排版。数值表由保存 CSV 生成，Word/Excel/PDF 一致性由 `audit_submission.py` 检查。

论文复核时使用新输出目录：`BIOEXPLAINR_PAPER_RESULTS_DIR=research/results/w00_baseline/paper_browser NODE_PATH=/tmp/opencode/node_modules node research/paper_smoke.cjs`；投稿审计增加 `--output research/results/w00_baseline/submission-audit.json`，保护旧记录。
`R --vanilla --slave -f research/audit_results.R --args --mode=current` 核对当前 manifest、行数/主键/响应/汇总/文件 hash；`--mode=historical` 显式核对旧六案例结果。默认是 current。
`python3 research/audit_paper_references.py` 保存 DOI 解析与元数据核对记录，范围是书目信息，不是全文设计审查。

附录材料索引在 `../docs/submission_assets/README.md`，预实验详情在 `../docs/SUPPLEMENTARY_MATERIAL.md`。每轮 54 个响应和 54 个独立 prompt 共 108 个 JSON，两轮合计 216 个，不应把文件数当作请求数。写作中保留了“claims 数值通过但文字误称 LFC shrinkage”的真实负例，不把数值通过写成全文正确。

交付索引为 `../docs/SUBMISSION_README.md`；旧 `BioExplainR-submission-bundle.zip` 保留为 historical_stale，差异在 `w00_baseline/bundle_inspection.json`。当前开发审阅包为 `BioExplainR-development-delivery-0.4.0.9000-r6.zip`，逐成员/外部 hash 审计为 `review-delivery-audit-result.json`；r5及其continuation审计保留。详见 `../docs/DEVELOPMENT_DELIVERY.md`。公开开发数据由执行者选择，专家评价待准备完成，用户研究 deferred。
