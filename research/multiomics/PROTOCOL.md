# miniACC 公开多组学开发案例

方案版本 1.0；2026-10-07。在首次计算组间结果前确定本方案。

目的：验证 BioExplainR 对真实缺失模态、按病例 ID 对齐、结果方向关系和离线报告的处理；描述 TCGA-ACC 中晚期与早期肿瘤的 RNA/蛋白差异。这是开发案例，不是独立最终 test、专家 gold、临床预测或因果研究。

- 输入：MultiAssayExperiment 1.28.0 随包公开提供的 `miniACC`，来源 https://github.com/waldronlab/multiassayexperiment-tcga ，原研究 PMID 27165744。使用安装对象实际维度，不把帮助页的历史维度当成当前事实。
- 许可来源：软件包 DESCRIPTION 的 Artistic-2.0；本地保留包说明、数据帮助与来源元数据。原 TCGA 数据按其公开使用要求引用；本轮仅本地分析和交付，不新增外部发布。
- 数据选择由负责人授权执行者决定。纳入对象中的全部病例和 5 个模态作覆盖统计；保留缺失模态，不补值，不把缺失当零。
- 比较方向：late（stage iii/iv）减 early（stage i/ii）。独立单位为病例；每个模态每病例必须只有一个测量列，否则中止，不自动平均技术重复。
- RNA/蛋白联合比较：先通过 sampleMap 取有两种测量且分期已知的病例；再对各共有基因取两模态数值均有限的病例。保存每个特征的排除和组样本量。没有按显著性筛选特征。
- RNA 转换为 log2(normalized expression + 1)，不是 raw count 的 DESeq2 分析；蛋白使用对象已有的归一化 RPPA 数值。效应为各自单位下的组均值差；不跨单位比较大小。
- 每个特征每模态以双侧 Wilcoxon rank-sum（exact=FALSE，连续性校正）作探索性比较；分别对全部被检验的共有特征做 BH 校正。每组少于 3 个有限病例时不检验。
- 方向关系只是正负号一致性；零值为无法判断。不能把方向一致、同一病例的不同模态或显著性阈值通过解释成独立机制证据。所有共有特征均保留，包括相反方向和不显著结果。
- 完整输入快照、sampleMap、分期、分析输入长表、结果、context/project RDS、中英文 HTML、会话版本、方案/脚本 hash 和运行清单保存在新的不可覆盖目录。
- 保存程序构造的反例用于工程回归，明确标注 injected；这些反例不算自然错误发现或独立研究准确率。
- 用户体验/学习增益研究 deferred；专家评价在功能和案例准备完成后开展。本案例供专家材料准备，当前不填写人工评分或专家签字。

运行：`Rscript --vanilla research/multiomics/run_miniacc.R research/results/miniacc_development_v1`

独立离线数值复核：`python3 research/multiomics/audit_miniacc.py research/results/miniacc_development_v1`。
复核器从保存的测量长表重新计算均值差和方向，从原始映射重新计算覆盖；这是不同实现的计算检查，不是独立人员或独立数据集验证。
