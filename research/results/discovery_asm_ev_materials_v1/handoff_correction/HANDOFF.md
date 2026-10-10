# PXD055968 最终材料续接：最终入口

2026-10-10。**真实最终定量材料仍缺，候选身份检查未冻结、未启动。**

本轮继续公开来源追查，新增 HAL 真实论文记录（只列一 PDF）；复核 PRIDE
本项目56项及两关联项目48/38项，完整清单共142项。Recherche Data Gouv四
查询有效0索引结果；OpenAIRE超时、Figshare403、HAL PDF部分下载保留。

- [实际结果与缺口](../FINDINGS.md)
- [来源请求及内容核对](../public_routes_review.csv)
- [三项目完整文件清单](../related_project_inventory.csv)
- [材料接收核对顺序](../MATERIALS_RECEIPT.md)
- [原缺件清单](../../discovery_asm_ev_export_v1/required_materials.csv)
- [作者材料请求草稿：未发送](../../discovery_asm_ev_export_v1/AUTHOR_MATERIAL_REQUEST.md)
- [失败、中断与修订](../EXECUTION_NOTES.md)
- [来源清单](../materials_manifest.json)／[最终交接清单](../handoff_manifest.json)

下一实际动作：负责人以真实姓名／单位／邮箱发送现有材料请求，或提供已取得
的作者回信／公开链接／原附件。仍需论文对应未按差异预筛蛋白组×18run表、
最终联合workflow与版本说明、原缺测和同版本肽映射、六患者年龄／成人确认
及重复层级。接收合格后另冻结完整固定候选身份检查。

最终核验命令：

```sh
python3 research/discovery/asm_ev_materials_handoff.py verify
```

HAL字段计数初稿260误写，原机器结果一直为262。最终文字已纠正，修订前
rgo/FINDINGS/执行记录先保存精确快照；旧清单通过这些快照核对，新交接清单
绑定现文字。所有科学原文件/hash保持，层叠核对旧封存和原2,905保护文件。
初封存README的直接核验命令是历史入口，当前使用上面的最终入口。
