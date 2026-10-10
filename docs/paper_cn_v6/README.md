# BioExplainR 中文论文 v0.12：完整集合与公开验证整合

2026-10-09。当前生物学工作稿。完整54基因在新增六成人ASM检查，整合前轮
早期／时间／GR／人源蛋白证据。原v0.11及此前验证报告原路径保留。

## 直接阅读

- [主稿PDF](BioExplainR-中文论文-v0.12.pdf)／[可编辑Word](BioExplainR-中文论文-v0.12.docx)／[自包含HTML](BioExplainR-中文论文-v0.12.html)
- [补充PDF](BioExplainR-补充材料-v0.12.pdf)／[补充Word](BioExplainR-补充材料-v0.12.docx)／[补充HTML](BioExplainR-补充材料-v0.12.html)
- [文字源](manuscript.md)／[科学问题与限制](ISSUES.md)／[表格CSV-XLSX](tables/)／[原PDF图稿](figures/)
- [新研究完整结果](../../research/results/discovery_set_validation_v1/)／[实际失败与修订](../../research/results/discovery_set_validation_v1/EXECUTION_NOTES.md)
- [BioExplainR集合中文报告](../../research/results/discovery_set_validation_v1/BioExplainR-set-zh.html)／[英文报告](../../research/results/discovery_set_validation_v1/BioExplainR-set-en.html)

## 集合层面新增结果

54冻结、53可测，53平均同向、50全部六供体预期方向；45/54通过配对t与计数模型
各自Holm54及全部方向敏感性。完整未通过/缺测公开，不只展示重点候选。
LINC00607在新来源可测且+.526、Holm54=.0233，旧缺测与airway阴性保留。
BMAL1/NPAS2上调、NR1D2/DBP/TEF下调增加时钟相关转录线索，不证明节律机制。
成人PER2早期诱导、真药物×时间、GR遗传及功能仍未确认；六供体精确全family
未确认。新family与原44项不同，不互换校正P。

## 完整人源蛋白新增

已取得两个完整未预筛proteinGroups及样本解码、参数，2998段HTTP206和6成员
CRC核对。METTL7A原七日期标签24h+.830（Holm112=.00990）、72h+1.396
（7.96e−6），各7/7↑；与论文六供体冲突保留，额外标签年龄/QC未知。
发表六标签子集24hHolm112=.0574、72h=.000160。原七标签/版本1.6.15与
论文1.6.11及两个原LFQ0/发表有限值冲突公开；不是七新增成人供体。
完整结果和R独立复核见`unselected_protein/`；[来源与边界](../../research/results/discovery_set_validation_v1/PUBLIC_SOURCES_FINDINGS.md)。
新原数组与旧选中表同生物学来源，不能累加独立队列；跨组织不替代ASM蛋白。

## 保存结果核验

```sh
# 仓库根目录；依赖numpy/scipy/PyMuPDF/python-docx/openpyxl
/tmp/opencode/validation-report-venv/bin/python research/paper_cn_revision/audit_set_paper.py docs/paper_cn_v6
python3 research/discovery/seal_set_validation.py verify
```

数值入口`numeric_audit.json`、`sensitivity_audit.json`、`r_tpm_audit.json`；
文档入口`audit.json`、`browser_final_v2/audit.json`及`manuscript_manifest.json`。
新的`research/results/latest_manifest.json`绑定本轮交付；旧current/baseline12
仍为其历史范围，不当成本轮全树验收。

## 新运行与环境

保存公共输入的实际新目录复现入口（先完成本稿seal）：

```sh
python3 research/discovery/reproduce_set_validation.py research/results/discovery_set_reproduction_new
```

此命令先核验输入/hash和旧文档快照，复用官方注释原记录，重新拟合计数模型及
六次留一、独立审计并实际应用R包。是同来源复现，不增加独立证据。新科学问题
另制定协议，不能把复现当盲法外部验证。首次原运行顺序为方案freeze→官方
注释→`measure`→`set_validation_models.R`→独立审计→`report_set_validation.R`。
HGNC全表下载失败恢复入口和全部修订见研究EXECUTION_NOTES，不能跳过mappingfreeze。
完整人蛋白入口`set_protein_archive.py`→`set_protein_extract.py`及保存成员CRC核验→
`set_protein_numeric.py freeze/measure`→`audit_set_protein.R`，供体/技术重复/缺测规则
在新designfreeze；不将下载列表当数组取得，不把部分容器当完整上游SHA1通过。

R4.3.3，edgeR4.0.16、limma3.58.1；BioExplainR0.4.0.9000实际源码载入。
报告venv原版本numpy1.26.4、scipy1.11.4、PyMuPDF1.26.5、python-docx1.2.0、
openpyxl3.1.2、matplotlib3.6.3；蛋白选择提取新增py7zr1.0.0。导出需Pandoc／
LibreOffice／NotoSansCJKSC，网页需Playwright／Chrome。

构建/审计脚本`build_set_paper.py`、`audit_set_paper.py`、`browser_set_paper.cjs`。
源码固定指向本轮研究；重跑新研究需新版本构建脚本显式调整路径，不覆盖本版。
作者信息及最终人工科学/图稿审阅待真实材料。GitHub／外部上传继续暂停。

最终导出为13页主稿／19页补充，3主图＋4补充图、3主表／5补充内嵌表，
34组CSV-XLSX、16参考文献。图1热图色块为原栅格，其他6图无栅格，PDF
直接嵌入原图稿；Word／HTML用PNG。1440／390双视口通过。
旧v0.11的README/index/rgo文档依赖用精确快照，其他科学原路径/hash不变；
新封存绑定当前入口，不重写旧manifest。依赖恢复见`requirements-set.txt`。
便携[本稿与新研究附件](BioExplainR-中文论文-v0.12-附件.zip)和
`docs/BioExplainR-development-delivery-0.4.0.9000-r15.zip`保留完整原proteinGroups
与解码／参数、原下载完成记录及错误；重复Range实体和全基因模型不重复打包，
仍由本地manifest逐hash索引。r15是本轮＋前轮公开验证的续接包，旧r14整项目
交付保留；不将其叫本轮全项目软件重新验收。
