# 实际执行与修订（2026-10-10）

1. 阅读根rgo、前轮公开检索原响应与脚本、PXD055968最新最终入口、缺件与
   未发送请求。发现旧两关键词都只保存page0各100项；旧临时目录无
   `PXD029135_median-normalized.txt`、无`verified_downloads.json`。不将其
   原叙述追认为本地可复核的完成记录；原临时61文件及三个脚本逐字节复制
   到新`imported/`，原路径保留。
2. 新目录启动先保存现rgo精确快照`rgo_before_continuation.md`，以及前轮
   `/tmp/opencode/rgo_before_public_search_20261010.md`精确原字节到
   `rgo_before_public_search.md`。后者与旧handoff清单绑定根rgo精确hash
   匹配后执行层叠验证；开始旧证据通过、原2,905保护文件通过。
3. PRIDE15关键词/负控制、18页全部取得。DEX113/GC105/smooth muscle165；
   全部同查询分页无重复，并与响应头`total_records`一致。总437查询命中，
   跨查询去重391项目；文本21线索逐项读取样本/设计，不称21成人ASM队列。
4. 四项目新完整清单22/54/72/56共204项。PXD055968按name/size/accession/
   checksum复核与原56项完全一致。未读取新RAW/MSF/pdResult/7z。
5. HBEC首请求HTTP200，但121.8秒达到限时，只得1,769,472/2,055,550bytes；
   原部分表及失败日志保留。另冻结带ETag的Range计划，HTTP206取
   1,736,704–2,055,549（318,846bytes），核对Content-Range、ETag及32,768
   重叠字节，合成**另名**完整表；2,055,550bytes/上游SHA1通过，未覆盖部分。
6. 新有效全文XML取得PMC11161633和PMC8688760。PMC11299423/5105184/
   9361782 XML各HTTP500；PMC HTML两连接reset，PMC5105184 HTTP200实际
   reCAPTCHA挑战页（21,313bytes），不作正文。三DOI原出版社及肺内ASM
   原PDF各403，Zed补充URL DNS失败；响应/错误按实际保留。
7. HBEC表3,072×46，43样本与作者SRDF和community SDRF全匹配；10个体四格
   主设计及5high/5low平衡，纠正旧“T2与ICS部分混杂”。PRIDE HF与原文/
   community HF-X仪器标注差异保留。三个mzTab本地压缩字节130,946/
   151,987/135,512，上游SHA1及gzipCRC通过；PRIDE大小753,018/871,109/
   770,183对应解压字节，不将压缩大小差记作下载不完整。
8. PXD015604条件初写“A-F加G-I”尚未封存时发现与原OOXML不符，审计前
   纠正为A-F各3重复及asthmatic/control epi各4重复；科学原字节不改。
   该映射仍不解码A-F的真实病组/供体/处理，不凭标题编造GC或独立供体。
9. 首次独立审计通过后追加原交接全文逐字节保留、旧临时请求hash与原OOXML
   单元格独立对照。原审计JSON不改写；修订前审计源码按精确hash恢复为
   `code_snapshot/audit_public_proteome_initial.py`（15,315bytes、SHA256
   `1dba5a9d34ac675fc10666ca688814299bd5d650408c995767630edc243ef4ab`）并核对
   原JSON绑定一致。最终新清单与verification对应增强审计源码。
10. 协议检索段初写“前轮11个真实关键词及负控制”计数误述；冻结的实际
    KEYWORDS为前轮**10真实词+1负控制**，新加4词，实际**14真实词+1负控制**
    共15查询。以原计划/实际请求为准；原冻结协议不改写，此处明确纠正。

本轮仅做来源、完整性、样本结构和可行性核对；候选效应/配对统计/BH/Holm
均未运行。最终验证入口及结果见README与independent_audit/verification；
旧清单不覆盖，新增封存只绑定新研究与根rgo，GitHub/外部上传继续暂停。
