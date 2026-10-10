# 分泌蛋白组来源诊断与成人ASM公开证据续接

2026-10-10。**4页中文报告，3表、2图、12组CSV/XLSX**；实际数值与来源核对
已完成。最新主稿仍为[v0.12](../paper_cn_v6/README.md)，原secretome报告保留。

## 直接阅读

- [PDF](分泌蛋白组-来源诊断与ASM公开证据续接.pdf)／[Word](分泌蛋白组-来源诊断与ASM公开证据续接.docx)／[自包含HTML](分泌蛋白组-来源诊断与ASM公开证据续接.html)
- [报告文字](results.md)／[表](tables/)／[两原矢量PDF图](figures/)
- [完整来源/计算结果](../../research/results/discovery_secretome_provenance_v1/)／[结论](../../research/results/discovery_secretome_provenance_v1/FINDINGS.md)
- [实际执行与修订](../../research/results/discovery_secretome_provenance_v1/EXECUTION_NOTES.md)
- [实际BioExplainR中文](../../research/results/discovery_secretome_provenance_v1/complete/report_final/BioExplainR-provenance-zh.html)／[英文](../../research/results/discovery_secretome_provenance_v1/complete/report_final/BioExplainR-provenance-en.html)
- [本地附件包](分泌蛋白组-来源诊断与ASM公开证据-附件.zip)／[新清单](provenance_manifest.json)

## 核心进展

1. **24h secretome差异定位更清楚**：非零LFQ0/803一致，原ALL9个一致
   全是双方0，正Intensity一致0；其他三对应数组的20,000余非零LFQ全部
   舍入一致。四原数组交叉匹配及六肽数公式均未解释24h来源处理差异。
   不能自行修正原表或称原Perseus复现。
2. **取得新真实ASM EV来源PXD055968**：原文件映射六患者/18run，三非哮喘/
   三哮喘，无GC/vehicle。54RAW/MSF/pdResult＋FASTA/映射56项清单及13页
   补充取得；没有未筛定量文本，完整数组未分析。原文PD3.0/CHIMERYS与
   PRIDE2.5/Mascot/Proline处理冲突保留；同患者重复不算18独立供体。
3. **原补充证据不能放大**：八糖酵解蛋白Expr P=.0912–.590均>.05，
   与正文“八显著上调”有差异。Expected Up/通路P不替代单蛋白显著性。
   表是选中通路表，候选没名字不记全数组阴性。
4. **PTX3已有ASM蛋白文献**：原DEX/分时ELISA/RU486支持药理相关分泌，
   无逐供体重算、年龄/时点冲突保留；不改变旧HTPC Holm112未通过，
   不替代ANGPTL2/FSTL3/PER2/METTL7A验证。

六范围检索去重180文献，30篇全文请求中21取得；正确PRIDE唯一8项目。
未取得合格数组不是数据不存在。独立R从原数组复核281,232测量比较、
31,228ALL比较、168列及4,968公式；独立OOXML解析23,436发表值通过。
实际BioExplainR两个generic context完整事实与范围，在线调用0。
3Word表/12CSV-XLSX/4页PDF边界及主报告/双语R报告1440和390网页通过。
正文Word/PDF图为PNG预览，另提供两幅原无栅格矢量PDF；自动核验非人工审稿。

## 保存结果验证

仓库根目录：

```sh
python3 research/discovery/seal_secretome_provenance.py verify
```

新manifest绑定新研究/报告/脚本/现根rgo。旧secretome的根rgo文档依赖
只用`rgo_before_provenance.md`开始精确快照核对，其余旧科学原路径/hash。
原2,905保护文件逐hash核验。旧latest仍v0.12/r15历史范围，不能把其pass
当新文件树验收；旧`seal_secretome.py verify`直接核对已更新根rgo会失败，
本轮用上述新入口执行含精确文档快照的完整旧/新层叠核验。

## 下一步入口

`complete/PXD055968_files.csv`、`EV_file_linkage.csv`、`project_feasibility.csv`：
继续取得实际Proline/PD未筛定量导出、明确版本和重复层级/个体年龄后，另冻结
ASM EV识别检查。无GC因素的EV身份不能升级成GC响应。24h来源问题需真实
原Perseus/处理材料。本轮未联络作者，GitHub及外部上传继续暂停。

Python3.12/R4.3.3；Python导出/浏览器依赖版本见新研究
`complete/python_environment.json`，R sessionInfo保留。原数值文件依赖由freeze
逐hash绑定；附包完整包含4个原proteinGroups及4解码/Workbook、新查询原响应
与PDF，不包含PXD055968全RAW/搜索实体，不声称其全数组复现。
