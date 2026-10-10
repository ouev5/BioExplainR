# PXD055968 完整定量导出追查：实际结果

2026-10-10。**版本与存档结构检查完成；正确版本的完整跨 run 定量导出仍未取得，
候选身份检查尚未开始**。机器状态：`final_status.json`。

## 取得的直接证据

|来源|实际观察|对应文件|
|---|---|---|
|完整提交清单|56 项：18 RAW、18 MSF、18 pdResult、1 FASTA、1 映射；FTP 另有 checksum|`PXD055968_file_inventory_verified.csv`、`sources/files_corrected.json`|
|18 个 pdResult 实体|全部 PD3.1.0.638，CHIMERYS inferys_3.0.0_fragmentation，2024-01-22 FASTA；每个一 RAW／一 sample|`version_evidence_complete.csv`、18 个 `pdresultNN_metadata.json`|
|定量结果结构|18 个 consensus 均 CWF_ID，mapper/quantifier 节点 0；54 个 target protein/group/peptide-group 表无 abundance/intensity/quantity/area 列|`protein_columns_exact.csv`、`schema_columns_exact.csv`、`workflow_evidence/`|
|已有 feature 数值字段|LcmsFeatures/LcmsPeaks/PrecursorInfoItems/PSM 有强度等字段；Minora 是单 run feature detection；未当最终跨 run 蛋白丰度|`schema_columns_exact.csv`、`workflow_parameters_complete.csv`|
|MSF 交叉线索|仅另查 run01 原 MSF 的版本／workflow：同 PD3.1 和 CHIMERYS；不是 18 个 MSF 全检|`msf01_metadata.json`、`independent_audit.json`|
|真实样本层级|595/614/615 非哮喘、BA184/185/186 哮喘；每患者三 repeat；18 run ≠ 18 独立供体|`sample_map_verified.csv`|
|映射完整下载|13,428 bytes，原 checksum SHA1 ba3b0aba4d013aedafc3d7b1706f65da175b1124 通过|`sources/Link_between_files.xlsx`|
|独立实现|builtin sqlite3 从已取得原字节块重读18结果的3,726条schema、1,645条metadata；原OOXML独立解码18映射通过|`independent_audit.json`|

**新增关键冲突**：PRIDE PD2.5/Mascot/Proline/2020 库；论文 PD3.0/CHIMERYS
inferys_2.1/2023 库；存档实际 PD3.1/CHIMERYS inferys_3.0.0/2024 库。
存档 charge 1–6、单 run ID 最少 peptide sequences=1；论文 charge 2–4、最终
master protein quantification ≥2 unique。ID 过滤与最终定量过滤含义也不同，
不把两者直接等同。独立 FASTA 提交文件名是2023_09_13，并非存档 workflow
指定的2024_01_22库。原因及最终发表版本仍需真实处理材料。

## 公开导出入口追查

当前原文 XML 只有 mmc1.pdf 与六视频附件；原补充 PDF 已知为选中 IPA／糖酵解表，
没有完整定量数组。当前 PRIDE／FTP 56 文件未有定量 CSV/TSV/XLSX/Proline 导出。
ProteomeCentral 只公布一轮正式公告并指向同一 PRIDE 项目；Crossref无data关系；
DataCite 的 accession/原文 DOI 两查询均 0；Zenodo accession 有效查询 0。
Figshare与ScienceDirect403，OA接口404／reset，Zenodo DOI500，均保留失败，不
解释为相关材料不存在。Elsevier200 XML仅元数据，未取得全文或额外定量附件。
具体 URL 和状态在 `public_routes_summary.csv`。

## 当前门槛与下一动作

仍缺：**论文对应的未按差异预筛完整蛋白组×18 run 数组、最终跨 run workflow／
版本、原缺测及肽段映射、六患者年龄或成人确认及重复定义**。完整数组未取得，
没有读取候选蛋白结果行或开始身份统计；不能将单 run feature/PSM 强度自行汇总
成“原发表定量导出”。`required_materials.csv` 给出逐项要求；未发送材料请求
在 `AUTHOR_MATERIAL_REQUEST.md`。

取得合格数组后，另冻结完整候选身份检查。无 GC/vehicle，EV 制备检出仅可支持
制备中的蛋白识别；不升级 GC 响应、经典主动分泌、每细胞分泌速率或功能因果。
六患者年龄未在映射给出，43人总体均龄不赋给这六人；重复培养/制备/进样层级
尚未明确。同患者三重复不增加独立供体数。既有ASM转录和HTPC候选结论保持范围。

## 保存结果与完整性

本轮只取得数据库部分字节块用于元数据／schema检查，没有下载16.38GB全pdResult，
没有整文件 SHA1 或整个原数据库完整性通过的声明。新封存独立记录这些范围、
失败和根rgo；旧provenance的唯一根rgo文档依赖用本轮开始精确快照核对，其余旧
科学原路径/hash。原2,905保护文件、旧清单与旧归档均保留。
