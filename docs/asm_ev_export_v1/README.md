# PXD055968 完整定量导出与处理版本核实

2026-10-10。**18个存档结果的版本／定量结构追查已完成；正确版本的完整定量
导出仍缺，候选身份检查尚未启动。**

## 结果入口

- [完整发现与边界](../../research/results/discovery_asm_ev_export_v1/FINDINGS.md)
- [18个结果的版本核对](../../research/results/discovery_asm_ev_export_v1/version_evidence_complete.csv)
- [三方处理版本比较](../../research/results/discovery_asm_ev_export_v1/processing_version_comparison.csv)
- [精确蛋白表列结构](../../research/results/discovery_asm_ev_export_v1/protein_columns_exact.csv)
- [六患者／18run映射](../../research/results/discovery_asm_ev_export_v1/sample_map_verified.csv)
- [缺件清单](../../research/results/discovery_asm_ev_export_v1/required_materials.csv)
- [材料请求草稿（未发送）](../../research/results/discovery_asm_ev_export_v1/AUTHOR_MATERIAL_REQUEST.md)
- [独立sqlite3／OOXML审计](../../research/results/discovery_asm_ev_export_v1/independent_audit.json)
- [实际失败与修订](../../research/results/discovery_asm_ev_export_v1/EXECUTION_NOTES.md)
- [机器状态](../../research/results/discovery_asm_ev_export_v1/final_status.json)
- [新封存清单](export_manifest.json)／[本地证据包](PXD055968-export-evidence.zip)

## 关键发现

存档18/18实际是 **PD3.1.0.638／CHIMERYS inferys_3.0.0／2024-01-22库**，
均单run、CWF_ID；54张target protein/group/peptide-group表均无最终丰度列，
跨run mapper/quantifier节点0。Minora feature及PSM强度不是最终蛋白定量导出。
论文PD3.0／inferys_2.1／2023库、PRIDE PD2.5／Mascot/Proline／2020库的冲突
现在有直接原文件证据，原因和最终发表版本仍需处理材料。

需要论文对应的完整未筛蛋白组×18run表、最终workflow／版本、原缺测与肽证据，
以及六患者年龄/成人确认及重复定义。三非哮喘／三哮喘患者，不计18独立供体；
无GC/vehicle因素。公开追查未取得数组，不说数据不存在，也不记候选阴性。

## 保存结果验证

仓库根目录执行：

```sh
python3 research/discovery/seal_asm_ev_export.py verify
```

新清单绑定本轮部分原字节、元数据、完整列结构、请求失败、结果说明和根rgo。
旧provenance根rgo依赖仅用 `rgo_before_asm_ev_export.md` 精确快照；其他旧科学
原路径/hash，层叠旧封存和原2,905保护文件逐项核验。旧latest/current仍是历史
范围。更新根rgo后，旧seal直接读现根rgo会失败，应使用上述新层叠入口。

本轮未取得完整原数据库，不宣称18个pdResult整文件上游SHA1通过；仅映射XLSX
完整文件上游SHA1通过。材料请求未发送，GitHub及外部上传继续暂停。
