# 候选后续检验与图表叙述续接（v0.10）

日期：2026-10-08，交付续接：2026-10-09。本轮在 v0.9.1 基础上新增两项已发表公开干预/队列数据的候选后续检验，并把它们接入主稿；同时把图表正文对应项从 21 项扩展到 25 项（10-09 纠正原交接计数误写）。研究数值来自 10-08 实际运行，日志在 `research/results/w00_baseline/biology-*`，完整性入口为 `docs/paper_cn_v4/audit.json` 与 `research/results/discovery_*/files_manifest.json`。

## 一、为什么先查文献再分析

核对 Himes et al. 2014（doi:10.1371/journal.pone.0099625）表 1 发现 SPARCL1 已被报告为地塞米松响应基因；Kan et al. 2019（doi:10.1165/rcmb.2018-0385OC）表 3 也报告其布地奈德响应。v0.9.1 中“SPARCL1 外部重复上调”的表述因此不足以构成新的生物学贡献。本轮据此把问题改为两个可证伪问题，并在方案冻结时写入“不主张首次发现”：

1. 该响应是否依赖 TNFα 炎症环境或 CEBPD？（GSE146017）
2. 该响应在所测致死性哮喘来源 ASM 中是否保留、组间是否有差异？（GSE94335）

## 二、GSE146017 因子干预重分析（阴性）

- 输入：GEO 发布 HTSeq 基因计数 `GSE146017_CEBPD_htseq_gene.txt.gz`（1,371,256 bytes，gzip CRC 通过），31 文库、4 供体；保留 rowSums≥10 的 27,409 特征。
- 设计：`~ donor + kd * bud * tnf`（full-rank 校验通过）；NT/无 BUD/无 TNF 为参照；关闭自动 Cook's replacement；文库不是独立人。
- 三个预定 SPARCL1 交互（同一 Holm family，α=0.05）：BUD×TNFα（NT 背景）−1.246（95% CI −2.715–0.222，Holm P=0.289）；BUD×KD（无 TNF）−0.142（P=1）；三因素 −0.136（P=1）。**均未通过校正。**
- simple effects（仅解释用）：NT/无 TNF +1.533（0.420–2.646）、NT/TNF +0.287（−0.672–1.245）、KD/无 TNF +1.391（0.076–2.707）、KD/TNF +0.009（−1.098–1.116）。
- 供体级敏感性：log2(规范化计数+1) 差中差，NT 无 TNF 四供体全为正（+1.83、+1.03、+0.87、+1.00）；交互方向 1 正 3 负，n=4 时双侧枚举 P 最小 0.125，不能作确认。
- 限制：SPARCL1 baseMean 8.175（低表达），全基因独立过滤可能使其与描述性 simple effect 不一致；CEBPD 敲低为 siRNA，可能含间接效应。
- 复核：Python 从原计数重算候选测量、R size factors、Wald P/CI 与各 family BH（82,227 个 padj）；DESeq2 拟合由 R 完成，Python 不自称独立重拟合。

## 三、GSE94335 多供体重分析（正向响应、组差不支持）

- 输入：`GSE94335_PostQC_all_sample_TPM.txt.gz`（121,575,832 bytes，SHA-256 `30ebc92d…189277f`，gzip CRC 通过；5,851,434 行 transcript×sample 长表）。串行下载多次超时后改用 232 段 HTTP Range 下载，逐段校验 `Content-Range`/`Last-Modified`，失败片段重命名保留。
- **元数据冲突（关键）**：GEO `donor` 字段等于逐文库标题，不能配对；原文 Supplement Table E1 的 Cell Line 才是真实供体。发布 TPM 缺原 N012412 的 28779/28782，多出原表未列的 28793/28796，且 28793 在 GEO 标为 asthma、在 TPM 命名为 non_asthma。按设计（不猜测配对）排除 28793/28796，得到 32 文库、7 非哮喘 + 9 致死性哮喘供体。
- 估计量：同基因全部 transcript TPM 求和 → log2(TPM+1) → 供体内 BUD−vehicle（TPM 不是计数输入，不作 DESeq2 log2FC）。
- 结果：非哮喘 +3.514（95% CI 2.448–4.580，配对 t P=1.94e-4，Holm P=3.89e-4，128 符号翻转 P=0.01563）；致死性哮喘 +3.598（3.270–3.926，P=6.42e-9，Holm P=1.92e-8，512 翻转 P=0.003906）；组间差 +0.084（−0.991–1.159，Welch P=0.859，Holm P=0.859，11,440 组枚举 P=0.844）。伪计数 0.5/0.1 下均值与方向不变（+3.58/+3.69、+3.65/+3.77）。
- 跨实验单位：GSE94335 与 GSE146017 至少共享 N010912、N051911、N061311 三个培养细胞系，故不得相加为 20 个独立供体；与 airway 的 N61311/N061311 别名对应未完整核实。
- 复核：R 从原 TPM 与原表文本重新实现全部配对/组间统计与精确检验，并逐样本比对 Cell Line、病组与处理（`r_numeric_checks.csv`、`audit.json`）。

## 四、图表正文叙述（21 → 25 项）

|项目|内容|
|---|---|
|主稿|图 3（新增）：A 16 供体配对测量、B 组内效应/组差与 95% CI、C 四条件 BUD simple effects、D 三项预定交互（Holm P≥0.289）；正文 3.5 逐 panel 引出并解释。图 2 图注改为“先前提出的后续实验路线，新增检验见图 3”。|
|补充表|S11 因子模型（4 基因×8 比较＋三交互 Holm）、S12 多供体配对与组间响应、S13 全部供体效应与伪计数敏感性；补充方法新增 S12、S13（含配对修订记录）。|
|自动化核验|`audit.json` 通过：32 引用、3 图、1 内嵌表、14 外置表（CSV↔XLSX 逐格一致）、25 项图表在正文对应、PDF 文字边界与图几何；网页 1440/390 双视口无溢出/JS 异常。|

## 五、本轮明确未做

未做新增供体湿实验、GR/CEBPD 直接结合、SPARCL1 干预与蛋白/基质/临床终点；未做六工具共同任务性能排名；未新增专家/用户研究；未改 R 包功能或重跑 testthat/build/check/Shiny/HTTP/bwrap/历史 API；未上传任何外部服务或调用 GitHub。

## 六、10-09 交付与审计续接

- 当前入口、网页索引与旧稿历史标识同步到 v0.10，图表总数统一为 25；不重导出主稿/图表。
- 打包脚本增加 `--biology-followup`，包括两个后续检验目录、完整模型、全基因结果、报告、原文配对证据、复现工具与既有日志。新交付路径 `docs/BioExplainR-development-delivery-0.4.0.9000-r11.zip`，完整性输出 `research/results/w00_baseline/biology-delivery-audit-result.json`；旧 r1–r10 保留。
- 仅原始 `discovery_donors_v1/tpm.txt.gz` 不进入新 ZIP；包内 `excluded_inputs` 保存原路径、121,575,832 bytes、完整 SHA-256、来源 URL 和下载命令。完整工作区 manifest 仍索引原始输入并核对 hash。
- current 审计补核 25 个唯一图表项、两个结果目录的完整成员/hash、候选供体分布、交互、共享细胞系与科学 ledger 的一致性；不把保存数值一致性称为本轮重新拟合。新增缺项/重复/失败状态、结果变更和未列成员拒绝探针。
- 下载工具增加 `--preserve-report`：恢复缺失 TPM 时逐段验证来源、CRC 与原 SHA-256，不改写包内历史 `range_download.json`，使封存清单仍可核对。已完成 5 项 current 审计测试与 2 项离线恢复测试；论文审计重新通过（25 项），网页索引 7 个本地链接全部有效，Python 语法检查通过。日志 `biology-handoff-*`。
- 实际验收入口为 `biology-delivery-*` 执行日志、`current_audit.json` 与 `historical_audit.json`；最终状态和 ZIP 字节/hash 见根交接，根交接独立进入 documentation 清单。
