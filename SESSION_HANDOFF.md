# BioExplainR 会话交接说明

## 2026-10-08 最新续接（优先阅读）

本轮已按用户要求完成中文**v0.9：9页主稿+16页独立补充**，六工具比較与SPARCL1固定候选/外部GEO培养实验。当前论文入口`docs/paper_cn_v2/README.md`，详细记录`docs/implementation_records/PAPER_RELEASE_CONTINUATION.md`。正文收束四贡献，较v0.8缩减65.75%；标题继承编号关闭，正确CRISPLD2及上标负号均已核验。

发现案例见`research/discovery/`、`research/results/discovery_sparcl1_v1/`：候选按发现集合排名固定后读取外部表达，24h主效应+4.132、WelchP1.55e-4、置换P1/35；Python与R独立12项一致。**外部为单个HASM1细胞系培养重复**，不声称独立供体/首次发现/因果机制。无新模型/专家/用户研究。

最新源码677项（676pass/1skip）和包checkOK；v0.9文稿/表/图/引用/hash/几何通过，双视口主稿2图1表、补充8图0表通过。新交付**r8**与baseline-7接入v0.9和外部案例；实际hash以`revision-delivery-audit-result.json`及最终current/historical audit为准。原2,905保护文件及旧r1–r7保留。

本地首个源码提交为 **`dbd7075`**（OpenCode执行身份，不冒充论文作者）；远程尚未配置。r8 **959成员、114,625,818bytes**，SHA-256 **`b639f263f0ede6bd365c2b941ea2f9ca1a52c5e6f29fdd5a758829626c05ce1b`**。暂存源码与r8常见凭据格式扫描均pass、0发现；外部PAT未写入文件。current/historical均pass，2,905原保护文件逐hash不变；本交接更新后重新manifest/audit，以最终manifest_sha256为准。

**已获本轮公开建仓库/提交/推送/release授权。** API账号为`ouev5`，拟建`BioExplainR`；提供令牌创建仓库GraphQL/REST均权限403，远程未创建/未推送/无release。正式网址与DOI未建立；`docs/RELEASE_ARCHIVE.md`记录阻塞和Zenodo需求，凭据不保存在任何文件。负责人需创建仓库或通过环境GH_TOKEN提供有效权限（勿聊天粘贴）。本地发布材料已准备，真实作者仍留位。

以下为上一轮v0.8/r7与历史记录，需按各自日期和版本阅读。

更新时间：2026-10-08。本轮已按用户要求完成中文论文v0.8、案例补充、PDF合图/外置表、工作台修复、指定服务公开上传及r7交付。**当前论文交接先读`docs/implementation_records/PAPER_CN_CONTINUATION.md`和`docs/paper_cn_v1/README.md`。** 此前“仔细检查”r6记录保留于REVIEW_CONTINUATION。

## 当前基线

- 工作目录 `/home/ubuntu/creatR`；历史软件/模型结果版本0.3.1；当前开发版**0.4.0.9000**，当前中文稿**v0.8，23页**，新目录`docs/paper_cn_v1/`；旧v0.7保留。
- Git无HEAD，项目文件仍未跟踪，是既有成果；不得reset/clean/删除。未提交/推送/release/DOI；本轮用户明确授权的新论文及图表附件已公开上传（#45/#46/#47），不得将这一授权扩大为发布其他材料。
- 当前 90 个导出函数，新增 `bio_validate_project_relations()`；10-08 历史 74 个 API 源码和真实安装包名称/位置参数顺序各74/74通过，非全部行为等价证明。English 默认，`language="zh"` 切中文。
- 模型解释入口默认完整 facts，超预算明确失败；旧 payload 位置参数保留 bounded 兼容。大型矩阵、原始图像/坐标与样本映射留本地。
- Shiny 监听 127.0.0.1；不同会话工作区隔离但共享 R/文件/网络权限。独立 bwrap 工程探针不能为 Shiny 宣称多租户沙箱。
- W00 done；W01–W09/W12 ready_for_review；W10-A/B 已有 miniACC 公开开发案例，W10-C/W11 blocked_external；W13 in_progress。工程检查不能代替独立科学/人员/伦理/发布验收。
- 用户已授权执行者自行选择公开测试数据并保留结果；用户体验/学习增益研究 W11-U 为 deferred，专家评价等软件、案例及评价材料准备完成后再开展。此决定已同步伦理、任务卡、用户事项和交付文档。

## 前轮基线修复与验收（2026-10-05）

完整记录：`docs/implementation_records/CONTINUATION_REVIEW.md`。核心修复包括 context identity、legacy missing、payload/list/URL/private 字段、typed aggregate/type/scope/unit、evidence pair、sample map、MAE/Spatial、docking、project/diagnose prompt、W09 artifact/replay/score 与 Shiny 详情。新修复不能倒写为 0.3.1 历史功能。

本轮实际增加：auto evidence 回归修复、usage token 计数保留、公开证据 URL 结构化过滤、实际 HTTP bytes/hash 两协议验证、Shiny 浏览器与 bwrap 边界。

| 验收 | 实际结果 | `research/results/w00_baseline/` 入口 |
|---|---|---|
| 源码 | **648 项：647 pass、1 skip、0 failed/error/warning** | `acceptance-source.txt/json` |
| 包 | build 成功；check **Status: OK**，0 ERROR/WARNING/NOTE | `acceptance-build.txt/json`、`acceptance-package-check.txt/json` |
| 历史 API | 74/74 名称/位置参数顺序通过，非全部行为等价证明 | `acceptance-legacy-api-result.json` |
| 真实上游依赖 | MAE 1.28.0、SpatialExperiment 1.12.0 手算对象专项；全部 Suggests installed | `continuation-optional-dependencies.csv`、tests |
| HTTP | loopback OpenAI/Anthropic 实际 body hash/bytes、极小 p/PCA/null、usage；503 retry=2、401=1 | `acceptance-http-result.json` |
| Shiny 浏览器 | payload/typed/evidence/manifest、HTML 转义、英中、报告下载、MAE、双会话；1440/390 无溢出 | `acceptance-shiny-browser/summary.json` |
| 安装包离线 | 完整依赖与 Imports-only context→typed validation→project→HTML report | `acceptance-full-smoke/`、`continuation-core-*` |
| 隔离边界 | input readonly、越界写入拒绝、gold/home 未挂载、host listener 不可达、scratch report、资源限额与 timeout | `acceptance-sandbox-result.json` |
| contract/W09/W12 | 5 个正反例按预期接受/拒绝；3 个 W09 流程测试；W12 template | fixture/benchmark 前轮真实日志 |
| 稿件 | 38 refs、35 Figure PDF、13 主稿 Word/Excel 表、4 补充表；PDF 65/10 页；7 图/13 表双视口 | `continuation-submission-audit-result.json`、paper browser |
| current/historical | 当前动态规模和历史 54/225 独立审计 pass；2,905 原文件 hash 不变 | `current_audit.json`、`historical_audit.json` |

唯一版本/结果入口`research/results/current_manifest.json`，当前为`development-baseline-6`。本轮采用`paper-cn-source`和`paper-cn-package-check`；source/package文件数、tar/ZIP/hash以manifest和`paper-cn-delivery-audit-result.json`为准。r6/r5结果分别保留为`review-delivery-audit-result.json`/`continuation-delivery-audit-result.json`。

## 已完成的公开案例与工程完善（2026-10-07）

详细记录：`docs/implementation_records/PUBLIC_CASE_CONTINUATION.md`；研究方案、运行脚本和独立实现复核器位于 `research/multiomics/`。

- `R/sample-map.R`：重新校验已构造映射、拒绝重复/缺失 observed ID，追加 `primary_units` 参数；返回 modality coverage、pairwise intersection、完整/未测量病例数。映射合法的 pass 不表示全部模态齐全。
- `R/adapters-multiomics.R`：MAE facts 接入覆盖/交集计数，原始样本映射和完整病例 ID 保留本地。
- 新增 `R/project-relations.R` / `bio_validate_project_relations()`：核对 dataset/comparison/species/tissue/sample_level、numerator/denominator、显式 feature_id 与有限非零效应正负号；支持 exact token 路径。未知或零效应不自动通过；不把符号一致当成显著性、因果或独立证据。
- `R/project.R` / `R/report.R`：方向关系表自动检查，项目报告和模型 payload 展示 findings/覆盖统计。NAMESPACE/man 已由 roxygen 更新。
- 新增 `tests/testthat/test-project-relations.R`，29 项针对性检查；README、DATA_CONTRACTS、MIGRATION、专家评价说明已更新。
- miniACC 实际运行一次，输出新目录且拒绝覆盖；原输入、映射、分期、配对长表、统计结果、context/project RDS、中英文 HTML、版本信息及逐文件 hash 已保存。具体数字见下节，不冒充独立研究。

| 2026-10-07 实际验收 | 结果 | 入口 |
|---|---|---|
| 最新源码 | **677 项：676 pass、1 skip、0 failed/error/warning** | `research/results/w00_baseline/improvement-source.txt/json` |
| 最新 tar 构建/检查 | build 成功；`Status: OK`，0 ERROR/WARNING/NOTE | `improvement-build.txt/json`、`improvement-package-check.txt/json` |
| miniACC Python 复核 | 23 个文件 hash，66 个效应、方向、覆盖及 BH 重算通过；未独立重算 Wilcoxon 原始 p 值 | `improvement-miniacc-audit.txt/json`、`research/multiomics/audit_miniacc.py` |
| current/historical | 均 pass；current 已使用 677 项新日志，2,905 个原文件 hash 保持不变 | `current_audit.json`、`historical_audit.json` |
| r5 开发审阅包 | 464 成员核验通过，包含 miniACC 24 文件（含 manifest）及复现脚本 | `continuation-delivery-audit-result.json` |
| Python 语法 | miniACC audit、manage_baseline、package_submission 编译通过 | 当次终端输出，无单独新增日志 |

上述完成项不包括新 HTTP/Shiny/bwrap 验收、安装后新增接口专项 smoke 或新版旧 API 专项；这些只有 10-05 前轮记录，不能算作新增功能的全部验收。

## “仔细检查”续接完成（2026-10-08）

前一会话止于静态审阅和手工探针，拟修复 patch 未应用。本轮已完成对应问题修复与适用验收，完整记录：`docs/implementation_records/REVIEW_CONTINUATION.md`。

- 过期 r3/current 入口改为 r6，保留历史日期；数据集 hash 改为 v1 原输入 RDS 的真实 SHA-256。执行者选择数据、专家后置、用户研究 deferred 已同步，交付边界明确已有开发案例但无新独立科学/专家评价。
- `run_miniacc.R` 增加 `--installed`；新 manifest v2 使用运行目录相对文件名，保存模式/版本/包路径。真实 tar 安装至 `/tmp/opencode/bioexplainr-install-review/` 后完整运行，输出 `research/results/miniacc_installed_review/`；原 v1 不覆盖。
- `audit_miniacc.py` 支持旧/新 manifest 异地回读且只访问给定目录，要求全部23成员、唯一主键和完整覆盖/交集/测量/关系/findings/反例集合，拒绝越界/symlink/缺失/重复；重算分组、66效应、方向、BH及摘要。安装包重跑8个核心表与v1逐字节一致。
- `tools/offline-smoke.R` 增加安装后覆盖/完整/未测量病例、含点号 exact-token 的 opposite 关系、错误方向拒绝和HTML展示。API工具支持安装模式；环境采集增加唯一prefix，打包及采集拒绝覆盖旧证据。
- r6补齐 improvement/review日志、公开案例/本轮记录、安装案例和manifest/审计工具。外部ZIP结果使用新 `review-delivery-audit-result.json`；r5和continuation审计保留。

| 10-08 实际验收 | 结果 | `research/results/w00_baseline/`入口 |
|---|---|---|
| 源码/build/check | **677项：676 pass、1 skip、0 failed/error/warning**；build成功；check **Status: OK**，0 ERROR/WARNING/NOTE | `review-source.*`、`review-build.*`、`review-package-check.*`、`review-00check.log` |
| 历史API/实际接口 | 源码、安装包各74/74名称/位置参数；90个安装导出函数 | `review-legacy-api*-result.json`、`review-api-inventory.csv` |
| 完整/Imports-only安装 | context→typed→覆盖/方向project→HTML均通过；全部Suggests可加载 | `review-full-smoke/`、`review-core-*`、`review-isolation-result.json`、`review-optional-dependencies.csv` |
| miniACC数值/边界 | v1和安装包结果各23文件hash、66效应/方向/覆盖/BH通过；**16 tests pass**，包括异地/拒绝覆盖及重写hash后的损坏拒绝 | `review-miniacc-audit.*`、`review-miniacc-installed-audit.*`、`review-miniacc-boundaries-final.*` |
| 契约/W09/W12 | 5契约正反例符合预期，3个W09测试通过；W12仍1行template | `review-contracts.*`、`review-benchmark.*`、`review-w12.*` |
| HTTP/Shiny/bwrap | 两协议实际body hash/bytes/精度/usage/retry/401；Shiny英中/下载/转义/MAE/双会话/1440与390；只读/越界/gold/home/network/scratch/限额/timeout通过 | `review-http-result.json`、`review-shiny-browser/summary.json`、`review-sandbox-result.json`、`review-bwrap.*` |
| Python/审计反例 | 修改工具语法通过；3个current audit损坏探针通过 | `review-python-syntax-final.*`、`review-audit-probes-final.*` |
| r6/current/historical | r6 **598成员**完整性通过；current/historical均pass，**2,905原文件hash不变**；current接入两份miniACC数值复核 | `review-delivery-audit-result.json`、`current_audit.json`、`historical_audit.json` |

本轮未改源码包功能或重导出主稿/图表；工程记录与研究复核已更新。本交接不进入ZIP，更新后重建manifest并再次current/historical审计，以最终审计记录的manifest_sha256为准。源码/文档后续再变更会使清单或ZIP当前文件比对过期，不可沿用本次pass。

## 已保存研究结果

2026-10-07 新增公开开发案例：`research/results/miniacc_development_v1/`。TCGA-ACC `miniACC`（MultiAssayExperiment 1.28.0）92 个病例、5 个模态；43 个病例五模态齐全；RNA/蛋白配对且分期已知 46 个（early 28、late 18）；33 个共有特征中 18 同向、15 反向；RNA BH<0.05 为 3、蛋白为 0。方案、源对象、sampleMap、输入长表、结果、双语报告和 hash 清单均保留；Python 独立实现复核通过。此为开发案例，不是独立 test/gold、专家评测或生物学泛化结果。用户体验/学习增益研究按负责人决定 deferred；专家评价待全部功能和材料准备完成。

10-08安装包同案例重跑保存在 `research/results/miniacc_installed_review/`，主要数字与8个核心表一致；这是同一开发来源工程复现，不增加独立样本量。Python未独立重算Wilcoxon原始p值，也未从RDS解码原始矩阵。

没有重跑在线 provider 或新增专家/用户评分。以下是 0.3.1 保存记录，当前仅离线核对：

- 5 个公开数据对象入口：airway、PBMC3k、pasilla、ALL、bladderbatch，保存测试 5/5 pass。
- pasilla 六组阈值 30/30 独立数值 facts 匹配。
- 主机制实验：120 程序生成 cases、480 unique target facts、3 输入×3 重复；1,080 requests、4,320 scores。direct_bounded 437/1,440（覆盖516/1,440、已回答437/516）；facts_only/evidence 各1,440/1,440。不是独立生物学泛化准确率。
- 双模型 StepFun step-5-preview、DeepSeek deepseek-flash：各120请求、480/480匹配；600 case-method 行包含 deterministic、agent not_configured、replay missing，不能合并为 API 分母。
- 相近工具为入口兼容检查；btw 未安装。外部评价只核对匿名聚合一致性，原评分/人员/伦理仍待负责人核实。
- 历史人工聚合：720维度评分、150功能评分，均分1.751/2、91.98/100，144/150有用；不是正式用户任务/ICC/SUS或学习增益。

## 当前论文与写作网站问题（2026-10-08本轮）

- 中文论文入口：`docs/paper_cn_v1/BioExplainR-中文论文-v0.8.{docx,pdf,html}`，文字源`manuscript.md`。PDF23页，29参考文献，方法10小节，结果按公开案例/机制/工程组织；作者、单位、通讯、基金等留位。
- **8个四联PDF合图/32个独立panel PDF**在`figures/composites/`和`figures/panels/`，框架图含原创矢量图标。正式论文附录直接嵌入合图PDF矢量内容；Word/HTML用预览PNG，图8截图为位图素材。
- **9份XLSX+9份CSV**在`tables/`，论文嵌入数据表为0；正文引用及附录B保留表题/表注/来源。文末附录C预留专家、用户体验、学习效果和独立验证，**新版不写旧专家/用户评分**。
- 新增`research/results/paper_cn_cases_v1/`：airway九阈值×五facts **45/45**源表匹配，Python另行重算45项；**15/15**期望状态匹配（8pass/5fail/1partial/1unverified）。真实对象回读、手算fixture、controlled mutation逐行标明，不作独立test/gold。
- 工作台`bio_project`专用dispatch修复，展示真实miniACC项目摘要/依赖/覆盖/交集/完整和未测量病例/方向findings；下载同一项目HTML，原始map/病例ID不展示。绘图页新增Cairo矢量PDF下载，失败清空旧图与下载入口；英中文案完善。
- 原3888工作台进程无连接时重载当前源码，保持127.0.0.1/local/空启动工作区；实际3888浏览器再次验证项目和PDF下载。新进程PID以`paper-cn-workbench-reload-result.json`为准。
- 本轮源码**677项：676pass、1skip、0失败/错误/警告**；build成功，check **Status: OK**；完整依赖及Imports-only安装离线通过；Shiny **7组**通过，论文HTML桌面/移动8图0表无溢出；40 Figure PDF文字边界/重叠、CSV/XLSX/hash/引用审计pass，3current损坏探针pass。
- 工具：`research/paper_cn/`；当前稿自动审计`docs/paper_cn_v1/audit.json`，本轮日志`w00_baseline/paper-cn-*`。旧导出增加legacy_layout默认TRUE；新稿关闭旧横向表分页。原稿不覆盖。
- 首次PDF下载探针因动态下载href尚未绑定而读到HTML，失败日志保留；等待href后通过。图稿发现并修复框架卡片重叠、注释重叠及标签越界；模型无PDF/图片直接视觉能力，本轮不等同人工图稿审阅。
- 本轮无在线模型、专家、用户研究；HTTP/bwrap/74API专项仍用此前10-08review记录，没有重新算成本轮新结果。

### 新论文公开上传（用户本轮明确授权）

|材料|服务编号/公开下载|本地路径|
|---|---|---|
|Word可编辑稿|**#45** http://62.234.106.117:8003/api/download/45|`docs/paper_cn_v1/BioExplainR-中文论文-v0.8.docx`|
|PDF正式稿|**#46** http://62.234.106.117:8003/api/download/46|`docs/paper_cn_v1/BioExplainR-中文论文-v0.8.pdf`|
|论文及图表附件|**#47** http://62.234.106.117:8003/api/download/47|`docs/BioExplainR-中文论文-v0.8-图表附件.zip`|

上传为is_public=1，HTTP200/ok:true；3文件的download/file共6匿名回读HTTP200且bytes/SHA-256与本地一致。大小/hash/UTC见`paper-cn-upload-result.json`及PAPER_CN_CONTINUATION。凭据不写入源码、日志、manifest或交接。论文附件ZIP76成员，仅含新稿/图表，不是r7源码包。

## 交付与历史保护

- 最近已核验开发审阅包：`docs/BioExplainR-development-delivery-0.4.0.9000-r7.zip`，**787成员**；含中文v0.8、图表、15场景、公开真实RDS输入和本轮工具/日志。75,313,559bytes，SHA-256`59993a682dd0f0f9cbe51cfe582234f5b846b5df748b40ff5f33daf0f2953581`；逐成员见`paper-cn-delivery-audit-result.json`。r1–r6保留，r6的598成员验收对应修改前树。
- 当前 tar：`BioExplainR_0.4.0.9000.tar.gz`，已 build/check；历史 `BioExplainR_0.3.1.tar.gz` 保留。
- 原主稿/补充及`docs/submission_assets/`保留历史记录；当前稿/图表以`docs/paper_cn_v1/`为准，历史图表35PDF/13Excel/2,770记录ZIP未改写。
- `docs/BioExplainR-user-guide.docx` 是历史0.3.1指南；新接口以 `DEVELOPMENT_DELIVERY.md`、`DATA_CONTRACTS.md`、`MIGRATION.md` 和安装帮助为准。
- 旧 `BioExplainR-submission-bundle.zip` historical_stale；210成员、132当时内容变化、2旧路径缺失；`bundle_inspection.json` 保留旧包检查，不能更新覆盖原保护清单。
- 私有服务器文件 #32/#33/#34 早于最终修订；新上传需当次明确授权。密钥不写源码、日志、manifest 或交接。

## 用户本人事项

**唯一用户待办文件：[docs/USER_ACTIONS_REQUIRED.md](docs/USER_ACTIONS_REQUIRED.md)。** 已精简为科学材料/决定、真实人员/伦理、在线预算/发表授权、作者信息和人工/第三方身份确认。不要把下载、hash、映射校验、自动测试或打包转交给用户。

该本地待办文件10-08已同步负责人决定；外部#35/#36仍为10-05版，未重新上传。旧版hash仅对应下方上传历史，不对应当前本地文件。

工程仍未完整覆盖：自动全覆盖分块协议、超出本轮显式标量符号关系的跨模态联合检查、Seurat spatial/复杂图层、真实引擎版本格式、全部API行为独立 sign-off、新独立 test/gold/评价、fresh OS/正式lockfile/远程矩阵。公开开发数据可由执行者继续选择；W10-C/W11/W09最终独立评价仍需冻结和真实专家/参考材料，无材料不能补造结果。

本轮 sandbox 只挂载 host runtime/安装库/public fixture，gold/project/home不挂载；实测无网络/只读/scratch/限额/timeout。不是全新容器镜像，也不是正式模型代码代理研究。早期失败日志保留，成功验收以 acceptance 入口为准。

## 用户本人事项上传记录（2026-10-05）

负责人授权后，已将“仅需负责人本人完成的事项”上传到外部上传服务。该动作只涉及待办清单，不含源码、稿件、数据或人工评价材料。

| 项目 | 实际值 |
|---|---|
| 目标 | `http://62.234.106.117:8003/api/agent-upload`（HTTP 200，`ok: true`） |
| 上传文件 | `docs/USER_ACTIONS_REQUIRED.md`，3,920 bytes，SHA-256 `6dcf5b59e29bc3711f58538c89eaf8b4ba9aa1f79d76c8232fb847d5e13527ce` |
| 服务端编号 | **#35**，上传者 id 4，`is_public=0`，时间 2026-10-05T15:43:53.868Z |
| 服务端文件名 | `1791215033858-2609292399-USER_ACTIONS_REQUIRED.md` |
| 返回地址 | download/preview/file `http://62.234.106.117:8003/api/{download,preview,file}/35` |
| 鉴权凭据 | 请求所用 bearer token 属秘密，未写入源码、manifest、文档、交接或日志；后续会话需由负责人重新提供 |

上传后按返回地址核对：`/api/download/35`、`/api/file/35`、`/api/preview/35` 在带和不带该 token 两种情况下均返回 **HTTP 403**。因此**未能完成上传后内容比对**，服务端副本是否与本地文件一致属于未验证状态；如需下载核验，请负责人使用其账号访问 #35 或提供具备下载权限的凭据。

本地文件是唯一可核对来源；current manifest 的 documentation 清单与原保护清单不受该外部上传影响。若负责人随后修改 `USER_ACTIONS_REQUIRED.md`，需重新上传并在本文追加新编号，不要覆盖本条记录。

## 用户本人事项公开上传记录（2026-10-06）

负责人随后明确要求以 `is_public=1` 重新上传同一文件，并已实际执行成功。这一版可匿名读取，因此上载内容视为公开。

| 项目 | 实际值 |
|---|---|
| 目标 | `http://62.234.106.117:8003/api/agent-upload`（HTTP 200，`ok: true`） |
| 上传文件 | `docs/USER_ACTIONS_REQUIRED.md`，3,920 bytes，SHA-256 `6dcf5b59e29bc3711f58538c89eaf8b4ba9aa1f79d76c8232fb847d5e13527ce`（与 #35 同一内容） |
| 服务端编号 | **#36**，`is_public=1`，时间 2026-10-06T00:25:31.958Z |
| 服务端文件名 | `1791246331956-1930385959-USER_ACTIONS_REQUIRED.md` |
| 公开地址 | `http://62.234.106.117:8003/api/download/36`、`/api/file/36`、`/api/preview/36` |
| 内容核对 | 三个地址在不携带凭据时均 HTTP 200，回读 SHA-256 与本地文件完全一致（#35 的 403 已不再出现） |
| 鉴权凭据 | 上传所用 bearer token 属秘密，未写入源码、manifest、文档、交接或日志 |

#35（私有）与 #36（公开）为同一文件的两条记录。若需撤销公开访问，需在该服务端删除或改为私有；本地文件不会因此改变，重新上传时追加新编号，不覆盖本条。

## 续接顺序

1. 先读PAPER_CN_CONTINUATION、paper_cn_v1/README、SESSION_HANDOFF及current manifest。当前主力是论文和实际写作中发现的工作台问题；核对current_audit的manifest_sha256确认清单未再变。
2. 修改当前稿时新建论文版本/结果输出/执行label并跑适用检查。公开开发数据由执行者选择；专家后置、用户研究deferred。最终独立评价另冻结test/gold，不能看test gold调规则后报同一test结果。
3. 本轮论文上传授权已执行，仅覆盖#45–47；未获其他明确授权不提交/推送/release/DOI或上传其他材料，缺作者信息保留占位。
4. 文档或源码变化后，更新交付包新路径和 manifest，再执行 current/historical audit；原保护清单不变。

## 环境与命令

Ubuntu24.04.4/R4.3.3/Bioc3.18；系统R及论文venv/Node工具已恢复。环境定义见 `docs/REPRODUCTION.md`，恢复 `restore-baseline.sh`/`restore-development-optional.sh`。依赖清单是实际版本，不宣称transitive lock。

```sh
R --vanilla --slave -f tools/check.R
R CMD build .
R CMD check --no-manual --no-vignettes --no-build-vignettes BioExplainR_0.4.0.9000.tar.gz
python3 tools/http-transport-smoke.py --output /tmp/opencode/http-check-new.json
python3 tools/shiny-acceptance.py --output /tmp/opencode/shiny-check-new
python3 tools/isolated-library-check.py --archive BioExplainR_0.4.0.9000.tar.gz --output /tmp/opencode/core-check-new
python3 tools/sandbox-boundary-check.py --library /tmp/opencode/core-check-new/library --output /tmp/opencode/sandbox-check-new.json
Rscript --vanilla tools/legacy-interface-check.R /tmp/opencode/api-check-new.json
python3 research/multiomics/audit_miniacc.py research/results/miniacc_development_v1
# 重跑真实案例使用新输出目录；默认源码，--installed 使用实际安装包：
Rscript --vanilla research/multiomics/run_miniacc.R research/results/miniacc_development_new
R_LIBS=/tmp/opencode/bioexplainr-install-review Rscript --vanilla research/multiomics/run_miniacc.R research/results/miniacc_installed_new --installed
python3 research/multiomics/test_audit_miniacc.py
R_LIBS=/tmp/opencode/bioexplainr-install-review Rscript --vanilla tools/legacy-interface-check.R /tmp/opencode/api-installed-new.json --installed
python3 research/manage_baseline.py manifest
R --vanilla --slave -f research/audit_results.R --args --mode=current
R --vanilla --slave -f research/audit_results.R --args --mode=historical
```

HTTP/Shiny acceptance 自动启动/停止本地服务，无真实模型调用。sandbox 使用当前可用sudo/bwrap，不应把不可用环境标为pass。源稿/表/图改动时才重导出，以交接和REPRODUCTION入口按实际范围执行。
