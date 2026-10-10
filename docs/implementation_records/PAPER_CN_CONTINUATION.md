# 中文论文v0.8与写作场景的网站修复交接

## 最新续接：做了什么、没做什么（2026-10-09，正式运行与独立复核）

当前主稿仍为[v0.10](../paper_cn_v4/README.md)，配套新[共同任务与机制研究增补](../research_followup_v1/README.md)为4页/4表，Word/PDF/HTML已导出核验。详细记录[FORMAL_FOLLOWUP_CONTINUATION.md](FORMAL_FOLLOWUP_CONTINUATION.md)；下方准备、原网站修复与#45–47上传记录保留历史范围。

**本次续接仅更新交接文字，没有开始v0.11主稿整合，没有新建论文图表或重导出v0.10主稿/补充材料，也没有新增研究运行。** 后续论文整合应另建版本目录，并继续保留本页的原网站修复、#45–47上传和历史稿记录。

### 做了什么：准备与正式执行

- 恢复临时ellmer0.5.0库及固定Qwen2.5-1.5B-Instruct Q4_K_M/llama.cpp b11429，复核大小与SHA-256；补齐三工具固定commit完整源码及iSEE2.14.0来源。任务输入、24任务/360顺序、bootstrap与正式脚本在推理前冻结，机制处理映射/设计和ChIP窗口亦各自冻结。方案入口为`research/common_performance/PROTOCOL.md`、`IMPLEMENTATION.md`及`research/discovery/MECHANISM_PROTOCOL.md`。

- **共同任务**：24任务×3重复×5方法＝360运行/1,800评分，216正式模型尝试+1预热。离线/base R/ellmer facts/Bio客户端各360/360；读表8/360、覆盖175/360、37真实超时，全正确0/72。两facts相对读表差+97.78个百分点，任务bootstrap95%CI+95.28–+100；Python原输入/原输出/HTTP/时间/tokens/区间独立复核通过。不是六工具全面排名。
- **机制**：GSE229084 A549 47文库TMM/voom-limma拟合完成，SPARCL1计数0–4，固定filter未通过，三交互不可估计；控制不代替候选。Python过滤/WLS代数、作者SE51样本映射和705,534共享计数核对通过。
- **ChIP**：18发布峰及原文HTML/RefSeq已保存，全基因组坐标核实hg19，人/mm9冲突与未获作者确认保留。SPARCL1主GR窗vehicle4/2、DEX8/8；RNAPII0/0、1/1；R288计数、2,505命中/距离/重复一致性独立复核通过。仅窗口重叠，非差异占据/因果证明。
- 增补4表与原结果/PDF文本边界、1440/390网页通过。初次入口/端口/映射/CI/科学计数格式、下载XML/403/challenge及OCR失败另保留；本地交付r13/baseline-11接入结果，以最终完整性和current/historical审计为准。
- 无新增湿实验、蛋白基质功能/临床、专家/用户研究或第三方人员sign-off；R包功能未改。GitHub/外部上传仍暂停，#45–47只对应原v0.8。

### 没做什么／未完成事项

- 新结果已独立导出研究增补，尚未整合成下一版主稿，当前工作稿仍为v0.10；真实作者/单位/通讯、CRediT、基金、利益冲突与适用伦理信息、人工最终图稿审阅未完成。
- 没有六工具全面性能排名；四专属工具仅源码/原生适用性核对，未执行其专属任务。未评价其他模型/新独立gold/人员收益；失败请求tokens和本地总成本未测量。
- A549 SPARCL1三交互是过滤后不可估计，不是机制阴性统计；TMM/voom/eBayes未独立重估。ChIP只有发布峰重叠，未做差异占据统计、增强子连接或直接调控证明，assembly未获作者确认，出版社补充/XML仍未取得。
- 新供体湿实验、GR/CEBPD rescue、位点reporter/CRISPR、SPARCL1干预、蛋白/基质/功能/临床终点及第三方人员科学/code sign-off未完成；专家/用户研究状态保持既有安排。
- 未重跑R源码/build/check、Shiny、历史HTTP/bwrap/API及旧案例；无新提交、推送、release、DOI或外部上传。

### 失败／中断与续接入口

- 正式成绩仅取`research/results/common_performance_v4/`；v1 Responses API忽略seed、v2端口冲突、v3客户端参数/finish_reason错误的失败与中止保留在各自目录。v4读表37超时全部进入分母。
- `discovery_mechanism_fit_v1/`–`v3/`的freeze路径、空白映射、CSV类型失败保留；v4原`model.rds`未改，CI另存`model_results_complete.csv`。作者处理对象下载503/超时、双层gzip及102未对应ID有独立记录。
- `discovery_chip_v1/`保留challenge HTML、XML500/出版社403及OCR不清楚记录，有效原文另存`PMC5576583_article.html`。R审计窗口科学计数格式失败后仅修复格式，未更改窗口或命中规则。
- 全部命令、UTC、退出码和日志hash在`research/results/w00_baseline/continuation-*.json/txt`；详细对照表见根`SESSION_HANDOFF.md`最新节。
- 下一轮先读研究增补README和两个方案，再核对正式目录的`files_manifest.json`、`scientific_ledger.json`及current manifest；保存结果复核无需新推理。继续整合从v0.10另建新稿，新研究另冻结/新目录，作者确认与湿实验按真实进展追加。
- 研究交付r13保留原hash；**本次交接文字更新使用r14/baseline-12**，完整性入口`research/results/w00_baseline/handoff-formal-docs-delivery-audit-result.json`。原网站修复及#45–47上传记录逐字保留，发布仍暂停。

## 历史续接：共同任务性能比较／机制检验准备阶段（2026-10-09，当时尚未运行）

**当前论文仍为 [v0.10](../paper_cn_v4/README.md)；用户指定的 [v0.9.1](../paper_cn_v3/README.md) 是保留的历史图表正文修订稿。** 本轮没有新文稿导出、性能成绩或机制统计结论，详细“做了／没做”清单在根`SESSION_HANDOFF.md`；以下原网站修复与上传记录保留。

### 已做

- 保存共同任务比较方案 `research/common_performance/PROTOCOL.md`：拟24任务、5整数facts、3重复，BioExplainR／base R／ellmer同任务比较，预定错误分母、tokens、时间及任务级区间。任务输入、runner和参考评分器尚未实现/冻结，不写成已运行24任务。
- 独立临时R库安装并载入ellmer **0.5.0**；本地libcurl开发头文件/链接补齐。llama.cpp b11429 CPU归档及Qwen2.5-1.5B-Instruct Q4_K_M实际下载且SHA-256核对一致；未启动推理。
- 保存 `research/discovery/MECHANISM_PROTOCOL.md` 和原freeze：固定SPARCL1，拟GSE229084受体降解/拮抗三交互及GSE95632 ASM GR/RNAPII峰核验。
- 取得并逐hash核对5输入：GSE229084 metadata、series、2,524,990bytes的geneCounts，GSE95632 metadata及Gazorpak原文XML。gzip全读通过；计数未读取候选行、未拟合。
- 新状态快照 `research/results/common_performance_checkpoint_v1/checkpoint.json` 标`preparation_partial`；依赖成功日志`performance-comparator-install-final.*`，失败/中断`performance-runtime-acquire*`和`mechanism-inputs-acquire*`保留。本次交接使用新r12完整性记录`followup-delivery-audit-result.json`，旧r11保留原hash。

### 未做／实际阻塞

- 没有共同任务推理、正确率/覆盖率/耗时/token/成本/区间或六工具排名；0模型调用、0评分。四个专属工具不原生输出该任务结果，不能算答错；完整六工具适用性记录待完成。
- SCassist源码归档下载被中断，gzip不完整；GPTCelltype/GeneAgent源码未取得，runtime manifest未生成。`performance-runtime-acquire-final`只有空txt、无完成json，不能标pass。当前临时库不能沿用历史iSEE/其他工具安装状态。
- GSE229084尚未核对处理映射或运行TMM/voom/三交互Holm；为A549癌上皮细胞系，不能当ASM患者验证。GSE95632峰尚未获取；GEO人样本标mm9导致assembly未验证，Sasse原文XMLHTTP500，不能猜hg19。
- 初始freeze后下载脚本因超时改为resume/逐文件清单；原script hash不改写，当前修订hash在checkpoint，正式分析脚本另冻结。
- 无新湿实验、GR/CEBPD rescue、SPARCL1功能/蛋白/基质/临床终点；无新R软件测试或论文/图表导出、专家/用户研究。GitHub仍暂停，本轮无提交/推送或外部上传，#45–47仅为v0.8。

继续先读两个方案及checkpoint，补齐输入与runtime、核实assembly、冻结runner/评分/拟合脚本再运行。日志UTC遵守主机实值（2026-10-08），会话交接日期2026-10-09，不改写历史时间。

## 最新续接索引：已完成与未完成（2026-10-09，当前稿 v0.10）

**当前稿已更新为 v0.10，入口 `docs/paper_cn_v4/README.md`（12 页主稿＋18 页补充；3 主图、1 内嵌表、补充表 S1–S13、32 参考文献）。本文下方 v0.8 的 23 页、r7、网站修复及 #45–47 上传记录保留历史范围，不代表新稿已上传。** 最新总交接为根目录 `SESSION_HANDOFF.md`。

### 后续已完成（v0.9 → v0.9.1 → v0.10）

- 六工具比较表及正文方法/结果：iSEE、SCassist、GeneAgent、ellmer、GPTCelltype vs BioExplainR，突出完整 facts、scope/unit、声明/图源核对、项目依赖/覆盖分母的集成能力。
- 正文压缩为四贡献，详细技术移补充；v0.10 因新增真实发现章节，相对 v0.8 缩减 47.39%（不再是 v0.9.1 的 50.56%）。Word 标题重复编号关闭、正确 CRISPLD2 及上标负号核验保持。
- SPARCL1 候选固定与外部 GSE34313 培养实验重分析已保存（+4.132、Welch P=1.55e-4、置换 P=1/35，Python/R 独立 12 项一致）。
- 按用户纠正逐项补齐全部图表在主稿正文的引出、图表号、主要结果/设计与解释。**v0.10 覆盖 25 项**（3 主图＋1 主表＋8 补充图＋13 补充表）；详见 `paper_cn_v4/figure_table_links.json` 与 `FIGURE_TABLE_NARRATIVE_CONTINUATION.md`。10-09 纠正了交接文字中“24 项”的计数误写，实际清单无缺项。
- **本轮新增候选后续检验（v0.10）**：
  1. GSE146017（Kan 2022，4 供体/31 文库，BUD×TNFα×CEBPD siRNA）全 HTSeq 计数 DESeq2 因子模型 `~ donor + kd * bud * tnf`；三项预定 SPARCL1 交互同一 Holm family，全部未通过（−1.246 Holm P=0.289；−0.142 P=1；−0.136 P=1）。Python 复核原始计数、size factor、Wald 代数与 BH/Holm，R/NumPy 独立供体级敏感性；`research/results/discovery_context_v1/`。
  2. GSE94335（Kan 2019）多供体重分析：从原文 Supplement Table E1 的 Cell Line 恢复真实配对（GEO donor 字段逐文库唯一，不可用）；7/7 非哮喘与 9/9 致死性哮喘供体 BUD 配对均上调，log2(TPM+1) 差 +3.514/+3.598，组间差 +0.084（Holm P=0.859，11,440 组枚举 P=0.844）；`research/results/discovery_donors_v1/`，R 独立重算全部配对/t/Welch/精确/Holm。
  3. 记录并披露的三项数据边界：28793/28796 映射与病组冲突按设计排除；GSE94335/GSE146017 至少 3 个培养细胞系 ID 相同，不合并供体数；SPARCL1 在 GSE146017 baseMean 8.175 的低表达限制。
  4. 原文核对显示 Himes 2014 表 1、Kan 2019 表 3 已报告 SPARCL1 响应，因此正文明确“不主张首次发现”，新增价值限定为供体分布、显式组差/交互与可定位映射。
- 网页 1440/390 双视口核验：主稿 3 图 1 表、补充 8 图 0 表，无横溢出/JS 异常（`research/results/w00_baseline/revision-biology-browser/`）。审计 `paper_cn_v4/audit.json`：32 引用、3 图、14 外置表、25 项图表对应、正文数值与保存结果一致。
- 10-09 续接补齐交付脚本与 current 审计：接入 v0.10、两个新分析目录、冻结方案、供体配对原表、双语报告和 `biology-*` 日志；本地新编号 r11 的完整性入口为 `research/results/w00_baseline/biology-delivery-audit-result.json`，current manifest 使用 baseline-9。验证状态以这些实际输出为准。

### 尚未完成及本轮未做

- **GitHub 仍暂停**：无远程仓库、未推送、无 release/正式网址/DOI；此前建仓权限 403 为真实失败记录。
- **v0.9/v0.9.1/v0.10 均未外部上传**；下方 #45–47 仍只对应 v0.8，不能作为当前稿下载地址。
- 未做六工具共同任务性能排名；未做新增供体湿实验、GR/CEBPD 直接结合、SPARCL1 干预、蛋白/基质/临床终点；GSE146017 仅 4 供体，交互阴性不证明无机制。
- 未开展新专家评价；用户研究 deferred。真实作者/基金/伦理/CRediT 及最终人工图稿审阅、第三方科学/代码 sign-off 待完成。
- 本轮未改 R 包功能、未重跑 R 源码/build/check、Shiny、HTTP/bwrap/历史 API、上游 airway 数据或在线模型；历史 677 项与 check OK 仍按各自日志引用。本轮数值仅来自新建的 `discovery_context_v1`、`discovery_donors_v1` 结果。
- GSE94335 原始 TPM（121.6 MB）通过分段下载取得并校验 SHA-256/gzip CRC；不进入交付 ZIP，按 `research/discovery/download_ranges.py` 可复现。

继续工作从当前 v0.10 入口读取，不覆盖旧稿/保护清单；恢复公开发布需要负责人再明确要求。

---

以下为v0.8阶段的原始实施与上传记录。

日期：2026-10-08；软件0.4.0.9000；本次按负责人要求完成中文稿、案例、图表及指定服务公开上传。专家评价后置，用户体验/学习增益deferred。

## 阅读基线

已阅读SESSION_HANDOFF、REVIEW_CONTINUATION、PUBLIC_CASE_CONTINUATION、CONTINUATION_REVIEW及current manifest。修改前current audit pass，r6再次核验**598成员**；该验证只对应修改前文件树，结果`paper-r6-start-integrity.json`保留。旧稿、历史图表和2,905原保护文件不覆盖。

## 新论文入口

- 唯一中文当前稿目录：`docs/paper_cn_v1/`，详见其README。
- `BioExplainR-中文论文-v0.8.pdf`：**23页**；可编辑DOCX和自包含HTML同目录；文字源`manuscript.md`。
- 细化方法为10小节，补充完整事实/预算、scope/design/unit、映射分母、方向关系、各案例预处理、Wilcoxon/BH、评分分母和版本边界；结果按airway、PBMC/微阵列、pasilla、miniACC、模型传递、机制场景及工作台组织。
- 作者、单位、通讯、贡献、基金、利益冲突及公开仓库/DOI留位。新版不包含旧专家/用户评分，末尾附录C预留独立专家、使用体验、学习效果与独立验证。
- 29参考文献均有引用；miniACC来源新增MAE方法和TCGA-ACC原文。TCGA-ACC doi/title/author/page/year通过Europe PMC检索核对，旧引用沿用已有出处。

## 图表组织

- **8张合图、32张独立panel PDF**，保存在`figures/composites/`、`figures/panels/`；框架图有原创数据库/图/网络/check/report矢量图标。
- 每图由4个PDF以PyMuPDF show_pdf_page组合，正式论文PDF直接嵌入合图矢量内容，不只是预览PNG；图8真实页面截图为位图素材。
- **9份XLSX+9份CSV**在`tables/`。论文数据表为0，仅保留正文引用和附录B表题/表注/来源；XLSX另含说明来源表。
- `assets_manifest.json`保存图表hash与合图成员，`export_report.json`记录论文直接嵌入位置，`audit.json`保存数值/引用/几何/表数据审计。
- 独立论文附件包`docs/BioExplainR-中文论文-v0.8-图表附件.zip`：**76成员**、7,670,920bytes，SHA-256 `f4e2f023be340ee4daacabb2d1eb50fe39ec66fcc5aec5d7d2411e4732ea137c`。包含稿件及图表，排除Word转换中间PDF。

## 新增案例及网站修复

- `research/paper_cn/run_cases.R`→`research/results/paper_cn_cases_v1/`；不可覆盖旧输出。从保存真实DESeqResults重算α=0.01/0.05/0.10×τ=0/1/2、5事实=**45/45**；Python从导出的全表另行重算45项。
- r7包含新场景实际回读的公开`research/cache/real_objects.rds`及miniACC项目RDS，`paper-cn-case-inputs.json`追加输入hash；这是运行后输入索引，不将其写成运行前冻结。原始准备脚本和新稿导出所需`export_paper.py`亦随r7保留。
- **15/15场景期望一致**：8pass、5fail、1partial、1unverified。涵盖独立供体、正确/坐标错/标签错PCA、raw-only、完整facts超预算、合法但不完整映射、未映射观测、病例越界、正确/错误关系、反转比较、缺scope及页面项目分派。手算和受控修改逐行标记，不冒充独立生物样本。
- 保留六公开来源：airway、PBMC3k、pasilla、ALL、bladderbatch、miniACC。历史模型结果只离线核对；新增无provider调用，无专家或用户评分。
- `R/shiny-app.R`新增bio_project专用dispatch，重算显式关系，展示项目摘要/依赖、覆盖与两两交集、完整/未测量计数和关系findings，下载同一项目报告。宽表容器横向滚动，原始map/病例ID不展示。
- 绘图页新增Cairo矢量PDF下载和英中文案，失败时清空旧图及下载入口，错误状态不保留成功名称。
- 浏览器用真实miniACC项目检查项目/报告、移动页面与不泄漏病例ID；下载一页实际PCA PDF并验证绘图内容。第一次浏览器探针在新动态按钮尚未绑定download href时点击，得到页面HTML；原失败日志保留。等待真实href就绪后7组通过，未将该失败当成软件PDF生成故障。
- 图稿发现5处框架卡片文字重叠及几个注释/边界问题，已修复并通过40张PDF的文字边界/重叠核对。模型不能直接看PDF或图片，本轮为自动几何/内容检查，没有人工视觉审阅。
- `research/export_paper.py`添加可选legacy_layout默认TRUE，新稿关闭历史横向表格/逐表分页，旧导出默认行为保留。
- 原有3888工作台进程经核对路径/启动命令且无连接后已重载当前源码，保持loopback、local预设和空启动工作区；重载结果`paper-cn-workbench-reload-result.json`。重载后的实际3888页面再次通过miniACC项目和PDF下载，见`paper-cn-live-browser/summary.json`；启动日志在`/tmp/opencode/bioexplainr-paper-cn-workbench-3888.log`。

## 实际验收

命令、UTC、退出码、log hash由manage_baseline保存，入口`research/results/w00_baseline/`。

|项目|实际结果|入口|
|---|---|---|
|源码|677项：676pass、1skip、0失败/错误/警告|paper-cn-source.*|
|构建及包检查|build成功；Status: OK，0ERROR/WARNING/NOTE|paper-cn-build.*、paper-cn-package-check.*|
|安装后完整/Imports-only|context→typed→coverage/direction project→HTML通过|paper-cn-installed-smoke.*、paper-cn-full-smoke/、paper-cn-core.*；隔离输出/tmp/opencode/bioexplainr-paper-cn-core|
|新增案例|45源表事实/15场景通过|paper-cn-cases.*及paper_cn_cases_v1|
|miniACC独立实现|23文件、66效应、方向/覆盖/BH通过；Wilcoxon原始P未独立重算|paper_cn_v1/audit.json；review安装案例日志保留|
|Shiny浏览器|7组通过，1440/390无页面横溢出；项目/报告/PDF/英中/两会话|paper-cn-shiny-final.*、paper-cn-shiny-browser-final/|
|稿件|23页、8合图/32panel、9外置表、0嵌入表、29refs；引用/内容/几何/hash/CSV/XLSX一致|paper-cn-document-audit-final.*、paper_cn_v1/audit.json|
|论文网页|双视口8图、0表、图片加载、无溢出/JS异常|paper-cn-html-browser.*及同名目录|
|Python/审计反例|修改工具语法通过，3损坏探针pass|paper-cn-python-syntax.*、paper-cn-final-python-syntax.*、paper-cn-audit-probes.*|
|公开上传|3文件，download/file共6匿名回读HTTP200，bytes/hash一致|paper-cn-upload-verification.*、paper-cn-upload-result.json|

本轮未重跑HTTP/bwrap或74旧API专项，仍引用10-08review历史；浏览器修复使用本轮新日志。软件check与45项核对不扩大为专家或科学泛化结果。

## 公开上传记录

负责人明确提供指定服务及`is_public=1`。只上传新稿和论文图表附件，HTTP200、ok:true；鉴权凭据未写入任何源码、交接、manifest或执行日志。

|服务编号|文件|bytes|SHA-256|公开下载|
|---|---|---|---|---|
|#45|BioExplainR-中文论文-v0.8.docx|1,093,006|fe68b2754c8cc349baf5239536c91ddbc8b1618fd02c9c9a934c4071a23752d8|http://62.234.106.117:8003/api/download/45|
|#46|BioExplainR-中文论文-v0.8.pdf|2,802,383|5a838cae8e801775a60fae1731a25d0740e6303a5724eec22520501fa433233d|http://62.234.106.117:8003/api/download/46|
|#47|BioExplainR-中文论文-v0.8-图表附件.zip|7,670,920|f4e2f023be340ee4daacabb2d1eb50fe39ec66fcc5aec5d7d2411e4732ea137c|http://62.234.106.117:8003/api/download/47|

上传UTC分别为09:35:22.964Z、09:35:23.407Z、09:35:30.660Z；上述3文件均以匿名download/file回读hash一致。再次修改稿件时新建版本/上传记录，不覆盖本次编号。

## 当前清单和下一轮

`manage_baseline.py`新增paper_cn_cases/paper_cn_revision分组与baseline-6，实际软件记录采用paper-cn；新交付r7以`paper-cn-delivery-audit-result.json`为唯一完整性入口。current audit检查新稿审计与15场景。r6当时ZIP保留，不能要求其与修改后树一致。SESSION_HANDOFF在打包后更新，不进入开发ZIP；随后重建manifest和current/historical audit，以最终manifest_sha256为准。

下一轮继续围绕中文论文和实际写作中发现的工作台问题推进。引用旧结果标明0.3.1，新增结果标明开发数据和所测版本；专家在材料准备完成后，用户研究deferred。新建论文目录版本/运行输出/执行label，不覆盖原保护清单。最终人工图稿审阅、独立科学/人员研究、作者基金和公开发布信息留于附录C。
