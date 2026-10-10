# BioExplainR 中文论文 v0.8

**已归档版本。当前精简主稿v0.9、工具比较与SPARCL1外部实验见 `../paper_cn_v2/README.md`。本目录原文件保留。**

日期：2026-10-08；当前软件开发版0.4.0.9000，历史模型结果0.3.1。本目录是新中文稿的唯一入口，旧v0.7稿及历史图表保留。

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
