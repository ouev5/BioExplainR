# 本轮实际执行与修订

2026-10-10。主机日志UTC按实际保存；旧secretome seal运行两次均pass，
旧v0.12/层叠科学清单及2,905保护文件通过。开始时保存根rgo精确快照。

1. 首轮`secretome_provenance.py analyze`完成，但数字proteome样本编码
   没有解码，proteome逐技术值被记为不可对应。该轮结果完整保留在根目录，
   不作为最终跨数组结论；`complete/freeze.json`重新冻结4原解码，
   `secretome_provenance_complete.py analyze`完整重建168样本列。
   总Intensity不受该样本列修订影响，complete仍独立核对。
2. `/pride/ws/archive/v2/projects?keyword=...`四检索返回相同100条早期
   项目，SHA256均`969052798efa2b2202f2f2d2c5f17f7cdb5c6ddfc01b65f5fca0cac6f05746b8`。
   接口忽略keyword，不作400相关命中。正确`/search/projects`分别1/7/0/0，
   唯一8项目；第五无关负控制0，通过。旧原JSON/表不删除。
3. `complete acquire`在120秒执行上限中断，五正确PRIDE原响应和项目表已
   保存，但无完成JSON。原文取得未完成，另`resume_freeze.json`与
   `secretome_provenance_resume.py`复用已保存原响应，继续缺失请求。
   30个原文请求中若干EPMC500失败逐次保存。最多30篇/顺序截断公开，
   不说已全文审读所有180文献。原HTPC源另使用冻结旧XML和新元数据。
4. 独立R审计第一轮拒绝Python CSV的`True/False`字符，修为显式logical。
   第二次误把摘要numeric `matches_rounding`也logical，摘要计数核对失败；
   增加仅字符布尔字段转换条件。最终R重建281,232逐测量比较、
   31,228总Intensity比较、168列、4,968公式比较及48摘要通过。
5. 独立OOXML审计遇到原Excel把一个gene cell保存为2008-09-01日期；
   原raw XML为序列39692，openpyxl读日期字符串。追加原styles.xml日期
   样式解码，原gene注释不自行改正；23,436发表测量全部一致后通过。
6. PMC的EV补充链接HTTP200返回1816bytes challenge HTML，不当作PDF。
   原PII含标点的Elsevier URL404，三失败保留。标准PII去标点后真实
   PDF取得8,947,418bytes/13页，SHA256
   `229e8e41eee68e83a5de42e0ebbe24bd8fbeed89cb5647762c309e27b3722fc5`。
   初自动测试寻找`Table S2`，而原文是`Supplemental table 2`，false保留；
   `supplement_review.json`另从题名/作者/原PII及实际表题核对身份。
   补充是IPA/选中糖酵解表，不是未筛数组，缺候选名字不作阴性。
7. 实际R包报告初次手填样本列162，原R复核168拒绝；仅更正事实分母，
   保存双语报告及实际版本。没有在线模型调用或新候选统计显著性检验。
8. 中文4页结果报告首次导出完成。网页验收在R包generic原宽表处失败：
   1440视口实际scrollWidth1822；旧截图`docs/secretome_provenance_v1/browser/`
   保留。generic未在正文渲染uncertainty，原14列数值展示还被format四舍五入。
   报告另建`complete/report_final/`，五列简明摘要计数使用精确字符串、
   限制同时写facts.scope_limitations，包装横向表滚动/viewport仅改变展示。
   原R包源码不改，原RDS/失败报告保留；新网页核验用browser_final。
9. EV补充糖酵解表8行实际ExprP全部>.05，原正文却称8significative
   upregulated，原PDF末页16个fold/P由文本和坐标两路核对通过。
   仅指出原表/正文差异，不宣布作者全数组无显著蛋白，不当新候选统计。
10. 整个既有未提交工作树`git diff --check`提示历史baseline CSV行CRLF
    trailing whitespace。新工作独立检查，原封存文件不清理重写；最终
    `complete/handoff_check.json`记录实际全树失败范围及新工作检查。
    当前模型不支持图像输入，截图读取返回unsupported；不称人工视觉检查。
    真实浏览器数值、文档文字/边界、原图无栅格及图表对应核对通过。

本轮纯计算/公开材料来源诊断。原ASM/HTPC候选统计与原manifest未覆盖；
新发现的PXD055968样本映射为六患者/18run，虽原表写biologicalreplicates，
同患者的三重复不可称三个独立供体。没有GC/vehicle因素。原文和PRIDE
处理版本/缺失值说明冲突保留，未取得完整Proline定量导出。
