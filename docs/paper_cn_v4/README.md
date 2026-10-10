# BioExplainR 中文论文 v0.10（历史软件主稿）

2026-10-09已完成[生物学主线v0.11初稿](../paper_cn_v5/README.md)，纳入54基因四背景响应、PER2暴露条件相关证据与完整问题说明。下方保留本v0.10当时结果及复现范围。

2026-10-08。本轮新增“候选后续检验”：在已固定的 SPARCL1 候选上，检验炎症环境/CEBPD 交互是否成立（GSE146017），并用原文供体映射核对后的多供体布地奈德实验（GSE94335）检验病组响应差异。正文明确保留阴性结果、供体共享与元数据冲突。

**2026-10-09正式后续研究已完成，见[共同任务与机制研究增补 v1](../research_followup_v1/README.md)（4页4表，Word/PDF/HTML）。** 新增360共同任务运行/1,800评分、A549候选过滤不可估计、ASM峰坐标核实与独立实现复核。该增补与本v0.10主稿分文件保存，当前本地交付r13；原v0.10主稿/图表保留。

## 文件

- `BioExplainR-中文论文-v0.10.{pdf,docx,html}`：**12 页主稿**，3 主图（新增图 3）、1 内嵌比较表、32 参考文献。
- `BioExplainR-补充材料-v0.10.{pdf,docx,html}`：**18 页补充**，8 补充图、补充方法 S1–S13（原 v0.8 的 S1–S10、原外部案例 S11、本轮新增 S12 因子干预与 S13 多供体响应/配对修订）。
- `manuscript.md`：可编辑主稿源；`manuscript_expanded.md` 为含展开参考文献/比较表的生成源；`supplementary.md` 为生成补充源。
- `tables/Table_1.{csv,xlsx}` 与 `Table_S1`–`Table_S13.{csv,xlsx}`：**14 组外置数据表**。
- `audit.json`：正文 **25 项**图表对应（3 主图＋1 主表＋8 补充图＋13 补充表）、引用、CSV/XLSX、PDF 文字边界与图几何核验；网页桌面/移动验收见 `research/results/w00_baseline/revision-biology-browser/summary.json`。2026-10-09 续接纠正交接文字中的“24 项”；实际清单一直包含全部 25 项。

## 本轮主要补充

1. **方法 2.5/2.6**：GSE146017 因子模型（`~ donor + kd * bud * tnf`，4 供体/31 文库）三候选交互同一 Holm family；GSE94335 多供体三检验 Holm family，明确 TPM 估计量、伪计数敏感性与配对来源。
2. **结果 3.4**：补上原文核对——Himes 2014 表 1、Kan 2019 表 3 已报告 SPARCL1 糖皮质激素响应，因此不把重复上调写成新发现。
3. **结果 3.5 / 图 3**：核对原论文 Supplement Table E1 的 Cell Line 后，7/7 非哮喘与 9/9 致死性哮喘供体配对均上调（log2(TPM+1) 差 +3.514 与 +3.598）；组间响应差 +0.084（Holm P=0.859）未获支持；GSE146017 三个 SPARCL1 交互均未通过 Holm 校正。
4. **讨论 4.1/4.2**：区分“表达重复”与“机制推断”；列出 GSE94335 两文库映射/病组冲突、跨实验共享培养细胞系（至少 3 个同 ID）、GSE146017 低表达与 4 供体限制。
5. 正文较 v0.8 缩减 47.39%（11,279→5,934 非空白字符）；v0.10 增加真实发现章节，故不再声称 50% 以上压缩。

## 复现导出与核验

```sh
python research/paper_cn_revision/build_revision.py --directory docs/paper_cn_v4 --version v0.10 --reuse-assets docs/paper_cn_v3 --biology-followup
python research/paper_cn_revision/audit_revision.py --directory docs/paper_cn_v4 --version v0.10
BIOEXPLAINR_PAPER_DIRECTORY=docs/paper_cn_v4 BIOEXPLAINR_PAPER_VERSION=v0.10 BIOEXPLAINR_MAIN_FIGURES=3 BIOEXPLAINR_MAIN_TABLES=1 \
BIOEXPLAINR_REQUIRED_TEXT=iSEE,SCassist,GeneAgent,ellmer,GPTCelltype,SPARCL1,GSE94335,GSE146017,致死性哮喘 \
BIOEXPLAINR_REVISION_BROWSER=/tmp/opencode/paper-browser NODE_PATH=/tmp/opencode/node_modules node research/paper_cn_revision/browser_revision.cjs
```

分析入口：协议 `research/discovery/CONTEXT_PROTOCOL.md`、`DONOR_PROTOCOL.md`、`DONOR_DESIGN_AMENDMENT.md`；结果 `research/results/discovery_context_v1/`、`research/results/discovery_donors_v1/`（含 `scientific_ledger.json` 与 `files_manifest.json`）。GSE94335 原始 TPM 输入（121,575,832 bytes，SHA-256 `30ebc92d…189277f`）体积较大，不进入交付 ZIP，按 `download_ranges.py` 重新下载并校验。

本地开发交付入口为 `docs/BioExplainR-development-delivery-0.4.0.9000-r11.zip`；逐成员完整性结果以 `research/results/w00_baseline/biology-delivery-audit-result.json` 为准。包内保留当前稿、历史稿、两项后续检验的结果/模型/报告与原文配对证据；原始 TPM 的排除条目、下载命令和完整 SHA-256 位于包内 `delivery_manifest.json` 的 `excluded_inputs`。

作者、基金及人工最终图稿审阅仍留真实信息补充位置；GitHub 发布按负责人要求暂停。
