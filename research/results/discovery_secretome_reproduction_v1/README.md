# PXD033504 同来源实际数值复现

2026-10-10实际执行。`reproduction_audit.json`为pass：重新运行样本解码/设计、
全部数组与112候选统计、独立R原数组复核、BioExplainR项目与双语HTML；
17个数值CSV与原结果逐字节一致。四命令真实UTC、退出码及日志hash均保存。

输入采用原固定hash的完整proteinGroups/参数/summary/解码，原提取清单保留
原输入路径；本目录不是重复网络下载，也不增加独立生物学证据。
原研究及报告在 `docs/secretome_validation_v1/secretome_manifest.json` 独立封存，
本目录为封存后新运行的复现结果，入口`reproduction_freeze.json`绑定原manifest。

数字：35,016LFQ、5,836日期组行、846全数组family、112固定候选、224敏感性、
56直接差、26留一方向独立R通过。报告入口
`../discovery_secretome_v1/README.md`；本目录不覆盖原数据或旧论文。
