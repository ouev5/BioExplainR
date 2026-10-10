# PXD033504 完整分泌蛋白组续接方案

2026-10-10，探索性公开数据重分析。读取 rgo.md、v0.12 主稿/补充及原来源记录后制定。
旧 ASM 转录结果及发表 secretome 检测表已知；本轮候选原 LFQ 尚未提取。

## 输入与独立单位

- PXD033504 两个 SEARCH 容器：HTPCsSecretome_24h_1uMdex.7z、
  HTPCsSecretome_72h_1uMdex.7z。先保存清单、成员/固实块位置，再取得完整
  proteinGroups、原样本解码、参数和 summary（及可用 mqpar）。
- HTTP 206、Content-Range、长度、Last-Modified 与逐段 SHA256 校验；成员 CRC。
  部分容器不声称整个上游 SHA1 通过。完整是处理蛋白数组，不是重新搜索所有 RAW。
- HTPC，DEX 1 µM 对溶剂对照，24/72h。供体以原解码日期标签为准；每条件
  三技术重复，技术测量先聚合、不作为独立 n。论文六供体与原标签若不一致保留。
  同原 proteome/发表表来源，跨组织线索不增加独立 ASM 队列。
- 旧 v0.12 先核验，保存根 rgo 精确快照；新输出独立目录
  research/results/discovery_secretome_v1，不覆盖旧清单/科学文件。

## 完整数值及家族

1. 完整蛋白组：Reverse、Potential contaminant、Only identified by site 的 +
   排除并逐行保存 QC。其余所有 proteinGroups（包括多基因组）均纳入全数组
   family，24/72h 两个数组的所有 QC 合格组统一 BH；不足测量以 P=1 保留位置。
   LFQ≤0 缺测不填补；每供体/条件至少 2/3 可测，平均 log2 LFQ；至少三配对
   标签双侧一组 t 检验、点态 95% CI；精确符号翻转另同分母 BH。
   单位为蛋白组，不能把多基因组分配为唯一基因效应。
2. 固定候选：沿用原 54 基因官方注释，加 PER1/NR3C1 控制，共 56×2=112
   双侧检验，统一 Holm；精确检验另112。只允许唯一 singleton Gene names，
   别名 METTL7A/TMT1A、ARNTL/BMAL1；多组/未检出/不足配对保留位置、P=1，
   效应/CI 留空。ANGPTL2、FSTL3 为重点解释，完整56公开。
3. 敏感性：发表 S6/S8 中每时点原六标签子集、严格 3/3 技术测量各112 Holm；
   主候选留一标签只检查方向，不当外部重复。直接72h−24h为同日期两时点药物
   响应差，56项 Holm，至少三共同可测标签。两个时点分开 MaxQuant 处理，
   即使 LC 梯度相同也不解释为绝对分泌速率、时间交互因果或累积动力学。
4. 与发表 ALL/DIFF 表匹配全部 protein IDs/Gene names、原检测/选中差异范围；
   候选若在选中表才逐格比较数组，不从选中表缺失推断零效应。
5. ANGPTL2/FSTL3 等分泌注释采用 UniProt 原公开响应，保留证据/功能范围；
   培养上清蛋白丰度不等于分泌速率，可受细胞数、死亡、释放、降解和归一化影响。

## 复核与交付

Python 输出完整原测量、供体效应、QC/检测/全 family 结果和版本；R 独立从原
proteinGroups 和解码重建所有 QC 合格组的样本映射、测量、供体配对、t/CI、
精确/BH/Holm，及候选/敏感性/直接差。实际 BioExplainR 离线 context/project/
双语报告保留完整分母与范围，在线调用0。
中文结果报告、CSV/XLSX、图、复现/保存验证命令、新清单及 rgo 更新。
保留真实错误/下载重试；旧2,905保护文件与v0.12原科学依赖再次逐hash核对。
