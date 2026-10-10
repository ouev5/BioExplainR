# 中文论文 v0.7 图表附件

对应主稿 `../BioExplainR-paper-draft.docx`。图表集中于 Word 附录 A/B，但在正文中按原编号引用。图内英文标签便于后续投稿复用；中文图注和表注保存在 Word。当前没有公开仓库 DOI，附件不代表已经提交期刊。

## 独立图文件

- `Figure_1_architecture.pdf`：四面板系统架构图；`Figure_1A_framework.pdf` 至 `Figure_1D_framework.pdf` 为独立 panel 原件。
- `Figure_2_ablation.pdf`：四面板目标事实匹配消融；`Figure_2A_overall.pdf` 至 `Figure_2D_latency.pdf` 为独立 panel 原件。
- `Figure_3_airway_PCA.pdf`：四面板 airway PCA 与配对设计边界；`Figure_3A_scores.pdf` 至 `Figure_3D_design.pdf` 为独立 panel 原件。
- `Figure_4_PBMC3k_UMAP.pdf`：四面板 PBMC3k UMAP/QC；`Figure_4A_embedding.pdf` 至 `Figure_4D_scope.pdf` 为独立 panel 原件。
- `Figure_S1_workbench.pdf`：四面板真实 Shiny 工作台记录；`Figure_S1A_workbench.pdf` 至 `Figure_S1D_workbench.pdf` 为独立 panel 原件。
- `Figure_S2_pasilla.pdf`：四面板独立 pasilla 基准；`Figure_S2A_pasilla_PCA.pdf` 至 `Figure_S2D_pasilla_thresholds.pdf` 为独立 panel 原件。
- `Figure_S3_human_evaluation.pdf`：四面板外部评价聚合图；`Figure_S3A_human_evaluation.pdf` 至 `Figure_S3D_human_evaluation.pdf` 为独立 panel 原件。

组合图与每个 panel 均为嵌入字体的独立 PDF，并另提供 PNG 与可编辑 SVG；补充图 S1 的 A-C panel 是截图型 PDF。图 2-4 的坐标/评分源 CSV 同目录保存，不含细胞条码或样本 ID；airway 图中的 donor 已去来源化为 D01-D04。数据图沿用现有 R 对象中的坐标，没有重新运行统计或模型实验。

## 独立 Excel 表

- `Table_1_tool_comparison.xlsx`：合并后的 8 列工具设计比较，非性能排名。
- `Table_2_main_results.xlsx`：主实验匹配、覆盖、已回答准确率和延迟。
- `Table_3_real_object_compatibility.xlsx`：所测真实对象与版本。
- `Table_4_case_results.xlsx`：六类功能家族逐方法评分汇总。
- `Table_5_claim_challenges.xlsx`：90 项声明挑战。
- `Table_6_plot_fix_challenges.xlsx`：图形与修复不变量挑战。
- `Table_7_external_evaluation.xlsx`：3 位外部评分者案例评分与 30 位评分参与者功能感知评分的聚合结果。
- `Table_8_main_scale_480_fact_results.xlsx`：120 个可复现案例、480 个唯一目标事实的逐项主实验评分；Display 中每个方法为三轮匹配/回答次数，Source 表保留 4,320 条逐事实记录。
- `Table_S1_citations_tokens_cost.xlsx`：引用、tokens 与估算成本。
- `Table_S2_external_validation.xlsx`：iSEE、GPTCelltype、ellmer、pasilla 的实际入口/独立数据测试。
- `Table_S3_pasilla_fact_checks.xlsx`：6 个阈值组合的 30 项 pasilla 事实核对。
- `Table_S4_common_task_models.xlsx`：StepFun 和 DeepSeek 在 120 个案例、480 个目标事实上的共同任务评分。
- `Table_S5_human_evaluation.xlsx`：外部评分者案例评分与功能感知评分明细汇总。

每个工作簿含 `Display`（与 Word 一致的展示内容）和 `Caption_Notes`（表题、表注、来源）；量化表另带 `Source_*` 的数值数据表。方法/来源编码不是共同任务运行结果；✓/×/partial 的含义见表注。S2 的相近工具测试是工作流入口/协议记录，不是性能排名。

## 原始补充记录

`supplementary_records.zip` 收录规模主实验 1,080 个响应和 1,080 个 prompt、旧主实验/预实验记录、评分与清单、机制挑战、脚本及浏览器截图；同时保留双模型规模共同任务的脱敏响应。早期 StepFun JSON mode 失败探针也保留用于解释协议边界，最终评分使用关闭 JSON mode 的结果。`supplementary_manifest.csv` 给出每个文件的相对路径、大小与 SHA-256。压缩包不包含大型原始下载缓存或 API key。详细说明见 `../BioExplainR-supplementary.docx`。

## 再生成

标准环境安装 Python 的 matplotlib、openpyxl、python-docx，并配置 Pandoc；在项目根目录运行：

```sh
R --vanilla --slave -f research/export_plot_data.R
python3 research/export_submission_assets.py
python3 research/export_paper.py
libreoffice -env:UserInstallation=file:///tmp/bioexplainr-paper-lo --headless --convert-to pdf --outdir docs docs/BioExplainR-paper-draft.docx docs/BioExplainR-supplementary.docx
```

服务器可用 `bash tools/server-R`；临时 Python 依赖位于 `/tmp/opencode/paper-python`，以 `PYTHONPATH` 加载。再生成只读取保存结果；原始 DeepSeek 调用不是排版的前置步骤。
