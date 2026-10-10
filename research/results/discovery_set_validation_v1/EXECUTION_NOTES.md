# 本轮实际失败、修复与范围

1. 初始HGNC完整表传输360s超时，已建freeze/样本/名单但无注释输入。再次freeze正确拒绝旧目录。
   改官方exactEnsemblREST，保留原freeze；54记录中3条TLS失败另文件重试，54唯一映射完成。
2. 初次PRIDE files/byProject入口返回空body，解析失败；改正确projects/accession/files取得
   三项目完整首分页，每页<100且唯一文件名。原失败输入、URL、UTC保留。
3. GSE42538 all接口在platform表被截断，不能当全样本元数据；逐12GSM保存，3TLS失败另
   文件retry后完成。四女性28/32/37/39岁，NT/GR/MRsiRNA，全部同含cAMP/P4/cortisone
   四天，无无药物组；按目标交互不适用排除，未作候选统计。
4. 7z头/末尾HTTP206和Content-Range取得目录，py7zr.archiveinfo要求本地文件名首次
   assert失败。改直接读取已验证header结构/blocks，保留前次结果，发现两个proteinGroups。
5. 大固实包8MiB范围每90s只约1.3MiB而超时，600s命令中断；原完成失败JSON及未完成
   header保留，早次被丢弃partialbytes只能据stderr记录，不能宣称保存实体。
6. 256KiB高并发96初次连接拒绝；另resume并发24、每次新attempt文件，成功part只读/hash
   复用，不覆盖失败。24h1062/1076后再续14段全部取得。全包未下载，不称上游SHA1通过。
7. selective读取首段边界时py7zr请求较大read，首次未取得位置262144拒绝。修复为BufferedIO
   合法短read，不填充未知字节；另extracted_verified按三个目标成员CRC核对。原失败保留。
8. v0.12初导出因长标题PDF自动折行，旧导出器逐字符串匹配图页失败；新导出器仅规范化
   标题空白匹配原图，无改原build_revision。Word/PDF图页与原PDF嵌入另核对。
9. 初稿图表正文审计发现S13b与S20仅成组范围未逐项引出，补全每张电子表的估计目标引用；
   新未封存稿refresh重导出，原v0.11不变。Pandoc缺zh翻译及LOjavaldx警告保留输出，数值/
   字体/边界/图嵌入/网页仍须逐项审计，不将警告当未运行或假装无警告。
10. 72h初次完成1867/1922段，另resume补55段至全1922；最终两时点2998成功段、
    6原目标成员CRC全部复核。高并发初次失败实体/headers和每次新attempt记录保留。
11. 读取完整MaxQuant表首次超过PythonCSV默认131072字段上限，随后只增加解析上限
    10MiB；72h解码control使用c1而24h为co1，按各自原解码文件支持精确c/co别名。
    两次均在新统计输出写入前失败，原freeze不重写、run记录实际修复脚本hash。
12. 完整原表每时点七标签、发表六供体，额外10.09.19作者排除/年龄/QC未知；原参数
    MaxQuant1.6.15与报道1.6.11冲突。另结果后子集/共有标签直接差修订，原主112保留。
    对144发表测量，142原非零匹配舍入、2原0发表有限值，不猜其处理；本轮不填补。
13. 来源发现文档新增六行Markdown表，补充Word渲染第一次因未提供第5native table
    spec停止；新增S26对应CSV/XLSX与内嵌表后重新导出，5原native表逐格核对。
14. 来源说明草稿曾将PRIDE每项目43文件误写37，在封存前按实际清单修正为42raw+
    1search；最终正文/补充/manifest范围一致。旧科学rgo以及v0.11 README/index
    更新前精确快照保存，新审计只对变更文档显式使用旧快照，不覆盖旧清单。

新研究是六候选结果已知后的54集合扩展及完整人蛋白数组再分析；不称预注册/盲法。
范围采集的失败与成功由原目录JSON/hash判定，无完成记录不能当pass。在线模型调用0。
