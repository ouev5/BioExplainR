# PXD033504 实际执行记录

- 2026-10-10会话；主机freeze/HTTP UTC仍显示2026-10-09深夜，不修改系统时钟。
- 开始先执行旧 `seal_set_validation.py verify`，17,257文件、79源码、旧附件/
  续接包及2,905保护文件hash通过；随后保存精确rgo和旧latest依赖。
- inspect成功：24h单固实block，72h两个；映射与目标表跨全部block，需
  447,338,271 + 645,402,933压缩字节。与前轮proteome不同，header+这些block
  可覆盖全部容器，新增真实上游SHA1逐字节核验，不沿用“部分容器”结论。
- 初次extract24并发：部分HTTP成功，但6553632–6815775连续四次curl7连接失败，
  无完成extraction。成功段/空失败body/headers保留。续传降8并发、重试退避，
  不覆盖旧段及失败；具体版本hash在extraction_attempt保存。
- 24h原解码不同于proteome：LFQ列使用日期而非数字ID，六标签/36列，原
  MaxQuant1.6.11.0。在候选数值提取前按真实header/summary调整解析器，
  不能把旧proteome七标签或1.6.15版本冲突搬到secretome。
- 72h完整数组/CRC/SHA1取得后，首个design命令在summary原RAW名为数字ID的
  检查处停止，尚未写designfreeze/数值输出。按72h原解码恢复数字→日期，
  同时保留内部RAW名及PRIDE提交日期文件名；统计规则/名单未变。
- 完整数组统计与R独立审计通过后，发表表比较读原proteinGroups遇Python默认
  131072字段限制。原freeze脚本不改，另包装器设10MiB字段上限重读；比较
  尚无输出，统计和供体范围不变，修订绑定evidence_parser_amendment。
- 诊断R首轮读CSV中的Python True/False为字符，逻辑比较停止；显式比较"True"
  后重跑。不更改原强度、published表或数字；原numeric R已通过，不覆盖。
- 完成主数组：24h600→466QC、六日期36列；72h531→380QC、八日期48列，
  相比发表六多10.09.19/18.11.14。两secretome参数1.6.11与发表一致。
  主112family仅FBN2 72h通过；发表六标签子集不通过。ANGPTL2/FSTL3有效
  配对不足，不因负面结果放宽预定规则或填补。
- 发表比对真实差异：24h选中828测量中803非零LFQ均不匹配，25零却有限；
  Intensity也不匹配，不是单常数偏移。72h2128非零舍入匹配、320零却有限。
  这些不是解析失败修正为pass；作为真实来源/处理限制公开。
- 新6页报告实际导出、27CSV-XLSX及3Word表逐格一致、PDF文字边界、两个
  原figurePDF无栅格、1440/390网页均通过。尝试读取两个PNG返回模型不支持
  图像输入；未完成视觉审图，不把结构/数值/网页检查称人工视觉审阅。
- 根rgo更新后用精确开始快照复核旧v0.12文档依赖，其他原科学hash以及
  2,905保护文件逐hash通过；旧manifest/软件成果未覆盖。
