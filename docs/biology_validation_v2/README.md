# 公开数据验证增补：当前完成结果

2026-10-09。按负责人“不能做湿实验，用其他数据集验证”的要求完成新公开数据
分析。**7页中文增补，4表／3图，实际BioExplainR项目及双语报告。**

## 直接阅读

- [中文PDF](BioExplainR-公开数据验证-结果增补-v1.pdf)
- [可编辑Word](BioExplainR-公开数据验证-结果增补-v1.docx)
- [自包含HTML](BioExplainR-公开数据验证-结果增补-v1.html)
- [文字与数值来源](results.md)／[4组CSV-XLSX](tables/)／[3个矢量PDF图稿](figures/)
- [完整原输入／新统计／失败记录](../../research/results/discovery_validation_v2/)
- [BioExplainR中文项目报告](../../research/results/discovery_validation_v2/BioExplainR-validation-zh.html)
- [BioExplainR英文项目报告](../../research/results/discovery_validation_v2/BioExplainR-validation-en.html)
- [新研究结论与限制](../../research/results/discovery_validation_v2/VALIDATION_FINDINGS.md)

## 新增结果

|重点|实际完成与结论|
|---|---|
|新增成人ASM|GSE130715六成人，19–54岁，24文库；PER2 −0.934（CI −1.044至−0.824；Holm44=.000157），6/6下调。六候选全部方向一致；计数敏感性同向。精确小样本校正未确认|
|成人匹配vehicle时间序列|取得此前遗漏的Bartman2021成人部分及表2，33–77岁；DEX30min脉冲后12/16/20/24h。PER2同24h药物对比Tukey=.7831，仅DEX组24h−12h=.0498，未确认药物×时间|
|新增早期ASM|GSE13168 8h：3可配对供体，PER2+0.691但Holm44=1。GSE135730 4h：PER2+.111、Holm33=1；METTL7A／MAOA两背景响应通过，匿名培养和年龄界限保留|
|GR遗传|GSE342887成熟RNA18／GSE342771新生RNA17文库；U2OS GR-KO背景WT／AF2／IDR rescue。110检验；PER2交互未确认，PER1控制AF2交互通过；无empty-KO组，预印本和共有样本界限保留|
|人源蛋白|HTPC六成人供体，三技术重复先平均；METTL7A24h+.921（Holm22=.0437）、72h+1.504（.00261），均6/6↑。跨组织、原文选中数组、精确Holm未通过；五共享供体直接时间差Holm11=.412|
|其他蛋白与功能|PXD081613实际mouse注释/PRIDEhuman冲突保留；PER2未检出不作阴性。ASM GRαsiRNA／蛋白／rapidcAMP及胎儿PER1/ARNTL Ca²⁺原文已核对，不能替代成人PER2候选功能|

**本轮支持成人ASM晚期响应重复，并增强METTL7A跨组织RNA／蛋白线索；成人
PER2先升后降、GR遗传因果、蛋白与Ca²⁺／收缩功能仍未得到确认。** 这些是
公开证据的解释界限，不是要求负责人追加湿实验的待办。

## 保存结果复核

```sh
# 仓库根目录，Python需numpy/scipy/PyMuPDF/python-docx/openpyxl：
/tmp/opencode/validation-report-venv/bin/python research/discovery/audit_validation_report.py research/results/discovery_validation_v2 docs/biology_validation_v2
python3 research/discovery/seal_validation.py verify
```

`audit.json`核对396原TPM/SOFT测量、88配对检验的Rpass，132原RPKM测量／33
检验，385GR原count测量／550WLS数值，220ASM精确WLS，160mouse蛋白测量和
144人蛋白XLSX原数组、4组CSV/XLSX、Word表、PDF文本/边界和3原图。各独立
数值输出在研究目录；voom/eBayes未跨语言重新拟合。桌面1440／手机390网页
检查另见`browser/audit.json`。

## 新运行入口

使用**新的输出目录**，不能覆盖已封存目录。采集顺序、源URL、原始freeze／
修复amendment均在研究目录；R依赖实际版本DESeq21.42.0／limma3.58.1／
edgeR4.0.16，BioExplainR0.4.0.9000源码载入。系统Pythonnumpy1.26.4/
scipy1.11.4；报告venv恢复：

```sh
python3 -m venv /tmp/opencode/validation-report-venv-new
/tmp/opencode/validation-report-venv-new/bin/pip install numpy==1.26.4 scipy==1.11.4 PyMuPDF==1.26.5 python-docx==1.2.0 openpyxl==3.1.2 matplotlib==3.6.3
python3 research/discovery/validation_sources.py search research/results/discovery_validation_new
python3 research/discovery/validation_sources.py metadata research/results/discovery_validation_new GSE13168 GSE130715 GSE95397 GSE63744
python3 research/discovery/validation_sources.py article_alt research/results/discovery_validation_new PMC8294620 PMC7052668 PMC7027561
python3 research/discovery/validation_expression.py freeze research/results/discovery_validation_new
python3 research/discovery/validation_expression.py acquire research/results/discovery_validation_new
python3 research/discovery/validation_expression.py measure research/results/discovery_validation_new
Rscript --vanilla research/discovery/validation_models.R research/results/discovery_validation_new
Rscript --vanilla research/discovery/validation_voom_exact.R research/results/discovery_validation_new
```

GR采集／拟合入口`validation_gr_acquire.py`和`validation_gr_models.R`，蛋白入口
`validation_protein.py`和`validation_protein_ranges.py`，人蛋白入口
`validation_human_protein_sources.py`→`validation_human_supplement.py`→
`validation_human_static.py`→`validation_human_protein.py`→
`validation_human_protein_numeric.py`，逐文件失败记录、freeze依赖不可跳过。
GSE135730入口`validation_early_acquire.py`→`validation_early.py`，独立审计R
与Python脚本同目录。全资料齐备后`report_validation.R`实际应用R包，再用
`build_validation_report.py`导出新报告目录。

### 原成果保留和封存范围

旧v0.11稿及科学结果原路径／hash保留；根`rgo.md`更新前精确快照已保存于
`research/results/discovery_validation_v2/rgo_before_validation.md`。本轮审计
对v0.11文档依赖的rgo只使用该快照，旧科学依赖用其原快照，其余全部原路径
核对。直接旧`seal_discovery_paper.py verify`会检出更新后的根文档hash，新的
显式复核入口为本目录命令；不覆盖旧manifest隐藏变化。

本目录`validation_manifest.json`绑定新研究、脚本、报告及更新根交接，附件包
为`BioExplainR-公开数据验证-附件.zip`；完整输入在manifest中逐hash索引，大
全基因RDS与下载Rangeparts不重复进入附件包。旧current/r14pass不是本轮
全树验收。`docs/biology_validation_v1/`为数字计数审计未通过的早期稿，保留
而不作为当前结果。发布授权沿用既有暂停决定。
