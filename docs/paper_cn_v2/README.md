# BioExplainR 中文论文 v0.9（历史稿，已归档）

**本稿已归档。当前入口为 [v0.10](../paper_cn_v4/README.md)；[v0.9.1](../paper_cn_v3/README.md) 保留图表正文修订阶段记录。本目录文件保留。**

2026-10-08。四项核心贡献：完整事实传递、科学范围/独立单位、可定位分项核对、依赖/覆盖-aware 项目报告。

## 稿件

- `BioExplainR-中文论文-v0.9.{pdf,docx,html}`：**9页主稿**，2主图、1内嵌工具对比表、30条参考文献。
- `BioExplainR-补充材料-v0.9.{pdf,docx,html}`：**16页独立补充**，11节详细方法、8合图、补充表S1–S10说明。
- `manuscript.md`：主稿编辑源；参考文献及比较表由生成脚本展开至 `manuscript_expanded.md`。
- `supplementary.md`：生成的详细补充文字源；历史方法/结果复用v0.8，本轮协议源为 `research/discovery/PROTOCOL.md`。
- 正文（引言到结论，不含参考文献/图注）由11,279压缩至3,863个非空白字符，**缩减65.8%**；10节技术方法移入补充。当前稿不加入历史专家/用户评分。
- 关闭Word标题继承自动编号，文字只保留一次编号。文献中的正确基因为 **CRISPLD2**。原v0.8保留未覆盖。

## 比较表、图及数据

- `tables/Table_1.{csv,xlsx}`：iSEE、SCassist、GeneAgent、ellmer、GPTCelltype 与 BioExplainR。
- `tables/Table_S1`–`Table_S9`：v0.8数据表逐字节复用；`Table_S10` 为新增SPARCL1外部验证。
- `figures/Figure_1.pdf`：v0.8框架矢量合图；`Figure_2.pdf`：新发现案例矢量图。对应PNG只用于Word/网页。
- `figures/composites/`、`panels/`、`previews/`：历史8合图/32panel复用供补充；正式PDF直接嵌入矢量原件。
- `assets_manifest.json`、`export_report.json`、`compression.json`、`audit.json`：来源、hash、导出和核验记录。

## SPARCL1 发现案例

airway/GSE52778固定规则选候选SPARCL1（log2FC +4.575）。候选与检验方案先于外部表达读取冻结；元数据/原论文已先行核实，非预注册。外部GSE34313 24小时主效应+4.132 processed单位，Welch P=1.55e-4，精确置换P=1/35。外部微阵列来自**一个HASM1细胞系**，仅支持外部实验初步重复，不声称独立供体队列、首次发现或机制验证。

实际输入、全部探针/数组、Python与R独立重算、context/project/双语报告和manifest：`research/results/discovery_sparcl1_v1/`；方案与脚本：`research/discovery/`。

```sh
# 新运行必须新目录；依赖 numpy/scipy，见 research/discovery/requirements.txt
python research/discovery/run_discovery.py freeze research/results/discovery_new
python research/discovery/run_discovery.py validate research/results/discovery_new
Rscript --vanilla research/discovery/audit_and_report.R research/results/discovery_new

# 论文生成依赖 tools/paper-requirements.txt；脚本有意刷新当前编辑稿v0.9
python research/paper_cn_revision/build_revision.py
python research/paper_cn_revision/audit_revision.py
NODE_PATH=/tmp/opencode/node_modules node research/paper_cn_revision/browser_revision.cjs
```

公开GitHub release/正式网址/DOI实际状态见 `docs/RELEASE_ARCHIVE.md`。作者信息及人工最终图稿审阅仍待负责人提供；自动文字/几何和浏览器检查不冒充人工科学审阅。
