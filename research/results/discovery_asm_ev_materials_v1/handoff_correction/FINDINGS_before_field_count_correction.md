# PXD055968 最终材料续接：来源追查结果

2026-10-10。**尚未取得论文对应的未按差异预筛蛋白组×18 run 表及最终联合
处理版本说明；候选身份检查未冻结、未启动。** 本轮完成来源追查，科学门槛
仍为 `blocked_missing_final_export`。

## 实际新增证据

|来源|本轮实际结果|保存证据|
|---|---|---|
|PRIDE PXD055968|完整 API 清单仍为 56 项；文件名、字节数及文件 accession 与前轮一致。18 RAW、18 MSF、18 pdResult、1 FASTA、1 映射 XLSX；没有新列出的独立最终定量表|`sources/PXD055968_files.json`、`related_project_inventory.csv`|
|明确关联的两个项目|PXD055949 为 48 项，PXD059603 为 38 项；前者另有 community SDRF，均为 EV 处理后的支气管上皮研究，不能替代 ASM EV 自身数组。清单只有 RAW/MSF/pdResult/FASTA/映射及该 SDRF，没有列出另附 EV 最终定量导出|`related_project_scope.csv`、各原 project/files JSON|
|HAL DOI 与原题名|各命中同一真实论文记录 `hal-05063440v1`；读取 260 个元数据字段及实际页面，API `files_s` 与页面下载项均只列 `celle et al. 2025.pdf`|`sources/hal_record_full.json`、`sources/hal_record_page.html`、`hal_source_review.json`|
|HAL accession／项目名|PXD055968、CHARMACOMA 两查询有效返回各 0 个索引结果|原查询 JSON、`public_routes_review.csv`|
|Recherche Data Gouv|accession、DOI、完整题名、CHARMACOMA 四查询有效返回各 0 个索引结果|四原 JSON、`public_routes_review.csv`|
|受阻入口|OpenAIRE JSON/XML 两次均 read timeout；Figshare DOI 请求 403，错误 HTML 原字节保存|`acquisition.json`、`hal_followup_plan_acquisition.json`、`sources/figshare_doi.json`|
|HAL PDF|两次 urllib 命令分别在外层 45／180 秒中断，无保存的完整响应或完成 JSON；随后 curl 总时限 60 秒、exit 28，只收到 3,564,070 / 13,089,865 bytes。部分原字节保留，不解析为完整论文|两个原计划、`hal_pdf_curl_acquisition.json`、`sources/hal_author_article_curl.bin`|

以上合计 **19 个元数据请求完成记录（16 响应取得、1 HTTP 错误、2 超时）＋
1 个部分 PDF 请求记录，另有 2 个外层中断尝试**。三项目原清单共 142 项。
未检索到或网络受阻，不证明相关材料不存在。

HAL 显示 version 1、2025-05-12 提交及 2026-09-30 元数据修改。这些是仓储
记录时间／版本，**不是 PD 最终联合处理版本说明**。该 PDF 本轮未完整取得，
不能声称已从这个新存档核对论文方法；前轮取得的原文方法证据继续有效。

## 未解除的阻塞

1. **论文对应完整定量表**：全部蛋白组，逐一对应 18 run；原 abundance、
   normalized abundance、缺测／零值／填补标记及 group/accession 信息。
2. **最终版本说明和联合 workflow**：说明发表分析、PRIDE 描述与存档单 run
   结果三者的关系；实际 PD/Proline/inferys/FASTA 及分组、FDR、过滤、归一化、
   缺测设置。现有 PD2.5／3.0／3.1、2020／2023／2024 库冲突仍未解决。
3. **同版本肽段／PSM 映射**：unique/shared、置信度／q 值、master/group、
   run/定量映射；不能用另一个处理版本补作最终鉴定证据。
4. **六患者和重复定义**：595/614/615/BA184/BA185/BA186 的年龄或成人确认；
   三重复究竟是培养、EV 制备、酶解还是 LC-MS 进样；QC／排除说明。

原精确清单及材料请求继续使用：
`../discovery_asm_ev_export_v1/required_materials.csv`、
`../discovery_asm_ev_export_v1/AUTHOR_MATERIAL_REQUEST.md`。请求仍为草稿、未发送。
本轮增加 `MATERIALS_RECEIPT.md`，明确收到原件后的核对顺序；没有虚构接收材料。

获得原件及作者最终说明后，先验收来源／版本／结构，再另冻结完整固定候选
身份检查。六患者三重复不算 18 供体；无 GC/vehicle，EV 识别不升级为 GC
响应、主动分泌速率或功能因果。ASM／HTPC 已有候选结果继续其原范围。

## 完整性与续接

本轮开始时原 export 封存及层叠旧证据、2,905 保护文件核验通过。根 rgo 开始
精确快照保存为 `rgo_before_materials.md`；新核验仅将前轮 export 的根 rgo
文档依赖对应到该快照，其余旧科学文件仍核对原路径／hash。

```sh
python3 research/discovery/seal_asm_ev_materials.py verify
```

原清单和归档保留。本轮新的来源追查、部分响应、说明和源码由
`materials_manifest.json` 独立绑定；GitHub／外部上传继续暂停。
