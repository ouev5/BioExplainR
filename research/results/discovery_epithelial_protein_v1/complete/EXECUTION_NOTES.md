# 执行记录

- 开始读取磁盘维护README与全部rgo。实测系统盘53%、/data 37%，无需继续迁移。
- 临时`/tmp/opencode`原venv已不在，系统Python具备实际依赖；系统R可载入pkgload/jsonlite，BioExplainR由项目源码实际载入。
- 按既有精确快照政策核验旧下载157文件／25完整文件、v0.13绑定302记录及ZIP，通过。旧验证函数仅在进程内将唯一rgo文档依赖指向其开始快照，原文件和旧清单没有改写。
- 新方案在候选丰度提取前写入，A549后缀未证实配对，采用Welch；HBEC沿用已核对原作者SRDF，不借样本数推断供体数。
- HBEC表缺完整转换日志，保留导出尺度；缺测不填补，混合基因/污染蛋白行排除，歧义与缺测保留固定检验位置。
- 使用Python实际数值分析；base R从原始表独立重建并复核；实际BioExplainR离线上下文／项目／双语HTML保存。
- 首轮R审计首次因空gene字符串被read.csv转NA失败，保留`../r_audit_first_failure.txt`；`../audit_resume.R`只纠正该解析类型后全部首轮数值通过。
- 首轮交付检查发现默认报告表截短长scope事实，`../build_first_failure.txt`保留；完整范围段落由新`report_epithelial_identity.R`追加到最终双语HTML，并明确HBEC适配字段名不证明log2倍数尺度。
- 看到首轮HBEC MAOA完整IDs还含非majority成员后，新冻结全成员统一身份修订，初稿原字节保留。最终QC从2722到2573组，MAOA改为QC排除，FKBP5为唯一可归属固定候选。
- 最终独立R审计首次Python的"True"/"False" CSV被读取为字符串，失败及诊断记录`r_identity_audit_failure.txt`；`audit_resume_all.R`仅统一两个布尔字段解析后，13116全数组检验／224候选位置／136测量／1680逐人位置／77敏感性／336描述性行通过。
- 最终工作簿11sheet、343957单元与CSV一致；保存结果检查源码语法、R包完整分母、报告完整范围字符串；ZIP及manifest由最后seal逐hash验证。
- 本轮没有网络数据取得、作者通信、在线模型或外部上传。保存结果审计和工作簿核对不代替最终人工科学审阅。
