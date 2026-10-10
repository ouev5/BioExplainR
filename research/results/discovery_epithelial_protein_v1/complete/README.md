# 上皮蛋白候选检查 v1

2026-10-10，公开数据实际下载后的统计续接。

- [中文科学结果](FINDINGS.md)
- [完整CSV-XLSX工作簿](epithelial_protein_tables.xlsx)／[候选结果CSV](candidate_results.csv)／[全部QC蛋白CSV](all_protein_results.csv)
- [实际BioExplainR中文报告](BioExplainR-epithelial-zh.html)／[英文报告](BioExplainR-epithelial-en.html)
- [冻结方案与输入](analysis_freeze.json)／[完整蛋白组身份核对](HBEC_all_member_identity.csv)／[独立R复核](r_audit.json)／[执行记录](EXECUTION_NOTES.md)
- [本地续接包](epithelial_protein_bundle.zip)／[独立清单](epithelial_manifest.json)

保存结果只读核验，在仓库根目录：

```sh
python3 research/discovery/finish_epithelial_identity.py verify
```

依赖Python3.12、numpy1.26.4、scipy1.11.4、openpyxl3.1.2；独立数值实现base R4.3.3／jsonlite。
本目录是完整Protein.IDs身份纠正后的**最终入口**，上级目录为保留的首轮结果。
首轮HBEC MAOA只验证主要成员，完整组还含其他accession，因此最终不将其归为MAOA。
[修订方案](../../../discovery/EPITHELIAL_IDENTITY_AMENDMENT.md)在看到首轮结果后冻结，
这不是盲法验证；原输入、名单、方向、统计及校正家族保持。

本地ZIP包含本轮最终及首轮结果、直接输入和冻结代码，可按内部完整文件路径恢复；更早v0.13/
下载封存的层叠核验仍需原文件树。清单不覆盖旧封存或把上皮结果作为ASM验证。
