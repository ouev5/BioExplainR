# BioExplainR 兼容与迁移

版本：1.0；适用包：0.4.0.9000。

## 0.3.1 对象

旧 `bio_context` 可直接传给 `bio_explain()`、`bio_report()` 和 `bio_project()`。缺失的 `schema_version/context_id/scope/design/fact_descriptors` 按 legacy 处理；不会根据 metadata 猜 scope。旧 `facts` 和 `top_features` 路径保持可读。

旧 payload 调用 `bio_context_payload(ctx, max_top, max_chars, include_features)` 仍保留位置参数和 bounded preview 行为。需要完整性保证的代码改用：

```r
policy <- bio_payload_policy(fact_mode = "complete", max_chars = 24000)
bio_context_payload(ctx, policy = policy)
```

## Claims

旧 `bio_validate_explanation()` 仍返回原 explanation，并保留 `validation$status/findings/n_claims/note`。新流程使用 `bio_validate_claims()`；它附加 `claim_ledger` 和 `validation$typed_findings/prose_status`，不删除旧列。`fact/reference/path` 被转换为安全 `path_tokens`；字段名包含点号的未来对象应直接保存 token 数组。

新验证会把缺 scope、未知 claim type、定义证据冒充处理支持和模型自报 pass 标为 unverified/partial/fail。这个语义收紧是迁移变化，不能为了保持旧数字而回退。

2026-10-05 续接修复：`bio_validate_claims()` 追加可选命名参数 `relations`；typed/evidence findings 纳入总状态，原状态保存在 `validation$legacy_status`。模型全文未独立映射时总 status 最多 partial。计数用精确比较，logical/string 类型不数值强转，scope 缺失不继承 context。`context_id` finalize 幂等，旧对象 manifest 不补造 context_id/facts_hash。`bio_explain()` 默认完整 facts，超预算报错；需旧 bounded 行为时显式传 `payload_policy = bio_payload_policy(fact_mode = "chunked")`。

## Evidence

原 `bio_evidence(source, id, title, claim, url, type, version, accessed, note)` 参数顺序不变。新增字段全部为命名参数。旧 evidence 没有 content hash 或 scope 时仍可显示和引用，但支持关系只能是 unknown/unverified，不能自动成为 expert reviewed。

## Project 和版本

`bio_project(results, title, dependencies, metadata)` 的旧位置参数不变；`sample_map` 和 `relations` 只能作为追加命名参数。旧结果和 0.3.1 论文记录继续按历史版本保存。带 W01–W08 新字段的代码使用开发版本 `0.4.0.9000`；发布候选由 W13 再统一版本号，不能把新实现标成 0.3.1。

## 迁移检查

2026-10-07：`bio_validate_sample_map(map, observed, primary_units=NULL)` 仅追加参数，并增加覆盖率和两两交集返回字段。已构造的 sample map 会重新校验，重复/缺失 observed ID 明确报错。新增导出 `bio_validate_project_relations()`；`bio_project()` 对具有方向契约列的 relations 自动生成 `relation_validation`。未知 scope/比较方向不推测，零效应方向保持 unverified。旧项目对象无新增字段时照常渲染。当前导出函数数为 90。

迁移后至少运行 `tools/check.R`、R CMD build/check、`inst/fixtures/contracts/validate_fixtures.R` 和离线 report smoke。旧对象缺字段的预期状态是 `legacy/unverified`，不是自动 pass。
