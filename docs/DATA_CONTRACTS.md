# BioExplainR 数据契约

版本：1.0，2026-10-05；实现版本：0.4.0.9000。

本文冻结 W01–W04 使用的机器字段。R 对象仍采用 list/S3 表示；JSON schema 位于 `inst/schema/`，最小正反例位于 `inst/fixtures/contracts/`。规划文件中的字段以本文为准，新增字段必须增加 schema 版本或给出迁移说明。

## 版本和状态

`schema_version` 是语义契约版本，当前为 `1.0`。缺失字段的旧对象按 `legacy` 读取，并保留信息缺失；读取过程不会推测来源、scope 或独立重复。`pass` 只表示已声明检查范围内的必需检查通过。聚合顺序为 `fail` → `partial` → `pass`，没有实际检查的对象为 `unverified`；当前能力明确不能评价时使用 `not_assessable`。

`bio_context()` 在新对象中保存 `schema_version/context_id/facts_hash/scope/design/fact_descriptors`。`context_id` 对规范化语义内容求 SHA-256，排除创建时间和自身 ID；`facts_hash` 只覆盖完整适配器事实。旧对象没有这些字段时，兼容读取器返回 `legacy` 或 `NULL`，不会伪造哈希。

## Context

必需字段为 `analysis_type`、`source_class`、`source_status`、`facts`、`uncertainty`、`metadata`、`adapter`。`source_package` 可以为 `NA`。`source_status` 为 `verified_class/user_declared/inferred_from_columns/unknown`。`top_features` 是有限 preview，不能被当成完整 facts；引用它的 finding 必须有 `reference_scope = preview`。

`scope` 使用已知值：`dataset_id/analysis_id/species/tissue/modality/assay/comparison_id/region_id/section_id/sample_level`。未知值保留 `NULL` 或 `unknown`。`design` 保存 `independent_unit/pairing/group/batch/donor/timepoint/replicate_role` 等设计信息。`fact_descriptors` 每个叶节点记录 `value_type/source_path/computation/inspection/completeness`。

## Model payload 与 manifest

模型输入和验证输出是两个 schema。`bio_payload_policy()` 显式决定 `max_top/max_chars/include_features/fact_mode/metadata_allowlist`。默认旧入口允许 preview 缩减；使用 `fact_mode = "complete"` 时 facts 超出预算会明确报错，不静默删事实。字段策略会移除样本、患者、barcode、本地路径、密钥和凭据样 URL；科学标签只有在 allowlist 中才进入 payload。

数值序列化采用 jsonlite `digits = 17`、`na = "null"`、`null = "null"`。NA 不是 0；Inf/NaN 由 JSON null 表示并须由 descriptor 说明不可比较。`facts_hash`、`payload_hash`、`request_hash`、`response_hash` 覆盖不同表示，manifest 不含鉴权信息，也不对含自身的 ZIP 求自引用 hash。`bio_explain()` 默认采用 complete facts；旧 payload 位置参数保持兼容。`completeness$omitted_fields/omitted_fact_paths` 记录字段/preview 及事实缩减，完整性限于隐私过滤后可发送内容；隐私删除不改变本地 facts。

manifest 至少包含 `manifest_version/run_id/context_id/facts_hash/payload_hash/request_hash/response_hash/schema_version/serialization_version/numeric_policy/policy_id/created/status`，并可保存公开的模型、provider、usage、elapsed 和 attempt 信息。缺失文件或响应使用 `missing/not_run`，不能写成成功。

`bio_llm_chat()` 的 `request_hash` 覆盖实际 UTF-8 HTTP JSON body（鉴权 header 不在 body 中）；`request_semantic_hash` 是另一个 canonical object hash。`response_hash` 覆盖 canonical parsed provider JSON，并由 `*_hash_scope` 说明，不声称是原始响应字节。usage 的公开 token 计数保留，API token/secret 字段删除。URL 使用结构化解析移除 user/password、凭据 query 和 fragment，保留公开来源地址。loopback 两协议实际传输已通过 `tools/http-transport-smoke.py` 核对。

## Typed claim ledger

每一行是一个原子声明。字段为 `id/schema_version/claim_type/text/origin/text_ref/context_id/fact_path/path_tokens/value/value_type/unit/direction/scope/evidence_refs/validation`。`claim_type` 为 `statistical_fact/statistical_interpretation/biological_association/causal/evidence_support/design/plot_mapping/unknown`；`origin` 为 `local_template/model/user`。

路径内部使用 token 数组，兼容层读取旧 `fact/reference/path` 和 `facts.x`、`x.1`、`top_features.1.x`。不能使用 `eval(parse())`。模型提交的 validation 字段不被信任；验证器重新生成 findings。没有 fact path 的 prose 保留在 `unmapped_prose`，不能由提交较少 claims 获得全文 pass。声明 scope 不从 context 隐式补写；integer/count 精确比较，logical/string 不与数字自动互换，数值 facts 可接受完整小数字符串；未知单位不可 pass。总 status 合并 typed/evidence findings，旧状态保存在 `legacy_status`，模型全文缺覆盖时最多 partial。

## Evidence relation

`bio_evidence` 保留既有 ID 和位置参数，增加 `content_type/scope/role/content_hash/content`。`bio_evidence_support()` 保存 claim–evidence pair 的 `relation/role/origin/status/detail/reviewed_at/reviewer_id/rubric_version`。relation 为 `supports/contradicts/definition_only/irrelevant/unknown`，role 为 `definition/annotation/method/dataset_support/experimental_support/structural_computation`。检索成功是 retrieved；`expert_reviewed` 只能来自明确人工输入。引用 ID 存在不等于支持成立。

## Sample map、空间和结构

`bio_sample_map()` 要求 `modality/source_id/biological_unit`，通过 ID 对齐，不按行序猜测。技术重复可多对一，但真实生物学重复冲突会 fail；缺失模态和额外 ID 保留在 alignment findings。`MultiAssayExperiment` 为每个 assay 保留 child context 和 sampleMap 摘要。

2026-10-07 向后兼容扩展：alignment 新增 `coverage/pairwise/n_primary_units/n_complete_units/n_unmeasured_units/coverage_basis`；可选 `primary_units` 保留完全未测量的病例。映射合法的 pass 不表示所有病例的模态齐全。`observed` 若提供，覆盖按实际观测 ID 计算；完整样本 ID 只在本地 alignment 中保存，payload facts 仅保留计数。

项目方向关系表要求 `id/from/to/from_fact/to_fact/feature_id/expected`，expected 为 same/opposite；可选 list 列 from_tokens/to_tokens 支持含点号键。`bio_validate_project_relations()` 要求 scope 的 dataset_id/comparison_id/species/tissue/sample_level 一致，design 的 numerator/denominator 明确且一致，fact descriptor 的 feature_id 匹配。只有有限非零标量可核对正负方向。方向检查不检验效应大小、显著性或机制；不同模态允许不同效应单位。`bio_project()` 自动检查含 from_fact/to_fact/expected 的关系表；旧关系表继续保留。新增 `relation_validation` 在报告和项目模型输入中展示，旧对象缺此字段仍可读取。此扩展不改变 1.0 既有必需字段，迁移说明见 MIGRATION。

`SpatialExperiment` 适配器读取公开 accessor 的坐标、imgData、colData 和 assay 名称，记录坐标单位、缺失和 section；没有 mask 不生成组织覆盖率，没有图层能力返回 not_checkable。`bio_spatial_neighbors()` 只建立记录单位、半径/k 和 section 边界的几何边，不把边解释成机制。`bio_docking_context()` 只解析表格并保存引擎、版本、文件 hash、score 方向和 RMSD 参考；默认不执行外部引擎，缺 provenance 时只能 partial/unverified。

## 生产者和消费者

Context 由适配器生产，被 payload、local explanation、project、report 和 manifest 消费；ledger 由本地模板/模型输出生产，由 validator、report 和 benchmark 消费；evidence relation 由规则/用户/专家生产，由 validator、report 和研究评分消费；sample map 由对象 accessor 或显式本地表生产，由 project 和跨模态检查消费。模型输入不得写入 verifier status，gold 不进入 runner 工作目录。
