---
title: "BioExplainR 中文论文 v0.9.1：补充材料"
date: "2026-10-08"
lang: zh-CN
---

本补充保留 v0.8 的详细方法及历史结果图表，软件版本与执行日期按原记录标注。S1–S10 是既有方法，S11 为本轮外部发现案例。主稿聚焦四项贡献；本文件并不新增专家或用户评分。参考文献编号与主稿一致。

# 补充方法


## S1 研究设计、版本与评价层级

研究包含对象接入、数值事实核对、受控机制挑战、模型结构化传递和工程验收五个层级。对象接入评价来源类、维度及设计字段；数值核对比较适配器值与直接源表计算；机制挑战注入事先定义的错误并检查返回状态；模型实验评价显式 fact-path 和标量值的传递；工程验收评价安装、传输、页面及下载行为。不同层级使用不同分母，不合并为总体“准确率”。

当前平台为 BioExplainR 0.4.0.9000，运行环境为 Ubuntu 24.04.4、R 4.3.3 与 Bioconductor 3.18。模型规模实验及五数据集保存结果产生于 0.3.1；本稿离线回读这些记录，并另外报告 0.4.0.9000 的 miniACC 开发案例、安装包复现和本轮新增场景。版本、命令、UTC 时间、退出码及逐文件 SHA-256 分别进入运行清单。miniACC 和新增场景用于开发应用与工程验证，不标记为冻结的独立 test/gold。

## S2 统一上下文与事实计算流程

平台首先依据类及接口分派输入。已测试入口包含 DESeqResults、MArrayLM、TopTags、SummarizedExperiment、SingleCellExperiment、SeuratObject、ExpressionSet、MultiAssayExperiment、prcomp、ggplot，以及符合约定的结果表；其余接口支持范围以安装帮助和数据契约为准。真实来源类可记录 verified_class，用户声明的来源记录 user_declared；列名推测不提升为来源已确认。多系数 limma 拟合要求明确所选系数。

适配后的 `bio_context` 包含分析类型、来源类与软件包、来源状态、确定性 facts、有限顶部预览、参数、图形映射和不确定性。当前契约进一步保存研究范围 scope、设计 design、事实描述符 fact_descriptors 和上下文标识。scope 记录数据集、比较、物种、组织、模态与观测层级；design 可记录独立单位、分子/分母和配对方式；描述符为事实标明特征、单位、来源路径、计算规则及完整性。软件能检查被明确提供的信息，不会从缺失字段补造研究设计。

完整输入用于适用的确定性计算，有界预览只服务展示。差异表达、富集、PCA、单细胞及多模态适配器生成类型相应的标量或结构化事实。大矩阵的某些诊断采用取样或稀疏摘要，相关检查范围保留于输出，不能由局部检查推断全矩阵均无问题。用于解释的上下文与本地原始对象分开保存，原始表达矩阵、样本映射和坐标不作为默认模型载荷。

## S3 阈值、缺失值及显示精度

对于给定校正阈值 α 和效应阈值 τ，差异表达筛选集合为：校正 P 值及效应非缺失、P_adj < α、且 |log2FC| > τ 的特征。上调和下调分别由集合内 log2FC 的正负确定。特征总数、显著数、上下调数、缺失校正值数均从完整提供的结果表计算。阈值使用严格小于/大于；NA 不作零，也不写为未显著的确定结论。

校正值沿用上游对象的统计流程；若用户明确要求从原始 P 值计算 BH，平台记录 computed_BH。只有原始 P 值的表格保留 raw-only 状态，不生成冒充校正显著性的计数。BH 方法参照既有定义 [14]；DESeq2 独立过滤可导致校正值缺失，应结合其来源解释 [1,15]。用于载荷及 HTTP 请求的数值保留 17 位序列化精度，文本显示可另行舍入。PCA 方差比例保存计算精度；表、图和正文中的舍入值不用于替代评分参考值。

## S4 模型载荷、本地解释与显式预算

本地模板无需模型连接即可输出数据事实、统计含义、候选生物学解释、不确定性与不能推出的结论。在线模式由用户配置服务 URL、密钥和模型 ID，支持 OpenAI-compatible 与 Anthropic Messages 协议。解释入口默认传递完整确定性 facts，并限制顶部预览与其他展示内容；完整 facts 超出显式字符预算时失败并说明原因，当前没有自动全覆盖分块协议。旧接口保留的 bounded 兼容策略与历史 direct_bounded 基线不代表当前默认事实载荷。

递归载荷策略过滤秘密、路径、样本/细胞标识和私有结构，并对公开证据 URL 做结构化过滤；HTTP 清单区分载荷与实际请求体的 bytes/hash，保留 usage token 计数。模型仅根据已提供事实组织文字，不承担完整长表重算，也不会自动执行生成代码。工作台默认 English，可切换简体中文；语言选择不改变 R 事实和判定规则。

## S5 证据检索与分项声明验证

证据检索由用户显式开启，可连接 Europe PMC、QuickGO、Reactome、KEGG 和 UniProt [16–20]。证据对象保留来源 ID、标题、URL、访问时间、提供方式、scope 与角色。检索命中、数据库注释、候选支持关系与专家确认是不同状态；平台不把题名命中自动当作论断已获支持。

显式声明验证接收上下文、声明及给定证据集合，检查事实路径、值类型、数值、方向、单位和 scope。历史机制实验使用非零参考值 10^-6^ 相对容差，参考为零时使用 10^-6^ 绝对容差，字符串精确匹配；有界顶部表路径对应保存的预览值。当前类型化声明及证据关系 findings 参与总体状态，旧兼容判定单独保留。不存在值或范围不足时为 partial/unverified，而非 pass。引用闭集检查只判断引用 ID 是否来自已提供集合，不证明文章支持论断；未声明自由文本不因数值通过而获得整体认证。

## S6 图形、代码记录与修复不变量

基于 ggplot2 的图形接口提供 PCA、UMAP/已有嵌入、富集气泡图与热图 [21]。图形核对使用明确的源对象：火山图比较 ID/可配对行的效应和 P 值来源；PCA 比较坐标、方差比例和轴标签；富集图比较条目、比例、Count、颜色和大小。允许预期子集必须显式指定。不能配对或超出支持图层范围时为 not_checkable。判定针对标度和坐标变换前的映射值，不覆盖所有像素、裁剪或人工注释。

用户代码通过 `bio_record_code()` 保存状态、警告、错误现场调用栈、对象摘要和软件调用表达式。显式提交的修复代码在独立 R 进程执行，并核对预先指定的类型、行数或因子水平等不变量；未设置不变量时仅记录 runtime_only。独立进程分隔会话状态，但不是操作系统沙箱。本文分别保存可运行且保持参照水平、可运行但反转参照水平的挑战，评价“可运行”与“满足指定条件”的区别。

## S7 多模态覆盖、依赖及明确方向关系

样本映射使用 modality、source_id、biological_unit 三个必需字段，并显式记录技术重复角色。验证器重新核对已构造映射，拒绝缺失/重复 observed ID，将观测 ID 与映射双侧比较；完整病例集合 primary_units 提供共同分母。输出包括每模态观测/缺失病例、两两交集、全部模态完整病例与未测量病例。映射的 pass 仅说明被核对的对应关系合法，不能解释为所有病例均测齐。

项目依赖图区分原始来源和派生结果，拒绝循环和未知依赖。方向关系验证针对显式 from/to 事实、共有 feature_id 与预期 same/opposite；先核对 dataset/comparison/species/tissue/sample_level、分子/分母及特征身份，再比较有限非零效应的符号。零效应或缺失科学范围不自动通过。两种效应可以具有不同量纲，因此这里仅比较符号，不比较绝对幅度；同向也不代表双方显著、机制一致、因果或独立确认。

## S8 公开案例及预处理

**airway：配对转录组及阈值敏感性。** 使用 airway 1.22.0 的人气道平滑肌地塞米松数据 GSE52778 [22]。保留 rowSums(counts) ≥ 10 的基因，以 `~ cell + dex` 设计拟合 DESeq2 1.42.0，设置 untrt 为参照，比较 trt 与 untrt；主阈值为 P_adj < 0.05、|log2FC| > 1，未执行 LFC shrinkage。效应阈值是结果筛选条件，不是“效应超过 1”的原假设检验。PCA 使用 VST(blind=FALSE)，选择 500 个最高方差非恒定特征，中心化、不标准化。limma voom/经验贝叶斯与 edgeR 准似然流程使用相同过滤和设计 [2,3,23]，各自结果不要求与 DESeq2 显著数相同。本轮从保存的真实 DESeqResults 回读，在 α∈{0.01,0.05,0.10}、τ∈{0,1,2} 九组条件下独立重算五项全表事实（补充表 S2）。

airway 的 Reactome ORA 使用带哈希的映射快照，保留人类且位于差异表内的基因；以有注释基因为背景，筛选大小 10–500 的通路，做超几何检验并对全部检验 BH 校正。对象接入和解释不把 ORA 显著性直接称作通路激活。

**PBMC3k：单细胞与独立观测单位。** 使用 10x Genomics 公开过滤矩阵 [24]，保存每细胞 UMI、检测基因和线粒体比例。SCE 与 SeuratObject 对象均使用同一矩阵及单供体信息。表达按每细胞 10,000 缩放后 log1p，选择 1,000 个最高方差特征作 20 维 PCA，再由 uwot 0.1.16 生成 UMAP，种子 20261004，单线程 [25]。保留全部 2,700 个细胞，线粒体 5% 仅用于图示分组，不实施细胞类型准确率评价或供体间差异推断 [26]。本轮重新核对保存的 SCE 是否同时保留细胞数和供体数。

**pasilla、ALL 与 bladderbatch：补充来源和设计字段。** pasilla 1.30.0 使用 `~ type + condition`，比较 treated 与 untreated；沿用保存的 α∈{0.01,0.05,0.10}、τ∈{0,1} 六组阈值、五事实核对（补充表 S3）。它未参与 airway/PBMC3k 初始开发，但这里只评价数值摘要，不是独立模型解释质量。ALL 与 bladderbatch 使用固定 Bioconductor 归档的 ExpressionSet，检查维度、分组、表型和批次字段，不重拟合差异模型或实施批次校正 [27,28]。

**miniACC：多组学覆盖与方向关系。** 使用 MultiAssayExperiment 1.28.0 内置的 TCGA-ACC 缩减对象，原研究出处和对象组织方法分别见 [6,29]。数据包含 92 个病例和 RNA、拷贝数、RPPA 蛋白、突变、miRNA 五模态。本轮纳入此前保存的开发分析与实际安装包重跑。先校验 sampleMap 与实验列名，再以全部 92 个病例为分母统计覆盖。在 RNA/蛋白均有测量且分期已知的病例中，stage I/II 为 early，III/IV 为 late；按共有行名选特征，RNA 使用 log2(归一化表达+1)，蛋白保留 RPPA 标准化值。每模态效应为 mean(late)−mean(early)，Wilcoxon 秩和检验使用 exact=FALSE、correct=TRUE，BH 在各模态的 33 特征内分别计算（补充表 S4、补充表 S5）。这不是配对 early/late 的检验：配对指同一病例同时具有 RNA 与蛋白，分期组之间是不同病例。分期未随机化，未调整年龄、肿瘤纯度或分子亚型；缩减对象的选择范围不支持新的临床结论。

## S9 历史输入消融、双模型及评分规则

历史主消融使用 120 个可复现程序案例：差异表达 30、富集 20、PCA 20、SCE 20、细胞组成 15、generic 15；每案例四个标量目标，共 480 个唯一目标。比较 direct_bounded（有限原始预览）、facts_only（R 全输入计算事实）和 facts_evidence（同一事实加保存 Europe PMC 记录）。三方法各重复三轮，共 1,080 实际请求、4,320 逐事实评分；每方法分母 1,440。参考事实从完整源对象计算，不使用模型响应。

DeepSeek deepseek-flash 请求采用 OpenAI-compatible、temperature=0、thinking disabled、JSON mode、5,000 输出 token 上限、120 秒 timeout，瞬时错误最多重试一次。direct_bounded 允许无法判断时返回 null；它是信息受限基线，不是代码执行代理。匹配率=匹配目标/全部目标，覆盖率=已回答标量/全部目标，已回答准确率=匹配/已回答。未回答记为未完成，不填补。重复共享输入与目标，只作描述性统计，不当作独立生物数据推断。

双模型共同任务使用相同 120 案例和 480 目标，StepFun step-5-preview 与 DeepSeek deepseek-flash 各调用一轮，temperature=0、最多 800 输出 token，最终均关闭 response_format=json_object。输入、提示、预算和评分相同，提示要求完整精度小数复制。模型别名无不可变快照，跨时间确定性未获保证。本轮只核对保存响应，不新增在线请求（补充表 S6、补充表 S7）。相关工具的保存入口检查涉及 iSEE 真实 SCE/UMAP 浏览器、GPTCelltype marker 到提示、ellmer 与本平台的响应 replay；这些不是完整共同任务性能排名。

## S10 机制挑战、新增场景与工程复现

历史声明挑战在 18 个事实加证据响应中分别注入错误数字、未知路径、向量值、未知引用及仅路径无值声明，共 90 项；移除验证器记为 unchecked。图形挑战为三张正确图与六种注入错误；修复挑战为保持/反转 untrt 参照水平的两段可运行代码。

本轮新脚本 `research/paper_cn/run_cases.R` 从保存公开对象和手算 fixture 执行 15 个场景（补充表 S8）：阈值核对、单供体保留、正确/错误 PCA、raw-only、完整事实超预算、合法但不完整的映射、观测未映射、病例越界、正确/错误跨模态关系、反转比较、范围缺失以及工作台项目分派。每项事先写明预期状态；错误注入标明 controlled mutation，不作为自然发生率估计。

工程检查包括源码 testthat、构建包检查、真实安装及 Imports-only smoke、历史 API 名称/位置参数、两种协议的实际 HTTP bytes/hash、浏览器桌面 1440 与移动 390 像素视口，以及独立 bwrap 边界探针。浏览器以真实 miniACC 项目检查覆盖、方向 findings 和报告回读，并下载实际生成的 PCA PDF。不同连接各有独立工作区，但仍共享 R/文件/网络权限；bwrap 的独立探针不能用于宣称 Shiny 为多租户沙箱。Python 独立实现从保存长表重算 miniACC 66 个效应、符号、覆盖和 BH，未独立重算原始 Wilcoxon P 值或从 RDS 解码原矩阵（补充表 S9）。


## S11 候选固定、外部实验及独立实现复核


日期：2026-10-08。此方案在读取 GSE34313 的候选基因表达值、拟合或检验前固定；GEO 元数据、原论文和平台注释已用于核实可用性与分析单位，不能称为预注册或完全盲法。

## 候选和可证伪问题

发现来源为已保存的 airway / GSE52778 DESeq2 全结果（4 供体、8 文库，`~ cell + dex`，trt/untrt）。在 `padj < 0.05` 且 `log2FoldChange > 1` 的集合中按 padj 升序、feature_id 升序选择第一个特征；不按验证结果替换候选。当前选中 ENSG00000152583，Ensembl 官方记录映射为 SPARCL1。

待验证陈述：**SPARCL1 在外部人气道平滑肌地塞米松 24 小时实验中相对未处理上调。** 更深入的候选机制是糖皮质激素响应伴随细胞外基质相关表达改变；仅表达重复不能验证 SPARCL1 的功能作用或直接 GR 调控。

## 外部来源与真实独立性

GSE34313，GPL6480，Masuno et al. 2011，doi:10.1165/rcmb.2010-0369OC。与 GSE52778 为不同 accession、平台及实验；**原论文明确微阵列来自一个 HASM 细胞系（HASM1）**，每组重复不是多个独立供体。未提供与 airway 供体逐人对照，故表述为“外部独立实验初步重复”，不声称供体独立队列或临床验证。

GEO 当前保留 untreated 4、dex 4h 3、dex 24h 3 个数组；仅使用已发布矩阵，不重新依据结果排除样本。GEO 说明剔除 2 个样本，正文方法曾写 1 个技术异常；两处差异原样记录。样本编号尾缀不作为配对供体 ID。

## 预定分析

1. 使用完整 gzip 校验的 GEO series matrix 和 GPL6480.annot.gz；保留 URL、UTC、bytes、SHA-256，避免使用截断下载。
2. 全量读取 ID_REF 与 10 列值，按 GPL 的 Gene symbol 精确单符号匹配 SPARCL1；所有匹配探针均公开。多探针时每数组取中位数，不选择最显著探针。
3. 使用发布的 processed log-scale 值，不再次 log/quantile normalization；矩阵约 5–17 的值域与发布 processed 文件的 log2 标注相互核对。若无法核实量纲，效应只称 processed-unit difference。
4. 主终点为 `mean(dex24h) - mean(untreated)`，两侧 Welch t 检验，95% Welch CI；支持条件为效应 > 0 且 P < 0.05。仅一个预先固定基因和主比较，不将全表候选筛选 P 值解释为外部验证 P 值。
5. dex4h 为次要描述终点；两个时间点的 Holm 校正作为敏感性结果。另对主比较报告所有 C(7,3)=35 组的双侧精确均值差置换 P；该小样本检验仅作敏感性分析。
6. Python/SciPy 实际计算；R 使用独立实现从导出测量重算效应、Welch P/CI 和枚举置换。BioExplainR 接入发现及外部结果、分别保留 dataset/comparison/unit/独立单位，生成离线解释、项目依赖和中英文报告。
7. 阴性或信息不足均报告，不更换候选、主时间点或阈值。软件状态检查与生物学支持分开记录。

## 可验证的下一步

在新增至少 3 个独立供体的 ASM 中，用 qPCR/蛋白检测检验 SPARCL1 的剂量与时间响应；用 GR 拮抗/敲低区分直接依赖，再用 SPARCL1 干预与基质/增殖测量验证功能。此轮不声称已完成这些实验，也不声称首次发现该基因响应。


外部数值结果见补充表 S10；Python/SciPy 与 R 的十项效应/P/CI/置换值及两项 Holm 值相符。BioExplainR 生成两个 scope/unit 明确区分的上下文与项目，报告并不把软件 pass 解释为机制成立。

# 补充结果图

框架图与各结果合图

合图按正文引用编号排列。每图由四张独立 PDF 使用保持矢量内容的 PDF 排版方式组成；补充 PDF 的本部分直接嵌入合图 PDF，Word 和网页使用其高分辨率预览。框架图包含原创数据库、图形、网络、校验和报告图标；真实页面截图为位图素材，其余框架/统计元素保留矢量。各合图与子图原件见专用目录。

## 补充图 S1 平台框架

![BioExplainR framework](paper_cn_v3/figures/previews/Figure_1.png){width=16cm}

**补充图 S1. 从已有 R 对象到可追踪解释的 BioExplainR 框架。**（A）以数据库、统计图、网络、校验和文档图标展示对象→确定性事实→可选语言→分项检查→输出流程；（B）本地计算与模型载荷边界，完整标量事实超预算时明确失败；（C）pass、fail、partial 与 unverified 的独立状态；（D）源队列及 RNA/蛋白派生结果的依赖关系。同一来源的结果不能当作独立确认。合图原件：`figures/composites/Figure_1.pdf`；子图：`figures/panels/Figure_1A.pdf` 至 `Figure_1D.pdf`。

## 补充图 S2 配对转录组案例

![airway case](paper_cn_v3/figures/previews/Figure_2.png){width=16cm}

**补充图 S2. airway 的全表统计、配对结构与阈值敏感性。**（A）trt/untrt 火山图，主阈值为 P_adj < 0.05、|log2FC| > 1，999 个显著特征中上调 519、下调 480；（B）VST 后 500 个高方差特征 PCA，PC1/PC2 为 47.8429%/23.3834%，连接线对应四个供体内的配对文库；（C）九组阈值的显著数轨迹，五事实×九条件均与直接源表相符；（D）DESeq2、limma、edgeR 方法各自的显著数。图 B 的 8 文库不是 8 独立供体；图 D 不构成方法优劣排名。原件：`figures/composites/Figure_2.pdf` 与 `figures/panels/Figure_2[A-D].pdf`。数值来源见补充表 S2 及数据清单。

## 补充图 S3 单细胞与微阵列案例

![single-cell and microarray cases](paper_cn_v3/figures/previews/Figure_3.png){width=16cm}

**补充图 S3. 细胞、供体和设计字段的分层摘要。**（A）PBMC3k 已有 UMAP，以线粒体比例≤5%/>5%着色；（B）线粒体比例分布及展示阈值，未据此排除细胞；（C）2,700 细胞、32,738 特征与单供体的不同层级；（D）ALL 与 bladderbatch 样本量及表型/批次字段摘要。QC 颜色不是细胞类型，UMAP 不用于推断供体间差异；微阵列摘要不是批次校正结果。原件：`figures/composites/Figure_3.pdf` 与 `figures/panels/Figure_3[A-D].pdf`。来源见补充表 S1。

## 补充图 S4 pasilla 数值基准

![pasilla benchmark](paper_cn_v3/figures/previews/Figure_4.png){width=16cm}

**补充图 S4. pasilla 独立来源的保存数值核对。**（A）保存 VST PCA；（B）treated/untreated 火山图；（C）主阈值下上调 108、下调 110，共 218；（D）六组阈值的显著数，30 项源表事实均一致。分析设计为 `~ type + condition`，校正值缺失 5,800；本轮回读保存结果，没有重拟合上游模型。原件：`figures/composites/Figure_4.pdf` 与 `figures/panels/Figure_4[A-D].pdf`。逐项数据见补充表 S3。

## 补充图 S5 miniACC 多组学案例

![miniACC multiomics](paper_cn_v3/figures/previews/Figure_5.png){width=16cm}

**补充图 S5. 多组学覆盖、方向与显著性的分离展示。**（A）92 病例分母下各模态覆盖，灰段为未测量，五模态完整病例为 43；（B）33 共有特征的 RNA 与蛋白 late−early 效应，18 同向、15 反向；（C）两模态 BH 校正值，特征按字母顺序，RNA 3/33、蛋白 0/33 通过0.05；（D）46 配对测量病例的分期组，early 28、late 18。RNA 和 RPPA 单位不同，图 B 只核对符号、不比较效应幅度。分期组不配对、不随机化；同病例跨模态测量和符号一致不建立独立证据或因果。原件：`figures/composites/Figure_5.pdf` 与 `figures/panels/Figure_5[A-D].pdf`。数值见补充表 S4–S5。

## 补充图 S6 模型事实传递

![fact-transfer ablation](paper_cn_v3/figures/previews/Figure_6.png){width=16cm}

**补充图 S6. 固定目标事实的输入消融与双模型协议结果。**（A）三输入总体匹配率；（B）覆盖与已回答准确率；（C）六功能家族匹配率；（D）相同输入下 StepFun 与 DeepSeek 各匹配480/480。A–C 为120程序案例、480唯一事实、三方法×三重复，共1,080请求与4,320评分；D各模型120请求，不与主消融分母相加。100%是R目标已显式提供后的结构化传递终点，有界raw缺少完整信息；不是自由文本正确率、独立推理或生物学泛化。全部为0.3.1保存记录，本轮没有在线调用。原件：`figures/composites/Figure_6.pdf` 与 `figures/panels/Figure_6[A-D].pdf`。数据见补充表 S6–S7。

## 补充图 S7 受控错误与新增场景

![controlled mechanism cases](paper_cn_v3/figures/previews/Figure_7.png){width=16cm}

**补充图 S7. 分项验证拒绝明确违例并保留信息不足状态。**（A）历史声明72个明确错误fail、18个仅路径partial；（B）3正确图pass、6注入错误fail；（C）本轮15场景按预期返回pass/fail/partial/unverified，合计15/15；（D）参照保持与反转代码均可运行，但仅前者满足不变量。A、B、D为历史机制记录，C为本轮实际运行；数值不合并为自然错误率或一般修复成功率。原件：`figures/composites/Figure_7.pdf` 与 `figures/panels/Figure_7[A-D].pdf`。新增场景列表见补充表 S8。

## 补充图 S8 工作台与工程验收

![workbench and engineering](paper_cn_v3/figures/previews/Figure_8.png){width=16cm}

**补充图 S8. 项目分析到论文图 PDF 导出的实际工作流。**（A）真实 miniACC 项目的中文桌面页面；（B）同项目移动视口，宽表在容器内滚动；（C）浏览器实际下载的 Cairo PCA PDF 回读预览，该图为手算工程输入，不是生物数据结果；（D）源码、安装及浏览器的分层检查。截图裁剪自自动化保存页面，未重绘页面。项目展示保留覆盖与方向findings，下载报告使用同一项目；不同浏览器工作区独立仍不等于多租户安全沙箱。原件：`figures/composites/Figure_8.pdf` 与 `figures/panels/Figure_8[A-D].pdf`。验收范围见补充表 S9。


# 补充结果表

外置表格的表题、表注与来源

本附录仅保留表题和说明，不插入表格数据。补充表 S1–9 的 XLSX 与 UTF-8 CSV 逐一保存在本稿 `tables/` 目录；每个 XLSX 另含“图表说明与来源”工作表。正文引用使用相同编号。

## 补充表 S1 案例数据、版本与分析边界

**表注：** 列出六个公开数据来源、所测对象/软件版本、规模与各自任务。airway 为8文库/4供体，PBMC3k 为2,700细胞/1供体，miniACC 为92病例；不同观测单位和任务不合并为研究样本量。**来源：** `data_manifest.json`、`public_datasets/dataset_tests.json`、`miniacc_installed_review/summary.json`。**文件：** `tables/Table_S1.xlsx`、`tables/Table_S1.csv`。

## 补充表 S2 airway 阈值敏感性及适配器核对

**表注：** α为0.01/0.05/0.10、τ为0/1/2，共九组合，每组合核对特征数、显著数、上/下调数与缺失校正值；45项全部一致。筛选使用P_adj<α与|log2FC|>τ，NA不作零。**来源：** `paper_cn_cases_v1/airway_threshold_checks.csv`。**文件：** `tables/Table_S2.xlsx`、`tables/Table_S2.csv`。

## 补充表 S3 pasilla 独立来源数值事实核对

**表注：** 六阈值组合×五事实=30项，保存适配器值与直接源表值一致。仅评价数值事实，不代表独立模型解释评价；本轮未重拟合pasilla。**来源：** `related_tools/pasilla_fact_checks.csv`。**文件：** `tables/Table_S3.xlsx`、`tables/Table_S3.csv`。

## 补充表 S4 miniACC 模态覆盖及统一分母

**表注：** 每模态观测/缺失病例以完整92病例为共同分母，完全观测43、未观测0。合法映射的pass不表示模态齐全；两个模态的交集另存项目结果。**来源：** `miniacc_installed_review/modality_coverage.csv`、`alignment_summary.json`。**文件：** `tables/Table_S4.xlsx`、`tables/Table_S4.csv`。

## 补充表 S5 miniACC 33特征效应、方向及显著性

**表注：** 46病例（early28/late18）中效应为late均值−early均值；RNA单位为log2(归一化表达+1)，蛋白为原RPPA单位。Wilcoxon使用渐近及连续性校正，BH按各模态33特征分别计算。same/opposite为符号关系，不替代P值、机制或独立证据。**来源：** `miniacc_installed_review/feature_results.csv`。**文件：** `tables/Table_S5.xlsx`、`tables/Table_S5.csv`。

## 补充表 S6 保存的主消融实验

**表注：** 每方法360请求、1,440目标评分，总1,080请求/4,320评分。匹配率、覆盖和已回答准确率分母分别为全部目标、全部目标、已回答目标；不把重复当独立生物数据。raw为信息受限基线，facts为目标显式提供后的传递。**来源：** `main_scale_480/ablation_summary.csv`。**文件：** `tables/Table_S6.xlsx`、`tables/Table_S6.csv`。

## 补充表 S7 六类功能家族与双模型事实传递

**表注：** 前18行汇总六家族×三方法的主消融；后两行分别为StepFun与DeepSeek单轮的480目标。不同实验分母分开解释，未配置代理和缺失replay不进入API请求数。**来源：** `main_scale_480/family_summary.csv`、`common_task_scale_480/common_task_summary.csv`。**文件：** `tables/Table_S7.xlsx`、`tables/Table_S7.csv`。

## 补充表 S8 新增开发场景的期望状态与实际状态

**表注：** 15场景均按预期；每行标明来源、目的、期望和实际状态。controlled mutation为人为注入，hand-computable fixture为手算工程样例，两者均不当作自然生物学样本。**来源：** `paper_cn_cases_v1/scenario_checks.csv`。**文件：** `tables/Table_S8.xlsx`、`tables/Table_S8.csv`。

## 补充表 S9 工程验收与复现层级

**表注：** 本轮源码、包和浏览器日志与此前安装/API/miniACC数值复核分别注明。74/74只为历史名称/位置参数，Python复核未独立重算Wilcoxon原始P。工程pass不表示专家、用户或科学泛化结果。**来源：** `w00_baseline/paper-cn-*`、`review-*` 与 `REVIEW_CONTINUATION.md`。**文件：** `tables/Table_S9.xlsx`、`tables/Table_S9.csv`。


## 补充表 S10 SPARCL1 外部实验与重算

**表注：** 24 小时为主比较，4 小时为次要比较；两侧 Welch、95% CI、两个时间点 Holm 值和 35 种分组枚举置换分别提供。培养重复来自同一细胞系，不作为独立供体。**来源：** `research/results/discovery_sparcl1_v1/validation_results.csv`、公开 GEO 输入及 `r_numeric_checks.csv`。**文件：** `tables/Table_S10.csv`、`tables/Table_S10.xlsx`。

# 后续研究与投稿信息

真实作者、基金、伦理、独立专家评价与人工图稿审阅待负责人确认；用户研究 deferred。DOI 只有归档平台实际签发后填写。
