# miniACC 真实多组学开发案例

2026-10-07 已完成公开 TCGA-ACC / MultiAssayExperiment 1.28.0 `miniACC` 分析。方案在首次计算组间结果前固定于 [PROTOCOL.md](PROTOCOL.md)。

结果目录：[miniacc_development_v1](../results/miniacc_development_v1/)。入口为 `summary.json`、`report-zh.html`、`report-en.html`、`feature_results.csv` 和 `manifest.json`。

| 项目 | 结果 |
|---|---:|
| 病例记录 | 92 |
| 模态 | 5 |
| 五模态齐全病例 | 43 |
| RNA/蛋白配对且分期已知 | 46（早期28，晚期18） |
| 共有特征 | 33 |
| 同向 / 反向 | 18 / 15 |
| RNA BH < 0.05 | 3 |
| 蛋白 BH < 0.05 | 0 |

这些数字描述本次选择的公开开发数据及固定分析，不是生物学泛化准确率。方向一致不表示显著、机制或独立验证；两模态测量共享病例。分期比较未调整年龄、纯度、亚型等混杂，数据是预先筛选的特征子集。

保留 23 个输入/分析/报告文件及其 SHA-256 清单。Python 离线复核从配对测量长表重算 66 个均值差、方向、样本覆盖和 BH 校正，结果 pass；Wilcoxon 原始 p 值由 R 计算，Python 未独立重算该统计量。6 项工程检查包括真实映射/方向以及显式 injected 反例，不计入自然错误或专家评测准确率。

```sh
Rscript --vanilla research/multiomics/run_miniacc.R research/results/miniacc_development_new
# 安装真实 tar 到新库后可显式使用安装包，runner 不加载源码：
R_LIBS=/path/to/installed/library Rscript --vanilla research/multiomics/run_miniacc.R research/results/miniacc_installed_new --installed
python3 research/multiomics/audit_miniacc.py research/results/miniacc_development_new
python3 research/multiomics/test_audit_miniacc.py
```

输出路径已存在时拒绝覆盖。来源说明、原始 RDS、sampleMap、分期、配对测量和依赖版本均在结果目录，可离线复核；无模型调用。用户体验研究 deferred，专家研究在工程与案例准备完成后启动。

新运行 manifest v2 使用相对于运行目录的文件名，可整目录复制后复核；旧 v1 路径前缀按同一运行目录成员名兼容回读，不访问原结果目录。复核器要求全部 23 个成员、表主键、完整覆盖/关系/findings/工程反例和配对测量集合；缺失、重复、越界路径、symlink 和重算不一致均失败。`datasets.csv` 的 hash 是 v1 原始 `input_miniACC.rds` 的 SHA-256，详细文件入口为结果目录 `manifest.json`。
