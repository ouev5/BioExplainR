# BioExplainR 中文稿交付索引

**2026-10-08当前入口：** [paper_cn_v1/README.md](paper_cn_v1/README.md)及`paper_cn_v1/BioExplainR-中文论文-v0.8.pdf`。v0.8为23页中文稿，8合图/32子图PDF、9份外置CSV/XLSX，正文及附录保留图表引用/注释。专家/用户结果不写入新版，仅在末尾预留补充内容。公开上传PDF/Word/图表附件为#46/#45/#47，匿名回读hash一致。当前开发审阅包为r7，详细记录见`implementation_records/PAPER_CN_CONTINUATION.md`。

## 以下为保留的v0.7交付记录

当前是为后续英文投稿整理的中文初稿，软件与实验采用 BioExplainR 0.3.1 的保存结果。

W00 当前版本/结果入口：`../research/results/current_manifest.json`；复核说明为 [REPRODUCTION.md](REPRODUCTION.md)，实际执行记录为 [W00.md](implementation_records/W00.md)。2026-10-05 已恢复环境并重跑软件、稿件和当前/历史结果审计；没有新增科学解释或用户研究。

## 阅读顺序

1. `BioExplainR-paper-draft.docx`：主要审阅稿，正文图表集中于附录并在正文引用。
2. `BioExplainR-supplementary.docx`：S1-S8 补充说明，包含独立基准、预实验、语义负例和外部评价聚合图。
3. `submission_assets/README.md`：独立图表与原始记录索引。

同名 PDF 由 LibreOffice 从实际 Word 导出；同名 HTML 自包含图片，便于浏览器阅读。Word 表格为可编辑元素。图 1-4 和补充图 S1-S3 均为四面板组合图，每个 panel 另保留独立矢量 PDF/PNG/SVG；图内使用英文标签、中文图注。

本轮最终导出为主稿 PDF 65 页、补充材料 PDF 10 页；主稿包含 7 个图形元素和 13 个可编辑表，其中表 8 为 480 个目标事实的逐项记录；补充材料包含 2 个图形元素和 4 个可编辑表。自动审计、HTML 桌面/移动 smoke test 均通过。

## 附件

`submission_assets/` 含 4 个正文组合图 PDF、3 个补充组合图 PDF，以及 28 个 panel 的独立 PDF/PNG/SVG（共 35 个 Figure PDF）；另含 13 个主稿/补充 Excel 表，其中主稿表 1-8 共 8 个、补充表 S1-S5 共 5 个，表 8 的 Source 表保留 4,320 条逐事实评分。补充图 S2 记录相近工具入口测试与独立 pasilla 数值基准，补充图 S3 记录外部评价聚合结果；表 S4 记录 120 案例/480 事实双模型共同任务，表 S5 记录外部评分聚合。图 2 误差棒为共享案例三轮评分的描述性样本标准差，不是独立样本置信区间。表 1 为合并后的设计比较，不是性能排名。

同目录 `supplementary_records.zip` 含 2,770 个保存记录及脚本；规模主实验 1,080 个响应和 1,080 个 prompt，另含 historical 六案例实验/预实验、相近工具、浏览器记录、双模型规模共同任务响应和逐事实评分。`supplementary_manifest.csv` 为逐文件 SHA-256 清单，W00 已实际核对全部 ZIP 成员。

旧 `BioExplainR-submission-bundle.zip` 保留为过期历史交付：210 成员中 132 个内容与当时当前树不同、2 个旧路径不存在，hash/差异见 `../research/results/w00_baseline/bundle_inspection.json`。当前开发审阅包为 `BioExplainR-development-delivery-0.4.0.9000-r6.zip`，含当前稿件资产、0.4.0.9000 源码、miniACC 公开开发案例及安装包重跑、工程验收和开发迁移说明；详见 [DEVELOPMENT_DELIVERY.md](DEVELOPMENT_DELIVERY.md)。源码和开发包 hash 在 current manifest 及 `review-delivery-audit-result.json`；r5 外部审计保留。此包不是正式投稿完成证明。

`research/study_materials/` 另含 30 个匿名病例、外部评分者 0-2 评分模板、30 位评分参与者的功能感知工作簿和盲法案例包。它们只提供采集结构，没有任何虚构的人类评分；研究负责人保留的答案密钥不进入公开盲法压缩包。

## 本轮修改

- 按方法期刊结构重写中文摘要、引言、模块方法、结果、讨论与结论。
- 加入 iSEE 浏览器 DOM/图像 smoke test、iSEE/GPTCelltype/ellmer 入口记录和未参与开发的 pasilla 事实基准。
- 将预实验/迭代细节移入补充材料，保留开发集乐观偏倚说明。
- 主实验扩展为 120 个案例、480 个目标事实、三种输入、三轮重复；保留 `direct_bounded` 信息受限基线与 R 事实摘要方法的区别。
- 将 4,320 条逐事实主实验评分作为表 8 嵌入主稿，并在 Excel Source 表和记录压缩包中保留原始逐项记录。
- 双模型共同任务扩展为 120 个案例、480 个目标事实；StepFun 与 DeepSeek 均为 480/480。
- 保留数值 claims 通过但自由文本错误推测 LFC shrinkage 的实际响应。
- 修正非缺失校正 P 值计数与原始检验数的混淆，修正 llm2geneset 引文并补核实论文。
- 当前为 38 条参考文献；书目信息解析记录为 `research/results/reference_audit.json`，W00 核对保存 resolved 状态，未重新在线解析 DOI。

Word/Excel 一致性、图表位于附录、PDF 分页、字体与文字边界、35 个 Figure PDF 的非空像素与边界、表 8 的 480 行逐项记录、记录哈希和 HTML 桌面/移动布局已由 W00 重新自动验证。新日志保存在 `w00_baseline/`，未进行人工图稿审阅。

## 仍需作者补齐

2026-10-07 决定及开发进展：公开测试数据由执行者选择，miniACC 开发案例已完成但未加入上述 0.3.1 论文结果；专家评价在功能/案例/材料准备完成后启动，用户体验/学习增益研究 deferred。本人事项集中于 [USER_ACTIONS_REQUIRED.md](USER_ACTIONS_REQUIRED.md)。

作者、单位、通讯邮箱、贡献、经费、利益冲突、公开 GitHub URL 与版本化 DOI 为明确占位。pasilla 已完成独立数值事实基准；双模型已完成一次 120 案例/480 事实共同任务机制比较，但不是泛化性能排名。当前外部评分仅为聚合描述统计，真实用户任务实验、伦理/招募资料核实和更多隔离代码代理比较仍未完成。这些后续研究不作为本稿已有结果。
