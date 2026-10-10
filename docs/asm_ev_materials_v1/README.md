# PXD055968 最终材料续接

2026-10-10。**公开来源续查已完成，最终未按差异预筛蛋白组×18 run 表与版本
说明仍未取得；候选身份检查未冻结、未启动。**

- [实际发现与缺口](../../research/results/discovery_asm_ev_materials_v1/FINDINGS.md)
- [新增公开来源请求及内容核对](../../research/results/discovery_asm_ev_materials_v1/public_routes_review.csv)
- [三关联项目142项原清单](../../research/results/discovery_asm_ev_materials_v1/related_project_inventory.csv)
- [关联项目范围](../../research/results/discovery_asm_ev_materials_v1/related_project_scope.csv)
- [HAL真实论文记录及附件核对](../../research/results/discovery_asm_ev_materials_v1/hal_source_review.json)
- [材料接收核对顺序](../../research/results/discovery_asm_ev_materials_v1/MATERIALS_RECEIPT.md)
- [原缺件清单](../../research/results/discovery_asm_ev_export_v1/required_materials.csv)
- [材料请求草稿：未发送](../../research/results/discovery_asm_ev_export_v1/AUTHOR_MATERIAL_REQUEST.md)
- [真实失败及中断](../../research/results/discovery_asm_ev_materials_v1/EXECUTION_NOTES.md)
- [机器状态](../../research/results/discovery_asm_ev_materials_v1/final_status.json)
- [新完整性清单](../../research/results/discovery_asm_ev_materials_v1/materials_manifest.json)

HAL `hal-05063440v1` 当前只列一论文 PDF；元数据 version 1／修改日期不等于
最终蛋白组 workflow 版本。PDF本轮只取得部分原字节，不宣称完整下载。
PRIDE本项目56项与前轮一致，两个关联项目48/38项均为EV处理后的上皮研究。
Recherche Data Gouv四查询有效0索引结果；OpenAIRE超时、Figshare403保留。

下一实际动作是以负责人真实身份发送现有材料请求，或提供已收到的作者回信、
下载链接及原附件。接收先核对最终版本、18run映射、原缺测、肽证据与重复层级，
合格后另冻结完整候选身份检查。缺件继续记录为阻塞。

保存结果核验：

```sh
python3 research/discovery/seal_asm_ev_materials.py verify
```

该入口核对新来源和源码，并将前轮export唯一根rgo文档依赖对应到开始精确快照
`rgo_before_materials.md`；其余旧科学原路径/hash，层叠旧封存与2,905保护文件。
根rgo已更新，前轮seal直接读取现根rgo会失败，应使用上述续接入口。
