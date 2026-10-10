# 中文论文v0.8与写作场景的网站修复交接

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
