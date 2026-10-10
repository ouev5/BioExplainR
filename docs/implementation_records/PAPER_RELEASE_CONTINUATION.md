# 中文v0.9、工具比较、发现案例与发布续接

日期：2026-10-08；软件0.4.0.9000。本轮用户明确要求工具比较、正文压缩/排版修正、代码公开仓库与release/DOI，并建议发现案例。无子代理，所有分析实际本地运行。

## 论文

- 当前目录 `docs/paper_cn_v2/`，主稿v0.9 **9页**，独立补充**16页**；30refs，主稿2图/1内嵌表，补充8合图/11节详细方法，Table_1及Table_S1–S10共11组CSV/XLSX。
- 正文按四项贡献组织：完整facts、scope/independent unit、可定位检查、dependency/coverage-aware project。引言到结论非空白字符11,279→3,863，缩减65.75%。v0.8保留，10节原方法移补充。
- 六工具比较依据iSEE、SCassist、GeneAgent、ellmer、GPTCelltype原论文及官方文档；原生能力/任务定位不冒充性能排名。认可SCassist已有R指标增强提示、GeneAgent已有数据库自验证，突出本文审查环节的集成价值。
- Word标题显式numId=0，文字只编号一次；正确基因为CRISPLD2。v0.8源中本身未见CRISPR2/1.1.1，但导出检查新版PDF/Word无此错误。发现PDFUnicode上标负号字体问题，改为真正Word上标run。
- 新图最初24h行标签越界，自动审计失败；增加左侧边距后pass。失败日志保留。正式PDF直接嵌入矢量图，Word/HTML为PNG预览。比较表宽度调至所有工具名可完整显示，表+表注为单页。

## SPARCL1候选与外部实验

- 协议 `research/discovery/PROTOCOL.md`，freeze UTC与hash见 `discovery_sparcl1_v1/frozen_protocol.json`。在airway上调集合按padj/feature_id排名首位，固定ENSG00000152583/SPARCL1，log2FC+4.57496679448078，padj7.0559599945773e-132。
- 元数据、原文/平台用于可用性核查先于冻结；候选表达与统计值在冻结后读取。非注册平台预注册，不宣称全部盲法。未根据外部结果换候选/阈值。
- 完整GEO series matrix **1,932,820bytes**，41,000探针行/10数组；GPL6480注释 **7,380,104bytes**，gzip CRC完整。一个精确SPARCL1探针A_23_P113351；全发布untreated4/dex4h3/dex24h3数组保留。
- 24h主效应+4.1315175526666685发布processed单位，95%CI3.747855828517914–4.515179276815423，Welch P0.00015547054705390362，Holm同值，枚举35组双侧P1/35。4h次效应+1.9658497193333337，Welch P6.566062912590384e-6。
- R stats::t.test/combn独立复核10项效应/P/CI/置换+2 Holm通过。重新从完整gzip/注释回读探针、测量、候选规则和数字，20文件hash通过；脚本 `audit_saved.py`。
- BioExplainR真实context/project/双语HTML与RDS保留，区分两个dataset及供体/培养单位；本轮无在线模型调用。
- **原文明确微阵列来自单个HASM1细胞系**。不同accession/platform为外部实验，但培养重复不当成独立供体；无逐供体重叠确认、蛋白/机制/临床验证或首次发现主张。提出GR/SPARCL1干预与基质终点的后续实验。

## 验收

入口 `research/results/w00_baseline/revision-*`，命令/UTC/exit/log hash由manage_baseline保存。

|项目|结果|
|---|---|
|源码|677项：676pass、1skip、0失败/错误/警告|
|构建/包检查|build成功，R CMD check Status: OK，0ERROR/WARNING/NOTE|
|发现案例|完整公开gzip/注释/10数组回读，固定规则与数值核对，R独立12项一致|
|主稿/补充|引用编号/全引用、比较表Word/CSV/XLSX一致、11组表回读、hash、标题、PDF边界、矢量图、新图文字重叠pass|
|网页|1440/390两视口，主稿2图1表、补充8图0表，图片加载/无横溢出/无JS异常|
|Python及审计反例|修改工具语法通过，3个current审计损坏探针pass|

源码功能未新增；Shiny/HTTP/bwrap/历史API实测仍用前轮记录。论文图稿检查为自动几何/文字/网页，不冒充人工视觉或独立科学审阅。

## 公开发布实际状态

- 用户授权已明确，目标账号API核实为 **ouev5**，仓库名 **BioExplainR**。
- 环境无gh，sudo受no-new-privileges限制；从Ubuntu包下载/解包gh2.45.0至/tmp/opencode使用。
- `gh repo create`返回GraphQL Resource not accessible by personal access token；`gh api user/repos`进一步实际HTTP403。`gh repo view`不能解析目标。**未创建远程仓库、未推送、无公开release、正式URL或DOI。** 密钥不写源码、日志、清单或文档。
- `CITATION.cff`、`NEWS.md`、`docs/index.html`和`RELEASE_ARCHIVE.md`已准备。原Authors@R占位保留，未推断人员。Zenodo凭据未配置，不能凭GitHubPAT签发DOI。
- 本地源码提交与r8新交付归档用于下次直接发布；旧r1–r7/受保护历史记录不覆盖。代码/论文/案例公开复现入口见`PUBLIC_REPRODUCTION.md`。

## 续接

首先看本文件和paper_cn_v2/README。负责人创建公开BioExplainR仓库或环境配置合适GH_TOKEN后，执行者核实远程内容、推送、release附件匿名回读；Zenodo关联或归档后填真实URL/版本DOI。继续修改论文时新版本/新日志/新ZIP，不沿用旧hash验收。专家评价后置，用户研究deferred。
