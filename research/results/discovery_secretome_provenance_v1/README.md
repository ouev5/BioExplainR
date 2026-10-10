# 来源诊断与ASM公开材料续接

[4页中文报告](../../../docs/secretome_provenance_v1/README.md)／
[实际结论](FINDINGS.md)／[修订](EXECUTION_NOTES.md)。2026-10-10。

- `freeze.json`、`rgo_before_provenance.md`：开始原输入hash/旧rgo精确快照。
- 根`cross_array*`/`analysis.json`：首轮结果，proteome数字样本编码未解码；
  完整保留，最终以`complete/`为准。根ALL不受该样本列修订影响。
- `complete/freeze.json`、`sample_map.csv`：四原解码/168列完整新冻结。
- `complete/diff_measurement_cross_array.csv`：281,232位置，包括iBAQ未提供；
  `cross_array_summary.csv`48摘要；根ALL31,228位置，最终R逐格核对。
- `complete/scale_formula*`：六诊断公式4,968位置，零不填补，未校正候选值。
- `sources/`：实际查询JSON/XML、PRIDE项目/56文件清单/映射Workbook、
  13页EV原补充PDF与失败challenge；失败请求在对应acquisition.json保存。
- `complete/EV_*`：六患者/18run映射、原选中糖酵解8行、两路PDF核验和范围。
- `complete/project_feasibility.csv`、`public_evidence_scope.csv`：八项目排除原因、
  PTX3/咳嗽/EV/旧HTPC原文支持与限制；不是全文系统综述。
- `complete/r_audit.json`、`independent_audit.json`：R原数组/解码与独立OOXML。
- `complete/report_final/`：实际BioExplainR两个generic context、项目/双语HTML；
  根complete旧报告宽表失败保留，最终版本五列精确计数和完整scope。
- `complete/scientific_ledger.json`：科学范围与实际审计；报告`audit.json`/
  `browser_final/audit.json`和独立`provenance_manifest.json`。

本轮无新GC候选蛋白显著性检验、无PXD055968完整定量数组分析。旧科学全部
原路径/hash，现根rgo由新清单绑定。保存核验入口见中文报告README。
