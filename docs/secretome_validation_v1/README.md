# PXD033504 完整分泌蛋白组结果报告

2026-10-10。已完成公开处理数组分析与独立数值复核。6页中文报告、3表、
2图、27组CSV/XLSX；旧v0.12主稿继续由其原清单封存，新研究另交付。

## 直接阅读

- [结果PDF](PXD033504-完整分泌蛋白组-结果报告.pdf)／[Word](PXD033504-完整分泌蛋白组-结果报告.docx)／[自包含HTML](PXD033504-完整分泌蛋白组-结果报告.html)
- [报告文字](results.md)／[全部表](tables/)／[原矢量图PDF](figures/)
- [完整原输入与结果](../../research/results/discovery_secretome_v1/)／[实际科学结论](../../research/results/discovery_secretome_v1/FINDINGS.md)
- [实际错误与修订](../../research/results/discovery_secretome_v1/EXECUTION_NOTES.md)
- [BioExplainR中文报告](../../research/results/discovery_secretome_v1/BioExplainR-secretome-zh.html)／[英文](../../research/results/discovery_secretome_v1/BioExplainR-secretome-en.html)
- [本地附件包](PXD033504-完整分泌蛋白组-附件.zip)／[新封存清单](secretome_manifest.json)

## 主要结果

|问题|实测结果|
|---|---|
|完整数组|24h600原组→466QC组、6日期/36技术列；72h531→380、8日期/48列。统一846项BH，194/153可估计，7/16通过；精确BH均未通过|
|ANGPTL2|24h14肽/13unique肽、覆盖37.3%；只有两合格配对，−.453/−1.088，同ASM下调方向但不足至少三供体，不能确认。72h未检出|
|FSTL3|两时点各2unique肽；LFQ有效配对均0。支持识别与可分泌身份，不确认DEX响应|
|完整候选|原54＋PER1/NR3C1，共112位置，4可估计、1Holm通过；缺测位置不解释为阴性|
|FBN2新线索|72h主7对+1.535（点态CI1.112–1.958）、Holm112=.0127；严格3/3技术测量6对+1.419、.0259。发表六标签只有5可测、+1.466、.270未通过，依赖标签范围；精确不确认|
|PTX3|24h+.620、6/6↑，Holm112=.592未通过；72h亦不通过，1次留一方向反转|
|来源冲突|24h原/发表六标签一致，72h原多10.09.19/18.11.14、作者QC/年龄未知。两secretome参数1.6.11与发表一致；旧proteome版本冲突保留其范围|
|发表数组差异|24h803原非零选中测量均不匹配发表值，25原零却有限；467ALL总Intensity只有9一致，处理/来源差异未核实。72h2128非零舍入一致、320原零却有限；不填补|

上清LFQ为相对细胞外蛋白丰度，不是每细胞分泌速率。HTPC与ASM组织/药物/
剂量/测量尺度不同；同原proteome生物学来源，不增加独立ASM蛋白队列。
UniProt Secreted/信号肽支持身份，不替代候选GR依赖或功能。直接时间差未确认。

## 实际复核

4,170成功block段＋header覆盖两个完整容器；PRIDE上游SHA1与8成员CRC通过。
R独立从原表/解码/summary核对35,016LFQ、5,836供体组行、846全组/112候选/
224敏感性/56直接差/26留一；另核对7识别行/288未归一Intensity与肽测量/
3,276发表尺度比较。BioExplainR0.4.0.9000实际2context和双语报告，在线调用0。
CSV-XLSX/Word表、6页PDF文字边界与2原无栅格图、1440/390网页通过。
Word/PDF图为PNG预览，另提供两幅原矢量PDF。

## 保存结果核验

仓库根目录，封存后可重复运行，不重写历史结果：

```sh
/tmp/opencode/validation-report-venv/bin/python research/discovery/seal_secretome.py verify
```

新清单绑定新报告/研究/源码/根rgo。旧v0.12的根rgo依赖使用本轮开始时精确快照
`rgo_before_secretome.md`，其余旧科学原路径/hash。原2,905保护文件逐hash核对。
旧`latest_manifest.json`仍指v0.12/r15历史范围；新入口为本目录manifest，
不将旧软件全项目验收改写为本轮重跑。

## 新目录实际数值复现

```sh
/tmp/opencode/validation-report-venv/bin/python research/discovery/reproduce_secretome.py research/results/discovery_secretome_reproduction_new
```

先核验seal，复用固定hash的完整原表，重新解码/设计、全部统计、R独立复核、
实际R包报告，并核对17个数值CSV逐字节一致。不是新增独立证据。新路径须不存在。
附件含完整原proteinGroups、解码/参数/summary、原文/发表表、全部数字及脚本；
重复下载实体.bin留本地清单，恢复网络执行见下面。附件异地恢复需重建原仓库路径，
本地seal完整范围包含下载实体，不能把ZIP解包直接说成全本地下载实体都已验证。

首次执行入口，必须新输出目录：

```sh
# freeze → metadata/inspect → extract（断网可续传且旧失败保留）→ design → analyze
/tmp/opencode/validation-report-venv/bin/python research/discovery/secretome_acquire.py freeze research/results/discovery_secretome_new
/tmp/opencode/validation-report-venv/bin/python research/discovery/secretome_acquire.py inspect research/results/discovery_secretome_new
/tmp/opencode/validation-report-venv/bin/python research/discovery/secretome_acquire.py extract research/results/discovery_secretome_new
/tmp/opencode/validation-report-venv/bin/python research/discovery/secretome_analyze.py design research/results/discovery_secretome_new
/tmp/opencode/validation-report-venv/bin/python research/discovery/secretome_analyze.py analyze research/results/discovery_secretome_new
Rscript research/discovery/audit_secretome.R research/results/discovery_secretome_new
Rscript research/discovery/report_secretome.R research/results/discovery_secretome_new
```

Python3.12、numpy1.26.4/scipy1.11.4/py7zr1.0.0、R4.3.3及pkgload/jsonlite；
详细版本`python_environment.json`和`sessionInfo.txt`。报告另需openpyxl/
python-docx/PyMuPDF/matplotlib/LibreOffice、NotoSansCJKSC；网页检查Playwright/Chrome。
GitHub及外部上传继续暂停。
