---
title: "成人气道平滑肌糖皮质激素响应集合的跨来源重复：PER2晚期抑制与时钟相关转录线索"
subtitle: "中文论文 v0.12 · 公开数据扩展验证 · BioExplainR 0.4.0.9000"
date: "2026-10-09"
lang: zh-CN
---

**作者、单位与通讯作者：**［待真实材料填写］

# 摘要

**目的：** 检验气道平滑肌（ASM）跨炎症／CEBPD干预背景响应集合的外部可重复性，并以公开时间、受体干预及蛋白证据界定候选的生物学解释。

**方法：** GSE146017四供体、31文库的全基因交互和四背景响应采用DESeq2与TMM/voom分析；按固定效应、模型和供体方向规则得到54基因集合及前12候选。GSE94335排除三个已知共享培养系后，保留13配对供体。新增GSE130715六成人、24文库检查完整54基因：主药物响应54项Holm，另三比较162项Holm；独立提取TPM并重新拟合计数模型，进行伪计数与六轮留一供体检查。早期ASM、成人DEX脉冲时间序列、A549药理、U2OS受体变体及人源HTPC蛋白资料分别分析，不合并实验单位或不同尺度效应。BioExplainR组织完整统计事实与范围。

**结果：** 原82,227项交互无一通过统一BH。54基因集合在新增成人ASM中53个可测基因均保持发现方向，50个6/6供体同向；45/54通过配对t与计数模型各自54项Holm且全部供体、伪计数及留一方向稳定。PER2配对差−0.934（点态95%CI −1.044至−0.824；Holm54=0.000165），六供体均下调；计数效应−1.405（Holm54=3.09×10⁻⁸）。LINC00607由唯一官方注释映射为Entrez646324，在新增来源可测，上调+0.526（Holm54=0.0233）。BMAL1／NPAS2上调与NR1D2／DBP／TEF下调同时得到新增供体支持。精确六供体符号翻转全家族未确认。新增早期ASM与受体遗传数据未确认成人PER2早期诱导或遗传依赖。完整HTPC原LFQ数组中METTL7A24／72h均7/7日期供体标签上调；原表七标签与发表六供体的范围冲突保留，发表六标签子集72h通过、24h未通过新112项校正。

**结论：** 公开数据支持成人ASM晚期转录响应的集合层面可重复性，并拓展时钟相关候选线索。现有证据支持PER2晚期抑制，尚不能确认成人同供体先升后降、节律相位／振幅、GR因果或收缩功能。新增价值是完整集合检查、供体分布和可定位证据整合；分析为结果后探索。

**关键词：** 气道平滑肌；糖皮质激素；PER2；响应集合；供体配对；公开数据重分析

# 1 引言

ASM具有收缩、分泌及激素诱导的转录响应。已有研究报告布地奈德（BUD）响应及CEBPD对该响应的调节[1,2]。公共数据再分析可进一步检验两类估计目标：处理是否存在调节交互，以及一组候选是否在所测背景中保持响应。交互不显著不证明背景等效，响应集合重复也不能替代机制检验。

糖皮质激素与细胞钟的关系已有实验基础。发育期人ASM及成人来源细胞的时钟表达和钙调控已被研究[3]，跨组织GR转录响应也已公开[4]。因此，我们关注具体成人供体的晚期响应及可核对的不一致证据，不主张首次发现激素调节生物钟。PER2、PER3及其他时钟相关转录变化本身不能证明节律相位、振幅或功能改变。

前轮利用GSE146017得到54基因跨四背景响应集，并固定前12候选，在GSE94335及药理／暴露安排中追踪[1,2,5,6]。本稿进一步检验完整54基因在GSE130715六成人供体中的重复程度[12]，并整合新增早期ASM、公开GR遗传及蛋白资料。统计由DESeq2、edgeR、limma完成[7–9]；BioExplainR提供事实及项目追踪，GEO提供表达来源[10]。

# 2 方法

## 2.1 来源、单位与分析阶段

表1列主要数据、独立单位及估计目标。GSE146017包含四非哮喘ASM供体、31文库，BUD100nM、TNFα10ng/ml、18h，含NT／CEBPD siRNA四背景；一个敲低失败条件未测序[2]。GSE94335为BUD100nM24h的混合非哮喘／致死性哮喘供体[1]。GSE130715六成人（19–54岁）×对照／GNAS siRNA×vehicle／BUD1µM24h，共24文库，年龄与配对由原论文表1及GEO核对[12]。GNAS与NR3C1为不同靶点。

所有分析是探索性公共数据二次分析。原交互扫描阴性后制定响应筛选，前12候选在其外部表达提取前冻结；时间增补在初步结果后追加。本轮完整54基因扩展在六重点候选结果已知后制定，属于结果后探索。名单、方向、比较、映射和检验家族在完整集合提取前保存，不称盲法或前瞻注册。各阶段原方案、冻结和修订见补充方法S1–S8、补充表S12及S18。

六新供体与旧GSE94335标签无exact重叠，但未知别名尚不能完全排除；不累加为19名独立供体。A549、HASM1、U2OS为细胞系培养实验；技术重复及平行RNA测量均不增加独立人数。不同药物、剂量、组织、培养与测量尺度分别记录。

## 2.2 原全基因交互与集合固定

GSE146017总计数≥10保留27,409基因，DESeq2设计`~donor+kd*bud*tnf`，保留原size factors与dispersion。三个预定交互×全部基因共82,227项，非有限P按1纳入统一BH[11]。另从原计数进行TMM/voom/eBayes。每模型四背景响应×27,409基因共109,636项统一BH，两个模型各自执行，非逐背景校正。

集合要求baseMean≥10；四背景DESeq2效应同向且每项绝对log2FC≥0.5；两模型每背景BH<.05且同向；每背景至少三个可用供体的log2规范化计数配对响应均同向；四轮留一供体voom保持方向。得到54基因，按四背景最弱绝对Wald统计量降序、EnsemblID升序排列，固定前12。完整集合及全部留一结果见补充表S1／S1b；原12候选估计见S2。两模型及留一使用同来源，不是独立生物学重复。

## 2.3 旧13供体外部检查

GSE94335的GEO donor字段逐文库唯一，原论文补充表E1的Cell Line恢复配对。28793/28796标注冲突或配对不明，维持原排除；原N012412两文库未出现在当前TPM。另排除N010912、N051911、N061311三个已知共享培养系，保留13供体（4非哮喘／9致死性哮喘、26文库）。

同基因全部transcript TPM相加，估计每供体BUD−vehicle的log2(TPM+1)差。12候选×合并／两病组／病组差共48项Holm；配对t及Welch给点态95%CI。精确符号翻转／标签枚举另48项Holm。原LINC00607无注释，P=1保留四校正位置但效应及CI为空。定义重复为合并校正通过且同向；原结果保留11/12冻结分母与11/11可测分母。补充表S3给全部响应／病组差，补充表S4给逐供体效应，补充表S5给伪计数和留一方向，补充表S11提供原基因测量，分别核对估计量与单位。

## 2.4 新成人ASM完整54基因检查

完整名单由原`priority_pass=TRUE`54条直接提取，不按新表现重排。官方HGNC按exact Ensembl、Approved状态提供唯一Entrez映射，在候选提取前封存；缺失、多重映射和输入缺测均保留位置。HGNC现官方名TMT1A对应METTL7A，BMAL1对应文献常用ARNTL，稳定ID不变。HGNC原响应与映射冻结保存在新研究`sources/`及`annotation_freeze.json`。

主比较为对照siRNA背景BUD−vehicle，全部54项双侧配对t为一个Holm家族；另54项精确符号翻转形成对应家族。次级比较为GNAS背景药物响应、GNAS×BUD直接交互、vehicle下GNAS效应，54×3=162项Holm，参数与精确分别执行。缺测P=1占位，CI为空。原六重点候选44项family原样保留，其P值不与新的54／162项混写。

主尺度为log2(TPM+1)供体配对差，逐供体公开。伪计数0.1／0.5／1及六次留一供体t／CI用于方向敏感性。从28,395原整数计数重新构建`~donor+kd*gc`，固定filterByExpr、TMM、voom/eBayes，逐基因采用`c'(X'WX)^−1c`与moderated方差／df得到精确加权对比。另六次留一供体重做过滤与完整模型。补充表S14保存两模型全部主／次级比较，S15逐供体效应，S16记录TPM伪计数／留一，S16b记录新计数留一，S17汇总完整54位置；各敏感性只检验所述稳健性。

分别统计可测、同向、6/6预期方向及参数／计数各自Holm<.05。综合支持标准预定为两模型同向且校正通过、6/6预期方向、三伪计数和六次TPM留一、六次计数留一均保持方向。此标准是模型和供体敏感性，不是预测性能或功能确认。完整216项对比、供体效应、敏感性及54条汇总见补充表S14–S17。

## 2.5 时间、受体和蛋白交叉证据

A549 GSE229084原47文库、四batch，固定过滤保留15,437基因，设计秩15／df32。12候选×DEX短暴露／三个药理交互共48项Holm，精确逐基因加权协方差。短安排16hDMSO→2hDEX，长安排2hDEX→16h继续DEX，总窗口均18h；直接长−短与HASM1 DEX24h−4h共24项Holm。HASM1缺逐时匹配vehicle，仅估计暴露条件差。补充表S6给A549药理全候选，S7长暴露边际，S8HASM1两处理条件，S9两个实验直接差；S10保留原12完整证据摘要，便于核对不重复与缺测。

GSE13168三配对供体8hFP采用GCRMA；PKI为PKA抑制转基因，非GR敲低[15]。GSE1357304hDEX／IL17A采用log2(RPKM+1)，匿名培养系年龄及配对不明。前者11×4=44、后者11×3=33项Holm；不拼接不同来源为同供体时间曲线。Bartman2021成人ASM DEX30min脉冲洗去后12／16／20／24h匹配vehicle，只有发表Tukey表，无个体Ct／协方差，保留作者统计不重建交互[3]。

GSE342887／342771为U2OS GR-KO背景WTα、AF2-E755R及IDRΔ1–398 rescue，CORT100nM90min；成熟RNA18／新生RNA17文库，各11×5=55项Holm，精确WLS。无empty-KO组，不能完整比较KO→WT rescue；两RNA测量为平行来源，且原文为未同行评审预印本[14]。

HTPC原论文及选中补充表报告六成人供体，每供体／条件三技术重复先在log2LFQ平均，原22项Holm及五共有供体直接差11项保留[16]。本轮从PRIDE固实7z取得完整未预筛proteinGroups、样本解码与参数，2998段HTTP206及6成员CRC核对；不声称整个容器上游SHA1通过。原数组每时点七日期供体标签、42列，与论文六供体／36列不同，额外10.09.19标签年龄及作者QC不明；原MaxQuant参数1.6.15.0与发表1.6.11.0冲突保留。

新蛋白名单在候选LFQ提取前固定为原54＋PER1／NR3C1控制，共56×2=112项Holm，精确检验另112。去reverse／污染／site-only，仅唯一单gene蛋白组；LFQ0视缺测、不填补，每供体／条件至少2/3技术测量，平均log2LFQ后配对，至少三供体可估计。发表六标签子集另112项；共有原标签直接72h−24h及仅发表共有标签各56项Holm作为结果后敏感性。两时点不同LC梯度／assay，直接差不是绝对蛋白累积动力学。全部规则、测量与范围冲突见补充方法S8、补充表S23–S25。蛋白／功能原文不把跨组织GR／cAMP或胎儿PER1／ARNTL钙实验归为成人PER2功能[3,13]。

## 2.6 实际R包应用与复核

新集合实际源码载入BioExplainR0.4.0.9000，构建TPM／计数各主／次级四context、项目与双语HTML，在线模型调用0；新完整蛋白另实际1context／双语报告。R从原TPM独立核对1,272测量及212可测比较；Python从原count核对1,272测量、1,060WLS数值、54／162校正和2,385项TPM敏感性数值及324条计数留一方向。R从原proteinGroups复核924LFQ测量、784供体行、11可测统计及112Holm，Python核对范围/成员CRC、144原与发表测量及敏感性。TMM／voom／moderation未跨语言重拟合。包事实计数保留完整分母，综合支持标准另在统计汇总应用。

前轮软件共同任务准确率与计时见补充表S13a，任务级配对区间见补充表S13b；SPARCL1不可估计时的固定FKBP5控制见补充表S13c，ChIP窗口重叠见补充表S13d。各自范围及失败完整保留，不作为本稿候选机制证据。新旧输入、脚本、错误、UTC、版本及hash均绑定新交付清单，旧成果原路径保留。

# 3 结果

## 3.1 原发现集合与旧来源重复

原82,227项交互无一BH<.05，最小统一BH=.3515，限定所测数据交互证据而非证明无作用。按另一响应估计目标得到54基因集合，前12依次为PER3、ANGPTL2、LINC00607、TEF、METTL7A、TSC22D3、FSTL3、GCNT1、MAOA、ZBTB16、FKBP5、PER2。图1及补充表S1／S2展示原背景证据，保留原排名。

旧13供体11个可测候选全部通过各48项t／精确Holm，原LINC00607缺测。因此旧来源仍为11/12冻结、11/11可测；10候选13/13同向，GCNT1为12↑／1↓。PER2−.915（95%CI−1.048至−.782；tHolm1.55×10⁻⁷），PER3−2.082；METTL7A+2.044、MAOA+2.561。补充图S1显示全部固定候选的旧13供体平均响应与点态区间，保留缺测和GCNT1例外；病组差全部未通过，不证明疾病来源等效。

## 3.2 完整54基因在六成人中的扩展检查

表2公开完整分母及各检查层级，图2按原集合顺序展示六供体响应。54基因全部取得唯一HGNC映射，53个在原计数／TPM可测，LINC03140未出现在原输入，保留缺测位置。53/53平均响应与发现方向一致，50/53六供体全部预期方向。主配对t为45/54通过Holm，计数模型为51/54；45/54同时满足两模型、全部供体及全部敏感性方向标准。

综合支持比例为45/54冻结分母（83.3%）及45/53可测分母（84.9%），是所测集合的描述性比例，不是人群预测性能。计数模型秩9、df15，28,395基因保留14,692，六次留一模型秩8／df12。52个保持TPM伪计数／留一方向，52个保持计数留一方向；GABBR2均值接近零且留一不稳定。八个可测基因未满足综合标准，包括NEFM、GABBR2、VGLL3、LRRC15、SEMA6D、PTGER2、ANKRD1、TIPE3，全部原估计保留于补充表S17。

六供体双侧精确符号翻转最小P=2/64=.03125，54项Holm全家族无一通过。这反映该小样本完整家族的分辨率限制；参数与计数证据、精确未确认均同时报告，不把它们合称稳健非参数确认。

## 3.3 时钟相关线索与LINC00607的新增可测证据

表3按原集合排名列时钟相关基因及LINC00607。PER2−.934（CI−1.044至−.824；Holm54=.000165）、PER3−2.311（Holm54=.000934）均6/6下调。新增成人ASM亦显示BMAL1+1.138（.00474）、NPAS2+.727（.000596）、NR1D2−1.345（.000937）、DBP−1.060（.00679）、TEF−1.051（.000165），各6/6预期方向，并通过计数与留一方向标准。这是事后描述的多个时钟相关转录线索，不是预定通路富集检验或节律模型。

LINC00607在旧GSE94335缺注释，旧airway DEX18h不支持（−.082、BH=.915），两条限制保留。本轮官方Ensembl→Entrez646324唯一映射后，在GSE130715可测：配对差+.526（CI+.302至+.750；Holm54=.0233），6/6上调；计数+.776（Holm54=8.10×10⁻⁵），全部敏感性方向保持。此结果说明它并非在所有外部来源均不可测，但不更改旧缺测分母，不证明所有条件泛化或特异异构体机制。

METTL7A／TMT1A、MAOA、ANGPTL2、FSTL3延续各六供体同向。新完整54family的效应不变，校正P不同于旧44family；其单位与来源分别标注。表3与补充表S17不按新增显著性重新替换原12名单。

## 3.4 时间与GR证据收束

A549短DEX2h的PER2+1.092，KH103／MIF／Cort113三直接药理交互−.935／−.972／−.922，原48项Holm通过；长暴露效应+.175未显著负向，直接长−短−.917（Holm24=1.45×10⁻⁹）。补充图S2并列其药理差中差及短／长暴露效应，强调总培养同18h；HASM1直接24h−4h−1.651（参数Holm24=.0139），精确校正未确认。结果支持这些培养条件的差异，非成人同供体方向反转。

新增早期ASM PER2：GSE1357304h+.111（Holm33=1），GSE131688h+.691（Holm44=1），均未确认早期诱导。Bartman2021成人匹配vehicle的24h药物对比原Tukey=.7831，DEX组24h−12h=.0498是处理组内时间差，不能替代药物×时间；原Ct缺失无法重算交互。

U2OS遗传变体中PER2成熟RNA AF2×药物−.337（Holm55=1），新生RNA−.424（.348），未确认受体变体依赖。PER1控制的AF2交互分别−.776（9.05×10⁻⁶）、−1.569（.00383）通过，但不替代PER2；补充图S3展示两RNA直接遗传交互及各点态区间，阳性控制与PER2分别解释。GNAS×BUD候选直接交互亦不能转写为GR因果。图3整合上述不同证据层级，新增ASM检验见补充表S19，受体遗传全表见补充表S20，原选中人蛋白数组统计见补充表S21。

## 3.5 蛋白支持、缺测与范围核查

人源HTPC原选中数组中METTL7A24h+.921（Holm22=.0437）及72h+1.504（.00261），均六供体上调。精确Holm=.688；五共享供体直接72h−24h+.688（Holm11=.412），原处理表未确认进一步增幅。原数值不变。

完整原LFQ数组新112项检验中11项可估计、4项通过，为METTL7A与FKBP5两时点。METTL7A24h+.830（点态CI+.610至+1.049；Holm112=.00990）及72h+1.396（+1.287至+1.506；7.96×10⁻⁶），均7/7原日期标签上调，全部精确Holm未确认。发表六标签敏感性24h+.834（Holm112=.0574）未通过，72h+1.391（.000160）通过。六原共有标签直接药物响应差+.652（Holm56=.00268）；仅五发表共有标签+.657（.0237），但两assay/梯度差与缺测处理限定为探索性响应差。

原表与发表METTL7A/FKBP5的144技术测量比对：142非零原LFQ log2与发表值在四位小数舍入内一致，2项原LFQ0有发表有限值，未取得其作者处理机制；本轮不填补。额外供体标签与版本冲突无法由统计消除。缺少原LFQ的PER2／PER3不作蛋白阴性，跨组织及同来源重分析不增加独立供体队列。完整文件列表见补充表S22，主原112项见S23，发表子集见S24，原／发表共有标签直接差见S24b／S24c，原发表标签差异见S24d，原测量与缺测见S25、逐格原发表比较见S25b；补充表S26归纳六种METTL7A估计目标及分母，补充图S4显示本轮无预筛METTL7A全部供体标签。

PXD081613的PRIDE human与实际mouse搜索／注释冲突仍未解决，PER2缺测不记阴性。ASM GRαsiRNA／rapidcAMP与胎儿PER1／ARNTL Ca²⁺原文已核对[3,13]，没有成人PER2／METTL7A候选功能。GSE42538补获元数据：四女性供体子宫内膜基质细胞、NT／GR／MRsiRNA共12数组，所有条件均含cAMP／孕酮／可的松蜕膜化四天，无无药物因子，不能估计完整NR3C1×GC交互；本轮按设计排除，未进行候选统计。

# 4 讨论

## 4.1 集合层面可重复性与新增价值

本稿从少数候选扩展到原完整54基因，新增六成人来源的53个可测平均响应全部保持方向、45个满足较严格的参数／模型／逐供体敏感性标准。这加强所测晚期响应集合的可重复性，并明确公开未满足标准与缺测。药物剂量、培养来源及背景仍不同，因此并非所有四背景交互的外部复制。

PER2／PER3晚期抑制得到新的成人供体支持。BMAL1、NPAS2上调与NR1D2、DBP、TEF下调拓展候选范围，LINC00607新增可测响应解决一个来源的注释缺口。已有激素／时钟文献[3,4]及本轮检查强调：时钟相关转录响应与周期性节律是不同目标；不能从一次24h终点估计相位、振幅或同步化。以上线索可用于公开数据后续检验，而非完整时钟机制的确认。

## 4.2 推断与不一致证据

四供体筛选、两模型共享样本、方案在初始阴性后制定，存在选择影响；本轮又在重点候选已知后扩展，因此全研究多阶段未统一控制所有潜在假设。各54／162家族控制只对应本阶段定义。CI为点态，参数检验依赖供体效应分布，小样本精确全家族未确认。供体标签无exact重叠不保证别名全部排除，不累加独立供体人数。

原12候选排名保持，新增时钟基因作为完整集合检查后的解释，尚无预定基因集统计。TPM对数差、count log2FC、RPKM/GCRMA及LFQ尺度不能直接合并幅度。54基因不是疾病分类器；阴性病组差不证明等效，53/53方向也不是未来人群准确率。GABBR2等未满足标准及旧TEF微阵列不重复、LINC00607旧airway阴性共同限定泛化。

时间相关证据被进一步收束：成人早期诱导未通过，成人DEX脉冲同时间药物对比未支持，A549与HASM1暴露条件差不能拼接成人轨迹。U2OS预印本遗传变体缺空KO，候选PER2未确认；A549药理效应也不能替代ASM遗传因果。完整人蛋白比选中表扩大原数组范围，METTL7A72h在发表标签子集中仍通过；24h对范围/缺测规则敏感。原七标签/发表六人、MaxQuant版本及两个缺测填入值冲突均未获作者确认，不能把新数组重算当新队列或ASM功能。候选功能未得到新增直接证据。

## 4.3 后续纯计算方向

在不能开展新湿实验的约束下，下一步优先寻找同供体成人ASM逐时vehicle与GC、完整NR3C1×GC遗传因子及未按差异筛选的候选蛋白数组。先核对年龄、映射、重复、处理完整性与下载可用性，再另冻结估计目标；缺失数据公开为证据缺口。蛋白搜索输出应保留成员CRC和原样本映射，不能把部分压缩包采集当完整下载验收。

进一步的跨组织、公共人群或通路分析需要针对各自估计目标的新方案。可追踪METTL7A、LINC00607及新增时钟相关响应，但不以数据库连接或峰窗口重叠直接构建因果机制。真实作者及最终科学／图稿审阅仍需真实人员完成。

# 5 结论

成人ASM公开数据中，原54基因集合的53个可测平均响应保持方向，45/54经供体配对、计数模型及方向敏感性检查获得支持。PER2／PER3晚期抑制、多个时钟相关候选及LINC00607新增可测响应提供具体追踪线索。新增早期、时间、遗传与蛋白检查同时收紧机制表述。BioExplainR保存完整分母、独立单位及解释边界；结果支持所测晚期转录响应，不确认成人节律／GR／功能因果。

# 数据与代码可用性

原研究与v0.11原路径保留；新增集合分析、HGNC原记录、原TPM／count依赖、模型、供体表、原错误、范围采集及双语项目位于`research/results/discovery_set_validation_v1/`。此前验证目录`discovery_validation_v2/`及报告原样保留。新稿`docs/paper_cn_v6/`包含Word／PDF／自包含HTML、表图与独立清单；复现与保存结果核验见README。

BioExplainR0.4.0.9000为MIT软件。正式公开仓库／release／DOI尚待实际发布；本稿为中文工作稿。**作者贡献、基金、利益冲突、适用伦理与数据使用说明：**［按真实材料填写］。AI助手参与代码与文字整理，统计来自实际公开数据运行；最终科学与作者确认［待填写］。

# 参考文献

1. Kan M, Koziol-White C, Shumyatcher M, et al. Airway smooth muscle-specific transcriptomic signatures of glucocorticoid exposure. Am J Respir Cell Mol Biol. 2019;61:110–120. doi:10.1165/rcmb.2018-0385OC.
2. Kan M, Sun M, Jiang X, et al. CEBPD modulates the airway smooth muscle transcriptomic response to glucocorticoids. Respir Res. 2022;23:193. doi:10.1186/s12931-022-02119-1.
3. Bartman CM, Matveyenko A, Pabelick C, Prakash YS. Cellular clocks in hyperoxia effects on [Ca2+]i regulation in developing human airway smooth muscle. Am J Physiol Lung Cell Mol Physiol. 2021;320:L451–L466. doi:10.1152/ajplung.00406.2020.
4. Piechota M, Zieba M, Borczyk M, et al. A cross-tissue transcriptomic approach decodes glucocorticoid receptor-dependent links to human metabolic phenotypes. BMC Genomics. 2025;26:462. doi:10.1186/s12864-025-11676-w.
5. Gazorpak M, Hugentobler KM, Paul D, et al. Harnessing PROTAC technology to combat stress hormone receptor activation. Nat Commun. 2023;14:8177. doi:10.1038/s41467-023-44031-2.
6. Masuno K, et al. Expression profiling identifies Klf15 as a glucocorticoid target that regulates airway hyperresponsiveness. Am J Respir Cell Mol Biol. 2011;45:642–649. doi:10.1165/rcmb.2010-0369OC.
7. Love MI, Huber W, Anders S. Moderated estimation of fold change and dispersion for RNA-seq data with DESeq2. Genome Biol. 2014;15:550. doi:10.1186/s13059-014-0550-8.
8. Robinson MD, McCarthy DJ, Smyth GK. edgeR: a Bioconductor package for differential expression analysis of digital gene expression data. Bioinformatics. 2010;26:139–140. doi:10.1093/bioinformatics/btp616.
9. Law CW, Chen Y, Shi W, Smyth GK. voom: precision weights unlock linear model analysis tools for RNA-seq read counts. Genome Biol. 2014;15:R29. doi:10.1186/gb-2014-15-2-r29.
10. Edgar R, Domrachev M, Lash AE. Gene Expression Omnibus: NCBI gene expression and hybridization array data repository. Nucleic Acids Res. 2002;30:207–210. doi:10.1093/nar/30.1.207.
11. Benjamini Y, Hochberg Y. Controlling the false discovery rate: a practical and powerful approach to multiple testing. J R Stat Soc B. 1995;57:289–300. doi:10.1111/j.2517-6161.1995.tb02031.x.
12. Nuñez FJ et al. Glucocorticoids rapidly activate cAMP production via Gαs to initiate non-genomic signaling that contributes to one-third of their canonical genomic effects. FASEB J. 2020. doi:10.1096/fj.201902521R. GSE130715；PMC7027561.
13. Koziol-White C et al. Budesonide enhances agonist-induced bronchodilation in human small airways by increasing cAMP production in airway smooth muscle. Am J Physiol Lung Cell Mol Physiol. 2020. doi:10.1152/ajplung.00393.2019. PMC7052668.
14. Edmondson A et al. Post-transcriptional glucocorticoid receptor signalling synchronises circadian rhythms. bioRxiv. 2026;v2，未同行评审. doi:10.64898/2026.08.12.743743. GSE342887／342771；全文未取得，引用限公开数据与元数据。
15. Misior AM et al. Glucocorticoid- and protein kinase A-dependent transcriptome regulation in airway smooth muscle. 2009. PMC2701960；GSE13168.
16. Stepanov YK et al. Profound Effects of Dexamethasone on the Immunological State, Synthesis and Secretion Capacity of Human Testicular Peritubular Cells. Cells. 2022;11:3164. doi:10.3390/cells11193164. PXD033514／033534；PMC9562650.

# 图表

## 表 1 数据、单位与可估计范围

::: {.set-table-1}
:::

**表注：** 各行供体／培养／文库单位不相加；新旧供体别名未完全核实。A549总窗口同为18h；早期与晚期不同研究不拼接时间曲线。

## 表 2 完整54基因的检查层级与分母

::: {.set-table-2}
:::

**表注：** 主比较均对照siRNA背景BUD−vehicle。参数／计数各54项Holm；综合标准同时要求两模型、六供体及全部方向敏感性。精确校正未确认与参数证据同时公开。

## 表 3 时钟相关候选与LINC00607的新增成人响应

::: {.set-table-3}
:::

**表注：** 按原集合排名展示，非新显著性排序；BMAL1文献别名ARNTL。CI点态，TPM差与计数效应尺度不同。此列表为事后候选解释，不作通路或节律确认。

## 图 1 原固定候选的四背景响应

![图1原固定候选](paper_cn_v6/figures/Figure_1.png){width=16cm}

**图 1.** 原12候选排名和四背景DESeq2效应，复用已封存图稿。每模型109,636项统一BH，进一步方向／敏感性筛选；响应保留不等于四背景等效。

## 图 2 完整54基因的六成人逐供体响应

![图2完整集合](paper_cn_v6/figures/Figure_2.png){width=16cm}

**图 2.** 按原集合顺序分两列展示主BUD响应，圆点为各供体log2(TPM+1)配对差，黑方块为均值。绿色标签为预定综合标准通过，灰色为未通过，缺测原位置保留。53可测平均方向一致、50全部供体同向、45综合支持；不作为节律或未来预测性能。

## 图 3 候选证据层级与未确认范围

![图3证据层级](paper_cn_v6/figures/Figure_3.png){width=16cm}

**图 3.** 各来源及估计目标分别显示：成人晚期响应、早期ASM、A549药理、成人药物×时间、GR遗传及人源蛋白。支持／未确认／未可估计按实际结果区分；非定量汇总、非合并效应量、非机制因果图。
