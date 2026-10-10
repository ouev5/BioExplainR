---
title: "BioExplainR 中文论文 v0.11：补充材料"
date: "2026-10-09"
lang: zh-CN
---

本补充对应生物学主线初稿。S1–S6为分析阶段与复现细节；S13保留前轮共同任务与SPARCL1核验的背景及边界。旧v0.10软件主稿与图表仍独立保留。参考文献[1–11]与主稿一致，S13来源在该节单列。

# 补充方法

## S1 初始全基因交互方案

以下为当时方案/修订原文；本稿口径澄清见S6。


### 问题与已知信息

本轮目标是发现候选特异的 **TNFα 改变布地奈德响应／CEBPD 敲低改变响应**，而非再次报告已知的 SPARCL1 上调。GSE146017 原研究、旧 SPARCL1 结果及三个全基因结果文件的存在已知；本方案保存前未排序或筛选这些全基因结果。该工作是已发表数据的探索重分析，不是新湿实验或注册确认研究。

### 固定发现分析

1. 读取封存的 GSE146017 DESeq2 全模型，保持 `~ donor + kd * bud * tnf`、31 文库、4 供体、原总计数≥10过滤及所有原 size factors/dispersion。不改变旧模型或候选过滤。
2. 全基因三个交互：NT 背景 BUD×TNF、无 TNF 背景 BUD×CEBPD KD、三因素交互。**三个交互 × 全部保留基因组成一个 BH family**；非有限 P 记为 1，报告原 P 和 pooled BH。不以单一交互的独立过滤 BH 代替 pooled 校正。
3. 报告四个 BUD simple effects。可优先候选需 pooled BH<0.05、baseMean≥10、交互绝对 log2FC≥0.5。
4. 原始计数另以 edgeR TMM、limma voom/eBayes 拟合同一 full-rank 设计，报告新模型每交互及 pooled BH、CI；候选需替代模型 pooled BH<0.05且方向一致。
5. 在 DESeq2 规范化计数的 `log2(count+1)` 上计算每供体四个 BUD 响应和三项差中差。缺失条件不填补。优先候选需至少3个可用供体，全部差中差方向与 DESeq2 一致；公开每供体值。四供体符号翻转最小双侧 P=.125，不作为 P<.05 的确认。
6. 四轮留一供体 TMM/voom，重建完整设计；保存全部结果和不可估计情况。报告效应方向及效应范围，不将留一重复作为独立实验。
7. 候选按 pooled DESeq2 BH、绝对交互效应、Ensembl ID 顺序排序，固定前12个 gene×interaction 记录，再读取外部候选表达。无通过候选也如实完成。保留所有筛选阶段及全表。

### 配对供体检查

候选冻结后读取 GSE94335 完整 transcript TPM；按无版本 Ensembl gene 汇总所有转录本。保持原 Supplement Table E1 配对及28793/28796排除规则。明确排除与发现四供体同名的 N010912、N051911、N061311，使用其余 **13 供体（4非哮喘＋9致死性哮喘）**。

每基因分别报告两个病组、合并13供体的 `log2(TPM+1)` BUD−vehicle 平均差／t CI／t P，及病组差 Welch CI/P；**所选不重复基因 × 4 检验为同一 Holm family**。合并与组内检验保存全部符号翻转；组间保存全部715组标签枚举。比较伪计数0.1、0.5、1和留一供体响应。外部数据无TNF或KD，因而只检验基本药物响应，不能验证调节交互；不可把13供体与发现4供体或旧16供体相加。跨数据效应采用不同测量尺度，不直接合并效应量。

### 注释、新颖性与软件应用

基因名采用 TPM 的 ext_gene 注释，多个名字逐项保留。候选固定后核对原文全文及 Europe PMC 查询，记录 URL、UTC、返回原文/hash和检索范围；检索未命中不证明全球首次发现。将可支持的新结果写为具体条件依赖候选与后续实验假设。

实际调用 BioExplainR 的完整差异表 context、项目、离线中英文解释和 HTML 报告。统计拟合由 DESeq2/edgeR/limma完成，BioExplainR负责计算全表事实、记录范围与组织证据。保存原输入hash、脚本hash、UTC、版本、图表及独立Python数值复核；新目录拒绝覆盖。当前稿与旧成果保留。


## S2 四背景响应及候选固定

以下为当时方案/修订原文；本稿口径澄清见S6。


本方案在 GSE146017 全基因交互扫描未通过统一BH之后制定。旧SPARCL1响应、原论文及全基因simple effect文件已存在，但未按本方案排名。交互阴性保留，以下为新的探索问题，不将非显著交互解释为等效。

### 发现与固定排名

GSE146017原DESeq2与本轮独立TMM/voom模型中的四种背景BUD simple effects均用于筛查。每模型四比较×全部保留基因作为一个BH family（缺失P=1），优先候选需：

- baseMean≥10；四背景效应方向一致，每背景绝对DESeq2 log2FC≥0.5；
- 四背景在两模型均通过各自全family BH<.05且效应同向；
- 每背景每可用供体 `log2(normalized count+1)` 配对响应同向；
- 四留一供体voom中四背景效应均与主模型同向，效应绝对值不要求额外阈值；
- 每基因排名为四背景DESeq2最弱的绝对Wald stat降序，再按Ensembl ID；固定前12基因。全部通过基因与排名公开，旧候选SPARCL1不作新发现主张。

### 外部范围

GSE94335按已核实配对排除3个重叠细胞系，13供体（4非哮喘／9致死性哮喘）。先冻结12基因再读取完整TPM；汇总所有转录本，报告所有选中基因测量，不按外部表现换候选。候选×合并／两组／组差4项检验使用Holm，完整符号翻转、715组枚举、伪计数敏感性和留一供体结果均保存。重复支持以13供体合并响应Holm<.05且方向与发现一致定义；病组差未显著不证明等效。发布配对13供体响应的均值/CI为外部主估计量，不把文库当人。

### GR干预

GSE229084 A549模型保持原47文库、设计、过滤。仅对冻结候选提取DEX与KH103、MIF、Cort113交互，不降低过滤；所有候选×4项为一Holm family，不可估计P=1。使用逐基因精确WLS协方差（voom权重）和原模型moderated方差/df，报告效应、SE、CI和P。KH103方向与DEX相反且Holm<.05提示在A549该表达响应受到GR降解处理削弱；RNA响应不是直接结合或功能因果，跨细胞类型亦不等于ASM机制验证。所有阴性与未通过过滤均保留。

### 新颖性与交付

注释由原TPM ext_gene提供，检索固定候选及新的跨条件/跨数据组合；所有候选与原文命中公开。已知经典GR基因作为控制，不主张首次基因响应发现。实际结果可支持的新增价值为多条件/供体稳健响应与GR干预的可定位综合证据。只有具体候选检索和统计结果支持才提出新机制假设；保存版本、原输入、冻结、独立数值复核、BioExplainR项目及中英文报告和PDF/PNG图。


## S3 外部供体映射修订

以下为当时方案/修订原文；本稿口径澄清见S6。该修订先恢复7+9供体，本轮再排除3个已知重叠得到4+9。


本轮核实发布文件和原文补充后，发现必须先处理的设计差异；本记录与执行代码hash在读取候选TPM及统计检验前冻结。

1. TPM输入实际是空白分隔的 **transcript×sample 长表**，非gene宽表。对唯一候选及两个固定控制，按发布`ens_gene`精确匹配并将同基因全部transcript TPM相加，重复transcript/sample停止；不挑选最高/最显著转录本。
2. GEO的`donor`字段等于逐文库sample标题，不能配对。原文Supplement Table E1（PDF E9–E10，PDF页9–10）的`Cell Line`给出真实供体。逐样本解析原表、与GEO病组/处理/TPM样本名一一核对，不由表达推测配对。
3. GEO处理说明明确排除28782低read文库及其匹配vehicle28779；原文说34样本全部可用。实际TPM含34样本，28779/28782不在其中，另有28793/28796，但这两个不在原文Table E1，且28793的GEO病组为asthma、TPM名为non_asthma。不能假定它们是N012412替代文库或任意配成同供体。预先按设计可核对性排除这两个未能映射的文库，保留 **32可定位文库、7非哮喘+9致死性哮喘供体**；明确这不是全部发布样本、不新增表达/QC排除，候选值尚未检验。统计方法/候选/三个Holm检验不变。
4. 供体ID显示与GSE146017至少三条培养细胞系一致（N010912、N051911、N061311），所以不能把不同实验合并成独立总供体数。对airway的N61311/N061311等别名仍需逐一核实，现不宣称完全供体独立。
5. 原2019论文Table3也已报告SPARCL1布地奈德响应。因此本轮定位为供体级响应分布、显式组间差值及负面机制检验的透明重分析，不宣称首次发现基因响应或全新致死性哮喘效应。


## S4 暴露时长探索增补

以下为当时方案/修订原文；本稿口径澄清见S6。


本增补制定于固定12基因外部13供体和A549短时GR分析之后。已知PER2在18h/24h ASM下调、2h A549上调；不能据此区分组织、药物、剂量或时间效应。这里增加可在现有公开数据内检验的时间条件。

- GSE34313一个HASM1细胞系，DEX 4h/24h，各3培养重复对4 untreated。固定全部12基因，不替换未映射基因；取GPL6480精确symbol全部探针，每样本取探针中位数；原始发布处理单位不再归一化。两时间×12基因为一个24项Holm family，缺失P=1。Welch效应/CI/P和35组精确置换均保存。该设计非纵向独立供体时间曲线，未处理组亦非分别匹配每时点；只支持发布时间条件之间的差异。
- GSE229084原voom模型再提取 `post_DMSO - baseline_DMSO`，即2h DEX后16h继续DEX的18h终点，对18h DMSO；使用精确逐基因WLS及原moderated方差，12基因Holm family。原2h DEX比较继续引用原48项family，不将两个阶段重新作确认性统一分析。所有样本和过滤不变。
- 时间增补是读取初步结果后的探索，单独标记；不借此声称全局新颖或证明昼夜节律的振幅/相位/功能变化。PER2/PER3/TEF等节律候选至少需要密集、匹配时点及独立供体时间序列才可区分暂态、相位移动与长期抑制。


## S5 原执行失败与修订

以下为当时方案/修订原文；本稿口径澄清见S6。


分析和报告实际运行于主机UTC 2026-10-09；各freeze、文献acquisition与export分别保存实际UTC。此说明不是回填每命令精确起止时间的运行日志。

- `discovery_genome_v1`在完整交互筛查后，因0候选的留一供体赋值停止；空候选本身是真实科学结果。脚本仅修复零行赋值，重新冻结运行`discovery_genome_v2`，三交互均0显著。
- 启动稳定响应筛查的第一次命令误传未存在的`discovery_response_v1`来源，normalizePath即停止；尚未建立输出。改用实际`discovery_genome_v2`后完成`discovery_stable_response_v1`。
- 外部读取遇第3候选ENSG00000235770缺注释，原脚本停止；修订为固定12候选缺测P=1，重新提取原TPM，仍保留48检验分母，无替换候选。见external_execution_amendment.json。
- 原TPM独立R审计首次以all.equal相对1e-9比较遇CI差约5.0e-10；记录为−0.471686288430094 vs −0.471686288932591。显式容差改为abs差≤1e-10+1e-8×abs(reference)，随后全部通过；不改变结果或P。源于跨库浮点逆分布精度，不改写原TPM或效应。
- v1报告使用非合同字段uncertainties、direct_time仅声明ASM；v2改用uncertainty并显式混合scope/不合并单位，v1RDS/HTML保留。见report_amendment.json。
- 中文报告构建第一次相对source路径relative_to绝对ROOT失败，未保存稿件；v1目录仅保留错误JSON。路径resolve后在v2目录完成Word/PDF/HTML，文稿仍称结果报告v1。
- PMC8294620/PMC2701960全文XML实际500，失败保留focused_fulltext_acquisition.json；其已保存Europe PMC题名/摘要仅按该范围使用。
- 尝试读取PNG时模型环境不支持图像输入；未做视觉检查。数字/CSV、PDF文本边界与矢量路径、HTML实际加载/1440和390宽度均完成。
- 全仓git diff --check遇此前已修改的baseline CSV CRLF尾空白，未改旧manifest；本轮文件另作语法／尾空白及封存hash检查。

正式运行命令见报告README。独立Python审计增补了24项marginal微阵列结果／精确置换后复核通过；已保存的其他数值无变化。


## S6 本稿澄清、检验家族与实现复核

四背景校正每模型统一109,636项；A549短/长DEX暴露总培养窗口均18h，直接对比post_DMSO−pre_DMSO；HASM1缺各时点匹配vehicle。补充表S12列每个校正家族。全部区间为点态95%CI，多个探索阶段未作整体确认性控制。完整问题与完成标准见ISSUES.md。

保存环境：R4.3.3、DESeq2 1.42.0、edgeR4.0.16、limma3.58.1；BioExplainR0.4.0.9000以实际源码载入，9 context、0在线调用。原numeric_audit.json与external_r_audit.json记录原计数/数组/WLS及原TPM独立实现核验；不称跨语言重新估计所有拟合参数。原analysis/candidate/gr/time/direct_temporal_freeze.json保留阶段和实际UTC。新稿audit及manifest绑定表/图/原封存输入，复核无需重新拟合。

# 补充结果

## 原始测量与暴露条件

补充图S1展示PER2、PER3、METTL7A、MAOA、ANGPTL2、FSTL3全部13供体测量，供体效应与原测量见补充表S4/S11。补充图S2展示HASM1的PER2/PER3各数组，未处理4、DEX4h3、24h3；直接条件差见补充表S9，参数显著与精确检验限制分别报告。

## 补充表及来源

### 补充表 S1 54基因完整筛选与留一方向

保留全部priority_pass基因，按原最弱Wald统计量排序；留一只检验方向。 共54行。文件：`tables/Table_S1.csv`及同名XLSX；来源：`research/results/discovery_stable_response_v1/stable_response_screen.csv`。

### 补充表 S1b 54基因全部留一供体估计

54基因×4背景×4留一拟合，方向敏感性不作为独立实验。 共864行。文件：`tables/Table_S1b.csv`及同名XLSX；来源：`research/results/discovery_stable_response_v1/all_priority_leave_one_donor_out.csv`。

### 补充表 S2 12候选四背景模型

48行；DESeq2与voom各以109,636项校正，供体数可能为3或4。 共48行。文件：`tables/Table_S2.csv`及同名XLSX；来源：`research/results/discovery_stable_response_v1/candidate_context_effects.csv`。

### 补充表 S3 外部响应及病组差

48项原分母；44可估计，缺测P=1为占位；参数和精确各自Holm。 共48行。文件：`tables/Table_S3.csv`及同名XLSX；来源：`research/results/discovery_stable_response_v1/external_results.csv`。

### 补充表 S4 外部逐供体效应

11可测候选×13供体=143行；第12候选缺测在表S3保留校正位置，TPM差不当作count log2FC。 共143行。文件：`tables/Table_S4.csv`及同名XLSX；来源：`research/results/discovery_stable_response_v1/external_donor_effects.csv`。

### 补充表 S5 伪计数及留一供体敏感性

参数敏感性与方向，不增加独立供体数量。 共33行。文件：`tables/Table_S5.csv`及同名XLSX；来源：`research/results/discovery_stable_response_v1/external_sensitivity.csv`。

### 补充表 S6 A549全部候选DEX及药物交互

12×4=48项Holm；原过滤、精确逐基因WLS协方差及保存moderation。 共48行。文件：`tables/Table_S6.csv`及同名XLSX；来源：`research/results/discovery_stable_response_v1/gr_candidate_results.csv`。

### 补充表 S7 A549长暴露边际结果

12项Holm；结果后探索，18h指DEX暴露时长。 共12行。文件：`tables/Table_S7.csv`及同名XLSX；来源：`research/results/discovery_stable_response_v1/gr_late_results.csv`。

### 补充表 S8 HASM1全部候选两处理时长

24项Holm；共享未处理组，全部精确探针，精确置换不确认全家族时间结果。 共24行。文件：`tables/Table_S8.csv`及同名XLSX；来源：`research/results/discovery_stable_response_v1/asm_time_results.csv`。

### 补充表 S9 两实验直接暴露条件差

24项Holm，HASM1 DEX24h−4h、A549 post_DMSO−pre_DMSO；非纵向曲线。 共24行。文件：`tables/Table_S9.csv`及同名XLSX；来源：`research/results/discovery_stable_response_v1/direct_temporal_results.csv`。

### 补充表 S10 完整候选证据摘要

全部固定候选，保留缺测及不重复，实验尺度不混合。 共12行。文件：`tables/Table_S10.csv`及同名XLSX；来源：`research/results/discovery_stable_response_v1/evidence_summary.csv`。

### 补充表 S11 外部原基因级测量

11可测基因×26文库=286测量，供体配对不是文库独立检验。 共286行。文件：`tables/Table_S11.csv`及同名XLSX；来源：`research/results/discovery_stable_response_v1/external_gene_measurements.csv`。

### 补充表 S12 检验家族与时序

9阶段定义见`tables/Table_S12.csv`与XLSX。缺失占位、结果后追加及同来源模型均明确标注；不把这些阶段合并为一次预注册研究。

# S13 前轮共同任务与 SPARCL1/ChIP 背景

本节来自保存的前轮研究增补，未产生新性能运行或SPARCL1／ChIP统计。其软件指标不能作为PER2生物学机制证据。下列四内嵌表原数值保留，电子表复用原CSV，文件F1_common_task、F2_paired_bootstrap、F3_receptor_control、F4_chip_primary分别对应S13a–d。

## S13.1 正式共同任务比较

本增补对应预先保存的共同任务方案及机制方案。已知 airway/pasilla 开发数据不能视为盲法独立生物学 gold。两个数据集各取按 feature_id 排序均匀选择的50/200行，使用 α=.01/.05/.10 与 |log2FC|>0/1，24任务×3重复×5方法，共360方法运行、1,800目标评分；每方法分母360整数、72运行。两个 facts 客户端的72对 system/user 提示逐对相同。

五个输出为 n_features、n_significant、n_up、n_down、n_na_padj；严格 padj<α 且 abs(log2FC)>τ，NA不显著。BioExplainR 离线计算、base R 用户脚本、ellmer直接读表、ellmer读取完整BioExplainR facts、BioExplainR客户端读取同facts分别评价。Qwen2.5-1.5B-Instruct Q4_K_M（固定SHA-256）由 llama.cpp b11429 CPU服务执行；temperature=0、seed=42、输出上限256 tokens、180秒请求预算、无重试、无答案修订，关闭prompt cache。顺序及2,000次24任务配对bootstrap提前冻结，预热用非研究两行fixture。计时包括输入读取/对象/提示准备、调用和解析，不含库载入、下载和启动。

补充表 S13a 给出全目标分母与计时；失败、超时、截断/无效 JSON/缺项均留在全分母。共有 **37 个失败请求**。全任务正确率按每次运行的五目标均正确计。确定性步骤的极短耗时不宜解释为稳定速度优势；CPU负载/取消超时后的等待均可能影响本机计时。

| 方法 | 正确/360 | 覆盖/360 | 全正确/72 | 中位秒 | P95秒 |
|---|---|---|---|---|---|
| BioExplainR 离线 | 360 | 360 | 72 | 0.036 | 0.100 |
| base R 脚本 | 360 | 360 | 72 | 0.002 | 0.007 |
| ellmer 读表 | 8 | 175 | 0 | 180.829 | 182.755 |
| ellmer 读 facts | 360 | 360 | 72 | 18.583 | 63.812 |
| BioExplainR 客户端 | 360 | 360 | 72 | 18.653 | 64.857 |

表注：base R为用户实现基线；ellmer为通用客户端。表中全正确分母72是24任务的3重复，非72独立生物样本。

补充表 S13b 给出读facts相对直接读表的准确率差及按24任务聚合的配对bootstrap；只反映这个开发计数/传递任务。

| 对照：减去 ellmer 读表 | 准确率差 | 任务 bootstrap 95% CI |
|---|---|---|
| ellmer 读 facts | 97.78个百分点 | 95.28–100.00个百分点 |
| BioExplainR 客户端 | 97.78个百分点 | 95.28–100.00个百分点 |

全任务正确率为预定第二主终点：ellmer 读 facts相对读表的全任务正确率差为100.00个百分点（任务bootstrap 95% CI 100.00–100.00）；BioExplainR 客户端相对读表的全任务正确率差为100.00个百分点（任务bootstrap 95% CI 100.00–100.00）。按输入规模另报：ellmer 读表 50行目标为8/180；ellmer 读表 200行目标为0/180，完整分层在size_breakdown.csv。

ellmer 读 facts 完成响应共输入23085、输出3591 tokens；BioExplainR 客户端 完成响应共输入23085、输出3591 tokens；ellmer 读表 完成响应共输入78709、输出1925 tokens。失败请求的tokens未知，不将其计为0；外部API费0，本地CPU/能耗/货币总成本未测量。两个facts组目标答案已提供，结果不证明通用推理、整篇报告质量或生物学发现能力。

来源源码核查记录了iSEE 2.14.0、SCassist/GPTCelltype/GeneAgent固定commit及README。四个专属工具不原生返回该任务五整数，标not_applicable，不记错或性能0。结果不是六工具全面排名。早期Responses API忽略seed、端口冲突和入口参数错误的中止轮保留在v1–v3，正式结果仅v4；任务/提示未按答案调优。

## S13.2 SPARCL1的GR检验不可估计

GSE229084来自A549癌上皮细胞系，不能外推为ASM、患者或独立供体。保留Salmon/tximport发布非整数估计计数；按GEO处理和batch映射47文库（4 set，12处理/时序组），未处理组按设计排除；全基因filterByExpr默认min.count=10/min.total.count=15、TMM、voom、limma `~0+group+batch`，设计秩15、残差自由度32，35,942基因中15,437保留。三候选前给药DEX×KH-103/MIF/Cort113差中差构成预定Holm family；后给药仅描述。GEO两条DMSO标题rep2/rep3与set3/set4冲突，按batch与计数列核对保留，不补造缺失DMSO set2。作者处理对象的51个MG编号/处理/batch独立核对全部一致，缺MG_15确认；13,834共享基因×51列的705,534计数与发布矩阵一致（最大差4.66e-10），102空白/description标识无法对应并逐项保留。SPARCL1亦不在作者过滤后对象中。

**SPARCL1的47文库计数为0–4，全部候选主交互因未通过预定过滤而不可估计。** 不能据此支持或否定受体依赖，更不降低过滤阈值获得显著性。补充表S13c显示固定FKBP5控制在DEX及干预中有可测响应，但控制不替代候选。

| FKBP5 对照效应 | log2估计 | 95% CI | 未校正 P |
|---|---|---|---|
| DEX | +2.594 | +2.211–+2.976 | 3.29e-16 |
| KH103 | -2.515 | -3.023–-2.007 | 3.62e-12 |
| MIF | -2.498 | -2.996–-1.999 | 2.64e-12 |
| Cort113 | -2.121 | -2.611–-1.630 | 1.32e-10 |

表注：DEX是DMSO背景simple effect；KH103/MIF/Cort113为前给药差中差。均为固定描述控制、未校正P，不把它们混入SPARCL1三检验family。

Python从发布计数独立核对35,942基因过滤、188候选/控制测量、GEO映射、设计/对比、logCPM、39个WLS系数、t/CI。TMM/voom/eBayes未独立重估。独立复核发现limma contrasts.fit对加权设计采用共同相关近似，已重建该近似并另导出精确加权协方差敏感性，最大SE相对差2.19%。CI导出最初误按名称索引无名字的s2.post，保存失败记录后仅修复导出；冻结RDS/拟合未改变。

## S13.3 ChIP峰与参考基因组核实

GSE95632为单HASM2供体细胞系培养实验。取得全部18个发布narrowPeak gzip及原文HTML，逐hash/CRC核对。原GEO写人样本/mm9的冲突完整保留。全部1,347,409峰的染色体和末端落在hg19范围内；hg18/hg38/mm9分别12,937/10,043/158,229峰越界，且mm9缺chr20–22。该全基因组坐标指纹支持**坐标核实hg19/GRCh37**，不是作者确认的更正；原文XML不可取得、出版社补充HTTP403，OCR不构成确认。

使用UCSC ncbiRefSeq四条整染色体快照，固定SPARCL1/FKBP5/TSC22D3/KLF15全部注释TSS。BED零基半开，负链TSS=txEnd−1，GR±20kb、RNAPII±5kb；基因体及±100kb公开敏感性。MACS q≤.05（−log10q≥log10(20)）保留全部命中，不选最大峰。主分析仅8个未转导vehicle/DEX样本；额外10文库作描述，不混入主条件。

补充表S13d给出SPARCL1发布峰的主窗口计数。DEX GR两重复8/8峰逐坐标有8对重叠；RNAPII 1/1亦重叠。vehicle GR有4/2峰，两个峰重复重叠；RNAPII 0/0。这些结果支持“发布峰在候选窗口重叠”的描述，**不是差异占据统计**，不能由峰数或control不成峰推断显著增加、直接调控、enhancer连接或功能因果。

| 原样本 | 因子/处理 | 固定窗口 | q≤.05峰数 |
|---|---|---|---|
| GSM2519942 | GR EtOH_1D | TSS_20000 | 4 |
| GSM2519944 | GR EtOH_1E | TSS_20000 | 2 |
| GSM2519945 | GR Dex_2A | TSS_20000 | 8 |
| GSM2519947 | GR Dex_2E | TSS_20000 | 8 |
| GSM2519952 | RNAP2 EtOH_5E | TSS_5000 | 0 |
| GSM2519953 | RNAP2 EtOH_5b | TSS_5000 | 0 |
| GSM2519954 | RNAP2 Dex_6d | TSS_5000 | 1 |
| GSM2519955 | RNAP2 Dex_6e | TSS_5000 | 1 |

表注：全部坐标、距离、signalValue、q及重复重叠见原始结果表；单细胞系培养重复不增加独立供体数。

R GenomicRanges直接从原峰和原RefSeq重新构造窗口，288计数项、2,505峰窗口命中、summit/距离及16重复比较通过独立实现复核。原R审计窗口100000被默认科学计数格式变为1e+05的失败保留；包装器仅固定数字格式后通过。

## S13.4 背景结果边界

共同任务量化计算与语言传递分工；生物学结果则明确区分表达响应、药理干预可测性与染色质窗口重叠。A549无法检验低表达SPARCL1依赖；ASM峰可定位但不足以证明机制。没有新增湿实验、GR rescue、位点reporter/CRISPR、SPARCL1蛋白/基质/功能/临床终点；独立实现复核也不等于第三方人员科学/code sign-off。

主要结果目录：`research/results/common_performance_v4/`、`discovery_mechanism_fit_v4/`、`discovery_chip_v1/`、`discovery_chip_analysis_v1/`。方案与脚本在`research/common_performance/`和`research/discovery/`；所有输入、freeze、真实HTTP字节、scores、失败/中断、model.rds、独立审计、scientific_ledger及hash清单保留。以上为前轮v0.10配套研究增补的历史结果，本稿为v0.11生物学主线；GitHub/外部上传继续暂停。

## S13.5 背景参考来源

1. 共同任务方案：`research/common_performance/PROTOCOL.md`；实现修订：`IMPLEMENTATION.md`。
2. 机制方案：`research/discovery/MECHANISM_PROTOCOL.md`；GEO GSE229084、GSE95632元数据快照。
3. Gazorpak et al. 2023. doi:10.1038/s41467-023-44031-2；保存PMC10710461.xml。
4. Sasse et al. 2017. doi:10.1165/rcmb.2016-0357OC；保存PMC5576583_article.html。
5. UCSC hg18/hg19/hg38/mm9 chromosome sizes与hg19 ncbiRefSeq快照，访问UTC见acquisition记录。


# 补充图

## 补充图 S1 重点候选的逐供体测量

![补充图 S1 重点候选的逐供体测量](paper_cn_v5/figures/Figure_S1.png){width=16cm}

每线为一个供体，同一供体两文库不计为两人。各基因使用log2(TPM+1)原测量，全部候选测量见表S11。

## 补充图 S2 HASM1 的 PER2/PER3 暴露条件

![补充图 S2 HASM1 的 PER2/PER3 暴露条件](paper_cn_v5/figures/Figure_S2.png){width=16cm}

单HASM1细胞系培养重复；共享未处理组不是各时点匹配vehicle。参数直接差通过校正，精确置换全family不能确认，非节律相位/振幅证据。
