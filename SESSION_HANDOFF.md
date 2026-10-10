# BioExplainR 会话交接说明

## 最新交接：生物学主线论文 v0.11 已完成初稿（2026-10-09）

当前入口：[v0.11 README](docs/paper_cn_v5/README.md)；统一交接先读[rgo.md](rgo.md)第0节。主稿11页＋补充12页，Word/PDF/自包含HTML，5图、19表（24项正文对应）、11参考文献。依据54基因四背景响应与固定12候选的外部结果，以PER2暴露条件相关差异为主线；前轮共同任务及SPARCL1/ChIP核验纳入补充背景。

问题与已纠正文字见`docs/paper_cn_v5/ISSUES.md`：统一109,636项BH、A549暴露时长与总培养时间区分、点态CI、缺测分母、GCNT1反向供体、同来源双模型及结果后探索。独立供体时间序列、GR遗传/rescue、节律和功能尚需实验。

原封存依赖／旧ZIP、表源及CSV-XLSX、配对统计/48项Holm/24直接差、引用和PDF边界通过，主/补1440/390浏览器通过。新清单与附件包独立位于`docs/paper_cn_v5/`，原rgo快照保留以验证旧manifest；本次是文稿整合，不把保存统计算新拟合。适用命令与真实执行错误在新README和EXECUTION_NOTES。旧current/r14验收仅为历史版本，GitHub/外部上传继续暂停。

以下各“当前v0.10／未开始整合”描述属于v0.11之前的历史时点。

## 最新交接：做了什么、没做什么（2026-10-09，正式研究完成后）

**已从准备推进到真实执行与评分。当前正式论文仍为 [v0.10](docs/paper_cn_v4/README.md)，新增 [4页研究增补](docs/research_followup_v1/README.md)（Word/PDF/HTML、4表）。** 完整失败/修订及复现入口见`docs/implementation_records/FORMAL_FOLLOWUP_CONTINUATION.md`；下方准备阶段保留历史时点，不代表当前仍为0调用。

**本次继续仅整理交接文档，没有开始v0.11主稿整合、没有新建论文图表、没有重导出主稿/补充材料，也没有新增研究运行。** 下一次如整合正式后续结果，应从v0.10另建新版本目录，不覆盖v0.10、v0.9.1或v0.8历史稿。

本条收尾文字追加于r14/baseline-12验收之后；本次没有重打包或重建清单，原pass只对应当时文件树。下次使用current完整性结论前，应重新同步文档清单与归档并复核，不沿用旧文档hash。

### 做了什么

|事项|实际结果|入口|
|---|---|---|
|共同任务正式运行|24任务×3重复×5方法＝360运行/1,800评分，216正式模型尝试+1预热；离线/base R/ellmer facts/Bio客户端均360/360，ellmer读表8/360、覆盖175/360、全正确0/72；37超时全部保留分母|`research/results/common_performance_v4/`|
|配对区间与计时|facts相对读表目标正确率差+97.78个百分点，24任务bootstrap95%CI+95.28–+100；中位秒：base R .002、离线.036、读表180.829、ellmer facts18.584、Bio客户端18.654；失败tokens/本地总成本未知|`summary.csv`、`paired_bootstrap.csv`、`task_bootstrap.csv`、`audit.json`|
|完整来源／适用性|ellmer0.5.0真实载入、Qwen/llama固定hash复核与正式服务执行；三源码半包补齐固定commit，iSEE2.14.0保存。四专属工具not_applicable、不计错、不作六工具排名|`common_performance_applicability_v1/`|
|机制拟合|A549 GSE229084，47文库/4batch/35,942基因，15,437过滤保留，模型秩15/残差df32。SPARCL1计数0–4未通过固定filter，三候选交互**不可估计**；固定控制另描述|`discovery_mechanism_fit_v4/`|
|机制独立复核|Python35,942基因过滤、188测量、39WLS/t/CI、GEO映射通过；作者SE51样本映射及705,534共享计数一致，102不可对应ID保留。原模型RDS未改，CI导出修复/精确SE敏感性记录|`audit.json`、`published_mapping_audit.json`、`published_counts_audit.json`|
|ChIP／assembly|18峰文件1,347,409峰均符合hg19长度；hg18/hg38/mm9分别12,937/10,043/158,229越界。坐标证据核实hg19，原人/mm9冲突保留、未获作者确认。SPARCL1 GR±20kb vehicle4/2、DEX8/8；RNAPII±5kb0/0、1/1|`discovery_chip_v1/`、`discovery_chip_analysis_v1/`|
|ChIP独立实现|R原峰/原RefSeq/GenomicRanges288计数、2,505命中、summit/距离及16重复比较通过|`r_audit.json`、`r_replicate_audit.json`|
|增补导出核验|4页4表，Word表与CSV/原结果、PDF文本边界通过；1440/390均无横溢出或JS异常|`docs/research_followup_v1/`|

### 没做什么／解释限制

- 共同任务是已知开发数据、本机小模型固定计数/事实传递，200行读表36请求均超时；不是六工具全面排名、通用推理或独立生物学gold。facts组已含目标答案。
- A549候选不可估计，不能支持或否定GR依赖；ASM单细胞系峰重叠不是差异占据统计、直接调控或功能因果。assembly仅坐标证据核实，作者确认/出版社补充仍未取得；XML/403/challenge/OCR失败完整保留。
- 未独立重估TMM/voom/eBayes；没有新增湿实验、新供体/rescue/位点reporter/CRISPR/SPARCL1蛋白/基质/功能/临床终点、专家/用户评分或第三方人员sign-off。
- 本轮未改R包功能/重跑包check、Shiny、历史HTTP/bwrap/API或旧生物学分析；当前软件验收仍按历史版本日志引用。GitHub/外部上传继续暂停，#45–47只对应v0.8。
- 4页研究增补已导出，但其新结果尚未整合为新的主稿版本；当前工作稿仍为v0.10。真实作者、单位、通讯、CRediT、基金、利益冲突及适用伦理信息、最终人工图稿审阅尚未完成。四专属工具只完成源码/适用性核对，本轮未安装或执行其专属任务。

### 失败／中断／修订在哪里

所有执行记录在`research/results/w00_baseline/`，`.json`保存命令、UTC、退出码及日志hash；中断只有`.txt`的记录不能视为pass。下表用新路径和原label保留实际失败，不改写旧freeze。

|事项|实际失败与处理|文件位置|
|---|---|---|
|共同任务早期尝试|v1的ellmer默认Responses API忽略seed而中止；v2端口冲突、未推理；v3发现config参数及finish_reason映射错误而中止；正确入口重新冻结为正式v4|`research/results/common_performance_v1/`–`common_performance_v3/`；`continuation-performance-formal*.txt/json`；`research/common_performance/IMPLEMENTATION.md`|
|正式任务超时|v4读表组37请求真实超时（其中200行36请求全部超时），全部保留全目标分母；没有重试、修订答案或删除失败|`research/results/common_performance_v4/runs/`、`wire/`、`scores.csv`、`audit.json`|
|机制准备及导出|fit v1/v2/v3分别在freeze路径、处理空白和CSV逻辑类型阶段失败；v4完整拟合。CI初次导出误索引无名字的s2.post，另文件修复导出，原模型RDS保留；精确与limma近似SE差异已复核|`research/results/discovery_mechanism_fit_v1/`–`discovery_mechanism_fit_v4/`；`continuation-mechanism-*.txt/json`；v4的`export_amendment.json`、`exact_WLS_sensitivity.csv`|
|ChIP来源及复核|首个article/PDF传输返回challenge HTML，不当作有效原文；后取得有效HTML。XML500、出版社403、OCR不清楚保留；R首次100000窗口键格式为1e+05，包装器固定数字格式后通过|`research/results/discovery_chip_v1/acquisition.json`、`alternative_sources.json`、`build_evidence_acquisition.json`；`continuation-chip-*.txt/json`；`discovery_chip_analysis_v1/r_audit.json`|
|作者处理对象|串行下载503/超时后，59段HTTP Range取得30,570,232bytes；双层gzip分别验证CRC。51样本映射及705,534共享计数通过；102无法对应的基因标识逐项保留|`research/results/discovery_mechanism_fit_v4/range_download.json`、`nested_gzip.json`、`published_mapping_audit.json`、`published_counts_audit.json`、`published_unmatched_gene_ids.csv`|
|评分／文档检查|bootstrap索引list需数值转换，scorer包装器只修复类型；文档检查首次历史marker不匹配失败，改用原日期边界后通过|`research/common_performance/score_complete.R`、`check_handoff_complete.py`；`continuation-performance-scoring*.txt/json`、`continuation-handoff-check*.txt/json`|

### 当前结果／交付续接

新结果只用`common_performance_v4`、`discovery_mechanism_fit_v4`、`discovery_chip_v1`及`discovery_chip_analysis_v1`；早期v1–v3中止/映射/端口/入口/导出失败另保留，不混入正式分母。任务/提示/过滤未按答案改规则。运行UTC按主机真实时间；原2,905保护文件、v0.10主稿和r1–r12保留。

当前本地交付使用新 **r13**：`docs/BioExplainR-development-delivery-0.4.0.9000-r13.zip`，逐成员结果`research/results/w00_baseline/continuation-formal-delivery-audit-result.json`；索引baseline-11。最终状态以实际current/historical audit及manifest hash绑定为准。精确model/runtime恢复入口`restore_formal_runtime.py`；新推理需新目录，保存结果复核命令见增补README。

**最终交付验收：r13 2,871成员、365,123,176bytes，SHA-256 `66cf0dfbf72ff55ce954ef129c8eb6472adc77eb3867a7560dbfcc59eb7afc2e`；逐成员大小/hash/当前树一致。current/historical均pass，2,905原保护文件逐hash不变；baseline-11接入正式共同任务、机制、ChIP及研究增补。** 指定v0.9.1/当前v0.10链接有效，原网站/上传正文与HEAD一致，网页索引10链接有效；文档检查首个marker不匹配失败保留，修正包装器通过。本段补充实际结果后重新绑定manifest并复核，最终以最新审计`manifest_sha256`与真实清单匹配为准。

### 下一轮从哪里接

1. 先读本节 → `docs/research_followup_v1/README.md` → `docs/implementation_records/FORMAL_FOLLOWUP_CONTINUATION.md` → `docs/paper_cn_v4/README.md`。用户指定的历史v0.9.1入口仍为[`docs/paper_cn_v3/README.md`](docs/paper_cn_v3/README.md)。下方准备阶段的0调用/未拟合仅对应历史时点。
2. 核对`research/results/current_manifest.json`与`w00_baseline/current_audit.json`的manifest hash，及各正式目录的`files_manifest.json`；保存结果复核用增补README中的命令，无需重跑模型。主机真实UTC保留，不修改旧日志日期。
3. 若继续论文整合，从v0.10主稿和4页研究增补新建下一稿；将A549“不可估计”、ChIP“坐标核实／非差异占据”、37超时及开发任务边界一并纳入方法、结果和讨论。新版本另导出并核对图表，不覆盖历史稿。
4. 若继续新研究，另冻结输入、脚本和输出目录；新推理先按`research/common_performance/restore_formal_runtime.py`恢复同hash模型/runtime，ellmer固定0.5.0。不能将v4保存响应当新调用，不能降低候选过滤或把培养重复增加为独立供体。
5. 剩余科学验证为新供体、GR/rescue、位点及SPARCL1功能终点；第三方人员sign-off和真实稿件信息仍需真实材料。GitHub/外部上传继续暂停，负责人明确恢复后才执行。

**本次交接文档更新另用r14/baseline-12**：`docs/BioExplainR-development-delivery-0.4.0.9000-r14.zip`，完整性入口`research/results/w00_baseline/handoff-formal-docs-delivery-audit-result.json`。r13保留上述原hash及其当时验收范围；r14仅同步本次交接记录和索引，不新增研究成绩。最终状态以本次实际审计为准。

**r14逐成员核验通过：2,875成员、365,126,583bytes，SHA-256 `817bf7f2aa11a475909c0a6d054354c873ec12d78ca35df6abec38e66508f851`。** 三份文档已补齐做了/没做、失败位置和续接顺序；原网站修复/上传正文与HEAD逐字一致、v0.9.1/v0.10链接有效，适用语法与diff检查通过。根交接独立进入documentation清单；追加本条后重建manifest并复核current/historical，以最终真实输出为准。

## 历史交接：做了什么、没做什么（2026-10-09，共同任务比较／机制检验准备阶段）

**本轮仅完成准备和部分数据获取，尚无新的性能或机制统计结果。** 当前论文仍为 **v0.10**：[`docs/paper_cn_v4/README.md`](docs/paper_cn_v4/README.md)。用户提到的 **v0.9.1** 入口是 [`docs/paper_cn_v3/README.md`](docs/paper_cn_v3/README.md)，保留为历史图表正文修订稿；本轮未回退、未生成新版论文。执行日志按服务器真实 UTC 保存（显示 2026-10-08），本文会话日期为 2026-10-09，不改系统时钟或旧日志。

### 做了什么

|事项|实际完成内容|核对入口|
|---|---|---|
|现状核对|阅读共同任务 runner、冻结基准、六工具来源及既有机制方案；确认当前系统库无 BioExplainR/iSEE/SCassist/ellmer/GPTCelltype 安装、无模型密钥变量或 Ollama/llama-server；历史安装/传输 pass 不能当当前实测|本轮终端输出；`research/results/related_tools/`仅为旧记录|
|共同任务方案|保存 **24 任务×5 整数 facts×3 重复**方案：airway/pasilla、50/200行、α=.01/.05/.10与lfc=0/1；比较 BioExplainR离线、base R、ellmer直接读表、ellmer读facts和BioExplainR客户端读同facts；预定错误分母、计时、tokens和任务级bootstrap|`research/common_performance/PROTOCOL.md`；**研究输入与runner尚未冻结/实现**|
|比较依赖|在独立 `/tmp/opencode/common-performance-R-library` 成功安装并实际载入 **ellmer 0.5.0** 及其依赖；系统sudo因no-new-privileges失败，改为下载/解包libcurl开发deb并本地链接现有libcurl，不改系统R库|`performance-comparator-install-final.*`、checkpoint中的`comparator_session.txt`|
|本地模型／运行时|实际取得 llama.cpp **b11429** CPU归档（17,693,462bytes）及 Qwen2.5-1.5B-Instruct **Q4_K_M**（1,117,320,736bytes），checkpoint重新计算SHA-256与上游值一致；只下载/解包，**未启动或推理**|`research/results/common_performance_checkpoint_v1/checkpoint.json`；实体在`/tmp/opencode/common-performance-runtime/`|
|机制方案|保存SPARCL1固定候选方案：GSE229084 GR降解KH-103／MIF／Cort113的预定差中差与Holm；GSE95632 ASM GR/RNAPII峰窗口、控制与assembly核验规则|`research/discovery/MECHANISM_PROTOCOL.md`；`discovery_mechanism_v1/frozen_protocol.json`|
|部分干预输入|取得 **5 项**可核对输入：GSE229084样本元数据／series／geneCounts、GSE95632样本元数据、Gazorpak 2023原文XML；geneCounts **2,524,990bytes** SHA-256 `db961e988dfe8466d6a2426be60f2ec8976698648f48c1b52653fa65ed5ae466`，gzip全读CRC通过；冻结方案早于计数下载|`research/results/discovery_mechanism_v1/input_manifest.json`|
|真实进度快照|重新核对模型/runtime hash、ellmer载入、机制protocol及5输入hash；记录`preparation_partial`、0模型调用、0性能评分、未拟合；SCassist半包与失败日志保留|`common_performance_checkpoint_v1/`、`w00_baseline/followup-checkpoint-capture.*`|
|交接归档|三份指定文档均同步已做/未做；原v0.8实施及上传段与HEAD逐字一致，v0.9.1/当前v0.10链接有效，修改Python语法检查通过；**r12逐成员核验pass，1,386成员、205,362,776bytes**|`followup-handoff-*`、`followup-delivery-audit-result.json`|

### 没做什么／未完成／阻塞

- **共同任务尚未运行**：没有新准确率、覆盖率、耗时、tokens、成本、置信区间或排名；runner、任务输入/参考真值/顺序冻结、正式模型服务、warm-up、全部重复、评分和Python独立复核均未完成。24任务方案是计划，不是已执行规模。
- **六工具全面性能排名未完成**：四个专属工具不原生输出差异表五整数，方案拟记录`not_applicable`，尚未形成实测适用性表；不得将不适用当错误/性能0。iSEE/GPTCelltype/SCassist/GeneAgent本轮未安装或运行；只有ellmer载入检查成功。
- **runtime准备未结束**：GitHub直接下载超时、API下载续传成功；Hugging Face连接超时，Qwen通过ModelScope取得且hash一致。SCassist源码下载先HTTP415、修正Accept后再次获取时被中断，现有19,243,008bytes归档gzip不完整，不能安装；GPTCelltype/GeneAgent源码未取得。`runtime_manifest.json`未生成，`performance-runtime-acquire-final.txt`为空且无完成JSON，不能标pass。新日志须用新label，旧半包不能当完整下载。
- **机制统计未做**：未读取SPARCL1候选表达行、未完成样本/处理映射、filterByExpr、TMM/voom/WLS模型、三交互Holm或独立数值复核；没有新机制正/负结论。GSE229084为**A549癌上皮细胞系**，不是ASM或独立患者。
- **ChIP输入未完成**：Sasse 2017 `PMC5576583/fullTextXML`返回HTTP500；未取得峰文件。GSE95632公开人HASM2样本metadata却写 **mm9**，assembly尚未核实，当前`unverified`；不得猜hg19做基因窗口定位。浏览器查阅的原文说明不是已保存XML/峰的替代。
- **冻结后脚本变更有记录**：初次下载超时后`prepare_mechanism.py`增加`--resume`与逐文件输入清单，当前script hash与原freeze不同；保留初始freeze，并在checkpoint记录修订。下一轮分析脚本必须另冻结，不倒改原freeze。
- **未开展湿实验**：新供体、GR/CEBPD rescue、位点reporter/CRISPR、SPARCL1干预、qPCR/蛋白/基质/功能/临床终点仍未做；公开干预重分析不能冒充新实验或完整机制证明。
- **稿件／软件／外部状态**：本轮未改R包功能、未重跑testthat/build/check/Shiny/HTTP/bwrap/API、未重导出论文/图表、未新模型/专家/用户评分。GitHub继续暂停；无新提交、推送、release、DOI或外部上传，#45–47仍只有v0.8。

### 下一轮从哪里接

1. 先读本汇总、`common_performance/PROTOCOL.md`、`MECHANISM_PROTOCOL.md`及`common_performance_checkpoint_v1/checkpoint.json`。保留v0.10现稿和r1–r11；本次交接另用 **r12**，完整性入口`research/results/w00_baseline/followup-delivery-audit-result.json`，索引baseline-10，最终状态以实际审计为准。
2. 模型文件在临时目录，不随ZIP保存；checkpoint保留大小/hash，恢复用`setup_runtime.py`并核对相同hash。补齐源码半包、完成runtime manifest、实现runner及独立评分器，再冻结24任务输入与脚本后执行；不引用历史模型输出作本轮推理。
3. 保留已获取5输入，下载续接使用`python3 research/discovery/prepare_mechanism.py research/results/discovery_mechanism_v1 --resume`；当前缺原文XML，需记录替代来源与hash。先核实全部处理组/批次及ChIP assembly，再冻结拟合/峰脚本；不可估计或阴性如实保留。
4. 新分析使用新目录/label，旧未完成下载、失败和中断日志不覆盖；原2,905保护文件清单不改写。恢复GitHub或外部上传仍需负责人明确要求。

**本次交接包**：`docs/BioExplainR-development-delivery-0.4.0.9000-r12.zip`，SHA-256 **`93b7263b017ae52f7dc91b42ee1d1b52f8a250c2292221bd52253d65bbe54784`**。r12包含准备方案、已获取5输入和状态/失败记录，排除本轮26MB不完整metadata与临时模型/runtime/库；r11仍按原hash保留。baseline-10 **current/historical均pass，2,905原保护文件逐hash不变**，本轮分组明确标为`preparation_partial`，文件审计通过不表示研究完成。本根交接独立进入documentation清单；本条追加审计结果后重新生成清单并复核，以最新`current_audit.json`的`manifest_sha256`为准。

## 上轮已完成汇总（研究 2026-10-08，r11交付续接 2026-10-09）

**唯一当前论文入口：`docs/paper_cn_v4/README.md`。当前稿 v0.10：12 页主稿（3 主图、1 内嵌表、32 参考文献）＋18 页补充（8 补充图、补充方法 S1–S13、外置表 S1–S13）。** v0.9.1（`docs/paper_cn_v3/`）与 v0.9（`docs/paper_cn_v2/`）、v0.8（`docs/paper_cn_v1/`，历史稿）均保留。

### 已完成

|事项|实际完成内容|核对入口|
|---|---|---|
|SPARCL1 环境依赖性检验|固定方案后在 GSE146017 全 HTSeq 计数上拟合 `~ donor + kd * bud * tnf`（4 供体/31 文库/27,409 特征），三项预定 SPARCL1 交互同一 Holm family：**−1.246（Holm P=0.289）、−0.142（P=1）、−0.136（P=1）全部未通过**；四供体规范化计数响应在 NT/无 TNF 条件全为正|`research/results/discovery_context_v1/`（`model_results.csv`、`donor_sensitivity.csv`、`audit.json`）|
|多供体响应重分析|从原论文 Supplement Table E1 的 Cell Line 恢复真实配对（GEO donor 字段逐文库唯一，不可用）；GSE94335 **7/7 非哮喘、9/9 致死性哮喘供体布地奈德配对全部上调**，log2(TPM+1) 差 +3.514（Holm P=3.89e-4）与 +3.598（P=1.92e-8），组间差 +0.084（Holm P=0.859；11,440 组枚举 P=0.844）不支持病组差异|`research/results/discovery_donors_v1/`（`results.csv`、`donor_effects.csv`、`r_numeric_checks.csv`）|
|阴性/边界如实披露|28793/28796 映射与病组冲突在候选检验前按设计排除；GSE94335/GSE146017 至少 3 个培养细胞系 ID 相同（N010912、N051911、N061311）故不合并供体数；SPARCL1 低表达 baseMean 8.175；原文核对显示 Himes 2014 表 1、Kan 2019 表 3 已报告该响应，正文不主张首次发现|`DONOR_DESIGN_AMENDMENT.md`、`scientific_ledger.json`、v0.10 正文 2.6/3.5/4.2|
|独立实现复核|Python 从原计数复核候选测量、R size factor、Wald P/CI、BH/Holm 与全部供体差中差；R 从原 TPM/原表重新实现配对 t、Welch、CI、128/512 符号翻转与 11,440 组枚举、Holm，并逐样本比对原表 Cell Line/病组/处理|`audit_context.py`、`audit_donors.R` 及其输出 `audit.json`/`r_numeric_checks.csv`|
|软件衔接|BioExplainR 生成候选、因子实验、多供体响应的三上下文项目与中英文报告，显式保存阴性交互、单位与假设来源；本轮 0 次在线模型调用|`discovery_context_v1/followup_report_zh_v2.html`、`report_workflow_v2.json`|
|论文 v0.10|新增方法 2.5/2.6、结果 3.5、讨论 4.1/4.2、图 3（四联：配对测量/效应与组差/四条件效应/三交互）、补充表 S11–S13；正文 **25 项**图表（3 主图＋1 主表＋8 补充图＋13 补充表）对应核验通过；正文相对 v0.8 缩减 47.39%。10-09 纠正原交接“24 项”误写，实际清单无缺项|`docs/paper_cn_v4/`（`audit.json`、`figure_table_links.json`）|
|导出与网页核验|Word/PDF/HTML 导出，PDF 嵌入矢量图；网页 1440/390 双视口主稿 3 图 1 表、补充 8 图 0 表，无横溢出/JS 异常；图 2/图 3 文字边界与重叠核验通过|`export_report.json`、`research/results/w00_baseline/revision-biology-browser/`|
|输入可复现|GSE146017 计数与 GSE94335 TPM 经分段 HTTP Range 下载并逐段校验 Content-Range/Last-Modified，gzip CRC 通过；TPM 121,575,832 bytes SHA-256 `30ebc92d…189277f`|`download_ranges.py`、`range_download.json`、`input_manifest.json`|
|10-09 交付续接|生成 r11：**1,355 成员、202,742,054 bytes**，逐成员 bytes/SHA-256/当前树一致；纳入 v0.10、两个后续分析的完整模型/数值/报告/配对原表与复现工具。原始 TPM 在包内 `excluded_inputs` 保存精确恢复入口|`research/results/w00_baseline/biology-delivery-audit-result.json`|
|10-09 适用核验|Python 语法、5 项 current 审计失败探针、2 项离线恢复探针、论文 25 项图表及内容/几何审计、网页索引 7 链接均通过；旧论文 README 和根/网页/复现入口同步当前 v0.10|`biology-handoff-*`；未重跑 R 软件或研究拟合|
|最终 current/historical|**两者均 pass**；当前稿 102 文件、因子干预 36 文件、多供体 29 文件均接入索引；**2,905 原保护文件逐 hash 不变**，r11 全部成员与当前树一致|`current_audit.json`、`historical_audit.json`；baseline-9|

### 未完成／未开展／按要求暂停

- **GitHub 仍暂停**：未建远程仓库、未推送、无公开 release/正式网址/DOI；Zenodo 未配置。此前建仓 403 为历史真实记录。
- **v0.9/v0.9.1/v0.10 均未对外上传**：#45/#46/#47 仍只对应 v0.8；旧公开副本未替换或撤回。
- **生物学结论边界**：本轮支持“所测致死性哮喘来源 ASM 保留 SPARCL1 表达响应”这一陈述；不支持炎症抑制、CEBPD 依赖、组间响应差、蛋白/功能/临床效应，也未做首次发现主张。组差与交互阴性不证明等效。
- **未做湿实验与机制验证**：新增独立供体 BUD×TNFα 配对实验、CEBPD rescue、GR 干预、SPARCL1 干预、qPCR/蛋白/基质终点均未开展；GSE146017 仅 4 供体、GSE34313 仅 1 个细胞系。
- **未做工具性能排名**：表 1 仍为文档能力比较，不能声称速度/准确率/成本优越。
- **本轮未重跑软件与在线研究**：未改 R 包功能，未重跑 testthat/build/check、Shiny、HTTP/bwrap/历史 API、airway/miniACC 案例或在线模型；历史 677 项（676 pass/1 skip）与 check OK 仅按各自日志引用。原始计数模型的 dispersion 由 DESeq2 估计，本轮未做替代敏感性。
- **人员与稿件信息未完成**：无新独立专家评分；用户体验/学习增益仍 deferred。真实作者、单位、通讯、CRediT、基金、利益冲突、适用伦理待负责人提供；最终人工图稿审阅与第三方科学/代码 sign-off 未完成。

### 当前交付、保护与续接

- 最新本地交付 **`docs/BioExplainR-development-delivery-0.4.0.9000-r11.zip`**：1,355 成员、202,742,054 bytes，SHA-256 **`2aabcc9e7160410b0d058ebc5c75bc57cdc7159290835cb5bed260eca8228478`**；完整性结果 `research/results/w00_baseline/biology-delivery-audit-result.json`。包内 `excluded_inputs` 保存原始 TPM 的 121,575,832 bytes、SHA-256 `30ebc92ddbd40bf4dedab57d05b46ba10a763c0130c89f6154862b351189277f`、URL/下载命令；`--preserve-report` 恢复缺失输入时不改写历史下载报告。完整工作区 manifest 仍核对原输入。
- current manifest 使用 **development-baseline-9**，current/historical 均已通过；本根交接追加结果后重新生成清单并完成最终 hash 绑定，状态以 `current_audit.json` 与 `historical_audit.json` 为准，且 current 的 `manifest_sha256` 必须匹配实际清单。根交接不进入 ZIP，独立进入 documentation 清单；原 2,905 保护文件与 r1–r10 保留。当前工作树含未提交修订，禁止 reset/clean 覆盖。
- 阅读顺序：本汇总 → `docs/paper_cn_v4/README.md` → `research/discovery/CONTEXT_PROTOCOL.md`、`DONOR_PROTOCOL.md`、`DONOR_DESIGN_AMENDMENT.md` → `research/results/discovery_context_v1/scientific_ledger.json`；需要 v0.9 发布准备读 `PAPER_RELEASE_CONTINUATION.md`，需要 v0.8 网站/上传细节读 `PAPER_CN_CONTINUATION.md`。
- 下一轮以当前 v0.10 文稿与两个新结果目录继续。原始分析已封存；新科学分析/拟合使用新目录与冻结方案，不能把旧版本/日志/hash 当新结果。共同任务性能比较仍未完成；人工、人员/机制验证与发布状态如有真实进展再追加记录，恢复 GitHub 须负责人再次明确要求。

## 历史交接汇总：做了什么、没做什么（2026-10-08）

**（以下为 v0.9.1 阶段记录，当前稿已由上条 v0.10 取代；保留历史范围。）唯一当时论文入口为 `docs/paper_cn_v3/README.md`，v0.9.1 为 10 页主稿＋16 页补充。** 用户指定的 `docs/implementation_records/PAPER_CN_CONTINUATION.md` 和 `docs/paper_cn_v1/README.md` 已补入口；其中 v0.8 的网站修复与上传细节属于历史实测记录，不代表新稿已上传。

### 已完成

|事项|实际完成内容|核对入口|
|---|---|---|
|工具比较|iSEE、SCassist、GeneAgent、ellmer、GPTCelltype与BioExplainR六工具任务/内置能力表；正文方法2.3说明维度，结果3.1说明比较结果及集成审查优势|`paper_cn_v3/tables/Table_1.{csv,xlsx}`、主稿、`research/paper_cn_revision/tool_comparison.json`|
|正文压缩|聚焦完整事实、科学范围/独立单位、可定位核对、项目溯源四贡献，10节详细方法移补充；补齐图表说明后的正文11,279→5,576非空白字符，缩减50.56%|`paper_cn_v3/compression.json`|
|所有图表的正文叙述|逐项检查2主图＋8补充图、1主表＋10补充表，共21项；补齐引出、图表号、结果/设计和解释，四联图panel对应说明；修正补充图注旧主表号|`paper_cn_v3/FIGURE_TABLE_REVIEW.md`、`figure_table_links.json`、`audit.json`|
|排版与导出|Word标题继承编号关闭，正确CRISPLD2与上标负号核验；当前Word/PDF/HTML已导出，正式PDF嵌入原矢量图；引用/数据表/文字边界核验通过|`paper_cn_v3/export_report.json`、`audit.json`|
|发现案例|airway固定规则选SPARCL1后读取GSE34313外部表达；24h效应+4.132、WelchP1.55e-4、置换P1/35，Python/R独立12项一致；输入、方案、测量、context/project/双语报告/hash保留|`research/discovery/`、`research/results/discovery_sparcl1_v1/`|
|网页核验|v0.9.1网页1440/390视口主稿2图1表、补充8图0表均加载，无横溢出/JS异常|`w00_baseline/revision-links-browser/summary.json`|
|软件与网站既有修复|v0.8阶段完成Shiny项目分派、覆盖/方向展示、同项目报告及Cairo PDF下载；v0.9阶段源码677项（676pass/1skip）与包checkOK已实际运行|`PAPER_CN_CONTINUATION.md`、`revision-source.*`、`revision-package-check.*`|
|本地归档|MIT、CITATION.cff、NEWS、网页源和归档状态已准备；本地提交dbd7075/545bb89存在，GitHub暂停后v0.9.1及本次交接改动未新提交|`docs/RELEASE_ARCHIVE.md`、Git状态|

### 未完成／未开展／按要求暂停

- **GitHub现已暂停**：此前账号ouev5下创建BioExplainR仓库的GraphQL/REST均权限403，未建远程仓库、未推送、未公开release；用户随后要求先不要发GitHub，覆盖前次发布授权，不再使用会话中令牌。正式公开网址及DOI仍未建立；Zenodo未配置/未签发。
- **新版未对外上传**：v0.9/v0.9.1及后续本地交付包未上传指定外部服务；#45/#46/#47只对应原v0.8 Word/PDF/附件，不是当前稿链接。旧公开副本未替换或撤回。
- **工具性能排名未做**：表1为原论文/官方文档能力比较，未完成六工具相同任务、相同数据和预算下的准确率/速度/成本比较，不能据表1声称全面性能优越。
- **发现案例未完成独立供体或机制验证**：GSE34313微阵列来自单个HASM1细胞系，属于外部培养实验初步重复；未核实与airway逐供体无重叠，未做新增供体qPCR/蛋白、GR或SPARCL1干预、临床/因果验证，不声称首次发现。
- **人员与最终稿件信息未完成**：没有新独立专家评分；用户体验/学习增益仍deferred。真实作者、单位、通讯、CRediT、基金、利益冲突和适用伦理信息仍待负责人提供；最终人工图稿审阅和第三方科学/代码sign-off未完成。
- **本轮没有重跑软件或在线研究**：v0.9.1与本次交接只改文稿/工具/记录；未重跑上游分析、在线模型、Shiny应用、HTTP/bwrap、历史API专项或R源码/build/check。其历史pass只对应各自版本/范围。远程CI/fresh OS/完整依赖锁定也未完成。

### 当前交付、保护与续接

- r9为图表正文修订时的已验收包：1,073成员、135,296,414bytes，SHA-256`c1b4ae29ebef0d8dd92292b28faafdddf810d90cdbae7e64ccaa4a9b678c19f8`；交接文字更新使用 r10，1,073成员、135,298,936bytes，SHA-256`53e45cfa8777618ef055cda5b4f61047378295491317944023a36d2a4ab6258f`，完整性入口`research/results/w00_baseline/handoff-delivery-audit-result.json`。r1–r9均保留。本根交接不进入ZIP，另由documentation清单核验。
- 原2,905保护文件清单不改写；当时重建current manifest并执行current/historical审计。当前工作树含未提交修订，禁止reset/clean覆盖。
- 阅读顺序：本汇总→`docs/paper_cn_v3/README.md`→`FIGURE_TABLE_REVIEW.md`→`docs/implementation_records/FIGURE_TABLE_NARRATIVE_CONTINUATION.md`；需要v0.9发现/发布准备细节时读`PAPER_RELEASE_CONTINUATION.md`，需要v0.8网站/上传细节时读`PAPER_CN_CONTINUATION.md`。
- 下一轮以当前v0.9.1文稿继续；旧版本/日志/hash不能当新结果。人工、人员/机制验证和发布状态如有真实进展再追加记录，恢复GitHub须用户再次明确要求。

## 历史修订：v0.9.1 全部图表正文叙述（2026-10-08，已被 v0.10 取代）

用户最新要求：**先暂停GitHub，检查所有图表在正文是否有引出、结果及解释。** 当时稿为`docs/paper_cn_v3/`的**v0.9.1，10页主稿/16页补充**。逐项发现并补齐S1/S8缺引用、成组引用未逐图表展开、S7D修复结果、表1方法/结果；补充图注旧主表号统一为S编号。全部**10图/11表＝21项**在Markdown/Word/PDF参考文献前正文对应通过，网页1440/390通过。图表原件逐字节复用v0.9。正文仍较v0.8缩减50.56%。

先读`docs/paper_cn_v3/README.md`、`FIGURE_TABLE_REVIEW.md`和`docs/implementation_records/FIGURE_TABLE_NARRATIVE_CONTINUATION.md`；**当前稿请读`docs/paper_cn_v4/`。** 实际日志`revision-links-*`，最新本地交付r9/baseline-8，以最终current/historical hash核验为准。R软件和研究数值未改/未重跑，不把此前源码/check重新算本轮；原保护文件保留。**该轮不提交、不推送、不调用GitHub**；旧545bb89/dbd7075和403为历史记录。以下上一轮发布准备/v0.9信息按日期阅读。

## 历史续接：v0.9与发布准备（2026-10-08）

本轮已按用户要求完成中文**v0.9：9页主稿+16页独立补充**，六工具比較与SPARCL1固定候选/外部GEO培养实验。当前论文入口`docs/paper_cn_v2/README.md`，详细记录`docs/implementation_records/PAPER_RELEASE_CONTINUATION.md`。正文收束四贡献，较v0.8缩减65.75%；标题继承编号关闭，正确CRISPLD2及上标负号均已核验。

发现案例见`research/discovery/`、`research/results/discovery_sparcl1_v1/`：候选按发现集合排名固定后读取外部表达，24h主效应+4.132、WelchP1.55e-4、置换P1/35；Python与R独立12项一致。**外部为单个HASM1细胞系培养重复**，不声称独立供体/首次发现/因果机制。无新模型/专家/用户研究。

最新源码677项（676pass/1skip）和包checkOK；v0.9文稿/表/图/引用/hash/几何通过，双视口主稿2图1表、补充8图0表通过。新交付**r8**与baseline-7接入v0.9和外部案例；实际hash以`revision-delivery-audit-result.json`及最终current/historical audit为准。原2,905保护文件及旧r1–r7保留。

本地首个源码提交为 **`dbd7075`**（OpenCode执行身份，不冒充论文作者）；远程尚未配置。r8 **959成员、114,625,818bytes**，SHA-256 **`b639f263f0ede6bd365c2b941ea2f9ca1a52c5e6f29fdd5a758829626c05ce1b`**。暂存源码与r8常见凭据格式扫描均pass、0发现；外部PAT未写入文件。current/historical均pass，2,905原保护文件逐hash不变；本交接更新后重新manifest/audit，以最终manifest_sha256为准。

**已获本轮公开建仓库/提交/推送/release授权。** API账号为`ouev5`，拟建`BioExplainR`；提供令牌创建仓库GraphQL/REST均权限403，远程未创建/未推送/无release。正式网址与DOI未建立；`docs/RELEASE_ARCHIVE.md`记录阻塞和Zenodo需求，凭据不保存在任何文件。负责人需创建仓库或通过环境GH_TOKEN提供有效权限（勿聊天粘贴）。本地发布材料已准备，真实作者仍留位。

以下为上一轮v0.8/r7与历史记录，需按各自日期和版本阅读。

更新时间：2026-10-08。本轮已按用户要求完成中文论文v0.8、案例补充、PDF合图/外置表、工作台修复、指定服务公开上传及r7交付。**当前论文交接先读`docs/implementation_records/PAPER_CN_CONTINUATION.md`和`docs/paper_cn_v1/README.md`。** 此前“仔细检查”r6记录保留于REVIEW_CONTINUATION。

## 历史基线：v0.8阶段

- 工作目录 `/home/ubuntu/creatR`；历史软件/模型结果版本0.3.1；当前开发版**0.4.0.9000**，当前中文稿**v0.8，23页**，新目录`docs/paper_cn_v1/`；旧v0.7保留。
- Git无HEAD，项目文件仍未跟踪，是既有成果；不得reset/clean/删除。未提交/推送/release/DOI；本轮用户明确授权的新论文及图表附件已公开上传（#45/#46/#47），不得将这一授权扩大为发布其他材料。
- 当前 90 个导出函数，新增 `bio_validate_project_relations()`；10-08 历史 74 个 API 源码和真实安装包名称/位置参数顺序各74/74通过，非全部行为等价证明。English 默认，`language="zh"` 切中文。
- 模型解释入口默认完整 facts，超预算明确失败；旧 payload 位置参数保留 bounded 兼容。大型矩阵、原始图像/坐标与样本映射留本地。
- Shiny 监听 127.0.0.1；不同会话工作区隔离但共享 R/文件/网络权限。独立 bwrap 工程探针不能为 Shiny 宣称多租户沙箱。
- W00 done；W01–W09/W12 ready_for_review；W10-A/B 已有 miniACC 公开开发案例，W10-C/W11 blocked_external；W13 in_progress。工程检查不能代替独立科学/人员/伦理/发布验收。
- 用户已授权执行者自行选择公开测试数据并保留结果；用户体验/学习增益研究 W11-U 为 deferred，专家评价等软件、案例及评价材料准备完成后再开展。此决定已同步伦理、任务卡、用户事项和交付文档。

## 前轮基线修复与验收（2026-10-05）

完整记录：`docs/implementation_records/CONTINUATION_REVIEW.md`。核心修复包括 context identity、legacy missing、payload/list/URL/private 字段、typed aggregate/type/scope/unit、evidence pair、sample map、MAE/Spatial、docking、project/diagnose prompt、W09 artifact/replay/score 与 Shiny 详情。新修复不能倒写为 0.3.1 历史功能。

本轮实际增加：auto evidence 回归修复、usage token 计数保留、公开证据 URL 结构化过滤、实际 HTTP bytes/hash 两协议验证、Shiny 浏览器与 bwrap 边界。

| 验收 | 实际结果 | `research/results/w00_baseline/` 入口 |
|---|---|---|
| 源码 | **648 项：647 pass、1 skip、0 failed/error/warning** | `acceptance-source.txt/json` |
| 包 | build 成功；check **Status: OK**，0 ERROR/WARNING/NOTE | `acceptance-build.txt/json`、`acceptance-package-check.txt/json` |
| 历史 API | 74/74 名称/位置参数顺序通过，非全部行为等价证明 | `acceptance-legacy-api-result.json` |
| 真实上游依赖 | MAE 1.28.0、SpatialExperiment 1.12.0 手算对象专项；全部 Suggests installed | `continuation-optional-dependencies.csv`、tests |
| HTTP | loopback OpenAI/Anthropic 实际 body hash/bytes、极小 p/PCA/null、usage；503 retry=2、401=1 | `acceptance-http-result.json` |
| Shiny 浏览器 | payload/typed/evidence/manifest、HTML 转义、英中、报告下载、MAE、双会话；1440/390 无溢出 | `acceptance-shiny-browser/summary.json` |
| 安装包离线 | 完整依赖与 Imports-only context→typed validation→project→HTML report | `acceptance-full-smoke/`、`continuation-core-*` |
| 隔离边界 | input readonly、越界写入拒绝、gold/home 未挂载、host listener 不可达、scratch report、资源限额与 timeout | `acceptance-sandbox-result.json` |
| contract/W09/W12 | 5 个正反例按预期接受/拒绝；3 个 W09 流程测试；W12 template | fixture/benchmark 前轮真实日志 |
| 稿件 | 38 refs、35 Figure PDF、13 主稿 Word/Excel 表、4 补充表；PDF 65/10 页；7 图/13 表双视口 | `continuation-submission-audit-result.json`、paper browser |
| current/historical | 当前动态规模和历史 54/225 独立审计 pass；2,905 原文件 hash 不变 | `current_audit.json`、`historical_audit.json` |

唯一版本/结果入口`research/results/current_manifest.json`，当前为`development-baseline-6`。本轮采用`paper-cn-source`和`paper-cn-package-check`；source/package文件数、tar/ZIP/hash以manifest和`paper-cn-delivery-audit-result.json`为准。r6/r5结果分别保留为`review-delivery-audit-result.json`/`continuation-delivery-audit-result.json`。

## 已完成的公开案例与工程完善（2026-10-07）

详细记录：`docs/implementation_records/PUBLIC_CASE_CONTINUATION.md`；研究方案、运行脚本和独立实现复核器位于 `research/multiomics/`。

- `R/sample-map.R`：重新校验已构造映射、拒绝重复/缺失 observed ID，追加 `primary_units` 参数；返回 modality coverage、pairwise intersection、完整/未测量病例数。映射合法的 pass 不表示全部模态齐全。
- `R/adapters-multiomics.R`：MAE facts 接入覆盖/交集计数，原始样本映射和完整病例 ID 保留本地。
- 新增 `R/project-relations.R` / `bio_validate_project_relations()`：核对 dataset/comparison/species/tissue/sample_level、numerator/denominator、显式 feature_id 与有限非零效应正负号；支持 exact token 路径。未知或零效应不自动通过；不把符号一致当成显著性、因果或独立证据。
- `R/project.R` / `R/report.R`：方向关系表自动检查，项目报告和模型 payload 展示 findings/覆盖统计。NAMESPACE/man 已由 roxygen 更新。
- 新增 `tests/testthat/test-project-relations.R`，29 项针对性检查；README、DATA_CONTRACTS、MIGRATION、专家评价说明已更新。
- miniACC 实际运行一次，输出新目录且拒绝覆盖；原输入、映射、分期、配对长表、统计结果、context/project RDS、中英文 HTML、版本信息及逐文件 hash 已保存。具体数字见下节，不冒充独立研究。

| 2026-10-07 实际验收 | 结果 | 入口 |
|---|---|---|
| 最新源码 | **677 项：676 pass、1 skip、0 failed/error/warning** | `research/results/w00_baseline/improvement-source.txt/json` |
| 最新 tar 构建/检查 | build 成功；`Status: OK`，0 ERROR/WARNING/NOTE | `improvement-build.txt/json`、`improvement-package-check.txt/json` |
| miniACC Python 复核 | 23 个文件 hash，66 个效应、方向、覆盖及 BH 重算通过；未独立重算 Wilcoxon 原始 p 值 | `improvement-miniacc-audit.txt/json`、`research/multiomics/audit_miniacc.py` |
| current/historical | 均 pass；current 已使用 677 项新日志，2,905 个原文件 hash 保持不变 | `current_audit.json`、`historical_audit.json` |
| r5 开发审阅包 | 464 成员核验通过，包含 miniACC 24 文件（含 manifest）及复现脚本 | `continuation-delivery-audit-result.json` |
| Python 语法 | miniACC audit、manage_baseline、package_submission 编译通过 | 当次终端输出，无单独新增日志 |

上述完成项不包括新 HTTP/Shiny/bwrap 验收、安装后新增接口专项 smoke 或新版旧 API 专项；这些只有 10-05 前轮记录，不能算作新增功能的全部验收。

## “仔细检查”续接完成（2026-10-08）

前一会话止于静态审阅和手工探针，拟修复 patch 未应用。本轮已完成对应问题修复与适用验收，完整记录：`docs/implementation_records/REVIEW_CONTINUATION.md`。

- 过期 r3/current 入口改为 r6，保留历史日期；数据集 hash 改为 v1 原输入 RDS 的真实 SHA-256。执行者选择数据、专家后置、用户研究 deferred 已同步，交付边界明确已有开发案例但无新独立科学/专家评价。
- `run_miniacc.R` 增加 `--installed`；新 manifest v2 使用运行目录相对文件名，保存模式/版本/包路径。真实 tar 安装至 `/tmp/opencode/bioexplainr-install-review/` 后完整运行，输出 `research/results/miniacc_installed_review/`；原 v1 不覆盖。
- `audit_miniacc.py` 支持旧/新 manifest 异地回读且只访问给定目录，要求全部23成员、唯一主键和完整覆盖/交集/测量/关系/findings/反例集合，拒绝越界/symlink/缺失/重复；重算分组、66效应、方向、BH及摘要。安装包重跑8个核心表与v1逐字节一致。
- `tools/offline-smoke.R` 增加安装后覆盖/完整/未测量病例、含点号 exact-token 的 opposite 关系、错误方向拒绝和HTML展示。API工具支持安装模式；环境采集增加唯一prefix，打包及采集拒绝覆盖旧证据。
- r6补齐 improvement/review日志、公开案例/本轮记录、安装案例和manifest/审计工具。外部ZIP结果使用新 `review-delivery-audit-result.json`；r5和continuation审计保留。

| 10-08 实际验收 | 结果 | `research/results/w00_baseline/`入口 |
|---|---|---|
| 源码/build/check | **677项：676 pass、1 skip、0 failed/error/warning**；build成功；check **Status: OK**，0 ERROR/WARNING/NOTE | `review-source.*`、`review-build.*`、`review-package-check.*`、`review-00check.log` |
| 历史API/实际接口 | 源码、安装包各74/74名称/位置参数；90个安装导出函数 | `review-legacy-api*-result.json`、`review-api-inventory.csv` |
| 完整/Imports-only安装 | context→typed→覆盖/方向project→HTML均通过；全部Suggests可加载 | `review-full-smoke/`、`review-core-*`、`review-isolation-result.json`、`review-optional-dependencies.csv` |
| miniACC数值/边界 | v1和安装包结果各23文件hash、66效应/方向/覆盖/BH通过；**16 tests pass**，包括异地/拒绝覆盖及重写hash后的损坏拒绝 | `review-miniacc-audit.*`、`review-miniacc-installed-audit.*`、`review-miniacc-boundaries-final.*` |
| 契约/W09/W12 | 5契约正反例符合预期，3个W09测试通过；W12仍1行template | `review-contracts.*`、`review-benchmark.*`、`review-w12.*` |
| HTTP/Shiny/bwrap | 两协议实际body hash/bytes/精度/usage/retry/401；Shiny英中/下载/转义/MAE/双会话/1440与390；只读/越界/gold/home/network/scratch/限额/timeout通过 | `review-http-result.json`、`review-shiny-browser/summary.json`、`review-sandbox-result.json`、`review-bwrap.*` |
| Python/审计反例 | 修改工具语法通过；3个current audit损坏探针通过 | `review-python-syntax-final.*`、`review-audit-probes-final.*` |
| r6/current/historical | r6 **598成员**完整性通过；current/historical均pass，**2,905原文件hash不变**；current接入两份miniACC数值复核 | `review-delivery-audit-result.json`、`current_audit.json`、`historical_audit.json` |

本轮未改源码包功能或重导出主稿/图表；工程记录与研究复核已更新。本交接不进入ZIP，更新后重建manifest并再次current/historical审计，以最终审计记录的manifest_sha256为准。源码/文档后续再变更会使清单或ZIP当前文件比对过期，不可沿用本次pass。

## 已保存研究结果

2026-10-07 新增公开开发案例：`research/results/miniacc_development_v1/`。TCGA-ACC `miniACC`（MultiAssayExperiment 1.28.0）92 个病例、5 个模态；43 个病例五模态齐全；RNA/蛋白配对且分期已知 46 个（early 28、late 18）；33 个共有特征中 18 同向、15 反向；RNA BH<0.05 为 3、蛋白为 0。方案、源对象、sampleMap、输入长表、结果、双语报告和 hash 清单均保留；Python 独立实现复核通过。此为开发案例，不是独立 test/gold、专家评测或生物学泛化结果。用户体验/学习增益研究按负责人决定 deferred；专家评价待全部功能和材料准备完成。

10-08安装包同案例重跑保存在 `research/results/miniacc_installed_review/`，主要数字与8个核心表一致；这是同一开发来源工程复现，不增加独立样本量。Python未独立重算Wilcoxon原始p值，也未从RDS解码原始矩阵。

没有重跑在线 provider 或新增专家/用户评分。以下是 0.3.1 保存记录，当前仅离线核对：

- 5 个公开数据对象入口：airway、PBMC3k、pasilla、ALL、bladderbatch，保存测试 5/5 pass。
- pasilla 六组阈值 30/30 独立数值 facts 匹配。
- 主机制实验：120 程序生成 cases、480 unique target facts、3 输入×3 重复；1,080 requests、4,320 scores。direct_bounded 437/1,440（覆盖516/1,440、已回答437/516）；facts_only/evidence 各1,440/1,440。不是独立生物学泛化准确率。
- 双模型 StepFun step-5-preview、DeepSeek deepseek-flash：各120请求、480/480匹配；600 case-method 行包含 deterministic、agent not_configured、replay missing，不能合并为 API 分母。
- 相近工具为入口兼容检查；btw 未安装。外部评价只核对匿名聚合一致性，原评分/人员/伦理仍待负责人核实。
- 历史人工聚合：720维度评分、150功能评分，均分1.751/2、91.98/100，144/150有用；不是正式用户任务/ICC/SUS或学习增益。

## 当前论文与写作网站问题（2026-10-08本轮）

- 中文论文入口：`docs/paper_cn_v1/BioExplainR-中文论文-v0.8.{docx,pdf,html}`，文字源`manuscript.md`。PDF23页，29参考文献，方法10小节，结果按公开案例/机制/工程组织；作者、单位、通讯、基金等留位。
- **8个四联PDF合图/32个独立panel PDF**在`figures/composites/`和`figures/panels/`，框架图含原创矢量图标。正式论文附录直接嵌入合图PDF矢量内容；Word/HTML用预览PNG，图8截图为位图素材。
- **9份XLSX+9份CSV**在`tables/`，论文嵌入数据表为0；正文引用及附录B保留表题/表注/来源。文末附录C预留专家、用户体验、学习效果和独立验证，**新版不写旧专家/用户评分**。
- 新增`research/results/paper_cn_cases_v1/`：airway九阈值×五facts **45/45**源表匹配，Python另行重算45项；**15/15**期望状态匹配（8pass/5fail/1partial/1unverified）。真实对象回读、手算fixture、controlled mutation逐行标明，不作独立test/gold。
- 工作台`bio_project`专用dispatch修复，展示真实miniACC项目摘要/依赖/覆盖/交集/完整和未测量病例/方向findings；下载同一项目HTML，原始map/病例ID不展示。绘图页新增Cairo矢量PDF下载，失败清空旧图与下载入口；英中文案完善。
- 原3888工作台进程无连接时重载当前源码，保持127.0.0.1/local/空启动工作区；实际3888浏览器再次验证项目和PDF下载。新进程PID以`paper-cn-workbench-reload-result.json`为准。
- 本轮源码**677项：676pass、1skip、0失败/错误/警告**；build成功，check **Status: OK**；完整依赖及Imports-only安装离线通过；Shiny **7组**通过，论文HTML桌面/移动8图0表无溢出；40 Figure PDF文字边界/重叠、CSV/XLSX/hash/引用审计pass，3current损坏探针pass。
- 工具：`research/paper_cn/`；当前稿自动审计`docs/paper_cn_v1/audit.json`，本轮日志`w00_baseline/paper-cn-*`。旧导出增加legacy_layout默认TRUE；新稿关闭旧横向表分页。原稿不覆盖。
- 首次PDF下载探针因动态下载href尚未绑定而读到HTML，失败日志保留；等待href后通过。图稿发现并修复框架卡片重叠、注释重叠及标签越界；模型无PDF/图片直接视觉能力，本轮不等同人工图稿审阅。
- 本轮无在线模型、专家、用户研究；HTTP/bwrap/74API专项仍用此前10-08review记录，没有重新算成本轮新结果。

### 新论文公开上传（用户本轮明确授权）

|材料|服务编号/公开下载|本地路径|
|---|---|---|
|Word可编辑稿|**#45** http://62.234.106.117:8003/api/download/45|`docs/paper_cn_v1/BioExplainR-中文论文-v0.8.docx`|
|PDF正式稿|**#46** http://62.234.106.117:8003/api/download/46|`docs/paper_cn_v1/BioExplainR-中文论文-v0.8.pdf`|
|论文及图表附件|**#47** http://62.234.106.117:8003/api/download/47|`docs/BioExplainR-中文论文-v0.8-图表附件.zip`|

上传为is_public=1，HTTP200/ok:true；3文件的download/file共6匿名回读HTTP200且bytes/SHA-256与本地一致。大小/hash/UTC见`paper-cn-upload-result.json`及PAPER_CN_CONTINUATION。凭据不写入源码、日志、manifest或交接。论文附件ZIP76成员，仅含新稿/图表，不是r7源码包。

## 交付与历史保护

- 最近已核验开发审阅包：`docs/BioExplainR-development-delivery-0.4.0.9000-r7.zip`，**787成员**；含中文v0.8、图表、15场景、公开真实RDS输入和本轮工具/日志。75,313,559bytes，SHA-256`59993a682dd0f0f9cbe51cfe582234f5b846b5df748b40ff5f33daf0f2953581`；逐成员见`paper-cn-delivery-audit-result.json`。r1–r6保留，r6的598成员验收对应修改前树。
- 当前 tar：`BioExplainR_0.4.0.9000.tar.gz`，已 build/check；历史 `BioExplainR_0.3.1.tar.gz` 保留。
- 原主稿/补充及`docs/submission_assets/`保留历史记录；当前稿/图表以`docs/paper_cn_v1/`为准，历史图表35PDF/13Excel/2,770记录ZIP未改写。
- `docs/BioExplainR-user-guide.docx` 是历史0.3.1指南；新接口以 `DEVELOPMENT_DELIVERY.md`、`DATA_CONTRACTS.md`、`MIGRATION.md` 和安装帮助为准。
- 旧 `BioExplainR-submission-bundle.zip` historical_stale；210成员、132当时内容变化、2旧路径缺失；`bundle_inspection.json` 保留旧包检查，不能更新覆盖原保护清单。
- 私有服务器文件 #32/#33/#34 早于最终修订；新上传需当次明确授权。密钥不写源码、日志、manifest 或交接。

## 用户本人事项

**唯一用户待办文件：[docs/USER_ACTIONS_REQUIRED.md](docs/USER_ACTIONS_REQUIRED.md)。** 已精简为科学材料/决定、真实人员/伦理、在线预算/发表授权、作者信息和人工/第三方身份确认。不要把下载、hash、映射校验、自动测试或打包转交给用户。

该本地待办文件10-08已同步负责人决定；外部#35/#36仍为10-05版，未重新上传。旧版hash仅对应下方上传历史，不对应当前本地文件。

工程仍未完整覆盖：自动全覆盖分块协议、超出本轮显式标量符号关系的跨模态联合检查、Seurat spatial/复杂图层、真实引擎版本格式、全部API行为独立 sign-off、新独立 test/gold/评价、fresh OS/正式lockfile/远程矩阵。公开开发数据可由执行者继续选择；W10-C/W11/W09最终独立评价仍需冻结和真实专家/参考材料，无材料不能补造结果。

本轮 sandbox 只挂载 host runtime/安装库/public fixture，gold/project/home不挂载；实测无网络/只读/scratch/限额/timeout。不是全新容器镜像，也不是正式模型代码代理研究。早期失败日志保留，成功验收以 acceptance 入口为准。

## 用户本人事项上传记录（2026-10-05）

负责人授权后，已将“仅需负责人本人完成的事项”上传到外部上传服务。该动作只涉及待办清单，不含源码、稿件、数据或人工评价材料。

| 项目 | 实际值 |
|---|---|
| 目标 | `http://62.234.106.117:8003/api/agent-upload`（HTTP 200，`ok: true`） |
| 上传文件 | `docs/USER_ACTIONS_REQUIRED.md`，3,920 bytes，SHA-256 `6dcf5b59e29bc3711f58538c89eaf8b4ba9aa1f79d76c8232fb847d5e13527ce` |
| 服务端编号 | **#35**，上传者 id 4，`is_public=0`，时间 2026-10-05T15:43:53.868Z |
| 服务端文件名 | `1791215033858-2609292399-USER_ACTIONS_REQUIRED.md` |
| 返回地址 | download/preview/file `http://62.234.106.117:8003/api/{download,preview,file}/35` |
| 鉴权凭据 | 请求所用 bearer token 属秘密，未写入源码、manifest、文档、交接或日志；后续会话需由负责人重新提供 |

上传后按返回地址核对：`/api/download/35`、`/api/file/35`、`/api/preview/35` 在带和不带该 token 两种情况下均返回 **HTTP 403**。因此**未能完成上传后内容比对**，服务端副本是否与本地文件一致属于未验证状态；如需下载核验，请负责人使用其账号访问 #35 或提供具备下载权限的凭据。

本地文件是唯一可核对来源；current manifest 的 documentation 清单与原保护清单不受该外部上传影响。若负责人随后修改 `USER_ACTIONS_REQUIRED.md`，需重新上传并在本文追加新编号，不要覆盖本条记录。

## 用户本人事项公开上传记录（2026-10-06）

负责人随后明确要求以 `is_public=1` 重新上传同一文件，并已实际执行成功。这一版可匿名读取，因此上载内容视为公开。

| 项目 | 实际值 |
|---|---|
| 目标 | `http://62.234.106.117:8003/api/agent-upload`（HTTP 200，`ok: true`） |
| 上传文件 | `docs/USER_ACTIONS_REQUIRED.md`，3,920 bytes，SHA-256 `6dcf5b59e29bc3711f58538c89eaf8b4ba9aa1f79d76c8232fb847d5e13527ce`（与 #35 同一内容） |
| 服务端编号 | **#36**，`is_public=1`，时间 2026-10-06T00:25:31.958Z |
| 服务端文件名 | `1791246331956-1930385959-USER_ACTIONS_REQUIRED.md` |
| 公开地址 | `http://62.234.106.117:8003/api/download/36`、`/api/file/36`、`/api/preview/36` |
| 内容核对 | 三个地址在不携带凭据时均 HTTP 200，回读 SHA-256 与本地文件完全一致（#35 的 403 已不再出现） |
| 鉴权凭据 | 上传所用 bearer token 属秘密，未写入源码、manifest、文档、交接或日志 |

#35（私有）与 #36（公开）为同一文件的两条记录。若需撤销公开访问，需在该服务端删除或改为私有；本地文件不会因此改变，重新上传时追加新编号，不覆盖本条。

## 续接顺序

1. 先读本汇总、`PAPER_CN_CONTINUATION`、`paper_cn_v4/README`、SESSION_HANDOFF及current manifest。当前主力是论文与候选后续检验；核对current_audit的manifest_sha256确认清单未再变。
2. 修改当前稿时新建论文版本/结果输出/执行label并跑适用检查。公开开发数据由执行者选择；专家后置，用户研究deferred。最终独立评价另冻结test/gold，不能看test gold调规则后报同一test结果。
3. 本轮论文上传授权仍未扩展：#45–47仅覆盖v0.8；未获其他明确授权不提交/推送/release/DOI或上传其他材料，缺作者信息保留占位。
4. 文档或源码变化后，更新交付包新路径和 manifest，再执行 current/historical audit；原保护清单不变。

## 环境与命令

Ubuntu24.04.4/R4.3.3/Bioc3.18；系统R及论文venv/Node工具已恢复。环境定义见 `docs/REPRODUCTION.md`，恢复 `restore-baseline.sh`/`restore-development-optional.sh`。依赖清单是实际版本，不宣称transitive lock。

```sh
R --vanilla --slave -f tools/check.R
R CMD build .
R CMD check --no-manual --no-vignettes --no-build-vignettes BioExplainR_0.4.0.9000.tar.gz
python3 tools/http-transport-smoke.py --output /tmp/opencode/http-check-new.json
python3 tools/shiny-acceptance.py --output /tmp/opencode/shiny-check-new
python3 tools/isolated-library-check.py --archive BioExplainR_0.4.0.9000.tar.gz --output /tmp/opencode/core-check-new
python3 tools/sandbox-boundary-check.py --library /tmp/opencode/core-check-new/library --output /tmp/opencode/sandbox-check-new.json
Rscript --vanilla tools/legacy-interface-check.R /tmp/opencode/api-check-new.json
python3 research/multiomics/audit_miniacc.py research/results/miniacc_development_v1
# 重跑真实案例使用新输出目录；默认源码，--installed 使用实际安装包：
Rscript --vanilla research/multiomics/run_miniacc.R research/results/miniacc_development_new
R_LIBS=/tmp/opencode/bioexplainr-install-review Rscript --vanilla research/multiomics/run_miniacc.R research/results/miniacc_installed_new --installed
python3 research/multiomics/test_audit_miniacc.py
R_LIBS=/tmp/opencode/bioexplainr-install-review Rscript --vanilla tools/legacy-interface-check.R /tmp/opencode/api-installed-new.json --installed
python3 research/manage_baseline.py manifest
R --vanilla --slave -f research/audit_results.R --args --mode=current
R --vanilla --slave -f research/audit_results.R --args --mode=historical
```

HTTP/Shiny acceptance 自动启动/停止本地服务，无真实模型调用。sandbox 使用当前可用sudo/bwrap，不应把不可用环境标为pass。源稿/表/图改动时才重导出，以交接和REPRODUCTION入口按实际范围执行。
