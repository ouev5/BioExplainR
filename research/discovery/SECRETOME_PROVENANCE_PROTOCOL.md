# Secretome来源差异与成人ASM公共材料续接

日期：2026-10-10。已知完整PXD033504及候选结果，属于结果后来源诊断，
不是前瞻独立验证。旧secretome seal、v0.12及2,905保护文件先核验。
新目录`research/results/discovery_secretome_provenance_v1/`，旧结果不覆盖。

## 固定来源诊断

1. 原Table S2八个proteome/secretome工作表与四个完整MaxQuant
   proteinGroups：PXD033514/033534 proteome24/72h，PXD033504 secretome24/72h。
   输入按SHA256冻结。原发表表的蛋白ID精确匹配优先，其次唯一Majority ID；
   不按基因择优合并蛋白组。每个ALL工作表逐组比较四数组的总Intensity，
   每个DIFF工作表在相同日期/条件/技术编号下比较LFQ、Intensity与iBAQ。
2. 对正值计算log2；原零保持缺测。发表四位小数LFQ容差0.000051，
   ALL总Intensity仅精确相等算一致。完全公开所有匹配/不匹配/不可对应位置。
   不将列置换或拟合变换所得一致用作修正原表；不重新赋值给候选。
3. 24h secretome另外比较前/后18列与每个蛋白的差值及相关性；
   仅作为错来源/转换线索。来源诊断没有假设检验或候选显著性筛选。
   即使大量一致也不足以自行宣布作者错误，原因需原文/版本或作者材料支持。

## 公开材料检索

Europe PMC固定六项TITLE_ABS检索：成人airway/bronchial smooth muscle
secretome/conditioned medium/proteomic，糖皮质激素与secreted protein，
ANGPTL2/FSTL3/FBN2与ASM；另检索PXD033504/原文来源。
每项100条/页，最多10页，保留完整状态和页数。PRIDE API固定四项关键词
检索airway smooth muscle、bronchial smooth muscle、ASM secretome、
smooth muscle dexamethasone（每项100条）；接口或返回不支持则记录失败。
对命中且可取得原文者保存原文、处理与数据链接。

适用新验证需要：人成人ASM、至少3独立可辨供体、GC/vehicle明确配对、
未按差异预筛的候选分泌/细胞外蛋白测量。无法核实或不满足记录具体原因；
检索未取得不等于数据不存在。HTPC、细胞系或转录组不改称成人ASM上清验证。
可行新数组须另冻结样本设计与完整统计family后才读取候选效应。

## 交付与核验

Python原表诊断、R独立从原数组和导出发表数值复核；实际BioExplainR
generic context保存来源和完整计数，不把来源诊断伪装成差异表达P值。
中文Markdown/自包含HTML/Word与CSV-XLSX、执行记录及新manifest。
新seal用开始时根rgo精确快照核对旧secretome的rgo依赖，其余原路径/hash。
新manifest绑定现根rgo；GitHub及外部上传继续暂停，在线模型调用0。
