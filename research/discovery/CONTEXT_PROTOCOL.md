# SPARCL1 糖皮质激素响应的环境依赖性：补充重分析方案 v1

日期：2026-10-08。本方案在本轮读取 GSE146017 的表达矩阵或候选统计结果前保存。已阅读 GEO series 元数据及 Kan et al. 2022 原文，已知实验设计与原文重点；不是预注册或全部资料盲法。既有 airway/GSE34313 SPARCL1 结果已知。

## 科学问题与新颖性

Himes et al. 2014（doi:10.1371/journal.pone.0099625）表1已经报告 SPARCL1 地塞米松响应。本文不把重复上调当作首次发现。补充问题为：**SPARCL1 的布地奈德响应是否受 TNFα 环境或 CEBPD 敲低调节？** 若得到支持，贡献为公开干预数据的候选特异性、条件依赖重分析；若不支持，同样报告。

GSE146017（Kan et al. 2022，doi:10.1186/s12931-022-02119-1）包含四个非哮喘供体、NT/CEBPD siRNA、vehicle/BUD/TNFα/BUD+TNFα，原始32条件有1个因敲低失败未测序，发布31文库。BUD 100 nM、TNFα 10 ng/ml、18 h。这是已发表的实验干预，本文不新增湿实验；不同 accession 不证明与 airway 的供体无重叠。

## 固定候选、检验与多重性

- 唯一生物学候选：ENSG00000152583 / SPARCL1，延续此前固定规则，不按本轮结果换基因。
- 全部发布 HTSeq 基因计数与全部31样本用于 DESeq2；仅保留总计数≥10特征，标准 median-ratio size factors，默认 dispersion/Wald 拟合，关闭自动 Cook's replacement（minReplicatesForReplace=Inf）。基因 ID 去除版本号，重复则停止；不按显著性选择样本、探针或归一化。
- 设计：`~ donor + kd * bud * tnf`，NT、无BUD、无TNF为参考，full-rank 校验。供体为区组，文库不是31个独立人。
- 三个候选内、双侧预定交互检验组成同一 Holm family（α=0.05）：
  1. 主检验：NT 背景下 BUD×TNFα，衡量炎症环境对 BUD 响应的差中差。
  2. 次检验：无 TNFα 背景下 BUD×CEBPD 敲低，衡量敲低对 BUD 响应的差中差。
  3. 次检验：BUD×TNFα×敲低，衡量炎症调节是否随敲低改变。
- 同时公开四个 BUD simple effects 的 log2FC、Wald P 与95%CI；用于解释响应，不从“一个显著另一个不显著”推出交互。全基因交互表及各交互的 BH 校正提供探索性背景，不用全表筛选替换候选或主检验。
- 预定检查基因：CEBPD（敲低效果）、FKBP5 和 TSC22D3（经典糖皮质激素响应），作为描述性控制，不扩充候选主张。

## 小样本与实现复核

从规范化计数计算 `log2(count + 1)`，按真实供体配对计算上述差中差。完整条件供体纳入对应敏感性分析，缺失不填补；报告每供体值、配对 t CI/P 和全部2^n符号翻转的双侧精确 P。若n=4，双侧精确P最小为0.125，故无法作为P<0.05确认；它量化方向稳定性并提醒低独立样本量。该检验依赖供体级对称/可交换符号假设，与计数模型是不同估计量，不要求数值一致。

R/DESeq2 主拟合；Python/SciPy 从原发布计数复核候选测量、R size factors应用、所有供体差中差、t/CI/枚举P和Holm，独立重算 Wald normal P/CI及各family BH。不称Python独立重拟合DESeq2。保留元数据、全部输入、协议/脚本hash、运行UTC、版本及结果hash，输出目录拒绝覆盖。

## 结论边界

条件依赖的 mRNA 响应支持后续机制假设，不证明直接 CEBPD 结合、直接 GR 靶点、SPARCL1 功能、蛋白分泌或临床效应。siRNA 干预可能含间接/脱靶效应；模型控制 donor 基线不消除 donor-specific response 不确定性。强结论需新供体、CEBPD rescue、GR干预及SPARCL1蛋白/基质功能终点。正、负和不确定结果均进入正文。
