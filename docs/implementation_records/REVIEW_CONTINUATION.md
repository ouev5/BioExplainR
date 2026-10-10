# 中断点续接审阅与安装包验证

日期：2026-10-08；开发版 0.4.0.9000。本轮接续 SESSION_HANDOFF 中的“仔细检查”中断点。

## 修复与检查范围

- 同步真实数据由执行者选择、专家评价后置和用户体验/学习增益研究 deferred；修正 r3 过期入口及交付边界，保留 10-05/07 历史验收日期。`datasets.csv` 改为 v1 原始输入 RDS 的真实 SHA-256。
- `run_miniacc.R` 增加 `--installed`，记录实际包模式/版本/路径；新 manifest v2 使用运行目录相对文件名，旧 v1 输出不改写。
- `audit_miniacc.py` 以指定目录本地成员回读旧/新 manifest，要求全部 23 个成员，拒绝重复、缺失、越界路径和 symlink。校验表主键及完整覆盖/交集/测量/关系/findings/反例集合，重算分期分组、效应、方向、BH 和摘要计数；current audit 接入两份 miniACC 结果。
- 安装包离线 smoke 新增手算模态覆盖/完整/未测量计数、含点号 exact-token 的 opposite 符号关系及错误方向拒绝和 HTML 展示。
- 历史 API 检查新增安装包模式；环境采集用唯一 prefix 保存新输出，拒绝覆盖旧证据。交付工具加入 improvement/review 日志、公开案例记录、安装案例和复核/manifest 工具；r6 使用新外部 `review-delivery-audit-result.json`，r5 及其 continuation 结果保留。

## 实际验收

命令、UTC、退出码和 log hash 由 `research/manage_baseline.py run` 保存于 `research/results/w00_baseline/`。

| 项目 | 结果 | 证据入口 |
|---|---|---|
| 源码 | 677 项，676 pass / 1 skip / 0 failed/error/warning | `review-source.txt/json` |
| build/check | 构建成功；Status: OK，0 ERROR/WARNING/NOTE | `review-build.*`、`review-package-check.*`、`review-00check.log` |
| 历史 API | 源码、真实安装包各 74/74 名称/位置参数顺序通过；不是全部行为 sign-off | `review-legacy-api-result.json`、`review-legacy-api-installed-result.json` |
| 安装接口清单/依赖 | 90 个导出函数；全部 Suggests 可加载 | `review-api-inventory.csv`、`review-optional-dependencies.csv`、`review-environment.*` |
| 完整/Imports-only 安装 smoke | 新覆盖及方向接口、typed validation、项目 HTML 均通过 | `review-full-smoke/`、`review-core-*`、`review-isolation-result.json` |
| miniACC 安装包 | 新库安装 tar 后完整运行；92病例、5模态、43完全观测；46配对、33特征、18同向/15反向；RNA BH<0.05为3、蛋白0 | `review-install.*`、`review-miniacc-installed.*`、`research/results/miniacc_installed_review/` |
| miniACC 数值复核 | 两份结果各23文件hash、66效应、方向、覆盖和BH通过 | `review-miniacc-audit.*`、`review-miniacc-installed-audit.*` |
| miniACC 边界 | 16 tests pass，含实际安装包异地回读与原运行8个核心表逐字节一致、拒绝覆盖不改变文件、异地旧/新格式、成员缺失/重复、symlink、错误hash，以及重写hash后的缺行/主键重复/额外测量/错误分组/效应/BH | `review-miniacc-boundaries-final.*`（初轮14项保留） |
| 契约/W09/W12 | 5个契约正反例按预期，3个W09流程测试pass；W12仍为1行template | `review-contracts.*`、`review-benchmark.*`、`review-w12.*` |
| HTTP/Shiny | 两协议实际body hash/bytes/精度/usage/retry/401；Shiny typed/evidence/payload/manifest/转义/英中/下载/MAE/双会话，1440/390无溢出 | `review-http-result.json`、`review-shiny-browser/summary.json` |
| bwrap边界 | readonly/outside write拒绝、gold/home不挂载、host网络拒绝、scratch报告、资源限额及timeout=124通过 | `review-sandbox-result.json`、`review-bwrap.*` |

本轮源码包功能未改写；修复集中于研究复核、安装模式、记录和文档。主稿/图表未重导出，沿用前轮已保存内容/几何记录；新交付仍逐成员核对当前文件。最终交付及 current/historical 审计结果以 `current_manifest.json`、`review-delivery-audit-result.json`、`current_audit.json`、`historical_audit.json` 为准，不把打包前的检查当成最终审计。

打包与采集拒绝覆盖旧输出；复核已有交付时使用新的 `--result` 路径。ZIP不包含自身、打包执行中日志、外部ZIP审计及后生成的current manifest，避免自引用；上述完整性入口在外部保存。

## 范围边界与后续

miniACC 安装包重跑是同一公开开发数据的工程复现，不增加独立数据来源或研究样本量；Python 从保存长表独立实现重算，但未独立重算 Wilcoxon 原始 p 值或从 RDS 解码原始矩阵。没有在线模型调用或新增专家/用户评分。独立科学/test-gold、全部 API 行为 sign-off、自动全覆盖分块、通路/跨物种/复杂空间联合检查、真实 docking 引擎版本、fresh OS/lockfile/远程矩阵仍未完整验收。W10-C/W11 保留 blocked_external（专家后置），W11-U deferred，W13 in_progress。
