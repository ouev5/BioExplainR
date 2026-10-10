# 上皮蛋白候选检查 v1

2026-10-10，公开数据实际下载后的统计续接。

- [中文科学结果](FINDINGS.md)
- [完整CSV-XLSX工作簿](epithelial_protein_tables.xlsx)／[候选结果CSV](candidate_results.csv)／[全部QC蛋白CSV](all_protein_results.csv)
- [实际BioExplainR中文报告](BioExplainR-epithelial-zh.html)／[英文报告](BioExplainR-epithelial-en.html)
- [冻结方案与输入](analysis_freeze.json)／[独立R复核](r_audit.json)／[执行记录](EXECUTION_NOTES.md)
- 本地续接包`epithelial_protein_bundle.zip`和独立清单`epithelial_manifest.json`在最终核验后生成。

保存结果只读核验，在仓库根目录：

```sh
python3 research/discovery/finish_epithelial_protein.py verify
```

依赖Python3.12、numpy1.26.4、scipy1.11.4、openpyxl3.1.2；独立数值实现base R4.3.3／jsonlite。
本地ZIP包含本轮全部结果、直接输入和冻结代码，可按内部完整文件路径恢复；更早v0.13/
下载封存的层叠核验仍需原文件树。清单不覆盖旧封存或把上皮结果作为ASM验证。
