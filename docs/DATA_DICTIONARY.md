# BioExplainR 数据字典

这是 W01–W13 工程和研究产物的字段入口。它描述字段的语义和来源，不把占位候选或未执行研究写成结果。

| 对象/文件 | 主键 | 关键字段 | 来源 | 消费者 |
|---|---|---|---|---|
| `bio_context` | `context_id` | `analysis_type`, `facts`, `scope`, `design`, `fact_descriptors`, `facts_hash` | R adapter / `bio_context()` | payload、ledger、project、report |
| payload | `context_id` | `facts`, `top_features`, `completeness`, `policy_id` | `bio_context_payload()` | model request |
| manifest | `run_id` | facts/payload/request/response hashes, status, numeric policy | `bio_context_manifest()` | runner、报告、审计 |
| claim ledger | explanation 内 `id` | type、origin、path tokens、value、scope、evidence refs、validation | local/model/user claim | validator、report、benchmark |
| evidence relation | `claim_id + evidence_id` | relation、role、origin、scope finding | `bio_evidence_support()` | evidence validator、review |
| sample map | `modality + source_id` | biological unit、replicate role、missing/exclusions | explicit table / MAE sampleMap | project alignment |
| benchmark cases | `case_id` | dataset、family、question、input hash、required response items | frozen benchmark owner | runner |
| benchmark calls | `run_id + case_id + method_id + repeat_no` | request/response hash、status、usage、latency | runner | audit、scores |
| scores | endpoint analysis unit | prediction、reference、correct、answered、failure kind | controlled gold + runner | statistical analysis |

`created` and elapsed time are operational fields and do not enter semantic
hashes. Sample IDs, barcodes, patient identifiers, local paths and secret
configuration are either retained in a controlled local map or removed by the
payload policy. A hash proves identity of the covered bytes; it does not prove
that a source supports a biological claim.
