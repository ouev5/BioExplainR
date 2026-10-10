# 公开蛋白组续接结果（2026-10-10）

## 实际新增结果

|工作|结果与可复核入口|
|---|---|
|检索分页闭合|15查询（含负控制）18页，437查询命中、391唯一项目；DEX113、GC105，相比旧各100项增加13/5。全部短页闭合，逐页与`total_records`一致。`search_coverage.csv`/`additional_page_design_review.csv`|
|ASM相关文本逐项审查|21项目完整题名/描述/样本/处理线索与21项设计审查；未取得合格成人原代ASM受控GC蛋白矩阵。`project_eligibility_review.csv`|
|新增项目清单|PXD014171/015604/029550/055968完整22/54/72/56项，共204；前3分别病灶LCM、BSM-上皮研究、肺动脉SMC。`asm_inventory_plan_acquisition.json`及各inventory|
|HBEC完整表取得|2,055,550bytes，上游SHA1 `c99601bc60192720d23fc10d18bc8ce50e5e849f`；3,072蛋白组行×46列（3注释+43样本），73,453有限值/58,643 NA。`sources/PXD029135_median-normalized_complete.txt`/`HBEC_table_design_checks.json`|
|HBEC样本结构|43/43按作者SRDF和community SDRF对应；10个体每人ICS前/后×polyIC四格，另3imiquimod。主设计T2-high/low每格5/5，未见T2与ICS状态混杂。`HBEC_sample_decode.csv`/`HBEC_design_counts.csv`|
|已有处理文件复核|A5495,428×25字节一致、无上游SHA1不宣称通过上游；三成纤维细胞mzTab SHA1及gzipCRC通过，PRIDE大小对应解压字节。`imported_processed_file_checks.json`/`mztab_compression_checks.json`|
|有效全文|Zed HBSMC全文原比较为PDGF±Zed，无GC、完整矩阵为合理请求；HBEC原文明确本论文蛋白比较为3例steroid-free HBEC±imiquimod，数据集包含更广43run不等于均用于此论文。`key_article_sections.md`/`article_design_passages.csv`|
|EV状态复核|PXD05596856项name/size/accession/checksum与前轮一致；原缺件与未发送请求原hash保留。`EV_inventory_recheck.json`|

## 可及性与范围纠正

前轮临时目录的HBEC完整表与最终下载日志本轮开始未找到；本轮实际另取完整
表并验证，而非宣称找回旧完成日志。旧清点文字保留为历史，本节优先。

HBEC确有10个体纵向ICS前/后结构，T2身份各人固定并平衡。前轮“T2-high/low
与ICS状态部分混杂”无此映射支持，已在新交接明确纠正。**临床前后变化仍
不能单独归因GC**：非受控体外GC/vehicle，时间/临床状态及用药背景不由此
排除；组织为支气管上皮、非ASM、非上清。论文描述Q Exactive HF-X，与PRIDE
项目Q Exactive HF标注不同，原差异保留。

三成纤维细胞mzTab分别压缩130,946/151,987/135,512bytes、解压753,018/
871,109/770,183bytes，后者等于PRIDE大小；上游checksum绑定压缩原字节。
PRT800/918/762及PSM2,872/3,326/2,984，蛋白表无abundance列，仅肽段/
谱计数，不能把三份鉴定结果改成候选差异矩阵。

## 新线索实际为何不满足门槛

- PXD014171：4个移植肺BOS患者的15个发表OB病灶；19个存档run在summary/
  SDRF对应，不能当19供体；混合LCM病灶且无GC。
- PXD015604：54文件，原映射含A-F各3重复、哮喘/对照上皮各4重复；项目为
  BSM影响上皮rhinovirus反应，无受控GC因素，A-F原条件意义及独立成人ASM
  供体未据这份映射解码；不启动候选比较。
- PXD029550：人原代**肺动脉**SMC（血管来源）DAGAR/m6A研究，72文件为
  谱/鉴定结果，不是GC×vehicle的气道分泌设计。
- 本轮DEX新增9个PBMC条件/胞内组分/分泌组项目均为同一3志愿者研究；另
  MSC脂肪分化、肝星状细胞多药分化、植物诱导及小鼠模型。GC新增HeLa DNA
  pulldown、Hsp90互作、线虫SGK1、小鼠海马和脂肪分化，均非成人ASM。
- Zed论文取得原文：真实HBSMC胞内PDGF±Zed，数据声明“合理请求”；不能
  将此合理请求扩为必须联系所有公开项目或加入PXD055968既有请求。
- 肺内ASM疾病蛋白文献、TAS2R磷酸蛋白、胎儿肺GC分泌及RA相关研究的
  元数据线索仍按实际记录；全文获取500/403/reset/challenge/DNS失败不证明
  数组不存在。胎儿、疾病比较或非GC刺激不替代成人ASM受控GC验证。

## 当前结论

新增可追溯的完整公开来源审查，**没有新增候选统计或确认**。
ANGPTL2/FSTL3/FBN2/PER2/METTL7A维持原结论。PXD055968仍待论文版本
未差异预筛18run定量导出、联合workflow/版本、原缺测与同版本肽映射、六
患者成人/年龄及重复层级说明；请求草稿未发送，身份检查未冻结/启动。
18run不当18供体，无GC因素EV身份不升级GC响应、主动分泌速率或功能因果。

证据保存与来源筛查完成，不称全球穷尽搜索；未取得合格数组不等于不存在。
