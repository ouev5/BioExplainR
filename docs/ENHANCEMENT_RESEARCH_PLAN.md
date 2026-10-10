# BioExplainR 独立研究与补充材料框架

规划 v1.0，2026-10-05。对应 [总体框架](ENHANCEMENT_FRAMEWORK.md) 和 [任务卡](ENHANCEMENT_TASKS.md) 中 W09–W13。本文件描述后续方案，不包含新增实验、专家评分或伦理结论。

## 1. 研究问题与评价层级

主要问题：在相同任务和可比信息/预算下，BioExplainR 是否减少错误或无支持的组学解释，同时保持必要回答覆盖率？

| 层级 | 评价对象 | 参考来源 | 可支持的主张 |
|---|---|---|---|
| A 对象接入 | adapter 提取的事实、设计与范围 | 独立源表计算、上游 accessor、可手算 fixture | 对象适配和事实提取一致性 |
| B 传输保真 | 给定 facts 到模型结构化值 | 已冻结输入 facts | 精度、覆盖率和协议可靠性 |
| C 统计/生物学判断 | raw/padj、效应、重复单位、因果边界等 | 独立专家标准、真实情境 | 减少错误判断或无支持表述 |
| D 证据支持 | claim–evidence 关系 | 领域双评、范围及原文定位 | 支持关系质量与错误引用控制 |
| E 用户任务 | 实际任务正确率、时间、校准等 | 预设任务答案及真实参与者 | 特定人群和任务中的用户收益 |

当前已有的 120 案例/480 facts 归入 B 和部分机制验证；五数据集接入与 pasilla 数值核对归入 A。已有外部评分作为描述性 pilot，不能替代 C/D 的独立测试或 E 的对照任务。

软件验证器输出作为被评价对象之一，不能同时作为自己的科学解释质量金标准。

## 2. 研究设计先冻结的内容

在最终模型调用前确定并登记：

- 主要假设、主要终点和主要比较；分母、分析单位、缺失与拒答处理。
- dataset/study、case、claim、evidence pair、repeat 的层级与 ID。
- dev/validation/test 的划分、数据可见范围、冻结时间和 hash。
- 模型标识、服务方、日期、温度、输出预算、prompt 版本、JSON mode、重试、修订次数和最大费用。
- 证据检索快照、检索截止点、候选来源和支持关系 rubric。
- 专家背景、独立评分、盲法、分歧裁决和可靠性分析。
- 主案例 QC、样本排除、模态/feature 对齐、候选筛选和负对照。
- 统计分析、区间计算、少数主要比较及探索性比较处理。

协议建议保存为 `research/frozen_benchmark/protocol.md`。冻结是可核查的时间与内容记录，不以目录名带 frozen 即认定完成。

## 3. 开发与测试隔离

### 3.1 数据分层

按研究/队列或真正独立的数据来源划分，优先级高于按 claim 随机划分。同一源对象衍生的 DE、富集、图形、阈值变体、prompt 改写和重复调用属于同一 cluster，不能跨 dev/test 制造独立性。

| 集合 | 允许用途 | 禁止用途 |
|---|---|---|
| dev | 开发 adapter、模板、规则、prompt 和 schema | 对外称独立效果 |
| validation | 选择少量预设方案、发现流程问题 | 多轮查看后继续称最终盲测 |
| test | 冻结系统后的最终运行和预设评分 | 用失败结果调参后重用同集宣称独立提升 |

测试集暴露后如需修改系统，该轮保留为 exploratory；新的最终结论使用新增独立测试来源。修改 hash 或复制到新目录不恢复独立性。数据来源在开发前登记，并不等于实际用于开发的数据仍是 held-out。

### 3.2 输入、gold 和运行隔离

- 运行输入包含问题、事实/情境、候选证据；不包含 expected answer、expert label、裁决结果或方法名称提示。
- gold 放受控目录，由研究负责人管理；不打包进 runner、公开盲评材料、模型工具挂载或代码代理工作目录。
- 配置 prompt 的模型不得查看最终 gold。已作为输入提供的支持关系标签属于 oracle 条件，必须明确标注，不能当成系统预测能力。
- 固定问题中的候选断言可以给模型看；不给它正确性标签。自由生成任务不预先提供目标解释句。
- 外部检索在所有可比方法中使用相同冻结快照，或把检索能力单列为实验因子。

## 4. 任务规模和参考标准

路线图建议 100–200 claims、8–12 个真实公开数据/分析对象。实际独立来源数、聚类结构和预期区间精度需由负责人审定；多个对象来自同一研究时按同一来源报告。

可用的初始核心配额如下，共 160 个固定断言；这是供协议设计的建议，不是已收集样本或功效结论。

| 家族 | 建议核心数 | 代表性错误 |
|---|---|---|
| 差异表达 | 30 | raw/padj、方向、效应与显著性、NA、阈值 |
| 富集/GSEA | 20 | ORA 激活、NES、背景和条目重叠 |
| 单细胞设计 | 20 | cell/donor、batch、marker、UMAP 距离 |
| 图形映射 | 20 | 变换、subset、颜色/大小、原始与校正 p |
| 多组学 | 35 | 样本错配、feature 映射、方向冲突、派生证据 |
| 空间 | 35 | 坐标/区域、切片分母、共定位、邻域、伪重复 |

结构路线启动后另增约 30–50 个结构/空间联合声明，不能同时算入核心配额两次。错误诊断约 60 cases、图形挑战 40–60 cases 是不同任务单位，不能加进 claim 分母。正式规模可随协议调整，调整须发生在最终结果可见之前。

每个固定断言由至少两名领域专家独立标注：correct/incorrect/unsupported/indeterminate 及原因、所需事实、证据和适用范围。裁决保留原始分歧，不覆盖初评。

此外设置自由生成任务：模型根据相同情境生成解释，由不知道方法来源的评者拆分原子声明，检查 ledger 覆盖及未登记错误。这一部分能发现“结构化值全对，但 prose 错误”的情况。生成内容无法在生成前预标注，因此先冻结 rubric/任务，再对输出盲评；不与预先标注固定断言混称同一设计。

## 5. 比较方法和公平性

| 条件 | 用途 | 公平性要求 |
|---|---|---|
| 普通模型 | 评价常规解释流程 | 同源信息、相同任务、足够输入预算；不故意裁掉必要事实 |
| 本地模板 | 评价确定性输出 | 明确其可回答范围，拒答/不支持按覆盖率计 |
| facts-only | 结构化 facts 的作用 | 固定 facts、问题及基础 prompt |
| facts + evidence | 证据内容的增量 | 共用证据快照，额外输入与成本透明 |
| facts + evidence + validator | 验证层的作用 | 保存原始输出和检查结果，区分检测与修订效果 |
| 上一条件 + bounded revision | 有限反馈修订的作用 | 最大修订次数/成本固定，对照具可比调用预算或单列预算差异 |

至少增加一个“信息匹配的普通模型”比较：给同样 facts/证据而不启用 BioExplainR 检查层，分离信息量收益与验证机制收益。端到端从原始输出开始的比较可以另设；不能拿旧 direct_bounded 的信息限制作为唯一竞争基线。

“相同 prompt”指共用任务指令与仅改变预定实验因子的模板。不同消融条件不能一边改变证据、一边改变问题、模型版本和输出目标却仍称完全相同条件。

请求顺序随机或分块交错；记录服务漂移、模型实际返回名称、失败重试、输入/输出 token、时间和成本。模型名称由真实配置填写，不能假定旧预览模型仍可用。

## 6. 指标、分母与统计分析

### 6.1 主要与配套指标

| 指标 | 分子 / 分母 | 必须同时报告 |
|---|---|---|
| 固定断言判断错误率 | 错误判断 / 可评分目标断言 | 全部目标上的完成率；unsupported/indeterminate 分布 |
| 必需回答完成率 | 实质回答的目标项 / 所有指定目标项 | 解析失败、超时、拒答和输出截断 |
| 已回答准确率 | 正确判断 / 可评分实质回答 | 全部目标准确率，避免只回答简单项 |
| 全部目标准确率 | 正确判断 / 预先确定的可评分目标项 | 未回答、解析失败和超时在这些目标上记为未正确；gold 不可确定项按预设规则单列 |
| 自由生成错误/无支持率 | 专家判为错误或无支持的原子声明 / 全部可评价生成声明 | 每 case 的声明数、必需内容覆盖和未登记 prose |
| claim 抽取召回 | ledger 对应的真实原子声明 / 独立人工识别原子声明 | 抽取 precision、复合句与未映射内容 |
| support precision | 正确预测 supports 的 pair / 所有预测 supports 的 pair | 支持类别 recall、四/五类混淆矩阵 |
| support recall | 正确预测 supports 的 pair / 全部 gold supports pair | 无 supports 预测时 precision 为 NA，不写 100% |
| false-pass | 错误内容被检查器判 pass / 全部已知错误内容 | 非 pass 的漏检/不可评估分布；pass 结果中错误比例 |
| wrong-scope / definition-as-support | 错配/定义被当支持的 pair / 对应挑战 pair | 每类挑战数量和可检查覆盖率 |
| 成本 | 全部调用、重试、修订费用 / 正确且有支持的目标数 | 分母为零时 NA；token 与网络时间分列 |

主终点优先从 statistical/design error 或 unsupported claim rate 选一个，并预定最小覆盖率/覆盖率比较；不能通过全拒答降低错误率来宣称有效。统计事实、统计解释、生物关联、因果过度和引用错配分层报告，避免一个总分掩盖关键失败。

### 6.2 推断单位

- 以 case/dataset 为聚类单位做配对比较，必要时用分层 bootstrap 或预设混合模型；重复调用、同一对象的多个 claims 不当作独立生物样本。
- 报告绝对风险差、相对风险和 95% CI；零分母、零事件的处理在协议中确定。
- 独立来源较少时如实说明区间和外推限制；增加同源 claims 不能替代增加独立来源。
- 支持类别和名义标签用适合的多评分者一致性指标，如 nominal Krippendorff alpha；0–2 有序评分用 ordinal 方法。ICC 仅用于其假设适合的连续量，并说明模型，不对所有标签机械使用。
- 无评分变化或样本不足使可靠性不可估时，报告不可估；简单 exact agreement 可作为补充。
- 少数主比较预设，探索性结果单列；成功率目标未达到时保留真实结果。

## 7. 多组学、空间和结构主案例

### 7.1 数据选择表

候选来源需填写下列真实字段，未核实的值保持待核实：

`dataset_id/source_accession/url/release/license/download_hash/assays/species/tissue/n_subjects/n_samples/matched_level/missing_modalities/group/batch/timepoint/spatial_sections/independent_validation/data_size/compute_budget/development_status`。

推荐先验证样本可匹配的转录组+蛋白组或转录组+甲基化/CNV；有充分材料时选微生物组/代谢组/转录组。空间研究保留切片–样本–donor 的真实层级。样本级、同一切片和同一细胞的配对是不同条件，必须分别声明。

### 7.2 端到端流程

1. 固定科学问题、研究对象、独立重复、QC、比较和分析代码。
2. 锁定文件版本与下载 hash，生成 sample map、缺失模态和排除表。
3. 用已记录的上游方法计算各模态结果，保留原始/校正 p、效应和方向。
4. 独立计算关键参考事实，检查 adapter、模态/feature 对齐和依赖链。
5. 生成 context、解释和 typed claims，保留初始文字及所有检查状态。
6. 加入真实支持、矛盾、定义和无关证据，评估范围与支持关系。
7. 展示一致、冲突、缺失和不可核查的情况，量化各方法错误、覆盖和成本。
8. 保存项目报告、图源数据、脚本、环境、manifest；以独立来源验证主要行为。

### 7.3 负对照矩阵

| 层级 | 负对照/挑战 | 预期检查内容 |
|---|---|---|
| 样本 | 打乱 sample map、丢失模态、技术重复 | 错配识别、缺失保留、独立单位正确 |
| 跨模态 | 反向比较、ID 一对多、方向相反 | 范围/映射核查、冲突保留 |
| 空间 | 按预设合理零模型随机区域/标签 | 不把置换共现当稳健机制；说明空间自相关处理 |
| 结构 | decoy、非靶蛋白、负配体、参数敏感性 | score 方法依赖、target/decoy 区分及限制 |
| 证据 | 错物种、错组织、仅定义、相反结论 | 支持角色与 scope 拒绝/未知状态 |
| 联合 | 表达高而 docking 差；docking 好而该组织无表达证据 | 冲突和缺证据保持，不能补出机制 |

结构负对照和数据层级适配由领域人员审定；“不显著”不自动等于无表达或负证据。主案例报告候选优先级及可检验假设，不凭计算一致性宣称真实结合、通路激活或治疗效应。

## 8. 数据表与文件组织

以下为 W09–W11 拟创建结构，目前不是已有文件清单。

```text
research/frozen_benchmark/
  protocol.md
  datasets.csv
  cases.csv
  inputs/dev/
  inputs/validation/
  inputs/test/             # 不含答案
  methods.json
  rubrics/
  benchmark_manifest.json
research/multiomics/
  download_manifest.csv
  sample_map.csv
  feature_map.csv
  run_multiomics_case.R
research/spatial_structure/
  candidate_manifest.csv
  structure_manifest.csv
  controls.csv
research/results/frozen_v1/<run_id>/
  prompts/
  responses/
  manifests/
  calls.csv
  extracted_claims.csv
  evidence_pairs.csv
  scores.csv
  summary.json
  audit.json
```

Gold、原始匿名评分和同意/招募资料不默认进入公共树；它们的受控位置和授权范围由负责人记录。可公开的聚合、脱敏评分及裁决按数据管理方案另行导出，公共 manifest 不泄漏受控路径。

| 表 | 最小关联字段 |
|---|---|
| datasets | dataset_id、study_id、version、source、hash、split、independence_cluster |
| cases | case_id、dataset_id、family、question、input_ref/hash、scope、required_response_items |
| methods | method_id、model、prompt_version、evidence_condition、validator_policy、budget |
| calls | run_id、case_id、method_id、repeat、attempt、request/response hash、status、usage、latency |
| claims | run_id、case_id、method_id、claim_id、text_ref、type、scope、validation |
| evidence_pairs | claim_id、evidence_id、content_hash、proposed_relation、判定来源 |
| ratings（受控） | rater_id、case/claim/pair ID、rubric_version、label、reason、time、盲法标识 |
| adjudication（受控） | pair/claim ID、初评引用、裁决标签、原因、评者/负责人 |
| scores | endpoint_id、分析单位 ID、prediction、reference、correct、answered、failure_kind |

评分/专家备注里的答案不能通过公共 case metadata、文件名或 prompt 模板泄漏给 runner。所有表必须检查主键唯一性、外键完整性、缺失标签及零分母。

## 9. 需要由人员补充的材料

| 项目 | 模型可先完成 | 真实外部输入/行动 |
|---|---|---|
| 独立专家标准 | rubric、盲评包、匿名表、可靠性代码 | 领域专家实际评分、背景与分歧裁决 |
| 主案例 | 候选检索、下载/分析脚本、来源表 | 科学问题确认、适用范围和解释审阅 |
| 结构层 | parser、provenance、对照接口 | 实际结构文件/引擎运行及合适对照 |
| 人类评价 | 任务卡、随机化、记录/分析工具 | 真实招募、同意、适用审批/豁免、参与者数据 |
| 原外部评分 | 现有聚合记录索引 | 核实来源、原匿名评分可用性、使用范围 |
| 发布 | CI、容器、README、引用模板 | 实际 repo/release/DOI 发布信息 |
| 投稿 | 论文结构、图表和材料索引 | 作者单位/贡献/经费/COI、最终审阅及真实投稿 |

伦理/同意文件必须反映真实过程；补充说明不能把之前缺失的流程追认为已发生。若新研究需审批/豁免，在收集前完成适用流程。没有正式用户任务数据时，W11-U 可 deferred，主文相应不报告用户收益。

## 10. 论文与补充材料对应

| 产物 | 核心问题 | 必须有的来源 |
|---|---|---|
| Figure 1 | 对象、facts、claims、evidence、validation 如何连接 | 实现后的契约和实际工作流 |
| Figure 2 | 独立任务是否减少错误且保持覆盖 | 冻结 scores、方法/数据分母、CI |
| Figure 3 | 真实主案例如何处理匹配、缺失和冲突 | sample/feature map、上游结果、逐 claim 记录 |
| Figure 4 | 证据支持与检查器有哪些成功和失败 | pair labels、confusion matrix、覆盖/false-pass |
| 主表 | 工具设计、实测兼容性、逐任务结果、人工评价设计 | 可核实版本和实际记录 |
| Supplement | 旧传输实验、任务/证据字典、提示、失败、复现及人工流程 | 原始脱敏产物与 manifest |

拟补文档：`DATA_CONTRACTS.md`、`MIGRATION.md`、`DATA_DICTIONARY.md`、`ETHICS_AND_HUMAN_EVALUATION.md`、`REPRODUCTION.md`。它们应由对应任务填入真实内容；规划文件存在不表示这些文档已经交付。

最终审阅分别核对：

- 软件：契约、兼容性、测试、可选依赖、真实对象覆盖、R CMD check。
- 研究：独立来源、gold 来源、输入公平、失败记录、效应区间与覆盖。
- 主案例：匹配层级、独立重复、负对照、冲突和来源链。
- 人类材料：真实评分/招募/同意及适用审查，正确的人群与终点措辞。
- 发布与稿件：源稿/图表/数据一致、干净环境复现、作者信息和实际公开地址。

期刊方向由完成后的证据和 scope 决定。当前框架不把多组学、空间或 docking 的功能存在本身作为送审充分条件。
