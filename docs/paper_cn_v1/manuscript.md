---
title: "BioExplainR：面向已有 R 生物信息学结果的确定性事实、可追溯解释与联合核对平台"
subtitle: "中文论文初稿 v0.8 · 当前开发版 0.4.0.9000"
date: "2026-10-08"
lang: zh-CN
---

**作者：**［待填写］

**单位：**［待填写］

**通讯作者及邮箱：**［待填写］

# 摘要

**目的：** 生物信息学分析的计算结果与自然语言解释之间存在信息断层。初级研究者即使能够运行 R 代码，仍可能混淆比较方向、校正 P 值、独立重复和跨组学证据。本文构建 BioExplainR，将可精确计算的事实、可选模型生成的措辞与可检查的声明分开记录，形成对象解释、图形核对、项目整合与报告导出的连续工作流。

**方法：** 平台在 R 侧从完整输入对象计算确定性事实，构建带来源、研究范围、设计、量纲和不确定性的统一上下文；完整事实与有界预览形成显式预算控制的模型载荷。采用六个公开数据来源展示差异表达、单细胞、微阵列和多组学应用，并以源表重算、受控错误注入、安装包复现及浏览器自动化分别评价事实提取与工程行为。历史输入消融使用 120 个程序生成案例、480 个唯一目标事实、三种输入方法与三轮重复；本轮增加 airway 九组阈值的 45 项核对，以及 15 个覆盖映射、比较方向、图形和页面衔接的开发场景。

**结果：** airway 在校正 P < 0.05、|log2FC| > 1 时得到 999 个显著特征，其中上调 519 个、下调 480 个；新增阈值事实核对为 45/45。PBMC3k 在两类单细胞对象中均保留 2,700 个细胞、32,738 个特征与 1 个供体的独立单位信息。pasilla 六组阈值的 30 项保存数值核对全部一致。miniACC 的 92 个病例中，43 个五模态完整；46 个分期已知的 RNA/蛋白配对病例包含 33 个共有特征，其中 18 个同向、15 个反向，RNA 和蛋白分别有 3 个与 0 个特征通过 BH < 0.05。历史消融中，有界原始输出匹配 437/1,440 个目标（30.35%），两种 R 事实输入均匹配 1,440/1,440；15 个新增场景均返回预期状态。本轮源码检查 677 项中 676 项通过、1 项跳过，包检查为 Status: OK，项目显示及 PDF 下载通过浏览器验收。

**结论：** BioExplainR 在固定案例和受控挑战中支持将统计事实、来源、研究范围与验证状态共同保留到解释和报告。平台的优势体现在事实传递、分析边界显式化及错误可定位性；这些终点不等同于自由文本全面正确或生物学泛化。专家评价与用户体验研究留待后续补充。

**关键词：** 生物信息学；R；确定性事实；大语言模型；多组学；可追溯解释；Shiny

# 1 引言

R/Bioconductor 是转录组、单细胞和多组学研究的重要计算环境。DESeq2、limma 与 edgeR 将实验设计转化为可检验的统计模型，SingleCellExperiment、Seurat 和 MultiAssayExperiment 则组织不同层级的表达、表型及模态信息 [1–6]。分析完成后，研究者还需要回答“改变的数量是多少”“方向相对于哪个参照”“图与源结果是否对应”“哪些结论仍需证据”等问题。本文的目标用户是能运行分析代码、但尚不能独立审查统计和生物学解释的初级研究者。

这一需求不只是把结果转换成流畅文字。例如，有限顶部行无法决定全表显著特征数；缺失校正值不等于无检验；单供体的数千个细胞不能成为数千个独立重复；同一批病例的 RNA 与蛋白结果也不是独立队列确认。若这些约束没有进入解释入口，语言生成可能使其进一步隐形。面向生物医学的模型工具已覆盖细胞标注、工作流辅助、基因集解释与通用代理 [7–11]，交互式实验对象探索和 R 模型连接也有成熟基础设施 [12,13]。但这些工具的核心任务及评价终点不同，不能把自动化能力、标签准确率与已有结果的事实传递合并成一个指标。

BioExplainR 关注“已有对象的解释与检查层”：将计数、方向、方差比例和覆盖分母交给 R；将可选模型用于组织语言；再以显式声明、图形映射、样本关系与修复条件记录检查结果。平台并不提出新的差异表达算法，而是把分散在对象、脚本、图和说明文字中的信息连接为可追踪的工作流（图 1）。本文的贡献包括统一上下文和完整事实载荷、分项验证及范围记录，以及支持代码、对象、项目、图形和报告衔接的本地浏览器工作台。六个公开来源和若干针对性案例用于展示这些设计的实际作用（表 1）；专家与用户研究的位置在文末预留。

# 2 方法

## 2.1 研究设计、版本与评价层级

研究包含对象接入、数值事实核对、受控机制挑战、模型结构化传递和工程验收五个层级。对象接入评价来源类、维度及设计字段；数值核对比较适配器值与直接源表计算；机制挑战注入事先定义的错误并检查返回状态；模型实验评价显式 fact-path 和标量值的传递；工程验收评价安装、传输、页面及下载行为。不同层级使用不同分母，不合并为总体“准确率”。

当前平台为 BioExplainR 0.4.0.9000，运行环境为 Ubuntu 24.04.4、R 4.3.3 与 Bioconductor 3.18。模型规模实验及五数据集保存结果产生于 0.3.1；本稿离线回读这些记录，并另外报告 0.4.0.9000 的 miniACC 开发案例、安装包复现和本轮新增场景。版本、命令、UTC 时间、退出码及逐文件 SHA-256 分别进入运行清单。miniACC 和新增场景用于开发应用与工程验证，不标记为冻结的独立 test/gold。

## 2.2 统一上下文与事实计算流程

平台首先依据类及接口分派输入。已测试入口包含 DESeqResults、MArrayLM、TopTags、SummarizedExperiment、SingleCellExperiment、SeuratObject、ExpressionSet、MultiAssayExperiment、prcomp、ggplot，以及符合约定的结果表；其余接口支持范围以安装帮助和数据契约为准。真实来源类可记录 verified_class，用户声明的来源记录 user_declared；列名推测不提升为来源已确认。多系数 limma 拟合要求明确所选系数。

适配后的 `bio_context` 包含分析类型、来源类与软件包、来源状态、确定性 facts、有限顶部预览、参数、图形映射和不确定性。当前契约进一步保存研究范围 scope、设计 design、事实描述符 fact_descriptors 和上下文标识。scope 记录数据集、比较、物种、组织、模态与观测层级；design 可记录独立单位、分子/分母和配对方式；描述符为事实标明特征、单位、来源路径、计算规则及完整性。软件能检查被明确提供的信息，不会从缺失字段补造研究设计。

完整输入用于适用的确定性计算，有界预览只服务展示。差异表达、富集、PCA、单细胞及多模态适配器生成类型相应的标量或结构化事实。大矩阵的某些诊断采用取样或稀疏摘要，相关检查范围保留于输出，不能由局部检查推断全矩阵均无问题。用于解释的上下文与本地原始对象分开保存，原始表达矩阵、样本映射和坐标不作为默认模型载荷。

## 2.3 阈值、缺失值及显示精度

对于给定校正阈值 α 和效应阈值 τ，差异表达筛选集合为：校正 P 值及效应非缺失、P_adj < α、且 |log2FC| > τ 的特征。上调和下调分别由集合内 log2FC 的正负确定。特征总数、显著数、上下调数、缺失校正值数均从完整提供的结果表计算。阈值使用严格小于/大于；NA 不作零，也不写为未显著的确定结论。

校正值沿用上游对象的统计流程；若用户明确要求从原始 P 值计算 BH，平台记录 computed_BH。只有原始 P 值的表格保留 raw-only 状态，不生成冒充校正显著性的计数。BH 方法参照既有定义 [14]；DESeq2 独立过滤可导致校正值缺失，应结合其来源解释 [1,15]。用于载荷及 HTTP 请求的数值保留 17 位序列化精度，文本显示可另行舍入。PCA 方差比例保存计算精度；表、图和正文中的舍入值不用于替代评分参考值。

## 2.4 模型载荷、本地解释与显式预算

本地模板无需模型连接即可输出数据事实、统计含义、候选生物学解释、不确定性与不能推出的结论。在线模式由用户配置服务 URL、密钥和模型 ID，支持 OpenAI-compatible 与 Anthropic Messages 协议。解释入口默认传递完整确定性 facts，并限制顶部预览与其他展示内容；完整 facts 超出显式字符预算时失败并说明原因，当前没有自动全覆盖分块协议。旧接口保留的 bounded 兼容策略与历史 direct_bounded 基线不代表当前默认事实载荷。

递归载荷策略过滤秘密、路径、样本/细胞标识和私有结构，并对公开证据 URL 做结构化过滤；HTTP 清单区分载荷与实际请求体的 bytes/hash，保留 usage token 计数。模型仅根据已提供事实组织文字，不承担完整长表重算，也不会自动执行生成代码。工作台默认 English，可切换简体中文；语言选择不改变 R 事实和判定规则。

## 2.5 证据检索与分项声明验证

证据检索由用户显式开启，可连接 Europe PMC、QuickGO、Reactome、KEGG 和 UniProt [16–20]。证据对象保留来源 ID、标题、URL、访问时间、提供方式、scope 与角色。检索命中、数据库注释、候选支持关系与专家确认是不同状态；平台不把题名命中自动当作论断已获支持。

显式声明验证接收上下文、声明及给定证据集合，检查事实路径、值类型、数值、方向、单位和 scope。历史机制实验使用非零参考值 10⁻⁶ 相对容差，参考为零时使用 10⁻⁶ 绝对容差，字符串精确匹配；有界顶部表路径对应保存的预览值。当前类型化声明及证据关系 findings 参与总体状态，旧兼容判定单独保留。不存在值或范围不足时为 partial/unverified，而非 pass。引用闭集检查只判断引用 ID 是否来自已提供集合，不证明文章支持论断；未声明自由文本不因数值通过而获得整体认证。

## 2.6 图形、代码记录与修复不变量

基于 ggplot2 的图形接口提供 PCA、UMAP/已有嵌入、富集气泡图与热图 [21]。图形核对使用明确的源对象：火山图比较 ID/可配对行的效应和 P 值来源；PCA 比较坐标、方差比例和轴标签；富集图比较条目、比例、Count、颜色和大小。允许预期子集必须显式指定。不能配对或超出支持图层范围时为 not_checkable。判定针对标度和坐标变换前的映射值，不覆盖所有像素、裁剪或人工注释。

用户代码通过 `bio_record_code()` 保存状态、警告、错误现场调用栈、对象摘要和软件调用表达式。显式提交的修复代码在独立 R 进程执行，并核对预先指定的类型、行数或因子水平等不变量；未设置不变量时仅记录 runtime_only。独立进程分隔会话状态，但不是操作系统沙箱。本文分别保存可运行且保持参照水平、可运行但反转参照水平的挑战，评价“可运行”与“满足指定条件”的区别。

## 2.7 多模态覆盖、依赖及明确方向关系

样本映射使用 modality、source_id、biological_unit 三个必需字段，并显式记录技术重复角色。验证器重新核对已构造映射，拒绝缺失/重复 observed ID，将观测 ID 与映射双侧比较；完整病例集合 primary_units 提供共同分母。输出包括每模态观测/缺失病例、两两交集、全部模态完整病例与未测量病例。映射的 pass 仅说明被核对的对应关系合法，不能解释为所有病例均测齐。

项目依赖图区分原始来源和派生结果，拒绝循环和未知依赖。方向关系验证针对显式 from/to 事实、共有 feature_id 与预期 same/opposite；先核对 dataset/comparison/species/tissue/sample_level、分子/分母及特征身份，再比较有限非零效应的符号。零效应或缺失科学范围不自动通过。两种效应可以具有不同量纲，因此这里仅比较符号，不比较绝对幅度；同向也不代表双方显著、机制一致、因果或独立确认。

## 2.8 公开案例及预处理

**airway：配对转录组及阈值敏感性。** 使用 airway 1.22.0 的人气道平滑肌地塞米松数据 GSE52778 [22]。保留 rowSums(counts) ≥ 10 的基因，以 `~ cell + dex` 设计拟合 DESeq2 1.42.0，设置 untrt 为参照，比较 trt 与 untrt；主阈值为 P_adj < 0.05、|log2FC| > 1，未执行 LFC shrinkage。效应阈值是结果筛选条件，不是“效应超过 1”的原假设检验。PCA 使用 VST(blind=FALSE)，选择 500 个最高方差非恒定特征，中心化、不标准化。limma voom/经验贝叶斯与 edgeR 准似然流程使用相同过滤和设计 [2,3,23]，各自结果不要求与 DESeq2 显著数相同。本轮从保存的真实 DESeqResults 回读，在 α∈{0.01,0.05,0.10}、τ∈{0,1,2} 九组条件下独立重算五项全表事实（表 2）。

airway 的 Reactome ORA 使用带哈希的映射快照，保留人类且位于差异表内的基因；以有注释基因为背景，筛选大小 10–500 的通路，做超几何检验并对全部检验 BH 校正。对象接入和解释不把 ORA 显著性直接称作通路激活。

**PBMC3k：单细胞与独立观测单位。** 使用 10x Genomics 公开过滤矩阵 [24]，保存每细胞 UMI、检测基因和线粒体比例。SCE 与 SeuratObject 对象均使用同一矩阵及单供体信息。表达按每细胞 10,000 缩放后 log1p，选择 1,000 个最高方差特征作 20 维 PCA，再由 uwot 0.1.16 生成 UMAP，种子 20261004，单线程 [25]。保留全部 2,700 个细胞，线粒体 5% 仅用于图示分组，不实施细胞类型准确率评价或供体间差异推断 [26]。本轮重新核对保存的 SCE 是否同时保留细胞数和供体数。

**pasilla、ALL 与 bladderbatch：补充来源和设计字段。** pasilla 1.30.0 使用 `~ type + condition`，比较 treated 与 untreated；沿用保存的 α∈{0.01,0.05,0.10}、τ∈{0,1} 六组阈值、五事实核对（表 3）。它未参与 airway/PBMC3k 初始开发，但这里只评价数值摘要，不是独立模型解释质量。ALL 与 bladderbatch 使用固定 Bioconductor 归档的 ExpressionSet，检查维度、分组、表型和批次字段，不重拟合差异模型或实施批次校正 [27,28]。

**miniACC：多组学覆盖与方向关系。** 使用 MultiAssayExperiment 1.28.0 内置的 TCGA-ACC 缩减对象，原研究出处和对象组织方法分别见 [6,29]。数据包含 92 个病例和 RNA、拷贝数、RPPA 蛋白、突变、miRNA 五模态。本轮纳入此前保存的开发分析与实际安装包重跑。先校验 sampleMap 与实验列名，再以全部 92 个病例为分母统计覆盖。在 RNA/蛋白均有测量且分期已知的病例中，stage I/II 为 early，III/IV 为 late；按共有行名选特征，RNA 使用 log2(归一化表达+1)，蛋白保留 RPPA 标准化值。每模态效应为 mean(late)−mean(early)，Wilcoxon 秩和检验使用 exact=FALSE、correct=TRUE，BH 在各模态的 33 特征内分别计算（表 4、表 5）。这不是配对 early/late 的检验：配对指同一病例同时具有 RNA 与蛋白，分期组之间是不同病例。分期未随机化，未调整年龄、肿瘤纯度或分子亚型；缩减对象的选择范围不支持新的临床结论。

## 2.9 历史输入消融、双模型及评分规则

历史主消融使用 120 个可复现程序案例：差异表达 30、富集 20、PCA 20、SCE 20、细胞组成 15、generic 15；每案例四个标量目标，共 480 个唯一目标。比较 direct_bounded（有限原始预览）、facts_only（R 全输入计算事实）和 facts_evidence（同一事实加保存 Europe PMC 记录）。三方法各重复三轮，共 1,080 实际请求、4,320 逐事实评分；每方法分母 1,440。参考事实从完整源对象计算，不使用模型响应。

DeepSeek deepseek-flash 请求采用 OpenAI-compatible、temperature=0、thinking disabled、JSON mode、5,000 输出 token 上限、120 秒 timeout，瞬时错误最多重试一次。direct_bounded 允许无法判断时返回 null；它是信息受限基线，不是代码执行代理。匹配率=匹配目标/全部目标，覆盖率=已回答标量/全部目标，已回答准确率=匹配/已回答。未回答记为未完成，不填补。重复共享输入与目标，只作描述性统计，不当作独立生物数据推断。

双模型共同任务使用相同 120 案例和 480 目标，StepFun step-5-preview 与 DeepSeek deepseek-flash 各调用一轮，temperature=0、最多 800 输出 token，最终均关闭 response_format=json_object。输入、提示、预算和评分相同，提示要求完整精度小数复制。模型别名无不可变快照，跨时间确定性未获保证。本轮只核对保存响应，不新增在线请求（表 6、表 7）。相关工具的保存入口检查涉及 iSEE 真实 SCE/UMAP 浏览器、GPTCelltype marker 到提示、ellmer 与本平台的响应 replay；这些不是完整共同任务性能排名。

## 2.10 机制挑战、新增场景与工程复现

历史声明挑战在 18 个事实加证据响应中分别注入错误数字、未知路径、向量值、未知引用及仅路径无值声明，共 90 项；移除验证器记为 unchecked。图形挑战为三张正确图与六种注入错误；修复挑战为保持/反转 untrt 参照水平的两段可运行代码。

本轮新脚本 `research/paper_cn/run_cases.R` 从保存公开对象和手算 fixture 执行 15 个场景（表 8）：阈值核对、单供体保留、正确/错误 PCA、raw-only、完整事实超预算、合法但不完整的映射、观测未映射、病例越界、正确/错误跨模态关系、反转比较、范围缺失以及工作台项目分派。每项事先写明预期状态；错误注入标明 controlled mutation，不作为自然发生率估计。

工程检查包括源码 testthat、构建包检查、真实安装及 Imports-only smoke、历史 API 名称/位置参数、两种协议的实际 HTTP bytes/hash、浏览器桌面 1440 与移动 390 像素视口，以及独立 bwrap 边界探针。浏览器以真实 miniACC 项目检查覆盖、方向 findings 和报告回读，并下载实际生成的 PCA PDF。不同连接各有独立工作区，但仍共享 R/文件/网络权限；bwrap 的独立探针不能用于宣称 Shiny 为多租户沙箱。Python 独立实现从保存长表重算 miniACC 66 个效应、符号、覆盖和 BH，未独立重算原始 Wilcoxon P 值或从 RDS 解码原矩阵（表 9）。

# 3 结果

## 3.1 配对转录组案例：完整计数、方向与阈值一起保留

airway 的 63,677 个原始特征经固定过滤保留 22,369 个。主阈值下的 999 个显著特征由 519 个上调和 480 个下调构成；5,204 个校正值缺失，17,165 个校正值非缺失，原始 P 值均非缺失。仅要求 P_adj < 0.05 与非零效应时为 4,030 个。本轮九组阈值对应的 45 项事实全部与直接源表重算一致（表 2），说明摘要随阈值变化而同步，且顶部预览没有替代全表计数（图 2A、2C）。

配对 PCA 的 PC1 与 PC2 分别解释 47.8429% 和 23.3834% 方差，图中保留四个供体内的处理前后连接（图 2B）。同一过滤和设计下，limma 与 edgeR 分别得到 1,301 和 1,292 个显著特征（图 2D）；差异来自上游方法，平台保留其来源及数值，不强制统一结果。Reactome ORA 检验 1,104 个通路，只有 Interleukin-4 and Interleukin-13 signaling（R-HSA-6785807）通过 BH：重叠 16 基因、P=1.9558×10⁻⁵、P_adj=0.02159。该案例展示了把处理方向、独立供体、上游统计来源与候选解释同时带入报告的能力，而非新增通路激活结论。

## 3.2 单细胞和微阵列案例：观测数量不替代研究单位

PBMC3k 的 SCE 和 SeuratObject 均提取到 2,700 个细胞与 32,738 个特征，供体数保持为 1。本轮单供体场景再次通过，工作流没有将细胞数提升为独立样本数。UMAP 和线粒体比例展示了已有嵌入及 QC 的接入（图 3A、3B），摘要另行保留“2,700 细胞 / 1 供体”的层级信息（图 3C）。这一分离有助于约束解释终点：图形邻近不能自动变成细胞类型、因果或供体间差异推断。

ALL 的 ExpressionSet 提取到 12,625 个特征、128 个样本及 BT 字段的 10 个观察分组；bladderbatch 提取到 22,283 个特征、57 个样本、3 个癌症分组和 5 个批次（图 3D、表 1）。对这两类对象，平台的作用是展示设计字段并记录解释边界，不能把摘要通过当作已完成批次校正或疾病效应复现。

## 3.3 pasilla 案例：独立来源的数值一致性

pasilla 保存分析包含 14,599 个特征和 7 个文库。六个阈值组合的 30 项特征、显著、上下调和缺失校正值核对全部一致（图 4、表 3）。P_adj < 0.05、|log2FC| > 1 时为 218 个显著特征，上调 108、下调 110，校正值缺失 5,800。以另一来源复用同一提取规则，支持事实接口在所测对象上的一致性；本轮未重拟合上游模型，亦未对独立解释质量或生物学泛化给出评价。

## 3.4 miniACC 案例：覆盖、同向与显著性分开呈现

在统一的 92 病例分母下，RNA、拷贝数、RPPA、突变及 miRNA 分别观测 79、90、46、90 和 80 个病例。五模态完整病例只有 43 个，尽管样本映射本身通过核对（图 5A、表 4）。这一结果说明“映射合法”和“数据齐全”是两个不同终点，平台能显示缺失覆盖而不将 pass 解释为全模态完整。

RNA/蛋白均测量且分期已知的 46 病例包括 early 28、late 18，共有 33 个特征。18 个特征效应同向、15 个反向；RNA 有 3 个特征通过 BH < 0.05，蛋白为 0（图 5B–5D、表 5）。例如 BRCA2、CDK1 和 GATA3 的 RNA 效应分别约为 +1.233、+1.735 和 +2.315，而蛋白效应分别约为 −0.054、−0.063 和 −0.114；它们的 RNA BH 值约为 0.0315、0.0149、0.0149，蛋白均未通过阈值。实例直观显示 RNA 变化不能直接替代蛋白变化。

方向关系检查同时保留特征、比较和范围 findings；当把全部关系预设为 same 时，反向特征返回不一致，这不是程序失败，而是对预设陈述的反证。实际安装包重跑与开发运行的八个核心表逐字节一致；Python 从保存测量重算 66 效应、方向、覆盖及 BH 通过。它们支持工程复现和数值一致性，不增加独立队列。该案例的优势是把缺失模态、共有特征、配对病例与关联边界放到同一项目，避免将方向一致包装为显著性或独立生物学确认。

## 3.5 输入消融：显式 R 事实改善目标传递覆盖

历史主实验的 1,080 请求均成功并可解析。有界原始输出匹配 437/1,440（30.35%），覆盖 516/1,440（35.83%），已回答准确率 437/516（84.69%）；两种 R 事实方法的匹配、覆盖和已回答准确率均为 100%（图 6A、6B、表 6）。有界基线的低总体匹配主要受输入信息不足影响，例如差异表达全表计数只回答 9/360、generic 目标为 0/180；因此不能把这项对照解释为模型独立计算能力的公平排名。

六类功能家族的差异见图 6C 和表 7。direct_bounded 三轮分别匹配 149、143、145 个目标/480；R 事实方法每轮均为 480/480。三方法中位响应时间为 2.230、2.680 和 2.905 秒，重复共享同一案例，未作独立样本统计推断。事实加证据没有在该数值终点超过事实方法；其引用来源作用与数值传递需分开评价。

双模型共同任务中，StepFun 与 DeepSeek 各 120 实际请求，均回答并匹配 480/480 个目标（图 6D、表 7）。同一记录中的未配置代码代理与缺失 replay 条件不计入 API 分母。100% 表示模型接收了 R 已计算的目标事实后，在当前协议下成功传递，并不意味着自由文本、机制解释或新的知识发现准确率为 100%。

## 3.6 机制和新增场景：明确错误被拒绝，缺信息保持未验证

历史验证器将错误数字、未知路径、向量值和未知引用全部判为 fail（72/72），仅路径无值为 partial（18/18）；去除验证器时这些记录均为 unchecked（图 7A）。图形挑战中，三张正确图为 pass、六种注入错误为 fail（图 7B）。两段修复都可运行，只有保持 untrt 参照的方案满足不变量，反转参照的方案为 invariants_failed（图 7D）。

本轮新增 15 场景全部返回预期状态：8 项预期 pass、5 项 fail、1 项 partial、1 项 unverified（图 7C、表 8）。正确 PCA 与源坐标一致；单点坐标漂移及错误方差标签被拒绝；观察但未映射的样本为 partial；缺失比较范围的方向关系保留 unverified；反转比较分子/分母与错误关系为 fail。手算三病例映射即使合法，也仍显示 1 个全模态完整和 1 个未测量病例。完整事实超出极小预算时明确失败，没有静默省略事实。

这些例子支持“检查范围显式化”和“可定位违例”的设计。另一方面，历史一条数值与引用均通过的响应仍在自由文本中暗示执行了 shrinkage，而原流程未执行 lfcShrink。该语义负例说明显式声明通过不能自动覆盖未声明措辞，平台仍需呈现未验证内容。

## 3.7 工作台与工程：项目解释和论文图导出连续衔接

本轮源码 testthat 677 项中 676 通过、1 跳过，失败/错误/警告为零；唯一跳过是已有真实 DESeq2 类时不重定义模拟类。实际源码包构建成功，R CMD check 为 Status: OK（表 9）。此前 10-08 的源码及安装包历史 API 名称/位置参数各为 74/74、实际安装导出函数为 90；这些接口级检查不代表全部行为等价。

写作案例发现工作台缺少项目专用分派：bio_project 会进入单对象解释路径。修复后，真实 miniACC 项目直接展示摘要、依赖、主病例分母、模态覆盖、两两交集及方向 findings，并生成同一项目的中文报告（图 8A、8B）。绘图页新增 Cairo PDF 下载，失败时清空旧图；实际浏览器生成并回读一页 PCA PDF（图 8C）。英文/中文、HTML 转义、payload/manifest、MAE、项目、下载和两会话隔离共七组验收通过，1440/390 视口无页面横向溢出（图 8D、表 9）。项目宽表在自身容器内滚动，原始病例 ID 不进入展示与报告。

模型协议和独立 bwrap 边界仍引用此前 10-08 的实际日志：两协议请求体 bytes/hash、极小 P 值、PCA 精度、null、usage、重试与 401 行为均已验证；只读、越界写入、未挂载 gold/home、无 host 网络、scratch 输出和资源 timeout 按预期。工程保障增强复现透明性，但不能替代独立科学、专家或用户收益评价。

# 4 讨论

## 4.1 平台优势来自计算、解释和检查的明确分工

本文案例展示三项互补优势。首先，R 从完整输入计算事实，使模型无需从顶部行猜测全表数量；airway 的阈值敏感性与历史消融体现了这一点。其次，来源、比较方向、独立单位和覆盖共同分母随解释保留，PBMC3k 与 miniACC 展示了“观测很多”与“独立证据充足”之间的区别。第三，检查返回具体范围与 findings：图形、声明、样本映射和修复条件可以分别通过或失败，报告不需要用单一总体可信度掩盖局部问题。

这些优势是工作流设计的贡献，并非新的统计模型。平台在已有 DESeq2、limma、edgeR 和对象基础设施上增加可追踪解释层；它既可以离线模板工作，也能把同一事实交给用户配置的语言模型。模型的作用是组织措辞，关键计数和范围不依赖在线服务成功。

## 4.2 数值传递、证据追踪与科学解释应分别评价

显式事实的 100% 匹配是目标已在输入中的管道传递结果。direct_bounded 的不足部分源于缺少完整信息，因此不支持对通用代码代理或模型推理能力作优劣结论。双模型结果也只覆盖固定结构化目标与当时服务别名，不能推断长期稳定性。

同样，引用 ID 位于给定集合只能建立来源闭集，不能确定文章支持某一结论；miniACC 的同向效应只能形成关联假设，不能消除组间混杂或成为独立确认。平台应提供可审查材料，再由研究者评价实验设计、文献内容和解释合理性。自由文本 shrinkage 负例进一步表明，数值正确可与错误措辞共存。

## 4.3 局限性

六个公开来源承担不同任务，不能合并为六个独立模型泛化测试。模型消融使用程序生成案例且共享目标；新场景用于开发，受控违例不估计自然错误检出率。pasilla 提供另一来源的数值基准，miniACC 提供缩减多组学应用，但没有冻结独立科学 test/gold。Python 复核不包含 Wilcoxon 原始 P 独立重算，实际安装包复现也不是新队列。图形检查仍限于支持映射与图层，空间、跨物种和复杂联合关系不在本文的完整验收范围。

工程层面尚无全自动全覆盖分块、全部 API 行为独立确认、全新 OS/transitive lock 与远程平台矩阵验收。Shiny 为本地共享权限工具，不是多租户沙箱。当前结果没有建立初级研究者任务完成、认知负荷、信任校准或学习增益；专家评价和用户体验保持后置，后续研究入口列于附录 C。

# 5 结论

BioExplainR 将已有 R 生物信息学结果转化为保留确定性事实、来源、科学范围和分项检查状态的解释与项目报告。转录组、单细胞和多组学案例支持其完整计数、范围显式化与受控错误定位能力。本稿提供可复现开发证据及中文方法描述；科学解释质量、独立泛化与真实用户收益将在后续评价中补充。

# 数据、代码与稿件信息

**软件与许可证。** 当前开发版 BioExplainR 0.4.0.9000，MIT，R ≥ 4.1.0。源码、帮助、案例与复现脚本保存于项目。公开代码地址：［待填写］；版本归档/DOI：［待填写］。

**数据及图表。** 公开数据来源、分析边界见表 1。主图均集中于附录 A；每张合图从四张独立 PDF 排版合成，合图与子图分别保存在 `figures/composites/` 和 `figures/panels/`。表格数据不嵌入论文，9 份可编辑 XLSX 与 CSV 保存在 `tables/`，表题、表注及来源集中于附录 B。运行记录见 `research/results/paper_cn_cases_v1/`、`miniacc_installed_review/` 与 `w00_baseline/`；历史模型记录仍按原目录回读。图 8 的截图来自真实浏览器测试。

**作者贡献：**［待填写］。

**经费：**［待填写］。

**利益冲突：**［待填写］。

**伦理及人员研究信息：** 当前稿件报告公开数据复用与软件验证；专家和用户研究部分待实际开展后补充相关信息。

**AI 使用说明：** AI 助手用于软件开发、稿件与图表整理；历史模型实验使用授权接口。统计数字以保存源结果及计算记录为依据，生成文字不作为独立参考真值。作者核对与最终确认位置：［待填写］。

# 参考文献

1. Love MI, Huber W, Anders S. Moderated estimation of fold change and dispersion for RNA-seq data with DESeq2. Genome Biol. 2014;15:550. doi: [10.1186/s13059-014-0550-8](https://doi.org/10.1186/s13059-014-0550-8).
2. Ritchie ME, et al. limma powers differential expression analyses for RNA-sequencing and microarray studies. Nucleic Acids Res. 2015;43:e47. doi: [10.1093/nar/gkv007](https://doi.org/10.1093/nar/gkv007).
3. Robinson MD, McCarthy DJ, Smyth GK. edgeR: a Bioconductor package for differential expression analysis of digital gene expression data. Bioinformatics. 2010;26:139–140. doi: [10.1093/bioinformatics/btp616](https://doi.org/10.1093/bioinformatics/btp616).
4. Amezquita RA, et al. Orchestrating single-cell analysis with Bioconductor. Nat Methods. 2020;17:137–145. doi: [10.1038/s41592-019-0654-x](https://doi.org/10.1038/s41592-019-0654-x).
5. Hao Y, et al. Dictionary learning for integrative, multimodal and scalable single-cell analysis. Nat Biotechnol. 2024;42:293–304. doi: [10.1038/s41587-023-01767-y](https://doi.org/10.1038/s41587-023-01767-y).
6. Ramos M, et al. Software for the integration of multi-omics experiments in Bioconductor. Cancer Res. 2017;77:e39–e42. doi: [10.1158/0008-5472.CAN-17-0344](https://doi.org/10.1158/0008-5472.CAN-17-0344).
7. Hou W, Ji Z. Assessing GPT-4 for cell type annotation in single-cell RNA-seq analysis. Nat Methods. 2024;21:1462–1465. doi: [10.1038/s41592-024-02235-4](https://doi.org/10.1038/s41592-024-02235-4).
8. Nagarajan V, et al. SCassist: an AI based workflow assistant for single-cell analysis. Bioinformatics. 2025;41:btaf402. doi: [10.1093/bioinformatics/btaf402](https://doi.org/10.1093/bioinformatics/btaf402).
9. Wang Z, et al. GeneAgent: self-verification language agent for gene-set analysis using domain databases. Nat Methods. 2025;22:1677–1685. doi: [10.1038/s41592-025-02748-6](https://doi.org/10.1038/s41592-025-02748-6).
10. Lobentanzer S, et al. A platform for the biomedical application of large language models. Nat Biotechnol. 2025;43:166–169. doi: [10.1038/s41587-024-02534-3](https://doi.org/10.1038/s41587-024-02534-3).
11. Huang K, et al. Biomni: a general-purpose biomedical AI agent. bioRxiv. 2025. doi: [10.1101/2025.05.30.656746](https://doi.org/10.1101/2025.05.30.656746). ［预印本］
12. Rue-Albrecht K, et al. iSEE: Interactive SummarizedExperiment Explorer. F1000Res. 2018;7:741. doi: [10.12688/f1000research.14966.1](https://doi.org/10.12688/f1000research.14966.1).
13. Posit/tidyverse. ellmer: Chat with Large Language Models. [https://ellmer.tidyverse.org/](https://ellmer.tidyverse.org/). ［软件文档，访问2026-10-04］
14. Benjamini Y, Hochberg Y. Controlling the false discovery rate: a practical and powerful approach to multiple testing. J R Stat Soc Series B. 1995;57:289–300. doi: [10.1111/j.2517-6161.1995.tb02031.x](https://doi.org/10.1111/j.2517-6161.1995.tb02031.x).
15. Bourgon R, Gentleman R, Huber W. Independent filtering increases detection power for high-throughput experiments. Proc Natl Acad Sci USA. 2010;107:9546–9551. doi: [10.1073/pnas.0914005107](https://doi.org/10.1073/pnas.0914005107).
16. Europe PMC Consortium. Europe PMC: a full-text literature database for the life sciences and platform for innovation. Nucleic Acids Res. 2015;43:D1042–D1048. doi: [10.1093/nar/gku1061](https://doi.org/10.1093/nar/gku1061).
17. Binns D, et al. QuickGO: a web-based tool for Gene Ontology searching. Bioinformatics. 2009;25:3045–3046. doi: [10.1093/bioinformatics/btp536](https://doi.org/10.1093/bioinformatics/btp536).
18. Gillespie M, et al. The Reactome pathway knowledgebase 2022. Nucleic Acids Res. 2022;50:D687–D692. doi: [10.1093/nar/gkab1028](https://doi.org/10.1093/nar/gkab1028).
19. Kanehisa M, Goto S. KEGG: Kyoto Encyclopedia of Genes and Genomes. Nucleic Acids Res. 2000;28:27–30. doi: [10.1093/nar/28.1.27](https://doi.org/10.1093/nar/28.1.27).
20. UniProt Consortium. UniProt: the Universal Protein Knowledgebase in 2023. Nucleic Acids Res. 2023;51:D523–D531. doi: [10.1093/nar/gkac1052](https://doi.org/10.1093/nar/gkac1052).
21. Wickham H. ggplot2: Elegant Graphics for Data Analysis. Springer; 2016. doi: [10.1007/978-3-319-24277-4](https://doi.org/10.1007/978-3-319-24277-4).
22. Himes BE, et al. RNA-Seq transcriptome profiling identifies CRISPLD2 as a glucocorticoid responsive gene that modulates cytokine function in airway smooth muscle cells. PLoS One. 2014;9:e99625. doi: [10.1371/journal.pone.0099625](https://doi.org/10.1371/journal.pone.0099625).
23. Law CW, et al. voom: precision weights unlock linear model analysis tools for RNA-seq read counts. Genome Biol. 2014;15:R29. doi: [10.1186/gb-2014-15-2-r29](https://doi.org/10.1186/gb-2014-15-2-r29).
24. 10x Genomics. 3k PBMCs from a Healthy Donor, Chromium Single Cell Gene Expression v1.1.0. [公开矩阵归档](https://cf.10xgenomics.com/samples/cell-exp/1.1.0/pbmc3k/pbmc3k_filtered_gene_bc_matrices.tar.gz). ［公开数据集］
25. McInnes L, Healy J, Melville J. UMAP: Uniform Manifold Approximation and Projection for Dimension Reduction. arXiv. 2018;1802.03426. [https://arxiv.org/abs/1802.03426](https://arxiv.org/abs/1802.03426). ［预印本］
26. Squair JW, et al. Confronting false discoveries in single-cell differential expression. Nat Commun. 2021;12:5692. doi: [10.1038/s41467-021-25960-2](https://doi.org/10.1038/s41467-021-25960-2).
27. Bioconductor. ALL 1.44.0. [https://bioconductor.org/packages/3.18/data/experiment/html/ALL.html](https://bioconductor.org/packages/3.18/data/experiment/html/ALL.html). ［数据包］
28. Bioconductor. bladderbatch 1.40.0. [https://bioconductor.org/packages/3.18/data/experiment/html/bladderbatch.html](https://bioconductor.org/packages/3.18/data/experiment/html/bladderbatch.html). ［数据包］
29. Zheng S, et al. Comprehensive Pan-Genomic Characterization of Adrenocortical Carcinoma. Cancer Cell. 2016;29:723–736. doi: [10.1016/j.ccell.2016.04.002](https://doi.org/10.1016/j.ccell.2016.04.002).

# 附录 A：框架图与各结果合图

合图按正文引用编号排列。每图由四张独立 PDF 使用保持矢量内容的 PDF 排版方式组成；论文 PDF 的本附录直接嵌入合图 PDF，Word 和网页使用其高分辨率预览。框架图包含原创数据库、图形、网络、校验和报告图标；真实页面截图为位图素材，其余框架/统计元素保留矢量。各合图与子图原件见专用目录。

## 图 1 平台框架

![BioExplainR framework](paper_cn_v1/figures/previews/Figure_1.png){width=16cm}

**图 1. 从已有 R 对象到可追踪解释的 BioExplainR 框架。**（A）以数据库、统计图、网络、校验和文档图标展示对象→确定性事实→可选语言→分项检查→输出流程；（B）本地计算与模型载荷边界，完整标量事实超预算时明确失败；（C）pass、fail、partial 与 unverified 的独立状态；（D）源队列及 RNA/蛋白派生结果的依赖关系。同一来源的结果不能当作独立确认。合图原件：`figures/composites/Figure_1.pdf`；子图：`figures/panels/Figure_1A.pdf` 至 `Figure_1D.pdf`。

## 图 2 配对转录组案例

![airway case](paper_cn_v1/figures/previews/Figure_2.png){width=16cm}

**图 2. airway 的全表统计、配对结构与阈值敏感性。**（A）trt/untrt 火山图，主阈值为 P_adj < 0.05、|log2FC| > 1，999 个显著特征中上调 519、下调 480；（B）VST 后 500 个高方差特征 PCA，PC1/PC2 为 47.8429%/23.3834%，连接线对应四个供体内的配对文库；（C）九组阈值的显著数轨迹，五事实×九条件均与直接源表相符；（D）DESeq2、limma、edgeR 方法各自的显著数。图 B 的 8 文库不是 8 独立供体；图 D 不构成方法优劣排名。原件：`figures/composites/Figure_2.pdf` 与 `figures/panels/Figure_2[A-D].pdf`。数值来源见表 2 及数据清单。

## 图 3 单细胞与微阵列案例

![single-cell and microarray cases](paper_cn_v1/figures/previews/Figure_3.png){width=16cm}

**图 3. 细胞、供体和设计字段的分层摘要。**（A）PBMC3k 已有 UMAP，以线粒体比例≤5%/>5%着色；（B）线粒体比例分布及展示阈值，未据此排除细胞；（C）2,700 细胞、32,738 特征与单供体的不同层级；（D）ALL 与 bladderbatch 样本量及表型/批次字段摘要。QC 颜色不是细胞类型，UMAP 不用于推断供体间差异；微阵列摘要不是批次校正结果。原件：`figures/composites/Figure_3.pdf` 与 `figures/panels/Figure_3[A-D].pdf`。来源见表 1。

## 图 4 pasilla 数值基准

![pasilla benchmark](paper_cn_v1/figures/previews/Figure_4.png){width=16cm}

**图 4. pasilla 独立来源的保存数值核对。**（A）保存 VST PCA；（B）treated/untreated 火山图；（C）主阈值下上调 108、下调 110，共 218；（D）六组阈值的显著数，30 项源表事实均一致。分析设计为 `~ type + condition`，校正值缺失 5,800；本轮回读保存结果，没有重拟合上游模型。原件：`figures/composites/Figure_4.pdf` 与 `figures/panels/Figure_4[A-D].pdf`。逐项数据见表 3。

## 图 5 miniACC 多组学案例

![miniACC multiomics](paper_cn_v1/figures/previews/Figure_5.png){width=16cm}

**图 5. 多组学覆盖、方向与显著性的分离展示。**（A）92 病例分母下各模态覆盖，灰段为未测量，五模态完整病例为 43；（B）33 共有特征的 RNA 与蛋白 late−early 效应，18 同向、15 反向；（C）两模态 BH 校正值，特征按字母顺序，RNA 3/33、蛋白 0/33 通过0.05；（D）46 配对测量病例的分期组，early 28、late 18。RNA 和 RPPA 单位不同，图 B 只核对符号、不比较效应幅度。分期组不配对、不随机化；同病例跨模态测量和符号一致不建立独立证据或因果。原件：`figures/composites/Figure_5.pdf` 与 `figures/panels/Figure_5[A-D].pdf`。数值见表 4–5。

## 图 6 模型事实传递

![fact-transfer ablation](paper_cn_v1/figures/previews/Figure_6.png){width=16cm}

**图 6. 固定目标事实的输入消融与双模型协议结果。**（A）三输入总体匹配率；（B）覆盖与已回答准确率；（C）六功能家族匹配率；（D）相同输入下 StepFun 与 DeepSeek 各匹配480/480。A–C 为120程序案例、480唯一事实、三方法×三重复，共1,080请求与4,320评分；D各模型120请求，不与主消融分母相加。100%是R目标已显式提供后的结构化传递终点，有界raw缺少完整信息；不是自由文本正确率、独立推理或生物学泛化。全部为0.3.1保存记录，本轮没有在线调用。原件：`figures/composites/Figure_6.pdf` 与 `figures/panels/Figure_6[A-D].pdf`。数据见表 6–7。

## 图 7 受控错误与新增场景

![controlled mechanism cases](paper_cn_v1/figures/previews/Figure_7.png){width=16cm}

**图 7. 分项验证拒绝明确违例并保留信息不足状态。**（A）历史声明72个明确错误fail、18个仅路径partial；（B）3正确图pass、6注入错误fail；（C）本轮15场景按预期返回pass/fail/partial/unverified，合计15/15；（D）参照保持与反转代码均可运行，但仅前者满足不变量。A、B、D为历史机制记录，C为本轮实际运行；数值不合并为自然错误率或一般修复成功率。原件：`figures/composites/Figure_7.pdf` 与 `figures/panels/Figure_7[A-D].pdf`。新增场景列表见表 8。

## 图 8 工作台与工程验收

![workbench and engineering](paper_cn_v1/figures/previews/Figure_8.png){width=16cm}

**图 8. 项目分析到论文图 PDF 导出的实际工作流。**（A）真实 miniACC 项目的中文桌面页面；（B）同项目移动视口，宽表在容器内滚动；（C）浏览器实际下载的 Cairo PCA PDF 回读预览，该图为手算工程输入，不是生物数据结果；（D）源码、安装及浏览器的分层检查。截图裁剪自自动化保存页面，未重绘页面。项目展示保留覆盖与方向findings，下载报告使用同一项目；不同浏览器工作区独立仍不等于多租户安全沙箱。原件：`figures/composites/Figure_8.pdf` 与 `figures/panels/Figure_8[A-D].pdf`。验收范围见表 9。

# 附录 B：外置表格的表题、表注与来源

本附录仅保留表题和说明，不插入表格数据。表 1–9 的 XLSX 与 UTF-8 CSV 逐一保存在本稿 `tables/` 目录；每个 XLSX 另含“图表说明与来源”工作表。正文引用使用相同编号。

## 表 1 案例数据、版本与分析边界

**表注：** 列出六个公开数据来源、所测对象/软件版本、规模与各自任务。airway 为8文库/4供体，PBMC3k 为2,700细胞/1供体，miniACC 为92病例；不同观测单位和任务不合并为研究样本量。**来源：** `data_manifest.json`、`public_datasets/dataset_tests.json`、`miniacc_installed_review/summary.json`。**文件：** `tables/Table_1.xlsx`、`tables/Table_1.csv`。

## 表 2 airway 阈值敏感性及适配器核对

**表注：** α为0.01/0.05/0.10、τ为0/1/2，共九组合，每组合核对特征数、显著数、上/下调数与缺失校正值；45项全部一致。筛选使用P_adj<α与|log2FC|>τ，NA不作零。**来源：** `paper_cn_cases_v1/airway_threshold_checks.csv`。**文件：** `tables/Table_2.xlsx`、`tables/Table_2.csv`。

## 表 3 pasilla 独立来源数值事实核对

**表注：** 六阈值组合×五事实=30项，保存适配器值与直接源表值一致。仅评价数值事实，不代表独立模型解释评价；本轮未重拟合pasilla。**来源：** `related_tools/pasilla_fact_checks.csv`。**文件：** `tables/Table_3.xlsx`、`tables/Table_3.csv`。

## 表 4 miniACC 模态覆盖及统一分母

**表注：** 每模态观测/缺失病例以完整92病例为共同分母，完全观测43、未观测0。合法映射的pass不表示模态齐全；两个模态的交集另存项目结果。**来源：** `miniacc_installed_review/modality_coverage.csv`、`alignment_summary.json`。**文件：** `tables/Table_4.xlsx`、`tables/Table_4.csv`。

## 表 5 miniACC 33特征效应、方向及显著性

**表注：** 46病例（early28/late18）中效应为late均值−early均值；RNA单位为log2(归一化表达+1)，蛋白为原RPPA单位。Wilcoxon使用渐近及连续性校正，BH按各模态33特征分别计算。same/opposite为符号关系，不替代P值、机制或独立证据。**来源：** `miniacc_installed_review/feature_results.csv`。**文件：** `tables/Table_5.xlsx`、`tables/Table_5.csv`。

## 表 6 保存的主消融实验

**表注：** 每方法360请求、1,440目标评分，总1,080请求/4,320评分。匹配率、覆盖和已回答准确率分母分别为全部目标、全部目标、已回答目标；不把重复当独立生物数据。raw为信息受限基线，facts为目标显式提供后的传递。**来源：** `main_scale_480/ablation_summary.csv`。**文件：** `tables/Table_6.xlsx`、`tables/Table_6.csv`。

## 表 7 六类功能家族与双模型事实传递

**表注：** 前18行汇总六家族×三方法的主消融；后两行分别为StepFun与DeepSeek单轮的480目标。不同实验分母分开解释，未配置代理和缺失replay不进入API请求数。**来源：** `main_scale_480/family_summary.csv`、`common_task_scale_480/common_task_summary.csv`。**文件：** `tables/Table_7.xlsx`、`tables/Table_7.csv`。

## 表 8 新增开发场景的期望状态与实际状态

**表注：** 15场景均按预期；每行标明来源、目的、期望和实际状态。controlled mutation为人为注入，hand-computable fixture为手算工程样例，两者均不当作自然生物学样本。**来源：** `paper_cn_cases_v1/scenario_checks.csv`。**文件：** `tables/Table_8.xlsx`、`tables/Table_8.csv`。

## 表 9 工程验收与复现层级

**表注：** 本轮源码、包和浏览器日志与此前安装/API/miniACC数值复核分别注明。74/74只为历史名称/位置参数，Python复核未独立重算Wilcoxon原始P。工程pass不表示专家、用户或科学泛化结果。**来源：** `w00_baseline/paper-cn-*`、`review-*` 与 `REVIEW_CONTINUATION.md`。**文件：** `tables/Table_9.xlsx`、`tables/Table_9.csv`。

# 附录 C：后续可补充的研究与稿件内容

本节预留后续内容的位置，当前不填写专家分数、用户评价或体验结果。

## C.1 独立专家评价［待补充］

待软件、案例及评价材料准备完成后，可补充专家背景与评价流程、冻结案例/参考材料、匿名方法、独立评分、分歧处理以及统计/生物学论断支持程度。结果、图表编号与讨论位置均留待实际评价完成后扩展。

## C.2 用户使用体验与可用性［deferred；待补充］

可补充初级研究者的真实任务体验、结果理解正确率、错误发现率、完成时间、认知负荷、界面易用性、信任校准和访谈。届时应说明任务、样本来源、对照和量表；目前不填写用户满意度或使用收益结论。

## C.3 学习效果与独立验证［待补充］

可进一步增加预注册的学习前后对照、知识迁移、独立数据/冻结test-gold、更多模型及相近工具的共同任务比较。该部分应与当前确定性数值传递和工程终点分别报告。

## C.4 投稿信息与最终图稿审阅［待补充］
作者、单位、通讯、真实贡献、基金、利益冲突、公开代码归档及最终人工图稿审阅位置均已预留；人员研究开展后再填写实际伦理/同意信息。本版本为中文初稿，后续英文稿与期刊格式在内容审定后整理。
