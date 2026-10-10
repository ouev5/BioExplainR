"""Record actual continuation issues and source status before final manuscript sealing."""
import json
import sys
from pathlib import Path
from validation_sources import record,utc,json_out
from set_validation import rows

out=Path(sys.argv[1]).resolve()
summary=rows(out/"set_summary.csv");totals=json.loads((out/"numeric_audit.json").read_text())["set_counts"]
notes="""# 本轮实际失败、修复与范围

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

新研究是六候选结果已知后的54集合扩展及完整人蛋白数组再分析；不称预注册/盲法。
范围采集的失败与成功由原目录JSON/hash判定，无完成记录不能当pass。在线模型调用0。
"""
(out/"EXECUTION_NOTES.md").write_text(notes)
findings=f"""# 54基因集合检查的实测结果

原完整54基因、6成人GSE130715的24hBUD对照背景：53/54可测、53/53平均同向、
50/53全部六供体预期方向。配对t/Holm54通过45/54，count/Holm54通过51/54；
45/54同时通过两模型、六供体、伪计数与六轮留一方向标准。精确Holm54为0，
最小双侧符号翻转P=.03125；不作非参数全family确认。

LINC00607Entrez646324原新来源可测，+.526、Holm54=.0233，6/6上调；旧缺测与
airway阴性不变。BMAL1/NPAS2上调、NR1D2/DBP/TEF下调皆全供体/两模型/敏感性
支持，为事后时钟相关候选描述，不是节律或通路确认。LINC03140原输入缺测。

未满足综合标准：NEFM、GABBR2、VGLL3、LRRC15、SEMA6D、PTGER2、ANKRD1、TIPE3。
原完整汇总set_summary.csv保留。GABBR2均值接近零、留一方向不稳定；其他未通过
不等于无效应。新旧供体标签别名未尽，不累加人数；TPM/count是同六供体敏感性。

新BioExplainR实际4context、54/162完整family计数45/25和51/58一致；双语HTML。
数字审核numeric_audit/sensitivity_audit/r_tpm_audit为pass，原moderation保留范围。
"""
(out/"SET_FINDINGS.md").write_text(findings)
json_out(out/"scientific_ledger.json",dict(status="completed_set_expansion",utc=utc(),set_counts=totals,
    analysis_scope="After-known-candidatesexploratory, same-sourceTPM/count sensitivity; noaggregateindependentdonortotal",
    unsupported_claims=["adultPER2earlythenlatewithin-donortrajectory","adultASMNR3C1causalrescue","circadianphase/amplitude","candidatecontractionfunction"],
    online_model_calls=0,wet_experiments=0,source_results=[record(out/"numeric_audit.json"),record(out/"sensitivity_audit.json")],
    protein_status="See unselected_protein/run.json and r_audit.json; priorselectedarrays are samebiologicalsource"))
print("Scientific findings and actual execution issues recorded")
