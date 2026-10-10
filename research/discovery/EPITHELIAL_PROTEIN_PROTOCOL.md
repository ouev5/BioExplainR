# 已下载上皮蛋白数组的固定集合检查

2026-10-10。续接公开数据实际下载，独立输出目录
`research/results/discovery_epithelial_protein_v1/`。已有ASM转录、HTPC蛋白结果已知，
本轮为结果后、跨细胞来源的探索性检查。方案与输入hash在提取候选丰度前冻结。

## 名单、来源与单位

- 精确复用既有54基因顺序、方向及两个控制PER1/NR3C1，共56个位置。
  官方TMT1A使用已保存别名METTL7A，BMAL1使用ARNTL；不按新结果挑蛋白组。
- PXD063431为A549癌源上皮系、48h DEX与未处理各4培养孔。数字后缀不能
  证明配对，主分析为独立两组Welch t，n为培养孔，不是供体或独立实验批次。
- PXD029135为10人临床ICS前后×polyIC的40样本，原作者SRDF与community SDRF
  核对解码。三个额外imiquimod样本不进入本轮比较。临床前后不是培养GC/vehicle。
  不对病毒、感染或病原体结果作统计推断。

## 预处理、身份和缺测

1. A549去Contaminant非False、Exp q-value Combined>.01或缺失、unique peptides<1。
   强度非正/NA为缺测，不填补。主分析log2强度以全QC且8孔均有值的蛋白行
   为公共参考，逐列减参考中位数、加8列参考中位数的平均值；不使用候选选参考。
   未额外归一的log2强度为预定敏感性，不替代主结果。
2. HBEC保持公开median-normalized导出数值，不二次log、不重归一、不填补。
   数值量级兼容log2，但没有作者精确转换日志，效应标为“导出尺度单位”，
   不自行宣称已复现NormalyzerDE或换算倍数。
3. HBEC任一Protein.IDs带CON__/CONTAM_/REV__拒绝；从全部NX FASTA片段固定
   提取基因token（NX accession后第二个说明token之后的基因），要求所有可解析
   NX条目一致为单一基因。无完整注释/混合基因组不用于候选映射；保留原因。
4. 候选需要唯一QC蛋白行且精确基因/允许别名匹配；多行保持ambiguous，不选最显著。
   A549每组至少3/4有效孔，HBEC每比较至少3有效同人配对；缺测/歧义保留位置。

## 比较、校正与敏感性

- A549：DEX−NT，56双侧Welch t统一Holm；精确未配对标签置换另56 Holm，
  统计量为均值差，保留实际有效样本数。逐孔量值、点态95%CI、df和SE公开。
  相同56位置的未额外归一敏感性单独Holm，不增加证据n。
- HBEC主：未刺激post−pre，56配对t/Holm；次：polyIC下post−pre及
  同人(post−pre)_polyIC−(post−pre)_unstimulated，共112配对t/Holm。
  每个family另做完整2^n双侧均值符号翻转/Holm。互动要求同人四格齐全。
- 全数组：A549全部QC行一个BH；HBEC全部QC行×上述3比较一个BH。
  不可估计P=1占位；不因为不可测删除family位置。未确认不记作蛋白阴性。
- HBEC逐人效应、每比较留一人方向及T2-high/low描述性均值与有效n公开；
  不追加T2显著性检验，不合并两个组织的P/效应或供体数。
- 记录每个候选与原ASM转录发现方向的描述性一致性；同向并不等于响应被验证。

## 复核、应用与保存

Python实际统计，base R从两张原表、SRDF及冻结名单独立重做身份、原测量、
预处理、t/CI/精确P、全数组BH、候选Holm和缺测计数。实际BioExplainR源码
生成3个上下文、项目和双语离线HTML（在线调用0）。中文FINDINGS和完整CSV/
XLSX提供可读入口。新清单绑定本轮输入、代码与结果。

开始快照`rgo_before_epithelial.md`保留根文档，旧下载封存的rgo依赖只核对
`discovery_public_download_v1/rgo_before_download.md`；其他旧依赖按原路径/hash。
核验旧下载157文件、25完整文件和其v0.13绑定302记录/ZIP，不把该范围声称为
本轮全历史树重审。更新rgo只追加最新段落，保留全部历史文字。
