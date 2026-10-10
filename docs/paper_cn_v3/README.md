# BioExplainR 中文论文 v0.9.1（历史稿，已归档）

**当前稿为 [v0.10](../paper_cn_v4/README.md)，已加入多供体与因子干预后续检验。本目录保留 v0.9.1 的图表正文修订记录及原始导出。**

2026-10-08。本轮按“所有图表都需在正文引出并解释”的要求修订。完整检查覆盖**10张图、11张表**，具体位置见 `FIGURE_TABLE_REVIEW.md`；机器可读记录见 `figure_table_links.json`。

## 文件

- `BioExplainR-中文论文-v0.9.1.{pdf,docx,html}`：**10页主稿**，2主图、1内嵌比较表、30参考文献。
- `BioExplainR-补充材料-v0.9.1.{pdf,docx,html}`：**16页补充**，8补充图、补充表S1–S10说明和11节详细方法。
- `manuscript.md`：可编辑主稿源；`manuscript_expanded.md`为含展开参考文献/比较表的生成源。
- `supplementary.md`：生成的补充文字源，图注中的旧表号已统一改为补充表S编号。
- `audit.json`：正文21项图表对应、Word/PDF/CSV/XLSX/引用/几何核验结果；网页桌面/移动验收在 `research/results/w00_baseline/revision-links-browser/`。

## 这次主要补充

1. 表1：方法2.3交代与哪些工具、哪些维度比较；结果3.1报告比较结果和BioExplainR集成优势。
2. 图1/补充图S1：方法2.1说明架构A–D的设计含义，明确S1复用同一框架。
3. 补充图S2–S5/表S1–S5：结果3.2按airway、PBMC/微阵列、pasilla和miniACC分别引出，不再只挂成组编号。
4. 补充图S6–S7/表S6–S8：结果3.3区分主消融、家族/双模型、错误注入和修复不变量，补齐各panel的结果与含义。
5. 图2/表S10：结果3.4按候选→外部测量→效应→验证层级说明。
6. 补充图S8/表S9：结果3.5引出桌面/移动/实际PDF及分层工程验收，保留手算工程输入边界。

正文（引言到结论，非空白字符）11,279→5,576，仍缩减**50.56%**；旧v0.8/v0.9目录保留。图表原件逐字节复用v0.9，不重算实验或重绘图表。本轮无软件包源码、在线模型、专家或用户研究变化。

## 复现导出

```sh
python research/paper_cn_revision/build_revision.py --directory docs/paper_cn_v3 --version v0.9.1 --reuse-assets docs/paper_cn_v2
python research/paper_cn_revision/audit_revision.py --directory docs/paper_cn_v3 --version v0.9.1
BIOEXPLAINR_PAPER_DIRECTORY=docs/paper_cn_v3 BIOEXPLAINR_PAPER_VERSION=v0.9.1 BIOEXPLAINR_REVISION_BROWSER=/tmp/opencode/paper-v091-browser-new NODE_PATH=/tmp/opencode/node_modules node research/paper_cn_revision/browser_revision.cjs
```

本輪GitHub发布按负责人要求暂停。作者、基金及人工最终图稿审阅仍留真实信息补充位置。
