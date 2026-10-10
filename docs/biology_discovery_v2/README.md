# 生物学发现结果报告 v1（正式导出目录 v2）

2026-10-09。本轮从全转录组实际分析得到 **54基因跨四背景稳健激素响应集**；固定前12候选后，11个可测基因在排除3个已知重叠细胞系的13供体中重复。重点为 **PER2的短时上调／晚时回落与成人ASM晚期下调**，其次为METTL7A、MAOA、ANGPTL2、FSTL3。所有结论为公共数据探索重分析；文献已有激素与生物钟主题，本轮新增价值是候选特异的可定位整合证据。

## 直接阅读

- [7页PDF](BioExplainR-生物学发现-结果报告-v1.pdf)
- [可编辑Word](BioExplainR-生物学发现-结果报告-v1.docx)
- [自包含HTML（5图／3表）](BioExplainR-生物学发现-结果报告-v1.html)
- [Markdown文字及全候选表](results.md)
- [完整统计结果目录](../../research/results/discovery_stable_response_v1/)
- [全部12候选证据表CSV](../../research/results/discovery_stable_response_v1/evidence_summary.csv)
- [BioExplainR实际中文项目报告v2](../../research/results/discovery_stable_response_v1/BioExplainR-report-zh-v2.html)
- [本轮结果／图稿／脚本压缩包](BioExplainR-biological-discovery-results-v1.zip)
- [本轮独立SHA-256清单](discovery_manifest.json)

报告正文PDF中的图为PNG预览；[五个原始矢量PDF](../../research/results/discovery_stable_response_v1/figures/)单独提供。图1四背景候选热图、图2外部13供体效应、图3逐供体测量、图4PER2的GR及时间差、图5PER2/PER3微阵列时间条件。v1目录仅保存第一次导出前路径错误，v2为实际完成目录，文稿版本仍为结果报告v1。

## 核心可核查数值

|候选|外部13供体平均差：log2(TPM+1)|95%CI|48项Holm P|供体方向|
|---|---:|---|---:|---|
|PER2|−0.915|−1.048至−0.782|1.55e-7|13/13下调|
|PER3|−2.082|−2.324至−1.839|1.24e-8|13/13下调|
|METTL7A|+2.044|+1.896至+2.193|5.31e-11|13/13上调|
|MAOA|+2.561|+2.413至+2.710|3.70e-12|13/13上调|
|ANGPTL2|−0.869|−1.131至−0.608|3.03e-4|13/13下调|
|FSTL3|+1.414|+1.211至+1.617|1.34e-7|13/13上调|

上述六基因合并13供体的精确符号翻转Holm P均为0.01171875。PER2 A549 2h DEX +1.092，三药物交互−0.935／−0.972／−0.922，均通过原48项Holm；直接18h−2h −0.917、24项Holm P=1.45e-9；HASM1直接24h−4h −1.651、同24项Holm P=0.0139。微阵列精确置换全family不能确认，保留参数检验探索性结果。时间/药物/培养/组织混杂，未测节律相位或功能。

## 保存结果的复核

```sh
python3 research/discovery/audit_response.py research/results/discovery_stable_response_v1
# 独立原TPM的R审计拒绝覆盖旧审计；异地复制结果并删除其审计输出后，或使用新运行目录执行：
# Rscript --vanilla research/discovery/audit_response_external.R <new-run-directory>
/tmp/opencode/paper-venv/bin/python research/discovery/audit_response_report.py research/results/discovery_stable_response_v1 docs/biology_discovery_v2
python3 research/discovery/seal_response.py verify
```

Python需numpy/scipy，报告复核需PyMuPDF/python-docx；R版本4.3.3，DESeq2 1.42.0、edgeR 4.0.16、limma 3.58.1。`report_sessionInfo_v2.txt`保存实际版本。依赖安装入口参见原项目`docs/REPRODUCTION.md`。数值复核更新其审计输出时，封存清单将检测到变化；重新封存必须使用新的manifest文件名。

## 新运行复现

从仓库根目录执行；必须保留已保存输入路径，并使用从未存在过的新输出目录。协议见[GENOME_PROTOCOL](../../research/discovery/GENOME_PROTOCOL.md)、[RESPONSE_PROTOCOL](../../research/discovery/RESPONSE_PROTOCOL.md)及[TIME_AMENDMENT](../../research/discovery/RESPONSE_TIME_AMENDMENT.md)。

```sh
python3 research/discovery/freeze_genome.py research/results/discovery_genome_new
Rscript --vanilla research/discovery/screen_genome.R research/results/discovery_genome_new
Rscript --vanilla research/discovery/screen_response.R research/results/discovery_genome_new research/results/discovery_stable_response_new
python3 research/discovery/validate_response.py research/results/discovery_stable_response_new
Rscript --vanilla research/discovery/response_mechanism.R research/results/discovery_stable_response_new
python3 research/discovery/response_time.py research/results/discovery_stable_response_new
Rscript --vanilla research/discovery/response_late_gr.R research/results/discovery_stable_response_new
Rscript --vanilla research/discovery/response_temporal_difference.R research/results/discovery_stable_response_new
Rscript --vanilla research/discovery/audit_response_external.R research/results/discovery_stable_response_new
python3 research/discovery/audit_response.py research/results/discovery_stable_response_new research/results/discovery_genome_new
Rscript --vanilla research/discovery/report_response.R research/results/discovery_stable_response_new
```

本轮python数值审计默认正式`discovery_genome_v2`；新结果复核使用上述第二目录参数指定本次输入，不能拿旧表对新结果。中文构建器用独立新docs目录；不覆盖现有报告。原输入SHA-256绑定在分析freeze与本轮manifest；原TPM完整保留本地，压缩交付可通过原URL恢复。

## 验收入口

- [数值审计](../../research/results/discovery_stable_response_v1/numeric_audit.json)：82,227交互／109,636响应、109,636全基因供体方向及固定排名、192供体记录、300 WLS数值、110微阵列测量、24 marginal/24 direct时间检验通过。
- [原TPM独立R复核](../../research/results/discovery_stable_response_v1/external_r_audit.json)：5,851,434原始行、286测量、143供体效应、44可估计检验、48项分母与360统计检查通过。
- [文稿审计](audit.json)：7页、3表、5图，与CSV一致，PDF270文本片段／5个矢量PDF边界通过。
- [网页审计](browser/audit.json)：1440／390宽度，5图3表，无溢出或JS异常；未进行模型视觉审阅。

初始82,227交互无显著、LINC00607外部缺测／旧airway阴性、TEF微阵列不重复、两项原文XML500，以及空候选、脚本相对路径、跨语言CI数值容差和报告scope修订均保留。本轮主要入口为本报告和本轮manifest；全项目current清单的历史pass不扩大为覆盖本轮新文件。
