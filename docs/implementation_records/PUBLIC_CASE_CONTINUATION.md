# 公开案例与联合检查续接

日期：2026-10-07；开发版 0.4.0.9000。负责人授权执行者选择测试数据并保留结果；用户体验研究 deferred，专家评价在软件/案例/评价材料准备完成后开展。

本轮实现样本映射重新校验、observed ID 唯一性、primary unit 完整分母、模态覆盖/缺失数、两两交集、完全观测/未观测计数。MAE context 暴露计数，原始样本映射留本地。新增 `bio_validate_project_relations()` 检查显式有限效应、特征 ID、数据集/比较/物种/组织/样本层级和 numerator/denominator；unknown 或零效应不自动 pass。项目报告及模型 payload 接入 findings。

公开真实案例：TCGA-ACC `miniACC`，92病例、5模态、43病例五模态齐全。RNA/蛋白配对分期分析46病例（28早期/18晚期）、33共有特征，18同向/15反向，RNA BH<0.05为3，蛋白为0。输出 `research/results/miniacc_development_v1/`，来源、输入、分析表、RDS、双语 HTML、会话及23文件hash保留。独立 Python 实现重算66效应、方向、覆盖与BH通过；不是独立人员、数据集或专家科学验证。

源码测试 677项：676 pass、1 skip、0 failure/error/warning；新增29项。结果日志 `research/results/w00_baseline/improvement-source.*`，数值复核 `improvement-miniacc-audit.*`；包检查 `improvement-package-check.*` 为 Status: OK。10-07 未重跑旧 API 专项，不能将 improvement 日志称为 API 验收。

W10-A/B 公开开发案例已执行，W10-C 独立确认仍待系统冻结后专家材料；W11 暂缓至准备完成，W11-U deferred。W05 显式方向子范围已有检查，但通路映射、跨物种/跨区域泛化及自然科学支持判定未宣称完成。自动全覆盖分块、Seurat spatial复杂图层、真实docking引擎版本、独立API行为审阅、fresh OS/lockfile/远程矩阵仍待后续工程。当前工作包保持 ready_for_review/in_progress，不把局部工程通过标为整体 done。
