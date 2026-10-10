# BioExplainR 统一交接文档

整理日期：2026-10-10。本文合并 `SESSION_HANDOFF.md`、`docs/implementation_records/PAPER_CN_CONTINUATION.md` 和 `docs/paper_cn_v1/README.md`，按最新状态、续接步骤和历史记录组织，重复内容合并。

## 最新续接：公开蛋白组分页补齐与样本结构复核（2026-10-10）

按负责人“阅读这些文件，继续接着做”完成新一轮来源审查。
[本轮结果入口](research/results/discovery_public_proteome_v1/README.md)，
独立新目录`research/results/discovery_public_proteome_v1/`保存输入、实际请求、
完整/部分字节、逐项目设计与独立复核，不并入旧科学封存。

|工作|本轮实际新增结果|
|---|---|
|分页闭合|15关键词/负控制18页，437查询命中、391唯一项目；DEX113、GC105，比前轮page0各100新增13/5。全部与响应头total_records一致，21气道/平滑肌文本线索逐项核对|
|新增完整清单|PXD014171/015604/029550/055968各22/54/72/56项共204；分别病灶LCM、BSM-上皮研究、肺动脉SMC及已有ASM EV，未取得成人原代ASM受控GC上清数组|
|HBEC完整表|前轮目录完整表/最终下载日志未找到，本轮另取：部分1,769,472bytes保留；HTTP206尾段与32,768重叠核对后另名合成2,055,550bytes，上游SHA1通过；3,072蛋白组×46列，43样本/10个体，73,453有限值/58,643 NA|
|样本解码纠正|43样本与原作者SRDF/community SDRF全对应。10个体各有ICS前/后×polyIC四格，T2-high/low各格5/5，**纠正下节“T2与ICS部分混杂”**；仍为临床前后上皮、非受控GC/vehicle、非ASM，不能归因GC或替代ASM验证|
|既有处理表|A5495,428×25/字节复核；三成纤维细胞mzTab上游SHA1/gzipCRC通过，PRIDE大小753,018/871,109/770,183为解压字节，压缩原件130,946/151,987/135,512，不是下载缺段|
|原文与失败|Zed HBSMC原文为PDGF±Zed、无GC，完整数组合理请求；HBEC原文蛋白部分为3例steroid-free±imiquimod，43run不全属该论文对比。49请求记录；XML500/出版社403/reset/挑战页/DNS及部分下载完整保留|
|PXD055968|新56项name/size/accession/checksum与原清单一致；原缺件与请求草稿原hash通过，最终定量仍缺、请求未发送、候选身份未冻结/启动|

**本轮完成的是检索覆盖、真实文件完整性、样本设计及可行性复核，未新增
候选效应/BH/Holm/配对统计。** ANGPTL2/FSTL3/FBN2/PER2/METTL7A既有
结论维持范围。未取得合格数组不等于数据不存在；临床前后不是受控药物因素，
EV无GC不能升级GC响应、主动分泌速率或功能因果，18run不当18供体。

开始保存精确`rgo_before_continuation.md`；前轮/tmp公开清点前快照原字节
另存`rgo_before_public_search.md`，先核对与旧handoff根rgo依赖hash一致再
层叠验证；原2,905保护文件与旧科学原路径/hash核验。新清单绑定本轮文件及
更新根rgo，旧清单/归档保留。当前保存结果核验入口：

```sh
python3 research/discovery/audit_public_proteome.py verify
```

下一实际材料动作仍是负责人发送PXD055968现有精确请求，或提供作者原回信/
附件/链接；接收版本、未筛矩阵、原缺测、肽映射及供体/重复说明合格后，另
冻结完整候选身份检查。失败与修订见本轮EXECUTION_NOTES，GitHub/外部上传
继续暂停。下节公开清点为前轮历史状态，涉及HBEC混杂/可复核文件状态以本节
纠正为先；下方“最新/下一轮”均为各自历史时点。

## 最新续接：公开蛋白组数据可及性清点（2026-10-10）

针对“是否必须提交作者信息才能下载数据”的问题，本轮只做只读公开来源清点：**PRIDE/ProteomeXchange 与 Europe PMC 的存档文件和已发表处理表可直接匿名下载，不需要作者联系；需要作者回复的仅限论文对应的未按差异预筛定量导出与版本/重复层级说明。** 本轮未联络作者，`AUTHOR_MATERIAL_REQUEST.md` 仍为草稿、未发送。

检索与核对范围：PRIDE archive v2 `search/projects`（关键词 airway smooth muscle、bronchial smooth muscle、HASM、HBSMC、dexamethasone、budesonide、glucocorticoid、intrapulmonary、airway proteome、airway actin，外加一个无关负控制返回 0），Europe PMC 三组题摘检索（ASM 蛋白组、肺/气道 GC 蛋白、ASM GC 公开数据）。全部原始响应、文件清单与派生 summary 保存在 `/tmp/opencode/rgo_public_search_20261010/`，**未写入仓库、未上传、未封存**；未下载任何 RAW/MSF/pdResult/7z 大文件，未对任何新数据集做候选统计。

|项目|实际下载/核对结果|适用范围与边界|
|---|---|---|
|PXD063431|A549 人肺腺癌上皮系，地塞米松 1 µM 48h vs 未处理，n=4 wells；Proteome Discoverer 2.5、Swiss-Prot human 2024-03。公开表 `240221_PB_ProteomeDiscoverer_all_Proteins_A549.txt` 已下载，1,237,980 bytes 与 PRIDE `fileSizeBytes` 一致；5,428 数据行×25 列，LFQ 列 `A549_NT_1/3/4/5`、`A549_dexa_1/3/4/5`，另含 Exp q-value、Contaminant、unique peptides、PSMs。论文 STTT 2026（PMC13291245），转录组 GSE295999，补充 Zenodo 17368807|**可作 GC 蛋白响应的方法学参照，不能作 ASM 证据**：癌细胞系、癌源、非 ASM、单时点 48h、4 个 wells 非独立供体，无患者结构，不提供分泌/上清数组|
|PXD029135|人支气管上皮 HBEC，临床 ICS（布地诺德）治疗前后 × poly(I:C) × imiquimod；10 个个体 RC1/2/4/5/6/7/8/9/10/11，40 个主样本 + 3 个 imiquimod 样本；MaxQuant 1.6.15.0、THISP level2 2020-06-01、MBR、NormalyzerDE median 归一。`median-normalized.txt`（2,055,550 bytes）、`SRDF_File.txt`、community sdrf（43 行×35 列）已下载|**上皮而非 ASM**；ICS 是临床治疗状态、不是受控培养 GC/vehicle 因子，无 GC×时间设计；T2-high/low 与 ICS 状态部分混杂|
|PXD003963 / 003965 / 003971|人真皮成纤维细胞 IL-1β ± 地塞米松的 **上清分泌蛋白** 三条件，各 3 生物学重复；各下载 1 个 mzTab：PRT 800/918/762、PSM 2,872/3,326/2,984；mzTab 仅蛋白鉴定/肽段计数，**不是跨样本丰度矩阵**|非气道、非 ASM；只证明该类分泌蛋白 GC 数据集公开可及，不能估计候选差异|
|PXD029028|人间充质肺细胞 DIA（central airway vs distal parenchyma；供体 FL4/5/11/12 各 3 技术重复）及 4 个参考细胞类型的 DDA 光谱库，其中含 primary human aortic smooth muscle cells（hAaSMC 10 fractions）作建库参考；`meta_data.csv`、`DDA_sample_ID.csv` 已下载并逐行核对；`peptide_matrix.csv`（10,989,355 bytes）、`peptide_annotations.csv`（2,557,322 bytes）清单/checksum 已取得但未下载全量与 RAW|**无任何 GC 处理**；hAaSMC 仅为光谱库参考样本，不是处理比较，也不是气道来源 ASM|
|既有 ASM 项目复核|PXD015566、PXD055968、PXD059603、PXD055949、PXD010036、PXD001471、PXD029237 的项目描述、样本/数据方案与文件清单再次核对，与 `research/results/discovery_secretome_provenance_v1/complete/project_feasibility.csv` 既有结论一致：无一提供受控 GC/vehicle 的 ASM 上清蛋白设计|不改变 PXD055968 的缺件状态；已分析数组仍限于 PXD033504/033514/033534 与既有 PXD081613 范围|

**本轮明确未做**：未下载 RAW/pdResult/7z 等原始证据；未重新搜索或重建任何质谱检索；未对 PXD063431、PXD029135、PXD00396x、PXD029028 做任何候选基因/蛋白统计、BH/Holm 校正、供体配对或直接差检验；未替换 PXD055968 缺件清单，仍缺论文对应未按差异预筛蛋白组×18run 表、最终联合 workflow/版本、原缺测与同版本肽映射、六患者年龄/成人确认与重复层级；候选身份检查仍未冻结、未启动；18 run 不得当作 18 独立供体。

**结论边界**：新取得的三类 GC 相关蛋白数据集（A549 癌细胞系、HBEC 临床 ICS、皮肤成纤维细胞分泌蛋白）**均不是成人原代 ASM 的受控 GC×时间 或 GC×vehicle 上清设计**，不能升级 ANGPTL2／FSTL3／FBN2／PER2／METTL7A 既有候选结论，也不能替代 PXD055968 缺件。无 GC 因子的 EV/上清蛋白识别仍不得解释为 GC 响应、主动分泌速率或功能因果。本轮未联络作者、未上传、未改写任何科学 manifest、未重跑旧 seal；未取得合格数组不等于数据不存在。本轮更新前的根 rgo 精确快照另存于 `/tmp/opencode/rgo_before_public_search_20261010.md`，旧封存如直接核对已更新的根 rgo 会失败，可用该快照执行层叠核验，其余旧科学文件仍按原路径/hash 核对。若后续要把这些来源入库，须另建新研究目录冻结输入、样本解码与统计口径，不能并入旧封存。下面各“最新/下一轮”为对应历史时点。

## 最新续接：PXD055968真实最终材料来源续查（2026-10-10）

已读前轮交接、缺件清单及未发送材料请求，开始核验export及层叠旧封存通过。
[本轮最终入口](research/results/discovery_asm_ev_materials_v1/handoff_correction/HANDOFF.md)，新证据在
`research/results/discovery_asm_ev_materials_v1/`。

新增真实来源：HAL DOI／原题名各命中同一`hal-05063440v1`论文；262元数据字段
和实际页面都只列一论文PDF，没有最终定量附件。HAL记录version1／修改日期
不是最终蛋白处理版本。PRIDE本项目完整56项与前轮name/size/accession一致；
两个明确关联项目完整48/38项是EV处理后的上皮研究，未列另附EV最终定量表。
三清单共142项。Recherche Data Gouv四查询有效0索引；HAL accession/项目名
各0；OpenAIRE JSON/XML超时、Figshare403保留，不解释为材料不存在。

19元数据请求记录（16响应取得、1HTTP错误、2超时）＋1部分PDF请求记录，另有
2外层中断尝试。HAL PDF两urllib请求45/180秒中断无完成JSON；curl总60秒
exit28只得3,564,070/13,089,865bytes，原部分字节保存，未宣称完整全文取得。

**仍缺论文对应的未按差异预筛蛋白组×18run表、最终联合workflow／版本说明、
原缺测及同版本肽映射、六患者年龄／成人确认和重复层级。候选身份检查未冻结、
未启动。** 原`required_materials.csv`与`AUTHOR_MATERIAL_REQUEST.md`继续有效，
请求**仍为草稿、未发送**。本轮新增`MATERIALS_RECEIPT.md`，说明收到原件后的
核对顺序；先验收版本／结构／来源，再另冻结完整固定候选身份检查。

下一实际动作：负责人以真实姓名／单位／邮箱发送现有请求，或提供作者回信、
原附件／下载链接。六患者三重复不算18供体；无GC/vehicle，EV识别不升级GC
响应、主动分泌速率或功能因果。已有ASM／HTPC候选结果继续原范围。

新封存只将前轮export唯一根rgo文档依赖核对到开始精确快照
`rgo_before_materials.md`，其余旧科学原路径/hash，层叠核对旧证据及原2905保护
文件；原清单/归档保留。根rgo更新后下节旧seal直接读现根会失败，使用新入口：

```sh
python3 research/discovery/asm_ev_materials_handoff.py verify
```

最终核对纠正初稿元数据字段数260→262，原机器计数及原科学证据未改。三份修订
文字先保存精确快照，最终`handoff_manifest.json`绑定修订并层叠核验来源清单。
失败／中断及真实范围见本轮`EXECUTION_NOTES.md`。GitHub／外部上传继续暂停。
以下各“最新／下一轮”为对应历史时点。

## 最新续接：PXD055968完整定量导出版本核实（2026-10-10）

按最新入口继续取得并核对全部18个存档结果的实际版本／schema／workflow，
另查run01原MSF及公开导出来源。[直接阅读本轮入口](docs/asm_ev_export_v1/README.md)，
完整新证据在 `research/results/discovery_asm_ev_export_v1/`。

|工作|本轮实际结果|
|---|---|
|原文件直接版本|18/18存档pdResult均PD3.1.0.638、CHIMERYS inferys_3.0.0_fragmentation、2024_01_22 FASTA，与PRIDE PD2.5/Mascot/Proline/2020及论文PD3.0/inferys2.1/2023均有差异|
|是否最终完整定量|18/18一RAW／一sample、CWF_ID；54张target蛋白／蛋白组／肽组表无最终丰度列，跨run mapper/quantifier节点0。Minora feature／PSM强度存在，但不是最终蛋白数组|
|完整清单与映射|正确PRIDE56项、FTP/checksum及原映射复取；映射完整SHA1通过。六患者各三repeat，18run不计18供体；个体年龄及培养／制备／进样重复定义仍缺|
|独立实现|builtin sqlite3从已取得原字节块重读18结果3,726schema／1,645metadata；原OOXML18映射、54张蛋白相关表精确列结构及run01MSF线索通过|
|公开导出追查|原文只有1PDF＋6视频；Crossref无data关系、DataCite两查询0、有效Zenodo accession0。403／404／reset／500及Elsevier仅元数据保留；未取得不称数据不存在|

**推进状态：完整正确版本的跨run定量导出仍未取得，候选身份检查尚未启动。**
当前新结论是存档处理版本及结构的来源证据；不能把18个单run结果／feature
强度自行汇总为原发表完整定量，不能把缺件记为候选阴性。下一步需论文对应
的未按差异预筛蛋白组×18run表、最终联合workflow／版本、原缺测与肽段映射、
六患者年龄或成人确认及重复层级。逐项缺件在 `required_materials.csv`，精确
材料请求 `AUTHOR_MATERIAL_REQUEST.md` **仅草稿、未发送**。

合格材料到位后另冻结完整候选身份检查。无GC/vehicle，EV制备识别不升级GC
响应、主动分泌或功能因果；原ASM／HTPC候选结论保持。新目录仅含数据库部分
字节块和元数据，不声称18pdResult整文件SHA1或完整原数据库通过。

**新保存结果核验入口**：

```sh
python3 research/discovery/seal_asm_ev_export.py verify
```

新清单绑定本轮证据／源码／说明及现根rgo。旧provenance的唯一根rgo文档
依赖用开始精确快照 `rgo_before_asm_ev_export.md`，其余旧科学原路径/hash；
层叠旧封存与原2,905保护文件逐项核验。下方旧seal直接读更新根rgo会失败，
使用本节新入口；旧latest/current继续历史范围。失败、中断、regex初稿与
CRLF审计修订见本轮 `EXECUTION_NOTES.md`。GitHub／外部上传继续暂停。

## 最新续接：分泌蛋白来源诊断与新ASM EV来源（2026-10-10）

按本文最新续接建议继续，完成四原数组来源诊断和成人ASM公开材料追查。
[直接阅读4页中文报告](docs/secretome_provenance_v1/README.md)：Word/PDF/
自包含HTML，3表、2图、12CSV-XLSX。新研究
`research/results/discovery_secretome_provenance_v1/`，最终数值在`complete/`。

|工作|实际新增结果|
|---|---|
|完整来源比较|四原组4043/3097/600/531、解码168列；胞内24/72及secretome72非零LFQ4543/14829/2128全部与发表舍入一致。24h secretome0/803，ALL9一致全部双方0，正Intensity一致0|
|24h差异追查|其他三原数组日期/条件/重复交叉LFQ均0匹配；LFQ/Intensity各除三类肽数六公式均0匹配。蛋白特异均值偏移2.577–5.408，不能拟合变换后自行修正发表或称原Perseus复现；处理原因尚未确认|
|新ASM来源|PXD055968患者原代BSM的72h EV，原文/项目/56文件清单/映射及13页原补充取得。三非哮喘/三哮喘患者、18run/6label，同患者三重复不算18独立供体。无GC/vehicle，完整未筛定量数组未取得/未分析|
|新来源问题|PRIDE PD2.5/Mascot/Proline2020DB与原文PD3.0/CHIMERYS2023DB/缺测处理冲突保留；原文称8糖酵解蛋白显著，补充实际ExprP.0912–.590均>.05，16fold/P文本＋坐标核对，不把IPA通路P/ExpectedUp替代单蛋白显著|
|已有ASM蛋白背景|PTX3原ASM DEX分时ELISA/RU486及三供体ERK文献取得，支持已有分泌/药理关联；年龄/时点/promoter冲突与无逐供体数值保留，不改变旧HTPC Holm112未通过。成人咳嗽32因子面板非完整候选数组|
|检索/复核/应用|六查询180唯一文献，最多30全文请求21取得；正确PRIDE唯一8项目＋负控制0。R原数组281232逐测量/31228ALL/4968公式/168列，OOXML23436发表值通过；实际BioExplainR0.4.0.9000两个generic context/双语报告，在线调用0|

**科学结论**：24h存档/发表处理来源差异仍未解决，新ASM EV具真实来源线索，
但没有取得固定候选GC配对蛋白验证。ANGPTL2/FSTL3原结论、FBN2范围敏感
线索及ASM转录结论保持；不是新候选因果/功能确认。检索未取得不说数据不存在。
4页3表2图12CSV-XLSX/PDF边界及主报告/双语1440和390网页通过，非人工审阅。

**新核验入口**：`docs/secretome_provenance_v1/provenance_manifest.json`独立
绑定新研究/报告/源码/现根rgo。旧secretome根rgo文档依赖只使用开始精确快照
`rgo_before_provenance.md`，其余旧科学原路径/hash；原2905保护文件逐hash。
旧latest仍v0.12/r15历史范围；旧seal直接核对已更新根rgo会失败，使用新入口
执行含精确文档快照的旧/新层叠验证：

```sh
python3 research/discovery/seal_secretome_provenance.py verify
```

首轮数字样本解码遗漏、PRIDE普通接口忽略词、全文超时/500、R布尔/Excel日期/
报告宽表及出版社PII修订均保留，见新研究`EXECUTION_NOTES.md`。
下一轮优先从新报告及`complete/PXD055968_files.csv`/`EV_file_linkage.csv`读起，
取得实际Proline/PD完整定量导出并确认版本/供体年龄/重复层级，另冻结ASM EV
身份检查；无药物因素不能升级GC响应。24h来源问题需真实原Perseus/版本材料。
本轮未联络作者，GitHub和外部上传继续暂停。下面“最新/下一轮”为历史时点。

## 最新续接：PXD033504完整分泌蛋白组已完成（2026-10-10）

按负责人要求完成完整secretome处理数组、固定候选分泌证据与独立复核。
[直接阅读6页中文报告](docs/secretome_validation_v1/README.md)：Word／PDF／
自包含HTML，3表、2图、27组CSV-XLSX与2原无栅格PDF图。
完整新研究`research/results/discovery_secretome_v1/`，主稿v0.12继续原封存范围。

|工作|实际结果|
|---|---|
|完整原数组|24/72h两个未筛proteinGroups、解码、parameters、summary；4170成功HTTP206 block段＋header覆盖两个完整容器，上游SHA1和8成员CRC通过|
|真实样本与版本|24h六日期/36技术列，与发表一致；72h八日期/48列，比发表六标签多10.09.19/18.11.14，作者QC/年龄未知。两secretomeMaxQuant1.6.11与发表一致；不沿用旧proteome七标签/1.6.15冲突|
|完整分泌数组|600/531原组→466/380QC组；846项统一BH，194/153可估计，7/16通过；精确全family0通过。LFQ0缺测、不填补、每条件≥2/3技术值先平均，n按日期配对|
|ANGPTL2|24h14肽/13unique、覆盖37.3%；仅两合格日期配对−.453/−1.088，虽同ASM下调方向但不足预定三供体，未确认药物响应；72h未检出，不当阴性|
|FSTL3|两时点各2unique肽；24h仅一标签co1/dex2非零技术值、72hco0/dex2，合格LFQ配对均0；支持识别/Secreted身份，不确认DEX分泌响应|
|完整候选／FBN2线索|56×2＝112位置、4可估计、1Holm通过。FBN2 72h7/7可测↑，+1.535（CI1.112–1.958）、Holm112=.0127；严格3/3六对+1.419/.0259。但发表六标签仅五可测、+1.466/.270未通过；依赖原八标签范围，精确未确认|
|PTX3／直接差|24h+.620、6/6↑，Holm112=.592未通过；72h未通过/一留一方向反转。FBN2直接72−24五共有对+1.397、Holm56=.187未通过；不称累积动力学|
|原发表处理差异|24h803原非零选中测量均不匹配发表log2值、25原零却有限，ALL总Intensity仅9/467一致，非统一偏移/舍入，不能称原Perseus复现。72h2128非零舍入一致、320原零却有限；本轮不填补，冲突完整保留|
|复核与R包|R从原表/解码/summary核对35016LFQ、5836日期组行、846/112校正、224敏感性/56直接差/26留一；另7识别/288Intensity及肽测量/3276尺度比较通过。实际BioExplainR0.4.0.9000两context/双语HTML，完整846/112事实分母通过，在线调用0|

**科学结论**：ANGPTL2／FSTL3取得肽段识别和可分泌身份证据，但缺足够原LFQ
配对，尚不能确认候选DEX分泌响应。FBN2增加范围敏感的跨组织细胞外蛋白线索，
发表六标签校正未通过。HTPC上清相对丰度不是每细胞分泌速率；同旧proteome来源，
不增加独立ASM队列，不替代候选GR遗传／ASM功能。原ASM转录结论保持其范围。

**核验与续接**：新独立清单`docs/secretome_validation_v1/secretome_manifest.json`
绑定新研究／报告／根rgo；旧`latest_manifest.json`继续v0.12/r15历史范围。
本轮开始先核验旧seal，再保存`rgo_before_secretome.md`精确快照；新审计仅用
该快照核对旧v0.12的rgo文档依赖，其他旧科学原路径/hash。原2905保护文件核对。

```sh
/tmp/opencode/validation-report-venv/bin/python research/discovery/seal_secretome.py verify
# 同来源新目录实际数值复现入口，不增加独立证据：
/tmp/opencode/validation-report-venv/bin/python research/discovery/reproduce_secretome.py research/results/discovery_secretome_reproduction_new
```

实际下载连接失败/续传、数字RAW映射与长CSV字段修订见新研究`EXECUTION_NOTES.md`；
原规则与缺测未因候选表现放宽。下一轮先读新报告README／results／FINDINGS。
可优先寻找足够供体的未筛成人ASM上清数组、或明确原24h发表/存档处理差异的
公开材料；当前缺测不强行填补或转写阴性。作者材料及人工最终科学审阅待真实
材料，GitHub／外部上传继续暂停。下文“最新/待完成”为对应历史时点。

## 最新续接：完整54基因／原人蛋白数组与论文v0.12（2026-10-09）

负责人要求按审读建议继续，本轮完成新的实际统计、完整人蛋白来源追查和
[中文主稿v0.12](docs/paper_cn_v6/README.md)：**13页主稿＋19页补充，Word／PDF／
自包含HTML，3主图＋4补充图，3主表／5补充内嵌表，34组CSV-XLSX，16引用**。
新研究`research/results/discovery_set_validation_v1/`，旧v0.11及验证增补保留。

|新增工作|实际结果|
|---|---|
|完整54基因检查|GSE130715六成人／24文库，53可测平均方向均与发现一致，50六供体全部预期方向；45/54配对t与新count模型各Holm54通过，并通过全部伪计数／留一方向标准；原缺测LINC03140保留|
|新候选线索|LINC00607官方Entrez646324在新来源可测，+.526、Holm54=.0233，6/6↑；旧缺测/airway阴性不变。BMAL1/NPAS2↑、NR1D2/DBP/TEF↓均支持，为完整集合后的解释，不作节律/通路确认|
|模型／独立复核|28,395原count保留14,692，秩9／df15；6留一秩8／df12。R核对1,272TPM原测量／212可测检验；Python1,272原count、1,060WLS、2,385TPM敏感性、324计数留一方向。精确六供体Holm54全family未确认；两模型同源不增加独立n|
|完整人蛋白原表|PXD033514／033534正确文件清单各43项；7z部分block2998HTTP206段取得完整proteinGroups／解码／参数，6成员CRC通过，不称整个7z上游SHA1通过|
|METTL7A原LFQ|原七日期标签24h+.830（Holm112=.00990）、72h+1.396（7.96e−6），均7/7↑；完整56基因×2=112family，11可估计／4显著，PER2缺测不记阴性|
|蛋白冲突／敏感性|原七标签/发表六供体，多出10.09.19年龄/QC未知；MaxQuant参数1.6.15/报道1.6.11。144原发表测量142匹配舍入、2原零发表有限值，本轮不填补。发表六标签子集24h=.0574未通过、72h=.000160；共有原六/发表五标签直接差Holm56=.00268/.0237，但跨assay/LC梯度，精确未通过，旧选中表直接差未通过保留|
|GSE42538可行性|12原GSM／4女性子宫内膜基质细胞，NT/GR/MRsiRNA全部同含cAMP/P4/cortisone4天，缺无药物因子，不能估计完整NR3C1×GC；未作候选统计|
|实际R包／论文|实际BioExplainR0.4.0.9000新4集合context＋1蛋白context，双语HTML及54/162/112完整分母事实通过，在线调用0；原PDF图嵌入、34CSV-XLSX、Word表、PDF边界及1440/390网页通过|

**结论收束**：成人ASM晚期响应的集合层面重复增强，METTL7A取得未预筛原数组
的跨组织蛋白线索；成人PER2早期诱导、真药物×时间、GR遗传因果及节律／收缩
功能仍未确认。不称七新增成人蛋白供体或把新旧供体累加，不要求负责人做湿实验。
真实作者信息、最终人工科学/图稿审阅仍需真实材料。GitHub／外部上传继续暂停。

**复核入口**：本轮新`docs/paper_cn_v6/manuscript_manifest.json`、
`research/results/latest_manifest.json`及r15本地续接包；旧current/baseline12
历史范围保留。本轮更新前根rgo精确快照为新研究`rgo_before_set_validation.md`；
v0.11 README/index依赖亦保存精确快照，新审计只对这些变更文档用快照，其他
旧科学原路径/hash，原清单不覆盖。原2,905保护文件按旧清单逐hash核对。

```sh
/tmp/opencode/validation-report-venv/bin/python research/paper_cn_revision/audit_set_paper.py docs/paper_cn_v6
python3 research/discovery/seal_set_validation.py verify
# 同来源新目录数值复现，不增加独立证据：
python3 research/discovery/reproduce_set_validation.py research/results/discovery_set_reproduction_new
```

实际下载、解析、导出、原scope冲突和修订见新研究`EXECUTION_NOTES.md`、
`PUBLIC_SOURCES_FINDINGS.md`；新蛋白主/子集/直接差方案分别保存。后续纯计算
可优先追查PXD033504完整secretome（仅本轮清单取得，未声称数组已分析），
以及同供体成人ASM匹配逐时vehicle／完整NR3C1×GC公开因子。下一轮从v0.12
README、主稿／补充、ISSUES读取。下方各“最新／当前／未完成”为对应历史阶段。

## 0. 最新续接：公开数据验证已完成（2026-10-09）

负责人明确**不能做湿实验，用其他数据集验证**，本轮按此约束完成新的公共数据
统计及证据核对。[直接阅读7页中文验证增补](docs/biology_validation_v2/README.md)：
Word／PDF／自包含HTML，4表、3图和3个原矢量PDF；完整原输入、freeze、
统计及失败记录在`research/results/discovery_validation_v2/`。v0.11主稿保留，
以下第0.1节是本轮前的论文历史状态，新验证结论以本节及新报告为先。

|重点|本轮实际新增结果|
|---|---|
|成人ASM外部重复|GSE130715六成人（19–54岁）／24文库：PER2 −0.934（点态95%CI −1.044至−0.824；Holm44=.000157），6/6下调。PER3 −2.311、METTL7A +1.552、MAOA +2.832、ANGPTL2 −1.388、FSTL3 +1.135均6/6预期方向、配对t校正通过；精确符号翻转全family未确认|
|计数模型与遗传因子|新TMM/voom从28,395基因保留14,692，~donor+kd*gc，秩9／df15；PER2 −1.405、Holm44=3.54e−8。GNAS干预发生，但六候选直接GNAS×BUD交互未通过；不是GR敲低|
|成人真实时间序列原文|补获Bartman2021原文成人33–77岁部分；DEX100nM脉冲30min后12/16/20/24h匹配vehicle。PER2同24hDEX−vehicle原Tukey=.7831，只有DEX组24h−12h=.0498。无原个体Ct，未重算药物×时间，不能说成人先升后降已验证|
|早期ASM检查|GSE13168 8hFP：3配对供体PER2+.691、3/3↑但Holm44=1；PKI是PKA抑制转基因。GSE135730 4hDEX：PER2+.111、Holm33=1；METTL7A/MAOA两炎症背景响应通过。年龄／供体独立性未核实，不拼接时间曲线|
|GR遗传交叉检验|GSE342887/342771：U2OS GR-KO背景WTα／AF2-E755R／IDRΔ1–398 rescue，成熟RNA18／新生RNA17文库，110检验。PER2药物及变体交互未确认；PER1控制AF2交互成熟−.776（Holm55=9.05e−6）、新生−1.569（.00383）。无empty-KO组、平行样本及预印本限制保留|
|人源蛋白支持|HTPC六成人供体，3技术重复先平均；METTL7A24h+.921（Holm22=.0437）、72h+1.504（.00261），均6/6↑，增加跨组织蛋白线索。数组只公开于原文选中差异表，精确Holm=.688；五共享供体直接72h−24h差Holm11=.412，未确认进一步增幅|
|蛋白／功能边界|PXD081613原7,274行表mouse注释与PRIDEhuman冲突保留，PER2缺测不记阴性。ASM GRαsiRNA／GR蛋白／rapidcAMP及胎儿PER1/ARNTL Ca²⁺/SOCE原文已核对，未替代成人PER2／METTL7A候选功能|
|复核与R包应用|R核对396原TPM/SOFT测量／88检验、132原RPKM测量／33检验；Python核对385GR原count／550WLS及220ASM WLS数值；R核对160mouse蛋白测量、144人蛋白原数组／24供体效应／6可测统计。BioExplainR0.4.0.9000实际8context项目、双语HTML、全family事实计数通过；在线调用0|

**当前可支持结论**：成人ASM晚期PER2/PER3抑制得到新增公开供体支持，
METTL7A新增跨组织人源蛋白支持；成人PER2早期诱导、同一供体药物×时间、
GR遗传因果及蛋白／Ca²⁺／收缩功能尚未被确认。这些是可取得公开证据的科学
界限，不再要求负责人做湿实验。新旧供体不累加：六新label与旧GSE94335无
exact重叠，但未知别名未完全排除。范围检索31及193唯一series及失败公开，
不把未检出说成数据不存在。

**复核入口**：新报告`audit.json`、`browser/audit.json`、`validation_manifest.json`；
旧v0.11依赖87项及82ZIP成员、原科学203项在本轮再次核对通过。开始时根rgo
精确快照为`research/results/discovery_validation_v2/rgo_before_validation.md`；
新审计仅用此快照核对旧v0.11的rgo文档依赖，原科学仍用其旧快照，其余科学
文件原路径/原hash。不覆盖旧manifest。保存结果验证：

```sh
/tmp/opencode/validation-report-venv/bin/python research/discovery/audit_validation_report.py research/results/discovery_validation_v2 docs/biology_validation_v2
python3 research/discovery/seal_validation.py verify
```

失败与修订见新研究`EXECUTION_NOTES.md`，中文早期v1计数误写194、实际193，
保留未封存稿并另建通过的v2。后续纯计算优先寻找同供体成人ASM逐时vehicle、
完整NR3C1×GC遗传因子及未按差异筛选的候选蛋白数组；原文作者／单位及人工
科学/图稿审阅仍需真实材料。GitHub／外部上传继续暂停。

## 0.1 论文历史快照：已写成生物学主线论文 v0.11（2026-10-09）

已阅读并核验下节全基因新结果，按负责人要求完成[中文论文v0.11](docs/paper_cn_v5/README.md)：**11页主稿＋12页补充，Word／PDF／自包含HTML，3主图＋2补充图，2主表＋13组新补充表＋4背景表，11参考文献**。主线为PER2暴露时长／实验条件相关响应，次级为METTL7A/MAOA等。原v0.10软件主稿保留；当前生物学稿入口为v0.11。

**已补充的问题与纠正**见[ISSUES.md](docs/paper_cn_v5/ISSUES.md)：每模型四背景统一109,636项BH；A549“2h/18h”指DEX暴露，总培养窗口均18h；长暴露回落不等于A549已负向反转；11/12冻结与11/11可测分母同时公开；GCNT1有1供体反向、LINC00607缺测；CI为点态，两模型共享样本。讨论纳入结果后探索、供体别名、缺逐时vehicle、药物脱靶、节律和功能未测；逐项给出新实验完成标准。

**本次实测核验**：原科学封存203条依赖／200旧ZIP成员；候选表／15组CSV-XLSX／原配对t及48项Holm／24直接暴露差／11引用／24图表正文对应通过。Word2/4内嵌表、PDF11/12页及文本边界、原PDF图嵌入通过；主/补1440与390网页均无横溢出、JS异常。图1原PDF含栅格热图色块与矢量文字，不声称全部纯矢量；其他四图无栅格。实际问题与修订见[执行记录](docs/paper_cn_v5/EXECUTION_NOTES.md)。

本轮是已完成研究的论文整合与复核，统计值取自原封存结果。原科学manifest未改，先核验再保存其绑定的旧rgo快照`docs/paper_cn_v5/evidence/rgo_before_v011.md`；旧科学文件原路径/原hash不变，更新根交接由新`manuscript_manifest.json`独立绑定。本稿附件包`docs/paper_cn_v5/BioExplainR-中文论文-v0.11-附件.zip`；旧current/r14历史pass不视为本轮全树验收。

下一轮先读[v0.11 README](docs/paper_cn_v5/README.md)→主稿／补充→问题表；保存结果用`audit_discovery_paper.py`与`seal_discovery_paper.py verify`复核。真实作者信息、人工科学/图稿审阅及独立ASM时间序列/GR遗传和蛋白功能验证待完成；GitHub及外部上传仍按既有决定暂停。下节保留论文整合前的科学结果快照。

## 0.2 已完成的全基因生物学分析（v0.11整合前快照）

按负责人“主要做新的生物学发现，利用这个R包，必须要结果”的要求，本轮完成真实统计与BioExplainR应用。**直接阅读[7页中文结果报告](docs/biology_discovery_v2/README.md)**：Word／PDF／自包含HTML，3表、5图及五个原始矢量PDF；完整结果`research/results/discovery_stable_response_v1/`。

|事项|本轮实际结果|
|---|---|
|全基因交互|GSE146017：27,409基因×3交互＝82,227检验，统一BH后0显著，最小BH=0.3515；阴性完整保留|
|新的稳健响应集|四背景simple effects统一109,636项BH；DESeq2与新TMM/voom模型、全部供体方向和四轮留一供体筛查得到54基因，按固定最弱Wald统计量冻结前12|
|外部供体检查|GSE94335原补充表配对，额外排除3已知重叠细胞系，13供体（4非哮喘／9致死性哮喘）。11可测候选均通过48检验t／精确符号翻转Holm，1缺测保留分母；不与旧16供体累加|
|主线PER2|外部13/13下调，效应−0.915（95%CI −1.048至−0.782；Holm P=1.55e-7）。A549 DEX2h +1.092，KH103/MIF/Cort113交互−0.935／−0.972／−0.922均通过48项Holm；直接18h−2h −0.917、Holm P=1.45e-9；HASM1直接24h−4h −1.651、Holm P=.0139|
|次级线索|PER3 −2.082、METTL7A +2.044、MAOA +2.561、ANGPTL2 −.869、FSTL3 +1.414，外部均13/13同向，Holm通过；全12候选表公开|
|实际R包应用|BioExplainR0.4.0.9000实际源码载入，9context／项目／中英文HTML；四背景全表计数151/185/128/149与独立统计一致，交互0；v2修正报告scope/uncertainty；在线模型调用0|
|独立实现与交付|Python复核全family BH／109,636全基因供体方向和固定排名／原计数／300 WLS数值／110原数组测量／24 marginal及24 direct时间检验；R从5,851,434原TPM行与原配对表复核286测量、143效应及360统计检查通过。7页3表5图CSV/PDF边界与1440／390网页通过|

**可支持的发现是候选特异的时间／实验条件依赖综合证据，尤其PER2暂态与晚期效应。** 既有文献已研究激素与生物钟，不主张该主题首次发现；时间、药物、剂量、培养和细胞类型混杂，未测相位/振幅或功能。LINC00607外部缺注释、旧airway不支持；TEF单细胞系微阵列不重复；METTL7A/MAOA/FSTL3 GR交互校正未通过；微阵列精确置换全family不能确认，均在报告列明。

方案与复现入口：`research/discovery/GENOME_PROTOCOL.md`、`RESPONSE_PROTOCOL.md`、`RESPONSE_TIME_AMENDMENT.md`及报告README。本轮冻结/候选冻结、失败修订、版本及审计在新目录，`EXECUTION_NOTES.md`列真实错误。主论文仍v0.10；本次结果报告独立，不将旧current清单pass当成覆盖新文件。本轮封存由`docs/biology_discovery_v2/discovery_manifest.json`单独绑定；GitHub/外部上传继续暂停。下面第1节开始保留前次交接历史，读取时以本节新结果为先。

## 1. 历史快照：正式共同任务／机制增补完成后、v0.11整合前

**正式共同任务运行、机制拟合、ChIP 核验及独立实现复核已完成。当前工作稿仍为 [v0.10](docs/paper_cn_v4/README.md)，新增 [4 页研究增补](docs/research_followup_v1/README.md)已导出 Word/PDF/HTML，含 4 表。v0.11 主稿整合尚未开始。**

本次只合并交接文字为 `rgo.md`。下方研究、软件检查和归档验收均为已有记录；文档合并不产生新研究运行、论文图表或论文导出。

### 1.1 已完成

|事项|实际结果|核对入口|
|---|---|---|
|正式共同任务|24 任务 × 3 重复 × 5 方法 = 360 运行 / 1,800 评分；216 正式模型尝试 + 1 预热。离线、base R、ellmer facts、BioExplainR 客户端各 360/360；ellmer 读表 8/360，覆盖 175/360，全正确 0/72；37 次超时全部保留分母|`research/results/common_performance_v4/`|
|配对区间与计时|facts 相对读表的目标正确率差 +97.78 个百分点，24 任务 bootstrap 95% CI +95.28 至 +100；中位秒数：base R 0.002、离线 0.036、读表 180.829、ellmer facts 18.584、Bio 客户端 18.654|正式目录的 `summary.csv`、`paired_bootstrap.csv`、`task_bootstrap.csv`、`audit.json`|
|依赖与适用性|ellmer 0.5.0 实际载入；Qwen2.5-1.5B-Instruct Q4_K_M 与 llama.cpp b11429 固定 hash 复核并用于正式服务。三工具源码半包补齐固定 commit，保存 iSEE 2.14.0 来源；四专属工具记为 `not_applicable`，不计错、不作六工具排名|`research/results/common_performance_applicability_v1/`|
|机制拟合|GSE229084 A549：47 文库 / 4 batch / 35,942 基因，过滤保留 15,437；模型秩 15、残差 df 32。SPARCL1 计数 0–4，未通过固定 filter，三项候选交互**不可估计**；固定控制另行描述|`research/results/discovery_mechanism_fit_v4/`|
|机制独立复核|Python 复核 35,942 基因过滤、188 测量、39 WLS/t/CI 与 GEO 映射；作者 SE 的 51 样本映射及 705,534 共享计数一致，102 个不可对应 ID 保留。原模型 RDS 未改，CI 导出修复及精确 SE 敏感性另记|机制目录的 `audit.json`、`published_mapping_audit.json`、`published_counts_audit.json`|
|ChIP 与 assembly|18 峰文件共 1,347,409 峰均符合 hg19 长度；hg18/hg38/mm9 分别有 12,937/10,043/158,229 越界。坐标证据核实 hg19，原人/mm9 冲突及未获作者确认保留。SPARCL1 GR ±20 kb：vehicle 4/2、DEX 8/8；RNAPII ±5 kb：0/0、1/1|`research/results/discovery_chip_v1/`、`research/results/discovery_chip_analysis_v1/`|
|ChIP 独立实现|R 从原峰、原 RefSeq 与 GenomicRanges 复核 288 计数、2,505 命中、summit/距离及 16 重复比较，通过|ChIP 分析目录的 `r_audit.json`、`r_replicate_audit.json`|
|研究增补|4 页 / 4 表；Word 表与 CSV/原结果一致，PDF 文本边界通过；1440/390 双视口无横溢出或 JS 异常|`docs/research_followup_v1/`|

任务输入、24 任务 / 360 运行顺序、bootstrap 与正式脚本在推理前冻结；机制处理映射/设计及 ChIP 窗口亦分别冻结。Python 从原输入、原输出、HTTP、时间、tokens 和区间独立复核共同任务结果。

### 1.2 未完成与解释边界

- **论文整合未完成**：新结果只有独立研究增补，尚未整合为下一版主稿；当前仍为 v0.10。真实作者、单位、通讯、CRediT、基金、利益冲突和适用伦理信息，以及最终人工图稿审阅仍待完成。
- **共同任务范围有限**：已知开发数据、本机小模型、固定计数/事实传递；facts 组已经包含目标答案。200 行读表的 36 请求均超时。这不是六工具全面排名、通用推理评价或独立生物学 gold；四专属工具只完成源码/适用性核对，未安装或执行其专属任务。失败请求 tokens 与本地总成本未知。
- **机制候选不可估计**：A549 SPARCL1 三交互因过滤不可估计，不能支持或否定 GR 依赖，不是机制阴性统计。未独立重估 TMM/voom/eBayes。
- **ChIP 仅为窗口重叠**：ASM 单细胞系发布峰不等于差异占据统计、增强子连接、直接调控或功能因果。assembly 仅经坐标证据核实，作者确认和出版社补充/XML 仍未取得；XML/403/challenge/OCR 失败保留。
- **科学与人员验证未完成**：没有新增湿实验、新独立供体、GR/CEBPD rescue、位点 reporter/CRISPR、SPARCL1 干预、qPCR/蛋白/基质/功能/临床终点、专家/用户评分或第三方人员科学/代码 sign-off。专家评价后置，用户体验/学习增益研究为 `deferred`。
- **软件未在本轮重跑**：R 包功能未改，未重跑 testthat/build/check、Shiny、历史 HTTP/bwrap/API 或旧生物学案例；历史软件 pass 仍只对应各自版本和日志范围。
- **发布继续暂停**：GitHub/外部上传暂停，无新提交、推送、release、DOI 或外部上传；#45–47 只对应 v0.8。v0.9/v0.9.1/v0.10 均未对外上传，旧公开副本未替换或撤回。

## 2. 失败、中断与修订位置

全部执行记录位于 `research/results/w00_baseline/`。完成记录的 `.json` 保存命令、UTC、退出码及日志 hash；中断后只有 `.txt` 的记录不能视为 pass。以下失败保留原目录/label，不改写旧 freeze。

|事项|实际失败及处理|文件位置|
|---|---|---|
|共同任务早期尝试|v1 的 ellmer 默认 Responses API 忽略 seed 后中止；v2 端口冲突、未推理；v3 发现 config 参数与 finish_reason 映射错误后中止；正确入口重新冻结为正式 v4|`research/results/common_performance_v1/` 至 `common_performance_v3/`；`w00_baseline/continuation-performance-formal*.txt/json`；`research/common_performance/IMPLEMENTATION.md`|
|正式任务超时|v4 读表 37 请求真实超时，其中 200 行 36 请求全部超时；全部保留全目标分母，没有重试、修订答案或删除失败|正式 v4 的 `runs/`、`wire/`、`scores.csv`、`audit.json`|
|机制准备与导出|fit v1/v2/v3 分别在 freeze 路径、处理空白、CSV 逻辑类型阶段失败，v4 完整拟合。CI 初次导出误索引无名字的 s2.post，另文件修复导出；原 `model.rds` 保留，精确与 limma 近似 SE 差异已复核|`research/results/discovery_mechanism_fit_v1/` 至 `discovery_mechanism_fit_v4/`；`continuation-mechanism-*.txt/json`；v4 的 `model_results_complete.csv`、`export_amendment.json`、`exact_WLS_sensitivity.csv`|
|ChIP 来源与复核|首次 article/PDF 传输返回 challenge HTML，不当作有效原文，后取得有效 HTML；XML 500、出版社 403、OCR 不清楚保留。R 首次 100000 窗口键被格式化为 1e+05，仅修复数字格式后通过|`discovery_chip_v1/acquisition.json`、`alternative_sources.json`、`build_evidence_acquisition.json`、`PMC5576583_article.html`；`continuation-chip-*.txt/json`；`discovery_chip_analysis_v1/r_audit.json`|
|作者处理对象|串行下载 503/超时后，59 段 HTTP Range 取得 30,570,232 bytes；双层 gzip 分别验证 CRC。51 样本映射和 705,534 共享计数通过，102 个无法对应的基因标识逐项保留|机制 v4 的 `range_download.json`、`nested_gzip.json`、`published_mapping_audit.json`、`published_counts_audit.json`、`published_unmatched_gene_ids.csv`|
|评分与文档检查|bootstrap 索引 list 需数值转换，scorer 包装器只修复类型；文档检查首次历史 marker 不匹配失败，改用原日期边界后通过|`research/common_performance/score_complete.R`、`check_handoff_complete.py`；`continuation-performance-scoring*.txt/json`、`continuation-handoff-check*.txt/json`|
|准备阶段下载|sudo 因 no-new-privileges 失败，改为本地 libcurl 开发头文件/链接；GitHub/Hugging Face 超时后分别续传或改用 ModelScope，模型 hash 一致。SCassist 下载先 HTTP 415，修正 Accept 后被中断，19,243,008 bytes 半包 gzip 不完整；后来正式阶段补齐|`performance-comparator-install-final.*`、`performance-runtime-acquire*`、`common_performance_checkpoint_v1/checkpoint.json`|
|准备阶段输入与脚本|Sasse 原文 XML HTTP 500、ChIP 峰当时未取得；初次下载超时后 `prepare_mechanism.py` 增加 `--resume` 与逐文件清单，原 freeze 不改写，修订 hash 记入 checkpoint|`research/results/discovery_mechanism_v1/`、`mechanism-inputs-acquire*`、checkpoint|

正式结果只取 `common_performance_v4`、`discovery_mechanism_fit_v4`、`discovery_chip_v1` 及 `discovery_chip_analysis_v1`。早期中止、映射、端口、入口和导出失败不混入正式分母；任务、提示和过滤未按答案改规则。

## 3. 下一轮从哪里接

1. 阅读本文，再读 [研究增补 README](docs/research_followup_v1/README.md)、[正式研究实施记录](docs/implementation_records/FORMAL_FOLLOWUP_CONTINUATION.md)和 [v0.10 主稿入口](docs/paper_cn_v4/README.md)。用户指定的 [v0.9.1 历史入口](docs/paper_cn_v3/README.md)继续保留。
2. 核对 `research/results/current_manifest.json` 与 `research/results/w00_baseline/current_audit.json` 的 `manifest_sha256`，以及正式结果目录的 `files_manifest.json`、`scientific_ledger.json`。保存结果复核使用研究增补 README 中的命令，无需重跑模型；日志保留主机真实 UTC，不修改历史时间。
3. 若继续论文整合，从 v0.10 主稿和 4 页研究增补另建下一版目录，纳入 A549“不可估计”、ChIP“坐标核实/非差异占据”、37 超时及开发任务边界，再导出并核对图表。不要覆盖 v0.10、v0.9.1 或 v0.8。
4. 若继续新研究，另冻结输入、脚本和输出目录。新推理先按 `research/common_performance/restore_formal_runtime.py` 恢复同 hash 模型/runtime，固定 ellmer 0.5.0；不能把 v4 保存响应当新调用，不能降低候选过滤或把培养重复增加为独立供体。
5. 剩余科学验证为新供体、GR/rescue、位点及 SPARCL1 功能终点；真实稿件信息、作者确认与第三方人员 sign-off 按实际材料追加。GitHub/外部上传仍待负责人明确恢复。
6. 文档或源码变化后，如需新的交付完整性结论，另用新归档路径，更新清单并执行 current/historical audit。原保护清单和旧日志不改写；旧 ZIP 的验收只对应当时文件树。

方案入口：`research/common_performance/PROTOCOL.md`、`research/common_performance/IMPLEMENTATION.md`、`research/discovery/MECHANISM_PROTOCOL.md`。前期供体研究另见 `research/discovery/CONTEXT_PROTOCOL.md`、`DONOR_PROTOCOL.md`、`DONOR_DESIGN_AMENDMENT.md` 及 `research/results/discovery_context_v1/scientific_ledger.json`。

## 4. 论文版本与已保存研究

### 4.1 版本入口

|版本|状态与内容|入口|
|---|---|---|
|v0.12|**当前生物学工作稿**；13页主稿／19页补充，7图、34CSV-XLSX、16引用；完整54扩展与原人蛋白数组、scope冲突及敏感性|[docs/paper_cn_v6/README.md](docs/paper_cn_v6/README.md)|
|v0.11|前轮生物学主线初稿；11页主稿/12页补充，5图、19表=24项对应，11参考文献；PER2与54基因响应、问题及方法澄清|[docs/paper_cn_v5/README.md](docs/paper_cn_v5/README.md)|
|v0.10|历史软件主稿；12 页主稿，3 主图、1 内嵌表、32 参考文献；18 页补充，8 补充图、补充方法 S1–S13、外置表 S1–S13；共 11 图 / 14 表 = 25 项正文对应|[docs/paper_cn_v4/README.md](docs/paper_cn_v4/README.md)|
|研究增补 v1|正式共同任务、机制与 ChIP 后续结果；4 页 / 4 表，Word/PDF/HTML；尚未并入下一版主稿|[docs/research_followup_v1/README.md](docs/research_followup_v1/README.md)|
|v0.9.1|历史图表正文修订稿；10 页主稿 / 16 页补充，10 图 / 11 表 = 21 项均有正文引出、结果或设计及解释|[docs/paper_cn_v3/README.md](docs/paper_cn_v3/README.md)|
|v0.9|历史发现/发布准备稿；9 页主稿 / 16 页独立补充|[docs/paper_cn_v2/README.md](docs/paper_cn_v2/README.md)|
|v0.8|已归档历史稿；23 页、29 参考文献、8 四联图 / 32 panel、9 外置表、0 嵌入数据表；对应公开上传 #45–47|[docs/paper_cn_v1/README.md](docs/paper_cn_v1/README.md)|

旧 v0.7、原主稿/补充和 `docs/submission_assets/` 保留。v0.8 不作为当前稿引用，其图表与上传记录用于历史比对。

### 4.2 v0.10 候选后续检验（2026-10-08，交付续接 2026-10-09）

|事项|已完成结果|入口|
|---|---|---|
|环境依赖性检验|GSE146017 全 HTSeq 计数，4 供体 / 31 文库 / 27,409 特征，固定 `~ donor + kd * bud * tnf`。三项预定 SPARCL1 交互同一 Holm family：−1.246（Holm P=0.289）、−0.142（P=1）、−0.136（P=1），均未通过；四供体 NT/无 TNF 条件的规范化计数响应均为正|`research/results/discovery_context_v1/` 的 `model_results.csv`、`donor_sensitivity.csv`、`audit.json`|
|多供体响应|GSE94335 从原论文 Supplement Table E1 的 Cell Line 恢复真实配对，GEO donor 字段逐文库唯一，不可作供体 ID。7/7 非哮喘、9/9 致死性哮喘供体的布地奈德配对均上调；log2(TPM+1) 差 +3.514（Holm P=3.89e-4）与 +3.598（P=1.92e-8）；组间差 +0.084（Holm P=0.859；11,440 组枚举 P=0.844），不支持病组差异|`research/results/discovery_donors_v1/` 的 `results.csv`、`donor_effects.csv`、`r_numeric_checks.csv`|
|映射与解释边界|28793/28796 映射/病组冲突在候选检验前按设计排除；GSE94335/GSE146017 至少 3 个培养细胞系 ID 相同（N010912、N051911、N061311），不合并供体数；SPARCL1 baseMean 8.175，存在低表达限制|`DONOR_DESIGN_AMENDMENT.md`、`scientific_ledger.json`；v0.10 正文 2.6/3.5/4.2|
|独立实现|Python 从原计数复核候选测量、R size factor、Wald P/CI、BH/Holm 及全部供体差中差；R 从原 TPM/原表重做配对 t、Welch、CI、128/512 符号翻转、11,440 组枚举与 Holm，并逐样本比对 Cell Line/病组/处理|`research/discovery/audit_context.py`、`audit_donors.R` 及输出|
|软件衔接|生成候选、因子实验、多供体响应三上下文项目及中英文报告，保存阴性交互、单位与假设来源；该轮 0 次在线模型调用|`discovery_context_v1/followup_report_zh_v2.html`、`report_workflow_v2.json`|
|论文与导出|新增方法 2.5/2.6、结果 3.5、讨论 4.1/4.2、图 3 四联图和补充表 S11–S13；25 项图表对应通过，正文较 v0.8 缩减 47.39%。Word/PDF/HTML 导出，PDF 嵌入矢量图；1440/390 主稿 3 图 1 表、补充 8 图 0 表，无溢出/JS 异常，图 2/3 文字边界与重叠通过|`docs/paper_cn_v4/` 的 `audit.json`、`figure_table_links.json`、`export_report.json`；`w00_baseline/revision-biology-browser/`|
|输入与交付检查|GSE146017 计数和 GSE94335 TPM 分段 HTTP Range 下载，逐段核对 Content-Range/Last-Modified，gzip CRC 通过；Python 语法、5 项 current 审计失败探针、2 项离线恢复探针、25 项图表/内容/几何及网页索引 7 链接通过|`research/discovery/download_ranges.py`、`range_download.json`、`input_manifest.json`；`biology-handoff-*`|

原文 Himes 2014 表 1、Kan 2019 表 3 已报告 SPARCL1 响应，正文不主张首次发现；新增价值限定于供体分布、显式组差/交互与可定位映射。结果支持“所测致死性哮喘来源 ASM 保留 SPARCL1 表达响应”，不支持炎症抑制、CEBPD 依赖、组间响应差、蛋白/功能/临床效应。组差与交互阴性不证明等效；GSE146017 仅 4 供体，DESeq2 dispersion 未做替代敏感性。

2026-10-09 已纠正交接文字中“24 项”的计数误写；实际 v0.10 图表清单为 25 项，无缺项。该轮未改 R 包功能或重跑软件、旧案例、在线模型。

### 4.3 v0.9 / v0.9.1 修订与外部培养实验（历史）

- 六工具能力比较表涵盖 iSEE、SCassist、GeneAgent、ellmer、GPTCelltype 与 BioExplainR；方法 2.3 和结果 3.1 说明比较维度与集成审查能力。表 1 为原论文/官方文档能力比较，不是全面性能排名。数据入口 `docs/paper_cn_v3/tables/Table_1.{csv,xlsx}`、`research/paper_cn_revision/tool_comparison.json`。
- 正文收束完整事实、科学范围/独立单位、可定位核对、项目溯源四贡献，10 节详细方法移补充。v0.9 正文较 v0.8 缩减 65.75%；v0.9.1 补齐图表叙述后从 11,279 至 5,576 非空白字符，缩减 50.56%。Word 标题继承编号关闭，CRISPLD2 和上标负号核验通过。
- airway 固定规则选择 SPARCL1 后读取 GSE34313 外部表达：24 h 效应 +4.132，Welch P=1.55e-4，置换 P=1/35；Python/R 独立 12 项一致。输入、方案、测量、context/project、双语报告与 hash 位于 `research/discovery/`、`research/results/discovery_sparcl1_v1/`。
- GSE34313 为单个 HASM1 细胞系的培养实验初步重复，不是独立供体验证；未核实与 airway 逐供体无重叠，未新增供体、qPCR/蛋白、GR/SPARCL1 干预、临床或因果验证，不声称首次发现。
- 用户要求暂停 GitHub 并逐项检查图表后，v0.9.1 补齐 S1/S8 引用、成组引用逐图表说明、S7D 修复结果和表 1 方法/结果，补充图注旧主表号统一为 S 编号。2 主图 + 8 补充图、1 主表 + 10 补充表，共 21 项在 Markdown/Word/PDF 参考文献前正文对应通过；四联 panel 对应、正式 PDF 矢量图、引用/表数据/边界及 1440/390 网页通过。图表原件逐字节复用 v0.9。
- 详细记录为 `docs/paper_cn_v3/FIGURE_TABLE_REVIEW.md`、`figure_table_links.json`、`audit.json`、`export_report.json`、`compression.json`、`docs/implementation_records/FIGURE_TABLE_NARRATIVE_CONTINUATION.md`、`PAPER_RELEASE_CONTINUATION.md`；日志 `revision-links-*`。v0.9.1 文稿修订未重跑 R 软件或研究数值。
- v0.9 源码 677 项（676 pass / 1 skip）和包 check OK 已实际运行，日志 `revision-source.*`、`revision-package-check.*`。本地源码提交 `dbd7075`（OpenCode 执行身份，不冒充论文作者）和 `545bb89` 保留；暂停后 v0.9.1 及交接改动未新提交。
- 曾获公开建仓/提交/推送/release 授权，账号 `ouev5` 下创建 `BioExplainR` 仓库的 GraphQL/REST 均权限 403，未建远程仓库、未推送、无 release。随后用户要求暂停 GitHub，覆盖此前授权；不再使用会话令牌。MIT、CITATION.cff、NEWS、网页源与归档材料已准备，记录见 `docs/RELEASE_ARCHIVE.md`；正式网址/DOI 未建立，Zenodo 未配置。凭据未写入文件。

### 4.4 共同任务与机制准备阶段（2026-10-09，历史时点）

**本节的“0 调用、未拟合、未完成”仅描述正式执行前的准备快照，已由第 1 节的正式结果取代。** 会话日期为 2026-10-09，主机日志实际 UTC 显示 2026-10-08，不改系统时钟或旧日志。

- 核对当时系统库无 BioExplainR/iSEE/SCassist/ellmer/GPTCelltype 安装，无模型密钥变量、Ollama 或 llama-server；历史安装/传输 pass 不能当当前实测，`research/results/related_tools/` 当时仅为旧记录。
- 保存 24 任务 × 5 整数 facts × 3 重复方案：airway/pasilla，50/200 行，α=.01/.05/.10、lfc=0/1；五方法为 BioExplainR 离线、base R、ellmer 直接读表、ellmer 读 facts、BioExplainR 客户端读同 facts，预定分母、时间、tokens 与任务级 bootstrap。当时 runner、输入、参考真值和顺序尚未冻结/实现。
- 独立 `/tmp/opencode/common-performance-R-library` 成功安装并载入 ellmer 0.5.0 及依赖；sudo 失败后下载/解包 libcurl 开发 deb，本地链接现有 libcurl，不改系统 R 库。
- 实际取得 llama.cpp b11429 CPU 归档 17,693,462 bytes，Qwen2.5-1.5B-Instruct Q4_K_M 1,117,320,736 bytes；checkpoint 重新计算 SHA-256 与上游值一致。实体在 `/tmp/opencode/common-performance-runtime/`，当时只下载/解包，未启动推理。
- 固定 SPARCL1，保存 GSE229084 GR 降解 KH-103/MIF/Cort113 三项预定差中差与 Holm，以及 GSE95632 ASM GR/RNAPII 峰窗口、控制和 assembly 核验方案；原 freeze 为 `discovery_mechanism_v1/frozen_protocol.json`。
- 取得并逐 hash 核对 5 输入：GSE229084 样本 metadata、series、geneCounts，GSE95632 metadata、Gazorpak 2023 原文 XML。geneCounts 2,524,990 bytes，SHA-256 `db961e988dfe8466d6a2426be60f2ec8976698648f48c1b52653fa65ed5ae466`，gzip 全读 CRC 通过，方案冻结早于计数下载；当时尚未读取候选表达、处理映射或拟合。输入清单 `research/results/discovery_mechanism_v1/input_manifest.json`。
- 快照 `research/results/common_performance_checkpoint_v1/checkpoint.json` 标记 `preparation_partial`、0 模型调用、0 评分、未拟合；模型/runtime hash、ellmer 载入、方案与 5 输入重新核对，SCassist 半包和失败日志保留。`performance-runtime-acquire-final.txt` 为空、无完成 JSON，`runtime_manifest.json` 当时未生成，不能标 pass。
- 当时 GPTCelltype/GeneAgent 源码未取得，iSEE/GPTCelltype/SCassist/GeneAgent 未安装或运行；四专属工具的完整适用性记录待完成，不得将不适用当错误或性能 0。GSE95632 人 HASM2 metadata 写 mm9，assembly 当时 `unverified`，不得猜 hg19 定位；Sasse XML 返回 500，浏览器阅读不是已保存 XML/峰的替代。
- 准备阶段 r12/baseline-10 交付通过，只证明准备文件审计通过，不表示研究完成；三份文档原 v0.8 网站修复/上传段与 HEAD 逐字一致，v0.9.1/v0.10 链接有效，Python 语法通过。恢复缺失输入的历史入口为 `python3 research/discovery/prepare_mechanism.py research/results/discovery_mechanism_v1 --resume`，正式分析脚本另冻结，旧失败和中断不覆盖。

## 5. 软件、公开开发案例与历史验收

### 5.1 软件与任务基线

- 工作目录 `/home/ubuntu/creatR`；历史软件/模型结果版本 0.3.1，开发版 0.4.0.9000。当前 90 个导出函数，含新增 `bio_validate_project_relations()`；历史 74 个 API 的源码/真实安装包名称与位置参数顺序各 74/74 通过，不是全部行为等价证明。
- English 默认，`language="zh"` 切中文。模型解释默认完整 facts，超预算明确失败；旧 payload 位置参数保留 bounded 兼容。大型矩阵、原始图像/坐标和样本映射留本地。
- Shiny 监听 127.0.0.1，不同会话工作区隔离但共享 R/文件/网络权限；独立 bwrap 工程探针不能为 Shiny 宣称多租户沙箱。
- W00 done；W01–W09/W12 ready_for_review；W10-A/B 已有 miniACC 公开开发案例，W10-C/W11 blocked_external，W13 in_progress。工程检查不能代替独立科学/人员/伦理/发布验收。
- 负责人已授权执行者选择公开测试数据并保留结果；专家评价待软件、案例和材料准备完成，W11-U 用户体验/学习增益研究 `deferred`。决定已同步伦理、任务卡、用户事项与交付文档。
- v0.8 时 Git 无 HEAD、文件未跟踪是当时状态；后续已有本地提交。当前工作树含未提交修订，原 2,905 保护文件和旧成果均不得 reset/clean/删除或覆盖。

### 5.2 基线修复与验收（2026-10-05）

详细记录：`docs/implementation_records/CONTINUATION_REVIEW.md`。修复覆盖 context identity、legacy missing、payload/list/URL/private 字段、typed aggregate/type/scope/unit、evidence pair、sample map、MAE/Spatial、docking、project/diagnose prompt、W09 artifact/replay/score 和 Shiny 详情；后续增加 auto evidence 回归修复、usage token 保留、公开证据 URL 结构化过滤、HTTP 实际 bytes/hash 两协议验证及 Shiny/bwrap 边界。新功能不能倒写为 0.3.1 历史功能。

|验收|当时实际结果|`research/results/w00_baseline/` 入口|
|---|---|---|
|源码/build/check|648 项：647 pass、1 skip、0 failed/error/warning；build 成功，check Status: OK，0 ERROR/WARNING/NOTE|`acceptance-source.*`、`acceptance-build.*`、`acceptance-package-check.*`|
|历史 API / 依赖|74/74 名称/位置参数顺序；MAE 1.28.0、SpatialExperiment 1.12.0 手算专项，全部 Suggests installed|`acceptance-legacy-api-result.json`、`continuation-optional-dependencies.csv`|
|HTTP|loopback OpenAI/Anthropic 实际 body hash/bytes、极小 p/PCA/null、usage；503 retry=2、401=1|`acceptance-http-result.json`|
|Shiny / 安装离线|payload/typed/evidence/manifest、转义、英中、报告、MAE、双会话，1440/390 无溢出；完整依赖与 Imports-only context→typed→project→HTML|`acceptance-shiny-browser/summary.json`、`acceptance-full-smoke/`、`continuation-core-*`|
|隔离边界|input readonly、越界拒绝、gold/home 未挂载、host listener 不可达、scratch report、资源限额和 timeout|`acceptance-sandbox-result.json`|
|contract/W09/W12|5 个正反例按预期接受/拒绝，3 个 W09 流程测试，W12 template|当时 fixture/benchmark 日志|
|历史稿件 / 清单|38 refs、35 Figure PDF、13 主稿 Word/Excel 表、4 补充表，PDF 65/10 页，7 图/13 表双视口；current 动态规模与 historical 54/225 独立审计通过，2,905 原文件 hash 不变|`continuation-submission-audit-result.json`、`current_audit.json`、`historical_audit.json`|

### 5.3 miniACC 开发案例与工程完善（2026-10-07）

详细记录 `docs/implementation_records/PUBLIC_CASE_CONTINUATION.md`；方案、脚本、独立复核器位于 `research/multiomics/`。

- `R/sample-map.R` 重新校验已构造映射，拒绝重复/缺失 observed ID，追加 `primary_units`，返回 modality coverage、pairwise intersection、完整/未测量病例数；映射合法不表示模态齐全。
- `R/adapters-multiomics.R` 接入覆盖/交集 facts，原始映射和病例 ID 留本地；`R/project-relations.R` 核对 dataset/comparison/species/tissue/sample_level、numerator/denominator、显式 feature_id、有限非零效应正负号，支持 exact-token 路径。未知/零效应不自动通过，符号一致不等于显著性、因果或独立证据。
- `R/project.R`、`R/report.R` 自动检查方向关系，报告/model payload 展示 findings 与覆盖；roxygen 更新 NAMESPACE/man，新增 `test-project-relations.R` 29 项检查，README、DATA_CONTRACTS、MIGRATION、专家评价说明同步。
- `research/results/miniacc_development_v1/` 保存 TCGA-ACC miniACC（MAE 1.28.0）：92 病例、5 模态，43 五模态齐全；RNA/蛋白配对且分期已知 46（early 28、late 18）；33 共有特征，18 同向、15 反向；RNA BH<0.05 为 3、蛋白为 0。方案、源对象、sampleMap、输入长表、结果、context/project RDS、双语 HTML、版本和 hash 均保存。
- 源码 677 项（676 pass / 1 skip），build/check OK；Python 复核 23 文件 hash、66 效应、方向、覆盖和 BH，但未独立重算 Wilcoxon 原始 p。current/historical 通过，2,905 原文件不变；r5 464 成员，含 miniACC 24 文件（含 manifest）。日志 `improvement-source.*`、`improvement-build.*`、`improvement-package-check.*`、`improvement-miniacc-audit.*`。
- 该轮未新增 HTTP/Shiny/bwrap、安装后新增接口 smoke 或旧 API 专项。案例是开发来源，不是独立 test/gold、专家评测或生物学泛化结果。

### 5.4 “仔细检查”修复与安装包复现（2026-10-08）

前会话止于静态审阅/手工探针，拟修复 patch 未应用；续接已完成修复和适用验收，见 `docs/implementation_records/REVIEW_CONTINUATION.md`。

- 过期 r3/current 改为当时 r6，数据集 hash 改为 v1 原输入 RDS 真实 SHA-256；执行者选数据、专家后置、用户研究 deferred 和交付边界同步。
- `run_miniacc.R` 增加 `--installed`，manifest v2 使用运行目录相对路径，保存模式/版本/包路径；tar 实际安装至 `/tmp/opencode/bioexplainr-install-review/` 后运行，输出 `research/results/miniacc_installed_review/`，不覆盖 v1。8 个核心表与 v1 逐字节一致，同一来源复现不增加独立样本量。
- `audit_miniacc.py` 支持旧/新 manifest 异地回读，仅访问给定目录；要求 23 成员、唯一主键、完整覆盖/交集/测量/关系/findings/反例，拒绝越界/symlink/缺失/重复，重算分组、66 效应、方向、BH 和摘要；未从 RDS 解码原始矩阵，未独立重算 Wilcoxon p。
- `tools/offline-smoke.R` 增加安装后覆盖/完整/未测量、含点号 exact-token opposite 关系、错方向拒绝和 HTML 展示；API 工具支持安装模式，环境采集唯一 prefix，打包/采集拒绝覆盖旧证据。

|验收|当时实际结果|`research/results/w00_baseline/` 入口|
|---|---|---|
|源码/build/check|677 项：676 pass / 1 skip、0 failed/error/warning；build 成功，check OK，0 ERROR/WARNING/NOTE|`review-source.*`、`review-build.*`、`review-package-check.*`、`review-00check.log`|
|API / 安装|源码/安装包各 74/74，安装导出 90；完整/Imports-only context→typed→coverage/direction project→HTML，全部 Suggests 可加载|`review-legacy-api*-result.json`、`review-api-inventory.csv`、`review-full-smoke/`、`review-core-*`、`review-isolation-result.json`、`review-optional-dependencies.csv`|
|miniACC 数值/边界|两次结果各 23 文件、66 效应/方向/覆盖/BH 通过；16 tests，包括异地、拒绝覆盖及重写 hash 后损坏拒绝|`review-miniacc-audit.*`、`review-miniacc-installed-audit.*`、`review-miniacc-boundaries-final.*`|
|契约/W09/W12|5 契约正反例、3 W09 测试；W12 仍 1 行 template|`review-contracts.*`、`review-benchmark.*`、`review-w12.*`|
|HTTP/Shiny/bwrap|两协议 body hash/bytes/精度/usage/retry/401；Shiny 英中/下载/转义/MAE/双会话/1440 与 390；只读/越界/gold/home/network/scratch/限额/timeout|`review-http-result.json`、`review-shiny-browser/summary.json`、`review-sandbox-result.json`、`review-bwrap.*`|
|Python / 清单|语法及 3 个 current 损坏探针通过；r6 598 成员完整性通过，current/historical pass，2,905 原文件不变|`review-python-syntax-final.*`、`review-audit-probes-final.*`、`review-delivery-audit-result.json`|

该轮未改包功能或重导出主稿/图表。sandbox 只挂载 host runtime/安装库/public fixture，gold/project/home 不挂载，实测无网络/只读/scratch/限额/timeout；不是全新容器镜像或正式模型代码代理研究，早期失败保留。

### 5.5 0.3.1 历史模型与人工聚合记录

以下为保存记录，后续离线核对不能算新模型调用或独立人员评价：

- airway、PBMC3k、pasilla、ALL、bladderbatch 五公开对象入口 5/5 pass；pasilla 六阈值组 30/30 facts 匹配。
- 主机制实验 120 程序生成 cases、480 unique target facts、3 输入 × 3 重复，1,080 requests / 4,320 scores。direct_bounded 437/1,440（覆盖 516/1,440，已回答 437/516）；facts_only/evidence 各 1,440/1,440，不是独立生物学泛化准确率。
- StepFun step-5-preview、DeepSeek deepseek-flash 各 120 请求、480/480 匹配；600 case-method 行包含 deterministic、agent `not_configured`、replay `missing`，不能合并为 API 分母。
- 相近工具只是入口兼容检查，btw 未安装。外部评价只核对匿名聚合一致性，原评分、人员与伦理待负责人核实。
- 历史人工聚合 720 维度评分、150 功能评分，均分 1.751/2、91.98/100，144/150 有用；不是正式用户任务、ICC/SUS 或学习增益。v0.8 新稿不写旧专家/用户评分。

## 6. 交付归档与完整性范围

归档统一路径为 `docs/BioExplainR-development-delivery-0.4.0.9000-rN.zip`。以下均为各轮当时验收记录，不表示与本次合并后的文件树仍一致。

|归档|当时范围/规模|SHA-256|完整性结果入口（位于 `research/results/w00_baseline/`）|
|---|---|---|---|
|r5|464 成员，含 miniACC 开发案例|见对应实际结果|`continuation-delivery-audit-result.json`|
|r6|598 成员，安装包复现与审阅修复|见对应实际结果|`review-delivery-audit-result.json`|
|r7 / baseline-6|v0.8、图表、15 场景、真实 RDS、工具/日志；787 成员，75,313,559 bytes|`59993a682dd0f0f9cbe51cfe582234f5b846b5df748b40ff5f33daf0f2953581`|`paper-cn-delivery-audit-result.json`|
|r8 / baseline-7|v0.9 与外部案例；959 成员，114,625,818 bytes|`b639f263f0ede6bd365c2b941ea2f9ca1a52c5e6f29fdd5a758829626c05ce1b`|`revision-delivery-audit-result.json`|
|r9 / baseline-8|v0.9.1 图表正文修订；1,073 成员，135,296,414 bytes|`c1b4ae29ebef0d8dd92292b28faafdddf810d90cdbae7e64ccaa4a9b678c19f8`|`revision-links-delivery-audit-result.json`|
|r10|交接文字更新；1,073 成员，135,298,936 bytes|`53e45cfa8777618ef055cda5b4f61047378295491317944023a36d2a4ab6258f`|`handoff-delivery-audit-result.json`|
|r11 / baseline-9|v0.10、两个后续分析模型/数值/报告/配对原表/复现工具；1,355 成员，202,742,054 bytes|`2aabcc9e7160410b0d058ebc5c75bc57cdc7159290835cb5bed260eca8228478`|`biology-delivery-audit-result.json`|
|r12 / baseline-10|准备方案、5 输入、快照及失败记录；1,386 成员，205,362,776 bytes|`93b7263b017ae52f7dc91b42ee1d1b52f8a250c2292221bd52253d65bbe54784`|`followup-delivery-audit-result.json`|
|r13 / baseline-11|正式共同任务、机制、ChIP 与研究增补；2,871 成员，365,123,176 bytes|`66cf0dfbf72ff55ce954ef129c8eb6472adc77eb3867a7560dbfcc59eb7afc2e`|`continuation-formal-delivery-audit-result.json`|
|r14 / baseline-12|三份交接文档和索引更新；2,875 成员，365,126,583 bytes|`817bf7f2aa11a475909c0a6d054354c873ec12d78ca35df6abec38e66508f851`|`handoff-formal-docs-delivery-audit-result.json`|

- r11 当时 current/historical 均 pass，当前稿 102 文件、因子干预 36、多供体 29 接入索引，2,905 原保护文件逐 hash 不变。原始 TPM 不进入 ZIP，`excluded_inputs` 保存 121,575,832 bytes、SHA-256 `30ebc92ddbd40bf4dedab57d05b46ba10a763c0130c89f6154862b351189277f`、URL/恢复命令；`--preserve-report` 恢复缺失输入时不改历史下载报告，完整工作区 manifest 仍核对原输入。
- r12 排除当轮 26 MB 不完整 metadata 及临时模型/runtime/R 库；模型/runtime 实体不随 ZIP，checkpoint 保存大小/hash，准备阶段恢复入口为 `setup_runtime.py`。current/historical 当时 pass，但分组为 `preparation_partial`。
- r13 逐成员大小/hash/当时树一致，current/historical pass，2,905 原保护文件不变；网页索引 10 链接与 v0.9.1/v0.10 入口有效，原网站/上传正文与 HEAD 一致。首次历史 marker 检查失败保留，包装器修正后通过。
- r14 只同步交接文档/索引，不新增研究成绩；逐成员核验、原网站/上传正文保留、链接、适用语法和 diff 检查通过，根交接独立进入 documentation 清单。原交接在 r14/baseline-12 验收后又追加收尾文字，未再打包/重建清单；使用 current 完整性结论前须重新同步并复核，不能沿用旧文档 hash。
- r1–r14、原 2,905 保护文件、v0.10 与更早稿件均保留。最新真实状态以 `current_audit.json`、`historical_audit.json` 及实际 `manifest_sha256` 绑定为准。
- 当前 tar 为 `BioExplainR_0.4.0.9000.tar.gz`，历史 `BioExplainR_0.3.1.tar.gz` 保留；旧图表 35 PDF / 13 Excel / 2,770 记录 ZIP 不改写。`docs/BioExplainR-user-guide.docx` 为历史 0.3.1 指南，新接口读 DEVELOPMENT_DELIVERY、DATA_CONTRACTS、MIGRATION 与安装帮助。
- 旧 `BioExplainR-submission-bundle.zip` 为 `historical_stale`：210 成员、132 当时内容变化、2 旧路径缺失，记录 `bundle_inspection.json`；不能覆盖原保护清单。私有服务器 #32/#33/#34 早于最终修订。
- 暂存源码及 r8 的常见凭据格式扫描当时 pass、0 发现；外部 PAT 未写入文件。密钥不写源码、日志、manifest 或交接。

## 7. 用户事项与历史上传

唯一用户待办入口为 [docs/USER_ACTIONS_REQUIRED.md](docs/USER_ACTIONS_REQUIRED.md)，限科学材料/决定、真实人员/伦理、在线预算/发表授权、作者信息及人工/第三方身份确认。下载、hash、映射校验、自动测试和打包由执行者完成。

本地待办于 2026-10-08 同步负责人决定；外部 #35/#36 仍为 10-05 版，未重新上传，旧 hash 不对应当前本地文件。

### 7.1 用户待办私有上传（2026-10-05）

|项目|实际记录|
|---|---|
|目标|`http://62.234.106.117:8003/api/agent-upload`，HTTP 200、`ok: true`|
|文件|`docs/USER_ACTIONS_REQUIRED.md`，3,920 bytes；SHA-256 `6dcf5b59e29bc3711f58538c89eaf8b4ba9aa1f79d76c8232fb847d5e13527ce`|
|服务端|#35，上传者 id 4，`is_public=0`，2026-10-05T15:43:53.868Z|
|服务端文件名|`1791215033858-2609292399-USER_ACTIONS_REQUIRED.md`|
|返回地址|`http://62.234.106.117:8003/api/{download,preview,file}/35`|
|回读|download/file/preview 带和不带 token 均 HTTP 403，未完成上传后内容比对，服务端副本未验证|

该动作只上传待办清单，不含源码、稿件、数据或人工评价材料；当时本地文件为唯一可核对来源。凭据未写源码/manifest/文档/日志，后续核验需具下载权限账号或凭据。清单和原保护清单不受外部上传影响，后续重传另记新编号。

### 7.2 同一待办公开上传（2026-10-06）

|项目|实际记录|
|---|---|
|目标|同一 agent-upload 服务，HTTP 200、`ok: true`|
|文件|与 #35 同一内容，3,920 bytes；SHA-256 `6dcf5b59e29bc3711f58538c89eaf8b4ba9aa1f79d76c8232fb847d5e13527ce`|
|服务端|#36，`is_public=1`，2026-10-06T00:25:31.958Z|
|服务端文件名|`1791246331956-1930385959-USER_ACTIONS_REQUIRED.md`|
|公开地址|`http://62.234.106.117:8003/api/download/36`、`http://62.234.106.117:8003/api/file/36`、`http://62.234.106.117:8003/api/preview/36`|
|回读|三个地址匿名 HTTP 200，SHA-256 与当时本地文件一致|

#35 与 #36 是同一文件的私有/公开两条历史记录。撤销公开访问需在服务端删除或改私有；本地文件不随之改变，重传追加新编号。上传凭据未写入任何文件。

### 7.3 尚未完整覆盖的工程/评价

自动全覆盖分块协议、超出显式标量符号关系的跨模态联合检查、Seurat spatial/复杂图层、真实引擎版本格式、全部 API 行为独立 sign-off、新独立 test/gold/评价、fresh OS、正式 lockfile 与远程矩阵仍未完整覆盖。W10-C/W11/W09 最终独立评价需另冻结真实专家/参考材料，不补造结果，不看 test gold 调规则后报同一 test 结果。

## 8. 环境与适用复现命令

历史记录环境为 Ubuntu 24.04.4 / R 4.3.3 / Bioc 3.18；系统 R、论文 venv 和 Node 工具已恢复。环境定义见 [docs/REPRODUCTION.md](docs/REPRODUCTION.md)，恢复脚本 `restore-baseline.sh`、`restore-development-optional.sh`。依赖清单记录实际版本，不宣称 transitive lock；临时目录与服务状态须按当前环境核实。

以下是软件和历史案例的复现入口，不是本次合并已经执行的命令。新运行使用新输出目录/label，不覆盖旧结果；源稿/表/图改动时才重导出。

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

HTTP/Shiny acceptance 自动启动/停止本地服务，无真实模型调用；sandbox 依赖当前可用 sudo/bwrap，不可用环境不能标 pass。正式后续研究的保存结果复核与同 hash runtime 恢复，以研究增补 README 为准。

## 9. v0.8 原始实施、网站修复及公开上传记录

以下完整保留 `PAPER_CN_CONTINUATION.md` 的 v0.8 原始实施与上传段。该段“当前”“本轮”“下一轮”均指 **2026-10-08 的 v0.8 阶段**；相对资源路径指 `docs/paper_cn_v1/` 内部，最新主稿和续接顺序以第 1–4 节为准。网站重载、服务回读、测试及归档数字都是历史实测记录，不代表本次重新执行。

以下为v0.8阶段的原始实施与上传记录。

日期：2026-10-08；软件0.4.0.9000；本次按负责人要求完成中文稿、案例、图表及指定服务公开上传。专家评价后置，用户体验/学习增益deferred。

### 阅读基线

已阅读SESSION_HANDOFF、REVIEW_CONTINUATION、PUBLIC_CASE_CONTINUATION、CONTINUATION_REVIEW及current manifest。修改前current audit pass，r6再次核验**598成员**；该验证只对应修改前文件树，结果`paper-r6-start-integrity.json`保留。旧稿、历史图表和2,905原保护文件不覆盖。

### 新论文入口

- 唯一中文当前稿目录：`docs/paper_cn_v1/`，详见其README。
- `BioExplainR-中文论文-v0.8.pdf`：**23页**；可编辑DOCX和自包含HTML同目录；文字源`manuscript.md`。
- 细化方法为10小节，补充完整事实/预算、scope/design/unit、映射分母、方向关系、各案例预处理、Wilcoxon/BH、评分分母和版本边界；结果按airway、PBMC/微阵列、pasilla、miniACC、模型传递、机制场景及工作台组织。
- 作者、单位、通讯、贡献、基金、利益冲突及公开仓库/DOI留位。新版不包含旧专家/用户评分，末尾附录C预留独立专家、使用体验、学习效果与独立验证。
- 29参考文献均有引用；miniACC来源新增MAE方法和TCGA-ACC原文。TCGA-ACC doi/title/author/page/year通过Europe PMC检索核对，旧引用沿用已有出处。

### 图表组织

- **8张合图、32张独立panel PDF**，保存在`figures/composites/`、`figures/panels/`；框架图有原创数据库/图/网络/check/report矢量图标。
- 每图由4个PDF以PyMuPDF show_pdf_page组合，正式论文PDF直接嵌入合图矢量内容，不只是预览PNG；图8真实页面截图为位图素材。
- **9份XLSX+9份CSV**在`tables/`。论文数据表为0，仅保留正文引用和附录B表题/表注/来源；XLSX另含说明来源表。
- `assets_manifest.json`保存图表hash与合图成员，`export_report.json`记录论文直接嵌入位置，`audit.json`保存数值/引用/几何/表数据审计。
- 独立论文附件包`docs/BioExplainR-中文论文-v0.8-图表附件.zip`：**76成员**、7,670,920bytes，SHA-256 `f4e2f023be340ee4daacabb2d1eb50fe39ec66fcc5aec5d7d2411e4732ea137c`。包含稿件及图表，排除Word转换中间PDF。

### 新增案例及网站修复

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

### 实际验收

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

### 公开上传记录

负责人明确提供指定服务及`is_public=1`。只上传新稿和论文图表附件，HTTP200、ok:true；鉴权凭据未写入任何源码、交接、manifest或执行日志。

|服务编号|文件|bytes|SHA-256|公开下载|
|---|---|---|---|---|
|#45|BioExplainR-中文论文-v0.8.docx|1,093,006|fe68b2754c8cc349baf5239536c91ddbc8b1618fd02c9c9a934c4071a23752d8|http://62.234.106.117:8003/api/download/45|
|#46|BioExplainR-中文论文-v0.8.pdf|2,802,383|5a838cae8e801775a60fae1731a25d0740e6303a5724eec22520501fa433233d|http://62.234.106.117:8003/api/download/46|
|#47|BioExplainR-中文论文-v0.8-图表附件.zip|7,670,920|f4e2f023be340ee4daacabb2d1eb50fe39ec66fcc5aec5d7d2411e4732ea137c|http://62.234.106.117:8003/api/download/47|

上传UTC分别为09:35:22.964Z、09:35:23.407Z、09:35:30.660Z；上述3文件均以匿名download/file回读hash一致。再次修改稿件时新建版本/上传记录，不覆盖本次编号。

### 当前清单和下一轮

`manage_baseline.py`新增paper_cn_cases/paper_cn_revision分组与baseline-6，实际软件记录采用paper-cn；新交付r7以`paper-cn-delivery-audit-result.json`为唯一完整性入口。current audit检查新稿审计与15场景。r6当时ZIP保留，不能要求其与修改后树一致。SESSION_HANDOFF在打包后更新，不进入开发ZIP；随后重建manifest和current/historical audit，以最终manifest_sha256为准。

下一轮继续围绕中文论文和实际写作中发现的工作台问题推进。引用旧结果标明0.3.1，新增结果标明开发数据和所测版本；专家在材料准备完成后，用户研究deferred。新建论文目录版本/运行输出/执行label，不覆盖原保护清单。最终人工图稿审阅、独立科学/人员研究、作者基金和公开发布信息留于附录C。

## 10. v0.8 阅读、资源与历史复现入口

本节合并 `docs/paper_cn_v1/README.md` 的资源及命令。所有稿件资源位于 `docs/paper_cn_v1/`，仅作历史编辑/复现参考。

- `BioExplainR-中文论文-v0.8.{pdf,docx,html}`：23 页 PDF、可编辑 DOCX、自包含 HTML；Word/网页 8 图、0 数据表。`manuscript.md` 为文字源，作者/单位/通讯/基金/贡献留位，附录 C 预留专家/用户/学习效果/独立验证。
- `figures/panels/`：Figure_1A 至 Figure_8D 共 32 独立 PDF；`figures/composites/`：Figure_1 至 Figure_8 共 8 四联合图，PyMuPDF `show_pdf_page` 保留矢量，图 8 页面截图是位图；`figures/previews/`：8 张高分辨率 PNG，仅用于 Word/HTML。
- `tables/`：9 XLSX 与 9 UTF-8 CSV，XLSX 含说明/来源工作表，正文和附录 B 按表 1–9 引用。`assets_manifest.json` 保存源文件 SHA-256/合图成员/表结构，`export_report.json` 记录矢量图嵌入，`audit.json` 记录数值、引用、DOCX/CSV/XLSX 和几何检查。
- `rendered_docx/` 是含预览图的 Word 转换中间 PDF；正式历史稿使用目录根部 PDF，其中预览已替换为合图 PDF。
- 6 公开来源为 airway、PBMC3k、pasilla、ALL、bladderbatch、miniACC；v0.8 新增 airway 9 阈值 × 5 facts = 45 核对、15 开发场景，结果 `research/results/paper_cn_cases_v1/`，脚本 `research/paper_cn/`；miniACC 见 `research/multiomics/` 与 `research/results/miniacc_installed_review/`。

下面保留 README 原有命令。`--refresh-draft` 是 v0.8 尚在编辑时的用法；当前历史稿已归档，继续工作应复制脚本到新版本并改输入/输出路径，不直接覆盖旧资产或保护清单。

```sh
Rscript --vanilla research/paper_cn/run_cases.R research/results/paper_cn_cases_new
# 已有v1资产拒绝默认覆盖；--refresh-draft只用于尚在编辑的本目录。
/tmp/opencode/paper-venv/bin/python research/paper_cn/build_assets.py --refresh-draft
/tmp/opencode/paper-venv/bin/python research/paper_cn/export_manuscript.py
/tmp/opencode/paper-venv/bin/python research/paper_cn/audit_manuscript.py --output /tmp/opencode/paper-cn-audit-new.json
NODE_PATH=/tmp/opencode/node_modules BIOEXPLAINR_PAPER_CN_BROWSER=/tmp/opencode/paper-cn-browser-new node research/paper_cn/browser_manuscript.cjs
```

图表脚本固定回读 v1 案例路径；另跑新案例需用新版本脚本/路径。依赖定义见 `tools/paper-requirements.txt` 和 `docs/REPRODUCTION.md`。历史记录的 PDF 解析/文字几何检查不等于独立人工图稿审阅，新增开发场景不是独立 test-gold，历史模型响应未重跑。
