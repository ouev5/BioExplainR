# 本轮执行记录

1. v1 相对路径异常已保留在 `discovery_validation_v1/`。正式检索转为 v2。
2. v2 GEO 四项查询完成，31个唯一series汇总已保存；文献第五项出现一个缺少
   title 的 Europe PMC record，读取时 KeyError 停止。保留完整原JSON，改用
   `[metadata title missing]` 明示缺失，通过 `--resume` 回读已保存响应并完成
   后续查询；原 search freeze 不改，修复另记 `search_resume_amendment.json`。
3. 第一次resume因已有 `geo_series.csv` 的拒绝覆盖规则停止。修正为回读并
   逐行比对重建结果一致，保留原文件；后续resume另记编号amendment。
4. 原文XML返回500；BioC/普通PMC页面返回challenge HTML，均保存但未当原文。
   `?report=xml`替代入口成功取得三份有效原文HTML，正文及表格均抽取保存。
   GSE35643 metadata传输超时两次，未形成其完成记录；最终metadata范围只含
   四份实际下载成功的series，不将未获输入称为pass。
5. 会话续接后 `/tmp/opencode` 已为空，旧论文venv命令不可用；系统Python
   实测numpy1.26.4/scipy1.11.4，改用系统Python。新expression freeze发现
   GEO描述`N100217Gs_KD`缺下划线，按`N+六位日期+可选K`解析，和Patient编号、
   原文表1共同核对，而非依赖处理后缀作供体ID。
6. GSE13168 series matrix下载超时；已完整取得family SOFT，其样本表包含全部
   54×22,283发布值。另修订读取SOFT原表，不补猜表达；原freeze仍保留，运行
   manifest记录实际脚本hash。METTL7A现官方名TMT1A，NCBI同Entrez25840别名
   核对通过；保留冻结显示名METTL7A并公开alias表。
7. 蛋白全表串行下载超时，未生成完成输入；改为72段Range核对206、
   Content-Range、Last-Modified与PRIDE全大小37,713,383 bytes后完成。
   PRIDE写human，但搜索协议与7,218蛋白实际写mouse；不改标签掩盖冲突。
   原表只在annotation/QC检查后、定量计算前追加ortholog修订。
8. R蛋白复核第一次因CSV的True/False字符被作logical取反停止；修正为
   精确字符比较后另运行。原数值未变，未删source star29，主分析保留32样本。
9. bioRxiv全文／PDF／source XML接口返回403，EuropePMC preprintXML返回500。
   API元数据和GEO／PRIDE原始发布表可用，预印本文献结论只按元数据范围引用。
10. 全树`git diff --check`检出原w00基线CSV的CRLF尾空白；这些是开始前
    未提交文件，不修改其封存内容。本轮新增源码／文档另做适用语法和空白核验。
11. 人蛋白TableS2首次PMC接口返回HTML，替代接口／浏览器下载超时，均保留；
    后来出版社mdpi-res静态ZIP有效，CRC及两成员通过。ALL表没有逐样本数组，
    差异表才有选中数组；因此另存scope修订，不把未入选的候选当阴性。
12. 原同供体voom敏感性含limma近似contrast covariance，原模型与输出不改；
    新精确WLS导出及amendment保存，未改筛选。独立Python核对220数值。
13. 中文报告v1审计发现扩展series数字手写194而实际193。该未封存稿保留在
    `docs/biology_validation_v1/`，不标pass；构建器改为实际CSV计数，另建v2报告。
14. 扩大检索获得GSE200312 metadata，但无无药物组；未做候选GR×药物统计。
    后续GSE42538metadata下载超时，gr_knockdown文件夹为不完整可行性采集，
    不存在完成manifest或研究pass，ledger与findings已明确排除。
15. 最终新增三控制PER1/DUSP1/NR3C1用Ensembl REST再次核实ID／human种属，
    3/3通过。完整报告PDF7页、4表、3图及CSV/XLSX、原XLSX144测量、
    旧v0.11依赖87/ZIP82/科学203、1440/390网页通过。本轮精确ASM数值审计
    为220项，GR为550项，不称重新估计voom/eBayes。
