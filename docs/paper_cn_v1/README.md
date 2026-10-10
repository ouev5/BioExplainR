# BioExplainR 中文论文 v0.8（历史稿，已归档）

**本目录为已归档 v0.8 历史稿，不作为当前稿引用。唯一当前稿为 v0.10，入口 [`../paper_cn_v4/README.md`](../paper_cn_v4/README.md)；v0.9.1 已归档于 [`../paper_cn_v3/`](../paper_cn_v3/README.md)，v0.9 已归档于 `../paper_cn_v2/`。本目录原稿/图表保留，仅用于历史比对与上传记录对应。**

## 最新续接：正式共同任务与机制研究增补

当前主稿继续为[v0.10](../paper_cn_v4/README.md)，[v0.9.1指定历史链接](../paper_cn_v3/README.md)保留。本轮正式共同任务360运行/1,800评分及机制/ChIP独立复核完成，新增[4页增补](../research_followup_v1/README.md)。SPARCL1 A549交互因过滤不可估计；ASM峰为坐标核实hg19后的窗口重叠，不作因果证明。正式研究交付为r13，本次交接更新另用r14，GitHub/外部上传仍暂停。

- **做了什么：** 正式评分、机制拟合、ChIP坐标/窗口核实及Python/R独立实现复核已完成；研究增补Word/PDF/HTML已导出。结果/失败/续接入口见[`../../SESSION_HANDOFF.md`](../../SESSION_HANDOFF.md)和[`../implementation_records/PAPER_CN_CONTINUATION.md`](../implementation_records/PAPER_CN_CONTINUATION.md)。
- **没做什么：** 新结果尚未整合为下一版主稿；未完成湿实验、因果/蛋白/功能/临床验证、专家/用户评分、真实稿件信息或第三方人员sign-off。当前工作稿仍为v0.10，本目录v0.8及下方“未运行”文字只代表各自历史阶段。
- **本次交接更新：** r14/baseline-12同步三份交接文档，r13保留为正式研究交付；不以新文档更新产生新推理或研究成绩。下一轮从v0.10与研究增补续接。
- **当前续接边界：** v0.11尚未开始；本次只整理交接文档，没有改写本目录历史稿、没有生成新图表或论文导出。正式工作稿仍是v0.10，v0.9.1链接继续保留为历史入口。

## 上轮准备交接补充：已做／未做（历史时点）

- **用户指定的 v0.9.1 入口：[`../paper_cn_v3/README.md`](../paper_cn_v3/README.md)**（10页主稿／16页补充，21项图表正文对应）。该稿已被v0.10取代；当前入口仍为[`../paper_cn_v4/README.md`](../paper_cn_v4/README.md)，本轮未回退稿件。
- 已做：保存共同任务性能比较及GR机制检验方案；独立临时库安装ellmer0.5.0，取得并核对本地Qwen模型／llama.cpp归档；取得5项公开干预/元数据/原文输入。状态快照`research/results/common_performance_checkpoint_v1/checkpoint.json`。
- 未做：任务输入/runner/评分器尚未实现冻结，没有推理或性能数字；机制候选表达未读取，统计/独立复核未跑，ChIP峰和assembly尚未核实。SCassist半包中断、Sasse原文XMLHTTP500均保留。湿实验、蛋白/功能/临床验证及独立人员研究未完成。
- 最新“做了什么、没做什么”和续接命令见根`SESSION_HANDOFF.md`及[`../implementation_records/PAPER_CN_CONTINUATION.md`](../implementation_records/PAPER_CN_CONTINUATION.md)。本轮未导出新论文/图表或发布GitHub；#45–47仅对应本目录v0.8。交接新包r12，r11为上一轮已完成交付。

## 历史交接摘要（2026-10-09，v0.10主稿完成／正式后续研究前）

- 当前稿 **v0.10**（`docs/paper_cn_v4/`）：12 页主稿（3 主图、1 内嵌表、32 参考文献）＋18 页补充（8 补充图、补充方法 S1–S13、外置表 S1–S13）。新增候选后续检验：SPARCL1 在 GSE146017 的三项交互均未获支持；核对原论文供体映射后 GSE94335 的 7/7 非哮喘与 9/9 致死性哮喘供体均上调，组间响应差未获支持。
- v0.9.1 历史状态：10 页主稿＋16 页补充，全部 10 图/11 表完成正文引出与解释，记录见 [`../paper_cn_v3/FIGURE_TABLE_REVIEW.md`](../paper_cn_v3/FIGURE_TABLE_REVIEW.md)。
- 当前 v0.10 实际为 11 图/14 表＝25 项正文对应；本地开发交付入口 r11 及完整性记录见 [`../DEVELOPMENT_DELIVERY.md`](../DEVELOPMENT_DELIVERY.md)。
- 未完成：共同任务六工具性能排名、新增供体湿实验与机制/蛋白/临床验证、新专家与用户研究、真实作者/基金/伦理等最终信息及人工或第三方审阅。
- 已暂停/未发布：GitHub 按负责人要求暂停，无远程仓库、公开 release、正式网址或 DOI；v0.9/v0.9.1/v0.10 均未对外上传。公开上传编号 **#45–47 仅对应本目录 v0.8**。
- 本轮未重跑 R 包源码/build/check、Shiny、HTTP/bwrap 或在线模型；下方运行命令和数字为 v0.8 历史复现入口，不用于覆盖当前稿。

---

历史日期：2026-10-08；软件开发版0.4.0.9000，历史模型结果0.3.1。本目录是v0.8稿件入口，旧v0.7稿及历史图表保留。

## 阅读与编辑

- `BioExplainR-中文论文-v0.8.pdf`：**23页**，正文、29参考文献、8张附录合图、表题/表注、文末可补充部分。
- `BioExplainR-中文论文-v0.8.docx`：可编辑中文稿，8图、**0个数据表**；作者、单位、通讯、基金、贡献等留空位。
- `BioExplainR-中文论文-v0.8.html`：自包含浏览器版，桌面/移动8图、0表。
- `manuscript.md`：可维护文字源。
- 附录C预留专家、用户体验、学习效果和独立验证；本稿不写历史专家/用户评分。专家后置，用户研究deferred。

## 独立图与外置表

- `figures/panels/`：32张独立子图PDF，Figure_1A到Figure_8D。
- `figures/composites/`：8张四联PDF合图，Figure_1到Figure_8。每张由4张PDF以PyMuPDF `show_pdf_page`排版，矢量内容保留；图8真实页面截图是位图素材。
- `figures/previews/`：仅用于Word/HTML的8张高分辨率PNG预览。
- `tables/`：9份XLSX、9份UTF-8 CSV；XLSX含说明/来源工作表，正文和附录B按表1–9引用。
- `assets_manifest.json`：图表源文件SHA-256与合图成员/表结构。
- `export_report.json`：论文PDF中直接嵌入矢量合图的位置。
- `audit.json`：数值、引用、DOCX/CSV/XLSX及图形文字边界/重叠检查。
- `rendered_docx/`：Word转换中间PDF（含预览图）；正式论文请使用目录根部PDF，它以合图PDF替换了这些预览。

## 案例与复现

6公开来源：airway、PBMC3k、pasilla、ALL、bladderbatch、miniACC。本轮新增airway9阈值×5事实=45核对，15个有明确期望状态的开发场景；保存结果位于`research/results/paper_cn_cases_v1/`。miniACC详见`research/multiomics/`及`miniacc_installed_review/`。新脚本位于`research/paper_cn/`。

```sh
Rscript --vanilla research/paper_cn/run_cases.R research/results/paper_cn_cases_new
# 已有v1资产拒绝默认覆盖；--refresh-draft只用于尚在编辑的本目录。
/tmp/opencode/paper-venv/bin/python research/paper_cn/build_assets.py --refresh-draft
/tmp/opencode/paper-venv/bin/python research/paper_cn/export_manuscript.py
/tmp/opencode/paper-venv/bin/python research/paper_cn/audit_manuscript.py --output /tmp/opencode/paper-cn-audit-new.json
NODE_PATH=/tmp/opencode/node_modules BIOEXPLAINR_PAPER_CN_BROWSER=/tmp/opencode/paper-cn-browser-new node research/paper_cn/browser_manuscript.cjs
```

图表脚本固定回读v1案例路径；另跑新案例后应复制脚本到新版本并改输入/输出路径，不把旧资产或保护清单覆盖。依赖定义为`tools/paper-requirements.txt`和`docs/REPRODUCTION.md`。

当前模型不能直接查看PDF/图片；已用PDF解析与文字几何检查排除已发现的重叠、越界，未冒充人工视觉审阅。独立人工图稿审阅的位置在附录C。历史模型响应未重跑，新增开发场景不是独立test-gold；没有新增专家或用户研究。
