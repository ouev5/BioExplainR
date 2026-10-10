# 公开源码快照复现入口

当前软件0.4.0.9000；中文主稿 **v0.10**，独立补充见 `paper_cn_v4/README.md`。本文件为源码快照复现说明，正式发布状态见 `RELEASE_ARCHIVE.md`。

当前稿包含 11 图/14 表＝25 项正文对应、GSE146017 因子干预和 GSE94335 多供体响应重分析。GitHub 发布仍按负责人要求暂停。

2026-10-09新增[正式共同任务与机制研究增补](research_followup_v1/README.md)，包含原始HTTP、216模型尝试、1,800评分与独立复核，以及A549/ChIP公开输入和模型。精确runtime/model复原用`research/common_performance/restore_formal_runtime.py`；保存结果复核和新目录运行命令见增补README。本地当前交付r13，历史r11/r12保留。

## 软件安装和离线检查

```sh
Rscript --vanilla -e 'install.packages(c("httr2", "jsonlite", "digest", "testthat", "pkgload", "roxygen2"))'
R CMD INSTALL .
R --vanilla --slave -f tools/check.R
Rscript --vanilla tools/offline-smoke.R /tmp/bioexplainr-public-smoke
```

完整`R CMD check`需要DESCRIPTION列出的Suggests；对应R/Bioconductor版本见`REPRODUCTION.md`。模型调用不是上述离线检查的前置条件。

## 外部候选实验

`research/discovery/README.md`给出新目录运行命令，`research/results/discovery_sparcl1_v1/`保存公开输入（完整GEO gzip）、候选/规则冻结、十数组测量、Welch/CI/Holm/置换与R独立重算、BioExplainR报告。新的执行会使用新的UTC，并核实Ensembl映射；不自动声称与已保存输入为同一快照。软件事实接口来自当前包。

后续方案与配对修订见 `research/discovery/CONTEXT_PROTOCOL.md`、`DONOR_PROTOCOL.md`、`DONOR_DESIGN_AMENDMENT.md`；结果见 `discovery_context_v1/`、`discovery_donors_v1/`。GSE94335 原始 TPM 未放入 r11 ZIP，`delivery_manifest.json` 的 `excluded_inputs` 给出精确来源、路径、大小、SHA-256 和下载命令。重获后必须匹配原始校验值；`files_manifest.json` 仍包含这一输入。

## 论文重建

```sh
python3 -m pip install -r tools/paper-requirements.txt -r research/discovery/requirements.txt
python3 research/paper_cn_revision/build_revision.py --directory docs/paper_cn_v4 --version v0.10 --reuse-assets docs/paper_cn_v3 --biology-followup
python3 research/paper_cn_revision/audit_revision.py --directory docs/paper_cn_v4 --version v0.10
```

还需Pandoc、LibreOffice和Noto Sans CJK字体；浏览器验收需Chrome/Playwright。当前稿复用的v0.8图表在`docs/paper_cn_v1/`保存，构建脚本从这些原件逐字节复制，不需要重跑模型。`manuscript.md`是主稿编辑源，比较表由`tool_comparison.json`定义。

## 历史与本地交付审计

完整工作目录的 `current_manifest.json`、r11 和历史保护清单用于本地交接，可能引用未放入源码快照的大型缓存或历史交付 ZIP。`research/audit_current_results.py` 针对该完整工作目录。包内逐成员审计由 `research/package_submission.py --verify-only` 执行；排除的 TPM 需先恢复到相同 SHA-256。正式归档状态以 `RELEASE_ARCHIVE.md` 为准。

人员原评分、研究人员身份/伦理、最终作者信息及DOI不会由软件测试补造。外部SPARCL1实验仅含单细胞系培养重复；后续功能验证方案见`research/discovery/PROTOCOL.md`。
