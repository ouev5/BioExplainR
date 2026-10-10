# 54基因响应集合的成人ASM扩展检查

2026-10-09。负责人要求按审读建议继续。此前六重点候选的新成人ASM结果已知；
本轮扩展至原`priority_pass`全部54基因，属于结果后探索，不是盲法验证。

## 固定输入与单位

- 名单及顺序直接取`discovery_stable_response_v1/stable_response_screen.csv`
  中54条`priority_pass=TRUE`；不得按新数据改变名单、方向或排序。
- GSE130715原TPM与整数featureCounts，24文库、6成人供体、24h BUD 1µM。
  样本与年龄采用已核对的原样本表。GNAS不是NR3C1，供体数不与旧研究累加。
- 从HGNC完整公开表以唯一Ensembl→Entrez映射；无匹配、多Entrez或多候选
  指向同Entrez时不猜映射，公开缺测并保留检验位置。映射在候选提取前保存。

## 估计目标与规则

1. 主比较为对照siRNA背景BUD−vehicle。全部54项双侧配对t构成一个Holm
   family；另54项精确符号翻转形成对应family。点态95%CI；缺测P=1占位。
2. 次级比较为GNAS背景药物响应、GNAS×药物直接交互、vehicle下GNAS效应，
   54×3=162项Holm，参数与精确分别执行。原六候选的44项校正原样保留。
3. TPM估计量是供体内log2(TPM+1)差。逐供体公开；伪计数0.1/0.5/1、
   六轮留一供体配对统计用于敏感性，报告方向及范围，不增加n。
4. 从全部原计数重新构建~donor+kd*gc，filterByExpr、TMM、voom/eBayes。
   逐基因使用精确加权协方差与原moderation计算效应/SE/t/CI/P，主54/
   次162各Holm。过滤候选保留占位。六轮留一供体重做filter/TMM/voom，
   检查主响应方向；保存rank/df与不可估计结果。
5. 分别计数可测、与发现同向、6/6方向、TPM Holm通过且同向、计数模型
   Holm通过且同向，以及两者通过且全部方向/留一方向稳定。阈值均.05。
   不把模型一致称为额外独立生物验证；不合并不同尺度效应量。
6. 不改原12候选排序。新增值得追踪的基因按原54名单顺序给出，并明确它们
   是本轮扩展探索；精确小样本Holm的离散性限制与参数证据并报。

## 附加公开来源核查

核查PXD033514/PXD033534公开文件清单及相邻关联项目，寻找完整逐样本LFQ/
proteinGroups及样本映射；若只有原始质谱，不写成已取得完整数组。继续核查
GSE42538的metadata，先判断是否有完整遗传×药物因子，适用才另冻结统计。
保存URL、UTC、原响应/hash、失败与范围。不联系作者或上传文件。

## 审计与交付

Python直接提取原TPM并计算配对统计；R独立回读原TPM核对，Python从原
counts核对原测量与导出WLS、family校正、敏感性及汇总。实际应用BioExplainR
产生新项目/双语报告。先核验旧validation seal，再保存开始时rgo精确快照。
新研究`discovery_set_validation_v1`、新稿`paper_cn_v6`，拒绝覆盖旧封存。
更新根交接后旧validation文档依赖使用开始快照，其他原路径/hash。新稿v0.12
只引用实际结果，导出Word/PDF/HTML并核对图表/网页/清单。在线调用0。
