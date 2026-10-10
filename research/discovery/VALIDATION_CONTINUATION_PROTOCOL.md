# 成人 ASM 时间、GR 遗传与候选蛋白／功能续接方案 v1

制定日期：2026-10-09。方案在 v0.11 结果已知后制定，属于结果后探索。
主候选固定 PER2；次候选 PER3、METTL7A、MAOA、ANGPTL2、FSTL3。
FKBP5、TSC22D3、DUSP1 为技术／GR 响应控制，不替代候选终点。

## 1 检索与可用性核验

- 保存 Europe PMC 与 GEO 的完整查询、分页响应、UTC、URL、hash 和失败。
- GEO 搜索限制为 series；同时使用 airway / bronchial smooth muscle、human
  smooth muscle + steroid、time/circadian 以及 NR3C1/GR genetic intervention。
- 文献分开检查时间序列、受体遗传干预与候选蛋白／功能，核对原文的年龄、
  组织、供体、匹配 vehicle、时间、剂量及实际敲低靶点。
- fetal/developing ASM、上皮／肿瘤系、单培养系、药理 GR 干预与其他基因敲低
  分开标记。未检出只是本次检索范围内未找到，不证明资料不存在。
- GSE146017、GSE94335、GSE34313、GSE229084、GSE95632、airway/GSE52778
  是已知开发或已分析来源，不当成新独立验证。新 series accession 不自动
  等于新供体；必须核对 donor/cell-line 别名及原文。年龄未知不写成人已核实。

## 2 新公开表达分析

先完成 metadata 可行性筛查，另保存 design freeze，再读取候选表达。
保留所有符合固定 exact-symbol / unambiguous annotation 的探针，逐探针公开，
基因层面以探针中位数汇总，不按响应选择探针。使用发布的 log2 处理值，
先核对处理说明；原强度如需 log2 应在 freeze 说明。

若存在逐时间匹配 vehicle 与同一供体处理，主估计量为每供体的晚−早响应
差：[(GC−vehicle)_late − (GC−vehicle)_early]。供体为独立单位；培养／技术
重复先在同条件同供体平均，不增加 n。时间、处理与供体字段无法唯一映射时
不猜配对。无逐时 vehicle 只能估计暴露条件差，不能称药物×时间交互。

每个新数据集的候选与控制×预定比较组成完整 Holm family；缺测／不可估计
以 P=1 占位但 CI 留空。公开原 P、校正 P、点态 95% CI、个体差与效应方向。
小样本附精确符号翻转／标签置换，不按结果选择主检验。新数据若只含晚期
终点，作为晚期响应的新增外部检查，不能补齐独立成人时间序列。

若有 NR3C1 遗传×GC 因子，估计直接交互 (GC−vehicle)_KD −
(GC−vehicle)_control；分别报告受体敲低、候选 RNA 与蛋白验证及 rescue。
其他靶点 siRNA 或 RU486/KH103 等药物不能记为 NR3C1 遗传验证。

## 3 实验室交付标准

公开数据不能替代新湿实验。形成可直接执行的供体登记、随机化、逐时
vehicle、GR 两条独立 siRNA/CRISPRi、耐敲低 rescue、候选蛋白及 Ca2+／收缩
方案；RNA、蛋白与功能交互分别检验。所有供体、失败、排除与阴性保留。
节律与单次药物响应分开：相位／振幅需多周期密集测量或持续 reporter。
提供功效敏感性计算，不用已见的显著效应直接保证新实验成功。

## 4 完整性

新目录 `research/results/discovery_validation_v1/`；原结果和 manifest 不覆盖。
本轮保存开始时的 rgo 精确快照；若更新根交接，用新清单显式绑定旧快照验证
v0.11 文档依赖，其他旧科学文件仍核对原路径／原 hash。Python 与 R 独立
复核原候选数组、比较、校正和功效计算。实际 BioExplainR 离线应用单独记录。
GitHub／外部上传继续按交接暂停。
