# W13 发布与复现清单

状态：工程入口已准备，最终发布待干净环境、作者资料和真实公开地址。

- [ ] 在干净 Ubuntu/R/Bioconductor 环境运行 `tools/restore-baseline.sh` 或正式 lock/container。
- [x] 当前本地开发环境运行 `tools/check.R`、R CMD build/check，10-08 日志为 `review-source` / `review-package-check`；10-05/07 日志保留。
- [x] 运行 fixture 正反例验证、W09 dry-run/replay/audit 及 Imports-only/完整依赖安装包离线 report smoke。
- [x] 所有 Suggests 安装版本与测试范围记录；MAE/Spatial 已有实际专项测试，不把 installed 等同完整版本支持。
- [x] 在新路径重建当前开发审阅包，审计 DOCX/PDF/HTML/Excel/记录 ZIP 内容/hash，旧投稿包保留。
- [x] 实测两种 HTTP 协议的 body bytes/hash/精度/usage/重试，以及 Shiny 双视口/双语言/下载/会话隔离。
- [x] bwrap 的只读输入、scratch、gold 不挂载、无网络、资源限额和 timeout 工程探针通过。
- [x] miniACC 使用真实安装包完整运行；异地目录回读、成员完整性、主键和重写 hash 后的损坏拒绝测试通过。
- [ ] 在远程实际运行完整 R/Bioconductor/OS CI 矩阵；当前仅完成配置和本地 YAML parse。
- [ ] 作者补齐单位、通讯邮箱、CRediT、基金、利益冲突、数据许可、伦理和人工评价材料。
- [ ] 获得真实 repository/release/DOI 后再写入 citation 和 submission manifest；不填占位 URL。
- [ ] 论文把 0.3.1 历史结果、新开发功能、独立研究结果和未完成模块分开。

当前 `BioExplainR 0.4.0.9000` 是开发版本，不能代替发布候选或 0.3.1 历史实验版本。

本机 host runtime 隔离探针和 Imports-only 库验证已完成，fresh OS/lockfile/远程矩阵仍未完成；边界见 [CONTINUATION_REVIEW.md](implementation_records/CONTINUATION_REVIEW.md)。开发审阅包见 [DEVELOPMENT_DELIVERY.md](DEVELOPMENT_DELIVERY.md)，用户本人事项仅列在 [USER_ACTIONS_REQUIRED.md](USER_ACTIONS_REQUIRED.md)。
