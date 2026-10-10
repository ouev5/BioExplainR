# BioExplainR 中文论文 v0.11：生物学主线初稿

2026-10-09。依据已完成的全基因分析，将 **54基因跨四背景响应、固定12候选／11可测外部重复、PER2暴露条件相关差异** 写成完整中文论文。题目：**气道平滑肌跨背景糖皮质激素响应与PER2暴露时长相关差异：基于BioExplainR的可追溯公共数据重分析**。

## 直接阅读

- [主稿PDF：11页](BioExplainR-中文论文-v0.11.pdf)
- [可编辑Word](BioExplainR-中文论文-v0.11.docx)
- [自包含HTML](BioExplainR-中文论文-v0.11.html)
- [补充PDF：12页](BioExplainR-补充材料-v0.11.pdf)／[补充Word](BioExplainR-补充材料-v0.11.docx)／[补充HTML](BioExplainR-补充材料-v0.11.html)
- [论文文字源](manuscript.md)／[展开源](manuscript_expanded.md)／[补充源](supplementary.md)
- [问题、已纠正表述与后续验证标准](ISSUES.md)
- [本次执行问题记录](EXECUTION_NOTES.md)
- [表格CSV／XLSX](tables/)／[五个原PDF图稿与PNG](figures/)
- [文稿及附件包](BioExplainR-中文论文-v0.11-附件.zip)／[本稿独立清单](manuscript_manifest.json)

主稿3图／2内嵌表／11参考文献；补充2图、4前轮背景内嵌表。主表1–2、补充表S1–S12及S1b共 **15组CSV/XLSX**；前轮S13a–d另提供4个CSV。全部5图／19表＝**24项正文图表对应**。最终PDF直接嵌入原PDF图稿，保留其矢量文字与路径；图1原热图色块本身为栅格，其他四图无栅格，Word／HTML使用PNG预览。

## 结论及本稿澄清

- 82,227交互全部未通过统一BH；另按四背景响应规则筛得54基因，不能把响应保留写成四背景等效。
- 外部13供体剔除3个已知共享培养系；11/12冻结候选重复，11/11可测候选重复。LINC00607缺测、GCNT1有1供体反向均公开。
- PER2外部平均配对差−0.915，13/13下调；A549短DEX暴露上调并受三药物交互削弱，直接长−短暴露差−0.917；HASM1直接差−1.651，精确小样本校正不确认。
- A549两个安排总培养窗口均18h，“2h／18h”指DEX暴露时长；不把它们当不同总收样时点，不主张A549长暴露已负向反转。
- 每模型四背景统一109,636项BH，非逐背景校正；95%CI是点态区间。时间增补为结果后探索。
- 新颖性限候选特异整合，既有激素／时钟主题已引用；ASM受体依赖、相位／振幅、蛋白及功能尚待实验。

本文统计取自封存结果，此次实际工作为论文写作、表图整合与核验。此前共同任务、SPARCL1不可估计及ChIP窗口结果纳入补充S13背景，各自边界完整保留。v0.10软件主稿仍见[历史版本](../paper_cn_v4/README.md)。

## 核验与复现

`audit.json`已通过：203条原封存依赖／200旧归档成员、全部表源与15组CSV/XLSX、13供体配对t及48项Holm、24直接暴露条件检验、11引用、24图表对应、Word表与PDF内容/边界和原图嵌入。最终`browser_final/audit.json`核验主稿／补充1440和390双视口，5图加载、2/4表，无页面横溢出或JS异常；较早`browser/`保留为草稿检查。作者信息、人工视觉与最终科学审阅仍待完成。

```sh
# 在仓库根目录，需PyMuPDF/python-docx/openpyxl/numpy/scipy：
/tmp/opencode/paper-venv/bin/python research/paper_cn_revision/audit_discovery_paper.py
python3 research/paper_cn_revision/seal_discovery_paper.py verify
```

本机论文venv新增`scipy==1.11.4`；依赖恢复可使用`python3 -m pip install numpy==1.26.4 scipy==1.11.4 PyMuPDF==1.26.5 python-docx==1.2.0 openpyxl==3.1.2 matplotlib==3.6.3`，在自己的venv执行。导出另需Pandoc、LibreOffice、Noto Sans CJK SC；浏览器使用Playwright与Chrome，工具恢复见项目复现文档。

新目录重建：用`apply_patch`准备本目录三个源文件`manuscript.md`／`ISSUES.md`／`paper.css`的副本，随后运行：

```sh
/tmp/opencode/paper-venv/bin/python research/paper_cn_revision/build_discovery_paper.py --directory docs/paper_cn_v011_new
/tmp/opencode/paper-venv/bin/python research/paper_cn_revision/audit_discovery_paper.py docs/paper_cn_v011_new
NODE_PATH=/tmp/opencode/node_modules node research/paper_cn_revision/browser_discovery_paper.cjs docs/paper_cn_v011_new
```

构建器拒绝刷新已经封存的本稿；未封存工作目录才允许`--refresh`。浏览器输出目录同样拒绝覆盖。数值重新拟合入口见[原结果报告README](../biology_discovery_v2/README.md)，使用新研究目录。

### 封存范围

原生物学清单绑定旧`rgo.md`。本次先通过原封存核验，再保存其精确快照于`evidence/rgo_before_v011.md`；更新后的根交接由本稿新manifest绑定。`audit_discovery_paper.py`只对旧清单中的这一文档使用旧快照，全部原科学输入／脚本按原路径、原hash核验，且旧ZIP仍逐成员核验。原`seal_response.py verify`若直接针对更新后的根交接将检出其文档hash变化，核验旧版本请用本稿的显式快照入口，不能覆盖原manifest掩盖变更。

新manifest和附件包覆盖本稿、构建/审计脚本与更新交接依赖，原研究结果按原manifest/hash外部引用；附件包不重复打包大原输入。全项目旧current清单和r14交付的历史pass不扩大为本轮文件树验收。新稿信息以本目录manifest绑定的实际结果为准。
