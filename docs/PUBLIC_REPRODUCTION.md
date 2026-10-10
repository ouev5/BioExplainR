# 公开源码快照复现入口

当前软件0.4.0.9000；中文主稿v0.9，独立补充见 `paper_cn_v2/README.md`。

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

## 论文重建

```sh
python3 -m pip install -r tools/paper-requirements.txt -r research/discovery/requirements.txt
python3 research/paper_cn_revision/build_revision.py
python3 research/paper_cn_revision/audit_revision.py
```

还需Pandoc、LibreOffice和Noto Sans CJK字体；浏览器验收需Chrome/Playwright。当前稿复用的v0.8图表在`docs/paper_cn_v1/`保存，构建脚本从这些原件逐字节复制，不需要重跑模型。`manuscript.md`是主稿编辑源，比较表由`tool_comparison.json`定义。

## 历史与本地交付审计

完整工作目录的`current_manifest.json`、r8和历史保护清单用于本地交接，可能引用未放入Git源码快照的大型缓存或历史交付ZIP。`research/audit_current_results.py`针对该完整工作目录；它不是缺少这些历史成员时也能通过的公开源码安装测试。Git快照和GitHub release分别提供软件及本轮论文/案例复现，正式归档状态以`RELEASE_ARCHIVE.md`为准。

人员原评分、研究人员身份/伦理、最终作者信息及DOI不会由软件测试补造。外部SPARCL1实验仅含单细胞系培养重复；后续功能验证方案见`research/discovery/PROTOCOL.md`。
