# W01 现有接口清单

核对日期：2026-10-05；基线：BioExplainR 0.3.1；当前开发版：0.4.0.9000。本文记录原有源码与实际加载结果，**不是新增契约**。W01 契约已冻结，详见 `DATA_CONTRACTS.md` 和 `MIGRATION.md`。

## 机器清单

- `research/results/w00_baseline/api_inventory.csv` / `.json`：74 个导出函数的完整位置参数顺序、默认值、源文件和行号，由 `tools/capture-baseline.R` 从实际函数与 R AST 生成。
- `research/results/w00_baseline/continuation-api-inventory.csv`：0.4.0.9000 实际安装包的 89 个导出函数及签名；本页其余表格仍描述 74 个历史 API，开发契约以 DATA_CONTRACTS/MIGRATION 为准。
- `research/results/w00_baseline/legacy_object_shapes.json`：使用本轮构建/检查安装的包执行后保存的字段名。
- `research/results/w00_baseline/offline-context.json` / `offline-report.html`：可手算离线例；不作为科学研究结果。
- `research/results/current_manifest.json` → `source`：逐文件哈希和 package 内容哈希，无 Git HEAD 时 `commit_sha = null`。

## 核心入口

| 入口及当前位置参数 | 返回值 / 行为 | W01 兼容要求 |
|---|---|---|
| `new_bio_context(analysis_type, source_class, source_package, source_status, facts, top_features, plot_mapping, provenance, uncertainty, metadata, adapter)` | S3 list `bio_context`；构造器不自动设置 language | 新字段用追加命名参数；读取旧对象不补造来源 |
| `bio_context(x, analysis_type, adapter, species, tissue, contrast, gene_id_type, design, background, source_package, thresholds, p_adjust_method, coefficient, n_top, data_dependencies, notes, language, ...)` | 适配器确定性 facts；输入已是 context 时直接返回 | 旧 facts 的路径、类型与阈值语义保留；已有对象短路行为须明确 |
| `bio_context_payload(ctx, max_top=10, max_chars=12000, include_features=TRUE)` | JSON-ready list；先减 top，再移除 plot mapping 并截断长度 >20 的 facts | W02 将收紧完整性策略；当前 max_top 无完整校验，max_chars 为字符预算 |
| `bio_explain(x, config=NULL, use_llm=NA, language=NULL, level, question, evidence, max_top, cross_check, evidence_sources, evidence_args, allow_subset, ...)` | `bio_explanation`；NA 根据可用配置决定模型调用 | 示例显式 FALSE；模型输入/输出与验证器输出分离 |
| `bio_validate_explanation(explanation, claims=NULL, tolerance=1e-6)` | 返回原 explanation 加 `validation`；默认取 `llm$claims` | 旧 `validation$status/findings/n_claims` 必须可读；未来 validator 返回值待冻结 |
| `bio_evidence(source, id, title, claim, url, type, version, accessed=Sys.Date(), note)` | `bio_evidence`；ID 为 `source:id/title/unnamed` | 保留 ID 与位置参数；pair 支持关系不能写成整篇文献属性 |
| `bio_project(results, title, dependencies=list(), metadata=list())` | `bio_project`；命名结果、上游→派生 DAG、跨结果文字一致性 | sample_map/relations 为拟增内容；不改现有参数顺序 |
| `bio_explain_project(project, config=bio_get_config(), use_llm=FALSE, max_chars=24000, language=NULL)` | 返回 project 加 `interpretation`；模型 prose 始终 unverified | 项目级核查尚无 ledger，不能沿用模型状态为验证结果 |
| `bio_report(x, file, format, title, include_llm, include_session, config, show_answers, language)` | 不可见返回字符；写 Markdown/HTML/Quarto | report 消费验证结果，不重新推断科学判定 |
| `bio_build_request(config, system, user)` / `bio_llm_chat(config, system, user)` | `httr2_request` / `text, model, stop_reason, usage, endpoint_host, elapsed_sec` | W02 请求边界测试点；公开 hash 不包含鉴权配置 |

完整默认值以机器清单为准；本表只显示需要优先冻结的接口。

## 当前对象字段及消费者

| 对象 | 当前字段 | 生产者 → 消费者 |
|---|---|---|
| context | `analysis_type/source_class/source_package/source_status/facts/top_features/plot_mapping/provenance/uncertainty/metadata/adapter`；`bio_context()` 追加 `language` | `R/context.R`、`R/adapters-*.R` → payload、local template、validator、project、report、Shiny |
| provenance | `adapter/created/bioexplainr_version/thresholds/p_adjust_method/n_top/input_summary`，适配器可追加 | context/adapter → payload 只取 thresholds；report 取参数/时间；当前不做规范化 hash |
| metadata | species/tissue/contrast/gene_id_type/design/background/source_package/data_dependencies/notes/analysis_type_hint/coefficient（NULL 删除） | `bio_context()` → local/payload/project/report；不是 typed scope/design |
| payload | `analysis_type/source/study_context/facts/top_features/plot_mapping/thresholds/uncertainty` | `bio_context_payload()` → `.llm_user_prompt()`、项目解释；无 schema/version/completeness |
| explanation | `context/local/llm/llm_meta/evidence/evidence_trace/evidence_retrieval/cross_check/level/language/verification/created`；调用模型时才自动加 validation | `bio_explain()` → validator、report、project、教学模块、Shiny |
| local | 六个 section + concepts；无原子 claims | `.explain_local_en/zh()` → report/print/quiz |
| model claims | `id/text/fact/value/evidence`；validator 兼容 `reference/path` 与 `evidence_ids/citations/citation` | 模型 JSON 或用户 → `bio_validate_explanation()`；未强制 ID 唯一、claim type、scope、unit |
| validation | `status/findings/n_claims/note`；findings 为 `claim/check/status/detail` data.frame | validator → print/report/project/Shiny；无 prose coverage 和 evidence semantic status |
| evidence | `id/source/source_id/title/claim/url/type/version/accessed/note/supplied_by`；检索/解释可追加内容与 origin | evidence/provider/live retrieval → prompt/validator（只核 ID）/report |
| project | `title/items/dependencies/summary/consistency/metadata/created/version/interpretation` | `bio_project()` → project explanation/report；无 sample_map 或 modalities 对齐 |

## 枚举与边界

- 来源状态：`verified_class/user_declared/inferred_from_columns/unknown`。
- claim 聚合状态：`pass/fail/partial/unverified`；现有实现没有 `not_assessable`。
- project 一致性：`unknown/consistent/review_needed`；图形 `not_checkable` 与修复 `runtime_only/invariants_passed` 保持独立。
- 当前路径按 `.`/`$` 切分，支持 `facts.x`、数组 1-based 和 `top_features.1.x`；含分隔符的字段名尚无无歧义 token 路径。
- 计数方向、类型转换和 evidence ID 检查采用旧规则；支持关系与全文覆盖尚未验证。
- 包内 `.json()` 为 `digits=10`，`null/na="null"`；研究 runner 另用 `digits=17`。HTTP body 由 httr2 序列化，不是统一精度契约。
- source 默认缺失常用 NA_character_，可选元素可为 NULL，空 list/character/data.frame 并存；W01 须逐项冻结 null/empty，不把现状描述当作已完成 schema。

## 适配器与测试入口

自定义适配器优先；内置顺序为 DESeqResults、GSEA、enrich/compareCluster、limma、edgeR、cell composition、Seurat、SCE、SE、ExpressionSet、ggplot、prcomp、DE table、enrichment table、cell metadata、generic。空间类须在 SCE/SE 之前；当前无 MultiAssayExperiment、SpatialExperiment 或 docking 专用适配器。

W01 重点复用 `test-full-modules.R`、`test-hardening.R`、`test-llm.R`、`test-project-teaching-evaluation.R`、`test-i18n.R` 和 adapter tests；现有 531 项检查只证明当前软件行为。新增合法/缺失/错误类型/重复 ID/未知字段/legacy fixtures 仍由 W01 建立。

## 待 W01 冻结

1. context、fact descriptor、claim、relation、sample_map、manifest、finding 的必需字段/类型/枚举/null/empty；每个字段明确生产者和消费者。
2. 模型可见 schema 与验证器输出 schema；模型自报 validation 不被信任。
3. 新 validator 返回 explanation 的兼容方式、token 路径、unknown scope 聚合规则、preview 检查范围。
4. 开发版本号、schema 升级/迁移、导出 API 范围与 hash 依赖。W00 的 Python 文件 SHA-256 清单不等于 W02 包内 runtime manifest。
5. 所有新增参数追加并用命名调用；明确 local legacy 对象的 validation 缺失语义。
