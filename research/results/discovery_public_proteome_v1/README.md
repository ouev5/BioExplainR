# 公开蛋白组来源续接：阅读与复核入口

2026-10-10。完成公开清点分页补齐、HBEC完整处理表获取/映射核对、新来源
可行性审查及旧证据层叠核验。**未取得合格成人ASM GC蛋白验证数组，未做
候选统计，PXD055968最终导出仍缺。**

1. [实际结果与范围纠正](FINDINGS.md)
2. [检索范围](search_coverage.csv)、[新增分页18项目设计](additional_page_design_review.csv)、
   [21气道/平滑肌线索审查](project_eligibility_review.csv)
3. [HBEC表完整性/样本结构](HBEC_table_design_checks.json)、
   [43样本解码](HBEC_sample_decode.csv)、[四格/T2计数](HBEC_design_counts.csv)
4. [有效全文关键段落](key_article_sections.md)、[204文件清单获取](asm_inventory_plan_acquisition.json)
5. [真实失败与修订](EXECUTION_NOTES.md)、[请求计数与内容边界](request_summary.json)
6. [EV缺件/请求原hash核对](EV_inventory_recheck.json)、[最终状态](final_status.json)
7. [独立审计](independent_audit.json)、[新清单](public_proteome_manifest.json)、[验证结果](verification.json)

保存结果复核（只读，无网络，无统计重跑）：

```sh
python3 research/discovery/audit_public_proteome.py verify
```

本轮方案：[PUBLIC_PROTEOME_CONTINUATION_PROTOCOL.md](../../discovery/PUBLIC_PROTEOME_CONTINUATION_PROTOCOL.md)。
新目录`imported/`保存前轮61文件和3脚本原字节；`sources/`及`requests/`
保存本轮实际响应/每请求记录，完整/部分/HTTP错误/挑战页面明确区分。
实际查询为14真实关键词+1负控制；协议初稿词数误述与准确纠正见执行记录。
旧临时路径保留，`rgo_before_continuation.md`为本轮开始根rgo精确快照；
`rgo_before_public_search.md`为前轮公开清点前精确快照，其hash匹配旧handoff
清单根rgo依赖。核验只对这一变更文档使用快照，其他旧科学原路径/hash，
旧清单/ZIP与2,905保护文件保持。当前根rgo由新清单绑定。

下一实际材料动作仍为负责人发送PXD055968现有精确请求或提供原回信/附件。
收到原件后先按[材料接收顺序](../discovery_asm_ev_materials_v1/MATERIALS_RECEIPT.md)
核对版本/矩阵/缺测/重复，再另冻结完整候选身份方案。临床HBEC如另开展
探索须另冻集合与纵向关联模型，不转称ASM验证。GitHub/外部上传继续暂停。
