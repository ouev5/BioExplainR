# BioExplainR 增强任务卡与模型交接模板

规划 v1.0，2026-10-05；执行状态更新（2026-10-08）：W00 done，W01–W09/W12 ready_for_review，W10-A/B 已完成 miniACC 公开开发案例，W10-C/W11 blocked_external（专家后置），W11-U deferred，W13 in_progress。先读 [总体框架](ENHANCEMENT_FRAMEWORK.md) 和 [研究方案](ENHANCEMENT_RESEARCH_PLAN.md)。任务初始均为 planned，实际状态依据验收记录更新；现有软件基线不计入新任务完成量。

续接边界审阅已复现并修复 identity、typed 聚合、证据支持、样本冲突、optional adapter 和 W09 artifact/score 问题，记录见 [CONTINUATION_REVIEW.md](implementation_records/CONTINUATION_REVIEW.md)。本地完整依赖、Imports-only 安装报告、开发交付包已有实际记录；正式独立 sign-off、第三方干净环境/远程 CI 和研究验收尚不完整，工作包状态不据本轮局部通过提升为 done。

10-08 工程验收为源码 677 项（676 pass、1 skip）、包 check OK；实际 HTTP/Shiny/bwrap 边界、74 历史 API 源码与安装包参数顺序、安装后覆盖/方向报告均已通过。miniACC 安装包重跑和 Python 16 个边界测试通过，记录见 [本轮审阅](implementation_records/REVIEW_CONTINUATION.md) 及 `review-*`。仅用户本人事项见 [USER_ACTIONS_REQUIRED.md](USER_ACTIONS_REQUIRED.md)，其余工程缺口继续由工程流程维护。

## 1. 使用方式

一次给模型派发一个工作包或其明确子任务。执行者先检查依赖和既有实现，再完成代码、必要测试、文档和结果记录。某项依赖外部数据或专家时，完成可独立进行的基础设施，剩余部分写为 blocked_external，不能补造结果。

状态限定为 `planned/in_progress/blocked_environment/blocked_external/ready_for_review/done/deferred`。只有验收项有实际记录时才标 done。更新本表的状态和证据入口；不在 SESSION_HANDOFF 重新追加长篇流水账。

| ID | 工作包 | 实施依赖 | 类型 | 当前状态 / 证据入口 |
|---|---|---|---|---|
| W00 | 环境恢复、当前结果入口和基线冻结 | 无 | 工程基础 | **done**；[实际记录](implementation_records/W00.md)、[复现说明](REPRODUCTION.md)、`research/results/current_manifest.json` |
| W01 | 数据契约、兼容层与版本策略 | W00；静态设计可提前 | 核心 | **ready_for_review**；[记录](implementation_records/W01.md)、`docs/DATA_CONTRACTS.md`、`inst/schema/` |
| W02 | 精度、payload、隐私与 manifest | W01 | 核心 | **ready_for_review**；[记录](implementation_records/W02-W04.md)、`R/contracts.R` |
| W03 | claim ledger 与验证政策 | W01；集成依赖 W02 | 核心 | **ready_for_review**；[记录](implementation_records/W02-W04.md)、`R/claims.R` |
| W04 | evidence role 与支持关系 | W01；集成依赖 W03 | 核心 | **ready_for_review**；[记录](implementation_records/W02-W04.md)、`R/evidence-support.R` |
| W05 | MultiAssay 与样本对齐 | W01–W02；联合检查依赖 W03–W04 | 应用扩展 | **ready_for_review**；[记录](implementation_records/W05-W08.md)、`R/sample-map.R` |
| W06 | 空间对象与图形核对 | W01–W02；联合场景依赖 W05 | 应用扩展 | **ready_for_review**；[记录](implementation_records/W05-W08.md)、`R/adapters-multiomics.R` |
| W07 | 外部 docking 结果与结构证据 | W01–W04、W10 数据选择 | 按结构主案例启用 | **ready_for_review（parser）**；主案例 `blocked_external`；[记录](implementation_records/W05-W08.md) |
| W08 | 解释、报告和 Shiny 集成 | W02–W04；扩展展示等待对应模块 | 产品集成 | **ready_for_review**；[记录](implementation_records/W05-W08.md) |
| W09 | 独立 benchmark 基础设施 | W01–W04；最终运行等待冻结系统 | 研究基础 | **ready_for_review（offline runner）**；[记录](implementation_records/W09-W12.md) |
| W10 | 真实数据主案例与来源链 | 候选筛选可与 W00 并行；运行依赖应用模块 | 应用研究 | **A/B 开发案例已执行；C blocked_external**；`research/multiomics/`、[公开案例记录](implementation_records/PUBLIC_CASE_CONTINUATION.md) |
| W11 | 专家标注、研究执行与统计 | W09；标签流程可提前准备 | 人工/研究 | **blocked_external**；[伦理与评价入口](ETHICS_AND_HUMAN_EVALUATION.md) |
| W12 | 自然图形、诊断、修复及代理评价 | W02–W03、W09；真实材料就绪 | 补充研究 | **ready_for_review（challenge infrastructure）**；[记录](implementation_records/W09-W12.md) |
| W13 | 文档、CI、复现与稿件交付 | 分阶段进行；最终等待适用任务 | 发布 | **in_progress**；[清单](W13_RELEASE_CHECKLIST.md)、[记录](implementation_records/W13.md) |

推荐顺序：W00 → W01 → W02/W03/W04 → W05/W06/W08；W10 的开发数据选择及 W11 的人员/流程准备从早期开始。W09 在开发集完成演练后，冻结独立最终评测；W13 贯穿全程。

W10 按子任务推进：W10-A 为候选筛选和开发数据冻结，无应用模块依赖；W10-B 为开发主案例，等待 W05/W06 及适用的 W07；W10-C 为未参与开发的独立应用验证，等待系统冻结。W07 只依赖 W10-A 的结构材料选择，避免形成相互等待。

## 2. 工作包定义

### W00：环境、结果入口与基线

**目标：** 后续模型可以从明确的软件/数据/文档版本继续工作。

- 阅读：`SESSION_HANDOFF.md`、`tools/server-R`、`tools/ensure-server-r-dev.sh`、`tools/check.R`、`research/audit_results.R`、`research/audit_submission.py`、现有结果 manifest。
- 实施：恢复可用 R 和实际依赖；记录 R/Bioconductor/CRAN 包版本。确认系统工具后再恢复 Python/Node/Pandoc 等依赖。临时路径不是可复现环境定义。
- 建立 `research/results/current_manifest.json`，指向主实验、双模型、公开数据、外部评价、论文及源码清单。源码用相对路径和 hash 表示，Git 无提交时不得编造 commit SHA。
- 将旧结果审计保留为显式 historical 模式，新增/扩展当前结果审计入口；使用保存 manifest 与实际行数核对，不在新审计器继续硬编码旧规模。
- 修订 README、研究 README、交付索引的当前数字及历史标签。旧目录暂按索引归档，先查清引用再迁移，避免破坏论文源和保存响应。
- 拟交付：`docs/REPRODUCTION.md`、当前 manifest、实际 baseline 检查日志及文件 hash 清单。

**验收：** 当前结果清单每个路径存在且 hash 可复核；当前/历史审计分别运行；R 测试和包检查记录实际结果；无故删除未跟踪文件为不通过。依赖无法恢复时保留 blocked_environment。

**2026-10-05 验收记录：** 系统 R 4.3.3/Bioconductor 3.18 恢复；531 检查（530 pass、1 skip、0 fail/warning）、R CMD build/check OK；current/historical 分别通过；2,905 个原记录文件 hash 不变；74 旧 API 已清点。论文内容/几何与双视口也重新通过，输出写独立 W00 目录。旧投稿 ZIP 核对为过期，完整打包和干净环境发布验证留 W13。详见上表实际记录。

### W01：冻结数据契约与兼容策略

**目标：** 给并行或接续模型一个唯一接口依据。

- 阅读：`R/context.R`、`R/explanation-validation.R`、`R/evidence.R`、`R/project.R`、`R/explain.R`、`R/report.R` 和现有 tests。
- 拟新增：`docs/DATA_CONTRACTS.md`、`docs/MIGRATION.md`、`inst/schema/` 下版本化 schema，以及小型正反例 fixtures。
- 逐项确定 context、fact descriptor、claim、evidence relation、sample map、manifest、validation finding 的字段、枚举、null/empty 语义、默认值和路径编码。
- 冻结 `bio_validate_claims()` 的返回值、旧 validator 兼容层、旧对象加载方式；scope 缺失产生 unknown/unverified，不补写推测信息。
- 明确 model 输入 schema 与 verifier 输出 schema 分离，验证结果字段不能来自模型输入。
- 确定哈希实现依赖、开发版本号、公共 API 导出范围和 schema 版本升级规则。

**验收：** 有合法、缺失、错误类型、重复 ID、未知字段和 legacy fixtures；各字段都有生产者与消费者；旧位置参数不改变；枚举与报告、schema、任务卡一致。

### W02：数值精度、发送策略与 manifest

**目标：** 包、实验、HTTP 请求和归档使用可验证的同一数值及发送契约。

- 主文件：`R/utils.R`、`R/context.R`、`R/llm.R`；拟新增 `R/serialization.R`、`R/manifest.R`、`R/payload-policy.R`。解释、项目、诊断和报告的调用点需协同修改。
- 实施框架 §5.2–5.3；确认 `jsonlite` 参数含义并以 round-trip 和请求捕获证明精度，尤其不能把极小 p 变成零。
- 替换 payload 超限时静默截断 facts 的策略，保留 top preview 减量；记录所有被删字段，完整事实无法容纳时明确失败/显式分块。
- 内容规范化、语义 hash、发送 hash 和脱敏 hash 分开；公共配置采用 allowlist，不把密钥、secret header 或带凭据 URL 写入清单。
- 追加调用尝试、失败、usage、耗时、配置版本和响应记录；现有调用接口仍可使用。
- 拟测试：`test-serialization.R`、`test-payload-policy.R`、`test-manifest.R`，重用 `test-hardening.R` 和 HTTP mock。

**验收场景：** PCA 精度、`1e-132`、零、NA、Inf、整数标识、空数组；相同语义重建 hash 一致；内容改变 hash 变化；超限不丢 facts；嵌套 metadata/notes/labels/错误文本不泄漏测试标识；mock 捕获请求与 manifest 一致。纯文档路径检查不能代替这些测试。

### W03：类型化声明与验证政策

**目标：** 数值正确、证据支持、范围正确和文字覆盖分别可检查。

- 主文件：`R/explanation-validation.R`；拟新增 `R/claims.R`、`R/claim-policy.R`。联动 `R/explain.R`、`R/project.R`、`R/report.R`。
- 实施框架 §5.4–5.5；保留 legacy 路径，新增安全 token 路径和稳定 claim ID。
- 把旧数值检查抽为可复用机制；严格区分数值、逻辑、字符串、单位、精确计数与连续量容差。
- 建立 per-check findings 与聚合规则；合法 evidence ID 不能让无事实或无支持的声明自动通过。
- 保留自由文本和未映射 section；复合句拆分或标示未覆盖，不以模型的 claims 数作为全文声明总数。
- 任何修订带 parent claim、原文、原因、模型/规则版本；默认不无限重试。

**验收场景：** 正确/错误数值、缺路径、歧义路径、错误单位、比较方向反转、空 ledger、未知类型、模型自报 pass、数值正确但因果过度、仅引用合法 ID、预览舍入值。旧 `validation` 读取者继续工作，语义收紧有迁移说明。

### W04：证据支持关系

**目标：** 将“找到来源”与“来源在此范围内支持声明”分开保存和评价。

- 主文件：`R/evidence.R`、`R/evidence-live.R`；拟新增 `R/evidence-support.R`；与 W03 的 ledger 引用一致。
- 保存证据内容层级、版本/hash、可定位片段、scope 和 role；检索成功只表示 retrieved。
- 构建 pair-level relation、候选标注、双人审阅及裁决数据接口；机器候选不写为 expert_reviewed。
- 对物种、组织、比较、定义/实验角色等确定性不匹配给出 findings；未知 scope 不假定匹配。
- 处理重复 DOI/相同来源、矛盾证据、撤回或更新信息的已知状态；证据不可用时记录原因，不虚构全文。
- 拟测试：`test-evidence-support.R`，用本地固定片段和 mock，网络测试单列。

**验收场景：** supports、contradicts、definition_only、irrelevant、unknown 均能保存和展示；定义不能支持处理效应；同一文献支持 A 不自动支持 B；未知和模型候选不能变专家 gold；注入式指令文本只作为证据内容。

### W05：MultiAssayExperiment 与样本对齐

**目标：** 在真实匹配样本上组织多个模态及其不一致结果。

- 拟新增：`R/adapters-multiomics.R`、`R/sample-map.R`；修改 `R/context.R`、`R/project.R`、DESCRIPTION Suggests。
- 使用 `MultiAssayExperiment` 公共 accessor，构建每模态 context、合法 sample map 和联合摘要。
- 检查 assay–colname 的唯一映射、technical replicate 多对一、缺失/额外样本、样本顺序、donor/timepoint、group/batch 和重复单位。
- 实现派生关系与支持/矛盾关系分离；对齐明确后才比较方向。
- 真实开发例由 W10 提供，测试 fixtures 另建小型可手算数据，禁止从包自身输出复制 expected。

**验收场景：** 乱序可按 ID 正确对齐；重复键冲突可定位；技术重复不误报；模态缺失保留；已知方向冲突出现 findings；稀疏/延迟对象不整块稠密化；缺可选依赖时基础包可加载。

### W06：空间对象、空间结果及图形核对

**目标：** 空间数据有正确的层级、坐标和分析来源。

- 拟新增：`R/adapters-spatial.R`、必要的空间检查模块；修改 adapter 调度、`R/plot-cross-check.R` 和相应报告入口。
- SpatialExperiment 优先于 SCE/SE；Seurat spatial 与普通 Seurat 明确区分。
- 按 sample/section/region 汇总 facts；记录坐标系、单位、变换、QC、组织 mask 与空间统计方法。
- 优先读取已有邻域图；新增计算时明确参数、边界和复杂度；不隐式重跑空间统计。
- spatial cross-check 先覆盖可解释的代表性图形，再扩展复杂图层；对应源对象、subset 和映射规则一同记录。

**验收场景：** 专用 adapter 命中；坐标/metadata 乱序、缺失、重复 ID、不同切片相同 barcode；未声明坐标单位；多切片无跨片假边；缺 mask 不生成组织覆盖率；不支持图层返回 not_checkable；模型 payload 不含原始图像/全坐标/barcode。

### W07：结构计算结果与审计

**目标：** 为选定主案例接入可追踪的外部结构结果。

- 拟新增 `R/docking.R`，必要时拆分 parser；研究执行放 `research/spatial_structure/`。
- 首先选择有真实版本文件的一个引擎；建立 parser fixture、错误格式和通用结果 schema。第二引擎是独立子任务。
- 按框架 §5.9 保存来源与缺失字段；同尺度内汇总 pose/score/对照，多引擎只分层呈现。
- 通过项目关系连接空间、候选、结构和文献；保留“表达高但结构不支持”等冲突。
- 候选集和对照由 W10/W11 在最终实验前冻结。

**验收：** 真实文件能解析；版本/单位未知、单一 score 或缺 decoy 时不得给出机制 pass；RMSD 有参考定义；重复导入可追溯；默认解析不启动外部引擎。仅 parser 通过时在子任务记录其验收，主案例仍为 in_progress 或 blocked_external，不写整体完成。

### W08：解释、报告与工作台

**目标：** 新能力在用户真实入口中可使用、可理解。

- 主文件：`R/explain.R`、`R/i18n.R`、`R/i18n-en.R`、`R/report.R`、`R/shiny-app.R`、`R/shiny-i18n.R`、`inst/i18n/app-zh.txt`。
- 在本地模板和模型结构化输出中使用 ledger；保留原 prose，显示事实、证据、scope、未覆盖文字和验证边界。
- 新模态/空间对象拥有最小有效本地解释，不落入“未知 generic”后仍宣称完整支持。
- Shiny 提供发送字段预览、claim 与 evidence 详情、样本缺失/冲突、报告下载；不把所有 hash 塞到主页面。
- 更新 `inst/examples/`、Rd、安装说明、工作台说明和 `research/build_user_guide.py`。

**验收：** 无模型配置的完整流程通过；mock 模型、自由文本/非法 JSON、未知证据和部分验证有可理解状态；English/中文机器字段一致；报告转义外部文本；双会话状态隔离；桌面/移动及下载产物验证。Shiny 不增加自动执行模型代码的通路。

### W09：独立评价基础设施

**目标：** 可以冻结、运行、回放、评分和审计新研究。

- 拟目录：`research/frozen_benchmark/`；公共 case/input 与受限 gold 分开，由人工负责人控制 test 参考答案。
- 拟脚本：`run_claim_benchmark.R`、`run_evidence_support_benchmark.R`、`audit_current_results.R` 和统计汇总脚本；名称可在 W01 冻结。
- case、method、run、claim、evidence pair、rating、adjudication 和 score 使用明确 ID 关联；细节见研究方案。
- runner 默认 dry-run/replay；live 调用显式配置，保存预算、重试、请求顺序、usage 和失败原因。
- 比较完整系统、信息匹配的基线以及消融；validator/revision 的额外调用预算预先固定。
- 调参只用 dev/validation；每个新冻结运行目录不可覆盖，恢复运行校验 prompt/config/code hash。

**验收：** 离线 fixture 可完整运行并重复得到相同评分；损坏文件、hash 不匹配、漏评分和重复 case 能发现；runner 的工作目录/挂载范围不含 gold；无标签时不会输出虚假 accuracy；模型不回答和解析失败单列。

### W10：真实主案例与数据来源链

**目标：** 形成一个科学问题明确、模态匹配、含现实冲突的主应用。

- 先做数据候选表：来源、版本、下载/许可、可配对层级、真实模态、独立重复、空间资料、外部验证、体量和计算要求。
- 负责人已授权执行者选择公开测试/开发数据并保留结果；miniACC 开发案例已有输入、映射、统计结果、双语报告和独立 Python 数值复核。独立 test/gold 需另行冻结和科学确认。
- 选择一个开发主案例，冻结 QC、比较方向、样本排除与 feature 映射；保留原始文件 hash、下载清单、sample map、参数与 source package 版本。
- 同时给 W11 预留不同研究/队列的最终测试数据；同一研究的另一张派生表不能作为独立验证。
- 拟产物：`research/multiomics/`、`research/spatial_structure/` 下流程和 manifests，以及 `docs/DATA_DICTIONARY.md`。
- 结构路线保存全部候选与排除理由、结构选择、decoy 和重复搜索；模型负责计算基础设施，领域人员决定可解释的科学问题与金标准。

**验收：** 从锁定公开数据重建 context/project/report；样本缺失、模态一致和冲突均可追溯；主结论不依赖事后挑选漂亮示例；开发案例明确标注 development/application，只有未用于开发的来源才作为独立结果。

### W11：专家评价、研究执行与分析

**目标：** 获得可支持论文主张的独立人工参考与效果结果。

- 模型可准备 rubric、去方法标识材料、随机化代码、评分接口、功效/精度规划和分析脚本。
- 负责人决定：专家评价待软件功能、案例和评价材料准备完成后启动；W11-U 用户体验/学习增益研究 deferred，不作为本轮完成条件。
- 作者/研究负责人落实评者资历、盲法、真实招募/同意及适用伦理流程，至少两名领域评者独立标注，保留原评分和裁决。
- 根据研究方案运行固定断言判断与自由生成两类任务；独立人工审阅未登记 prose，避免验证器自证正确。
- 冻结模型配置和预算后运行；不支持预期结论的结果同样归档。
- 正式用户任务研究为子任务 W11-U：有用户收益主张时，事先确定任务、对照、主要正确率、时间、校准、样本量与缺失处理；否则明确 deferred 并限制论文主张。

**验收：** 每个 gold/rating 来源真实可追溯；不使用 AI 分数冒充专家；评分可靠性、分歧和裁决齐全；错误率、覆盖率、效应量和聚类区间可由逐项数据重算；无伦理/人员材料不记人工研究完成。

### W12：诊断、图形、修复与隔离代理补充评价

**目标：** 为既有辅助模块补上更自然的场景和失败覆盖。

- 诊断：约 60 个真实/盲法构造案例，领域参考根因；比较 top-1/top-3，包含未知类和歧义类。
- 图形：40–60 个真实或受控修改图，含 facet、变换、subset、label、多图层和空间图；参考标签独立于被测检查器。
- 修复：候选程序运行率与预定语义不变量通过率分开；design、方向、行/列、类型和缺失条件均覆盖。
- 代码代理：控制器与执行环境分开。模型调用可由外部控制器完成，执行容器使用只读输入、单独 scratch、资源限额及无网络；gold 不挂载。记录实际能力，容器不可用不写沙箱已验证。
- 增强包规则仅用开发部分；独立评测固定后不根据其失败调规则再报告同一测试结果。

**验收：** 每种输出状态有分母；false-pass 与 not_checkable 覆盖率并列；失败案例保留；越界写入、网络和超时的执行边界有实测记录。路线图建议 top-1 ≥0.75、top-3 ≥0.90、false-pass <5%、注入错误 recall ≥0.95，作为预设目标而非可改分的通过口令。

### W13：发布、复现与论文

**目标：** 将验证过的实现和研究变成可安装、可引用、可复核的交付。

- 扩展现有 CI：基础离线、完整可选依赖、合适的 R/Bioconductor 组合和操作系统；不能把缺依赖导致全 skip 当通过。
- 固定研究环境与源数据快照；包自身保留合理 Depends/Suggests。容器/lockfile 在干净环境实际测试。
- 使用匿名/获准公开的数据产物；公开 repo/release/DOI 的真实地址由实际发布取得，不填虚构地址。作者、基金和利益冲突信息由作者提供。
- 论文以事实接入、独立 claim benchmark、真实主案例、证据关系为主；仅在已完成时写正式用户收益。
- 更新所有源稿、图表、用户指南、安装说明、当前 manifest 和交接；历史机制实验与新结果分开。
- 执行包构建/检查及稿件导出/审计/打包，保留每个组合图和 panel 的独立资产。

**验收：** 第三方按说明可复现指定离线结果；每个主要数字能回到 source score；文档与导出文件 hash 一致；期刊范围与当年分区已实际核实；软件完成与投稿准备度分别记录。

## 3. 多模型工作边界

如用户同时交给多个模型，先完成 W01，再约定文件归属。

| 角色 | 可主责范围 | 共享文件的协调方式 |
|---|---|---|
| 集成负责人 | 契约、版本、DESCRIPTION、NAMESPACE、公共入口、验收 | 汇总各任务接口改动，统一生成 Rd |
| 核心实现 | 序列化、manifest、ledger、evidence | `R/context.R`、`R/explain.R` 修改交集须先约定 |
| 对象扩展 | multiomics、spatial、docking parser 和专属测试 | 提交 adapter 注册变更给集成人，不同时重排调度表 |
| 产品集成 | 报告、Shiny、i18n、示例 | 消费冻结契约，不在 UI 私自重算验证结论 |
| 研究实现 | case 管理、runner、分析、图表 | 不读取封存 gold 调 prompt，不修改旧原始记录 |
| 领域负责人 | 科学问题、真实标注、伦理与作者资料 | 记录真实判定及来源，不由编程模型代签 |

当前工作区尚无已提交基线。不能默认 `git worktree` 已可使用，也不能为了建立基线自行提交；若并行编辑，应先按实际仓库状态制定独立副本或文件归属方案。

## 4. 可直接复制的模型任务提示词

### 通用实施提示词

```text
你正在 /home/ubuntu/creatR 增强 BioExplainR。请先阅读：
SESSION_HANDOFF.md
docs/ENHANCEMENT_FRAMEWORK.md
docs/ENHANCEMENT_TASKS.md
docs/ENHANCEMENT_RESEARCH_PLAN.md

本次工作包：W__，子范围：__。
读取该任务列出的现有代码和测试，确认前置交付真实存在。
按冻结契约完成实现、必要测试、Rd/示例/相关文档与验证记录。
保持现有 S3/list 风格、离线功能和 English 默认/中文切换。
旧结果目录和论文数字保留，不把新规划当成既有功能或研究结果。
不得用包自身输出充当独立参考，不生成虚假专家/用户/伦理材料。

遇到缺少外部数据/人员时完成独立可做部分，并在任务结果中注明阻塞。
运行与改动相称的检查，区分 pass、fail、skip 和 not_run。
更新任务状态及证据入口，交付本次修改文件、实际测试、API 迁移、
仍缺内容和下一工作包。不要只输出建议。
未经明确要求，不提交、推送、发布或上传文件。
```

### 推荐首次派发

```text
本次只执行 W00，并为 W01 准备静态接口清单。
先恢复实际可用的开发环境，核实最新源码检查状态，建立 current manifest，
修正当前/历史审计入口和文档数字。保留已有实验原始记录。
交付可复现环境说明、基线日志、结果入口与阻塞项。
本轮不启动付费模型规模实验，也不把后续研究占位写成结果。
```

### 独立审阅提示词

```text
审阅工作包 W__ 的实现，依据框架、冻结数据契约和实际变更。
重点检查返回值兼容、missing/unknown 状态、gold 泄漏、数值精度、
发送字段、超限处理、样本对齐、适配器优先级和报告语义。
用可复现案例说明问题，不以函数数量或测试数量判定完成。
输出阻断问题、具体文件/行、复现方式，以及哪些验收已获得证据。
```

## 5. 每个任务的交付记录模板

```text
工作包 / 子任务：
状态：
执行日期 / 软件版本 / schema 版本：
前置任务与引用产物：
修改文件：
实现的 API / 行为：
旧对象/API 兼容与迁移：
实际命令、退出码、版本、pass/fail/skip/not_run：
测试和数据参考来源：
产物路径 / manifest / hash：
未解决问题与外部依赖：
下一任务所需输入：
```

日志放在 `docs/implementation_records/Wxx.md`；当前已建立 [W00 记录](implementation_records/W00.md)，其余工作包按实际执行创建。大型日志/数据放研究产物目录，并在记录中引用。

## 6. 实施时的检查入口

先使用恢复后的环境，在项目根目录运行；开发工具脚本会生成 Rd/NAMESPACE，执行者需检查这些差异。

```sh
R --vanilla --slave -f tools/check.R
R CMD build .
R CMD check --no-manual --no-vignettes --no-build-vignettes BioExplainR_<实际版本>.tar.gz
```

第三行是命令模板，必须替换实际版本，不能原样执行尖括号。使用服务器临时 R 时，把 `R` 换成 `bash tools/server-R`，前提是 runtime 和 `/tmp/opencode/r-env.sh` 已恢复。新增可选依赖要有安装后的专项运行记录；发布阶段另运行适当的 `R CMD check --as-cran` 并说明 NOTE。

论文有改动时才执行图表导出、Pandoc/LibreOffice、投稿审计、浏览器检查和打包流程，具体入口见交接文件。W09/W12 新研究脚本的实际命令、参数和结果目录由相应任务写入 `docs/REPRODUCTION.md`，不把拟定脚本写成已成功执行。
