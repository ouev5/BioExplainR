# 实际执行、失败与修订

2026-10-10，UTC按主机实际保存。开始两次运行旧 provenance seal 均通过，新目录
开始前第三次核验并保存 `prior_verification.json` 和根rgo精确字节快照。

1. `files/byProject` 误用旧错误接口，HTTP200空body保留，不视为合格清单；
   `inventory_amendment.json` 改正确 `/projects/PXD055968/files?pageSize=100&page=0`，
   返回56项、少于100，FTP及checksum名字核对。旧错误响应不覆盖。
2. 首个 pdResult 1MiB probe 核对206/Content-Range/总长/SQLite头成功。
   只读APSW3.53.0.0 VFS随后按64KiB／256KiB块取得需要的原页，核对所有块的
   ETag/Last-Modified/范围/hash；每文件64MiB上限。没有自行填原蛋白缺测。
3. 串行17文件batch在600秒执行上限中断，run02–04完成、run05缓存保留；
   初次4worker续传被用户消息中断，无完成JSON，不标pass。续传去掉不必读的
   DataTypesColumns行，只保留schema和五张元数据表，协议与改变原因另freeze。
   完成后18文件全部通过，run02–04额外DataTypesColumns元数据保留。
4. 用户要求继续时原 `/tmp/opencode/provenance-venv` 已不在；恢复独立
   `/tmp/opencode/asm-ev-export-venv`，固定APSW3.53.0.0。工作区没有旧成果清理。
5. 首份 `version_summary.json` 量字段regex只找方括号，遗漏双引号Intensity；
   该初稿保留，不把其空字段当作无任何feature强度。complete补找两类引号；
   最终另 `schema_columns_exact.csv` 用SQLite实际DDL/PRAGMA解码全部1,620表，
   精确区分已有precursor/PSM强度和缺最终蛋白丰度。旧regex表列列表也有一般
   类型识别不全，最终仅用exact列索引。
6. 独立审计首轮读XML字符串时Python通用换行把CRLF转换LF，逐字断言失败；
   改以 `read_bytes()` 对原UTF-8字节，通过。原XML不改。builtin sqlite3不是
   网络APSW读器，从已核对字节块的临时稀疏只读视图重读全部保存元数据/schema，
   包含XML／blob hash；不把临时部分视图宣称为完整原数据库。
7. 官网OA两入口404／reset；Zenodo带引号accession400，去引号后有效0；
   原文DOI查询500；Figshare和ScienceDirect403；Elsevier200仅元数据XML。
   所有请求和失败次数保留，不把HTTP成功自动称全文或完整数组取得。
8. 本轮先冻结来源获取，源码随实际接口/中断/列解析修订发生变化；早期freeze
   的code hash是当时版本记录，未另保存每个早期脚本精确快照，不能声称它们
   与最终源码hash仍相同。`final_evidence_freeze.json`是明确的获取后证据冻结，
   绑定最终输入/脚本，不伪装候选分析前冻结。候选结果尚未读取。

没有候选身份、疾病或GC差异分析，没有新模型调用、湿实验、人工科学审阅或
作者联络。正式状态是 `blocked_missing_final_export`，来源探查通过并不代表
候选验证完成。下一步需真实外部材料，草稿和缺件要求已保存。
