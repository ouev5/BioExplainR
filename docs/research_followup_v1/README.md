# 共同任务与机制研究增补 v1（2026-10-09）

当前正式论文仍为 [v0.10](../paper_cn_v4/README.md)。本目录保存本轮实际完成的共同任务、GR干预与ChIP分析增补，**4页、4个内嵌表**；历史主稿/图表保留。

- [PDF](BioExplainR-共同任务与机制研究增补-v1.pdf)
- [可编辑 Word](BioExplainR-共同任务与机制研究增补-v1.docx)
- [HTML](BioExplainR-共同任务与机制研究增补-v1.html)
- 可维护源：`research_addendum.md`；表 F1–F4：`tables/*.csv`。
- `audit.json`、`independent_audit.json`：数据表与原结果、PDF文本及边界核验。
- `browser_audit.json`：1440/390双视口，4表、无横溢出/JS错误。

## 实际结果

|方法|正确目标/360|覆盖/360|全正确运行/72|中位秒|
|---|---:|---:|---:|---:|
|BioExplainR 离线|360|360|72|0.036|
|base R 用户脚本|360|360|72|0.002|
|ellmer 直接读表|8|175|0|180.829|
|ellmer 读完整 facts|360|360|72|18.584|
|BioExplainR 客户端读同 facts|360|360|72|18.654|

- 24已知开发任务×3重复×5方法：360运行、1,800目标评分；216正式本地模型尝试+1预热。37个超时均为读表组，留在分母。读表50/200行分别8/180、0/180；后者36请求均超时。
- 两facts组相对读表准确率差 +97.78个百分点（24任务配对bootstrap 95% CI +95.28–+100）；全任务正确率差+100个百分点。不是六工具全面排名或通用推理测评。
- **GSE229084/A549**：47文库/35,942基因，SPARCL1计数0–4，固定表达过滤未通过，三候选交互全部不可估计。不能支持或否定GR依赖；固定控制不代替候选。
- **GSE95632/HASM2**：取得18峰文件。全基因组坐标支持hg19（hg18/hg38/mm9出现越界），原GEO人/mm9冲突保留，未经作者确认。SPARCL1主窗口GR vehicle 4/2、DEX 8/8；RNAPII vehicle 0/0、DEX 1/1。仅为发布峰窗口重叠，不是差异占据统计或直接调控/功能证明。
- 独立实现复核：Python重算参考/JSON/全部评分/tokens/时间/配对区间；机制35,942过滤、188候选/控制测量、39WLS对比及作者对象51样本/705,534共享计数；R GenomicRanges 288计数、2,505命中、summit/距离与16重复比较。

## 复现

结果：`research/results/common_performance_v4/`、`discovery_mechanism_fit_v4/`、`discovery_chip_v1/`、`discovery_chip_analysis_v1/`。原始HTTP、freeze、方案、输入、失败与中断保留。适用性来源：`common_performance_applicability_v1/`。

```sh
# 只复核保存结果，不再次推理
Rscript --vanilla research/common_performance/score_complete.R research/results/common_performance_v4
python3 research/common_performance/audit_benchmark.py research/results/common_performance_v4
Rscript --vanilla research/common_performance/supplemental_scores.R research/results/common_performance_v4
python3 research/common_performance/audit_supplemental_scores.py
python3 research/discovery/audit_mechanism_complete.py research/results/discovery_mechanism_fit_v4
Rscript --vanilla research/discovery/audit_chip_replicates.R research/results/discovery_chip_v1 research/results/discovery_chip_analysis_v1
# 重新推理必须用新目录；先恢复固定model/runtime及ellmer 0.5.0独立库
python3 research/common_performance/restore_formal_runtime.py
python3 research/common_performance/run_benchmark.py research/results/common_performance_new
```

脚本会拒绝既有推理/输入输出目录；固定运行的资产精确SHA-256在freeze/runtime_manifest中。新UTC对应新执行，不沿用历史推理。外部API费0，本地总成本未知；失败请求tokens未知。

没有新增湿实验、第三方人员sign-off或专家/用户评分；GitHub和外部上传继续暂停。当前本地交付r13，逐成员审计以`research/results/w00_baseline/continuation-formal-delivery-audit-result.json`为准。
