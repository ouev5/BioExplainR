# PXD033504 完整分泌蛋白组

[中文报告](../../../docs/secretome_validation_v1/README.md)／[实际结论](FINDINGS.md)／
[执行修订](EXECUTION_NOTES.md)。新研究在原候选LFQ提取前冻结，跨组织公开探索。

- `archives/{24h,72h}/extracted/`：完整proteinGroups、解码、parameters、summary。
  `extraction.json`记录8成员CRC及两个完整容器上游SHA1；header/block实体与失败保留。
- `analysis_freeze.json`、`design_freeze.json`、`frozen_genes.csv`：阶段、输入和
  实际执行脚本hash、56原名单、原样本双源核对及发表子集。
- `all_results.csv`、`all_measurements.csv`、`all_donor_effects.csv`、`group_QC.csv`：
  全846QC蛋白组统一BH、35,016LFQ技术测量、5,836日期组行、1,131原组QC。
- `candidate_*.csv`：完整112位置、识别/缺测/供体、主/严格/发表子集、直接差、
  留一及原ASM方向关系。不填补LFQ0，缺测P=1只是保留检验位置。
- `published_*.csv`：完整发表ALL/选中DIFF、逐格差异、总Intensity及尺度诊断。
- `r_numeric_audit.json`、`r_diagnostics_audit.json`：独立R原数组数值复核。
- `scientific_ledger.json`：结果/范围；`bioexplainr_project.rds`和双语HTML：实际
  源码R包应用，完整846/112分母通过，在线调用0。
- `sources/`：PRIDE项目与UniProt原响应；原论文/Workbook依赖由freeze精确hash引用。

保存验证与实际新目录复现命令见报告README。旧rgo精确快照用于原v0.12文档
依赖；原科学/旧清单不改写。新封存入口为报告`secretome_manifest.json`。
