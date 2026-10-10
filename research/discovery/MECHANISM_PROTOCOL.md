# SPARCL1 受体依赖与染色质占据检验 v1

2026-10-09，读取新计数/峰数据前固定。airway/GSE34313表达及GSE146017交互阴性已知；当前只检验既有候选SPARCL1，不根据新结果换基因。

## 1. GR降解与药理拮抗（GSE229084）

GEO元数据与原论文Gazorpak et al. 2023（doi:10.1038/s41467-023-44031-2）用于核实设计。A549为肺癌上皮细胞系，不能外推为ASM、患者或新独立供体。采用发布geneCounts（Salmon/tximport估计计数），不把整数化计数假装成原HTSeq计数。edgeR TMM/voom-limma模型处理非整数计数；设计含公开batch/set与处理组，不依据候选表达选择样本。

固定关注18h DMSO、18h KH-103/MIF/Cort113，以及16h上述药物预处理后2h DEX对应组。若元数据允许完整配对，用四组差中差分别检验DEX×KH-103、DEX×MIF、DEX×Cort113（同一SPARCL1三检验Holm family，α=0.05）。另提供DEX simple effect、各药物背景simple effect及CI，先核查候选有可测表达/通过固定全基因filterByExpr；未通过则主检验为不可估计，保留原测量与限制，不改变过滤以获得显著。

后给药（2h DEX后16h药物）仅作预定次要描述，与前给药混合不可冒称相同交互。FKBP5、TSC22D3、NR3C1为固定描述控制，不能替代候选。全基因voom趋势与经验Bayes估计；Python从发布计数核对候选输入、logCPM/WLS系数/CI/t代数和Holm，不自称独立重估TMM/voom。

## 2. ASM GR/RNAPII峰（GSE95632）

原文Sasse et al. 2017（doi:10.1165/rcmb.2016-0357OC）为单HASM2供体细胞系，GR/RNAPII vehicle/DEX各2培养样本；发布metadata写`mm9`却为人样本，属于重大assembly冲突。只有独立原文方法/峰染色体坐标/源分析注释能明确证明assembly时才做基因窗口归属；否则状态`unverified_assembly`，不把猜测hg19当证据。

固定SPARCL1全部已注释TSS±20kb作为GR窗口，TSS±5kb作为RNAPII窗口，同时公开基因体及±100kb敏感性。候选使用全部发布vehicle/DEX峰，MACS q≤0.05（narrowPeak -log10q≥1.301），仅称“发布峰在窗口重叠”，不将峰是否被调用当差异占据统计，不因control不成峰声称显著增加。输出每样本全部命中坐标、距离、q、signalValue和重复一致性；不以最大峰选基因。FKBP5/TSC22D3/KLF15为定位控制。

R GenomicRanges从原峰文件独立重算重叠与计数，Python负责主坐标实现。GR峰邻近不证明直接调控、enhancer连接或SPARCL1介导功能；受体药理有间接/脱靶/细胞环境边界。

## 3. 复现与解释

冻结protocol/script hash、UTC、元数据快照早于表达读取。全部输入bytes/SHA-256/CRC、映射冲突、不可估计与陰性结果保留；新目录拒绝覆盖。湿实验新增供体、rescue、位点reporter/CRISPR、SPARCL1敲低与蛋白/基质/功能终点本环境不能开展；公开干预重分析可以验证其中可检验环节，不声称完整机制已被证明。
