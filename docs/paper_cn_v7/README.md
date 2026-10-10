# BioExplainR 中文论文 v0.13：转录、胞内与上清蛋白证据整合

2026-10-10。当前生物学工作稿。整合v0.12之后已经封存的完整上清蛋白组、
四数组来源诊断、ASM EV版本核查及公开蛋白来源设计纠正。

## 直接阅读

- [主稿PDF](BioExplainR-中文论文-v0.13.pdf)／[可编辑Word](BioExplainR-中文论文-v0.13.docx)／[自包含HTML](BioExplainR-中文论文-v0.13.html)
- [补充PDF](BioExplainR-补充材料-v0.13.pdf)／[补充Word](BioExplainR-补充材料-v0.13.docx)／[补充HTML](BioExplainR-补充材料-v0.13.html)
- [正文源](manuscript.md)／[补充源](supplementary.md)／[问题与下一动作](ISSUES.md)／[执行记录](EXECUTION_NOTES.md)
- [51组CSV-XLSX](tables/)／[10张原PDF图及PNG预览](figures/)
- [本稿及直接使用结果附件](BioExplainR-中文论文-v0.13-附件.zip)／[独立交付清单](manuscript_manifest.json)

导出为**17页主稿＋24页补充**，4主图＋6补充图、4主表／5补充内嵌表，
51组CSV-XLSX、19引用。图1原热图色块含栅格，其他9图无栅格；正式PDF直接
嵌入原PDF图稿，Word／HTML使用PNG。1440／390双视口通过。

## 本版补齐的内容

|内容|整合后的结论|
|---|---|
|成人ASM集合|原54冻结、53可测、45综合支持；PER2晚期抑制，原家族和精确限制保持|
|胞内HTPC METTL7A|原七标签与发表六标签分开；72h发表子集通过，24h未通过；同来源不增加队列|
|上清ANGPTL2／FSTL3|肽段识别和可分泌注释支持；合格配对不足，尚未确认DEX响应|
|上清FBN2|72h原范围Holm112=.0127，但发表六标签子集=.270、直接时间差Holm56=.187未通过，范围敏感|
|24h上清处理来源|0/803非零LFQ与发表匹配，其他对应数组全部匹配；原因未解决，不能声称Perseus复现|
|PXD055968|六患者／18重复run，无受控GC，最终联合定量仍缺；身份检查未冻结／启动|
|HBEC设计纠正|10个体每人ICS前后×polyIC四格，T2-high／low各格5／5；临床上皮关联不作ASM受控GC验证|
|已有ASM文献|PTX3 DEX上清／RU486为已有文献，咳嗽32因子面板不等于完整候选数组|

这是**已保存研究的稿件整合与复核**；本轮没有新增候选效应、模型拟合或新的
外部验证队列。BioExplainR实际使用和在线调用0来自各原分析保存记录。

## 保存结果核验

在仓库根目录：

```sh
/tmp/opencode/paper-v013-venv/bin/python research/paper_cn_revision/audit_integrated_paper.py verify
```

依赖为Python3.12、numpy1.26.4、scipy1.11.4、PyMuPDF1.26.5、python-docx1.2.0、
openpyxl3.1.2、matplotlib3.6.3。临时venv如不存在，在可用环境安装这些依赖后
用该环境Python执行同一命令。保存结果核验无网络、无模型重新拟合。

`audit.json`绑定表格／源统计、候选配对t／CI／Holm、全数组BH、样本解码、
正文引用、Word表与PDF边界／原图嵌入；`browser_final_v2/audit.json`保存实际
网页检查。`integration_freeze.json`和`evidence/`保存输入及初稿修订，最终
`manuscript_manifest.json`绑定交付与更新根rgo。

旧public_proteome根rgo依赖使用本轮开始精确快照
`evidence/rgo_before_integration.md`，其余科学文件按原路径／hash层叠核验，
含原2,905保护文件。旧v0.12／latest／current及各研究清单继续对应历史范围；
更新根rgo后，请使用本版新核验入口。附件含稿件和直接结果依赖，大原数组继续
由旧研究封存索引；异地仅解压本稿附件不具备完整历史核验所需文件树。

## 下一实际动作

1. 负责人填写并发送既有[PXD055968材料请求草稿](../../research/results/discovery_asm_ev_export_v1/AUTHOR_MATERIAL_REQUEST.md)，或提供作者原回信／附件／下载链接。
2. 收件按[材料接收顺序](../../research/results/discovery_asm_ev_materials_v1/MATERIALS_RECEIPT.md)核对版本、未筛矩阵、原缺测、肽映射、年龄与重复；合格后另冻候选身份检查。
3. 24h上清处理差异需要真实Perseus／版本材料；成人同供体逐时GC／vehicle和完整NR3C1×GC仍待合格公开数据。
4. 真实作者／单位／CRediT／基金等稿件信息与最终人工科学／图稿审阅仍待完成。

GitHub／外部上传继续暂停。构建与核验方案为
[INTEGRATION_PROTOCOL.md](../../research/paper_cn_revision/INTEGRATION_PROTOCOL.md)；
源码`build_integrated_paper.py`拒绝覆盖已封存稿件。
