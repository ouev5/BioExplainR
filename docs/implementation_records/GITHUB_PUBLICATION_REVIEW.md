# BioExplainR 发布前检查与 GitHub 记录

日期：2026-10-10。包版本：0.4.0.9000；R 4.3.3 / Ubuntu。

负责人本轮重新授权：阅读 `rgo.md`、修复项目问题，以 R 包名创建 GitHub 仓库并上传项目。
旧文档中的 GitHub 暂停和创建失败为此前记录，本次执行状态以本文为准。

## 本次检查

|检查|实际结果|
|---|---|
|源码 testthat|677 项，676 pass、1 skip，0 failed / error / warning；当前环境安装真实 DESeq2，模拟类测试按预期跳过|
|当前 R 依赖|全部 Imports / Suggests 可加载|
|最新上皮结果封存|按交接指定的精确 rgo 快照政策核验 pass：30 文件、38 依赖、79 ZIP 成员；13,116 全数组检验、224 候选位置、343,957 工作簿单元；前下载封存 157 文件 / 25 完整文件 pass|
|R 包构建与检查|新临时目录构建成功；`R CMD check --no-manual --no-vignettes --no-build-vignettes` 为 Status: OK，0 ERROR / WARNING / NOTE|
|安装后离线工作流|Imports-only 独立库实际安装通过；context → 声明核对 → 覆盖 / 方向关系项目 → HTML 报告通过；README 快速示例实际执行通过|
|离线配套检查|5 个契约示例；3 个冻结基准测试；2 个分段下载测试；5 个 current 审计损坏探针均通过|
|GitHub 创建与推送|公开仓库 https://github.com/ouev5/BioExplainR 已创建；源码 / 文档 / 研究文件已全部推送至 main（远程不含按负责人选择省略的 CI 工作流）|
|发布内容扫描|38,781 个暂存文件及 5 个 LFS 实体扫描 pass，常见凭据格式发现 0；历史失败响应按原始字节扫描|

上皮封存的 rgo 文档记录通过
`research/results/package_discovery_workflow_v3/rgo_before_package_workflow.md`
核对，先匹配原记录的字节数与 SHA-256，再仅在核验进程内映射该文档项。
保存研究结果的复核没有重新拟合统计模型。

## 已修复问题

1. `.Rbuildignore` 排除根 `rgo.md`，避免非标准文件混入安装包。
2. README 与文档索引指向最新已导出 v0.13 和后续实际包应用 / 上皮结果。
3. README 离线快速开始提供可直接执行的合成示例表。
4. `.gitattributes` 保留已封存研究与文档原始字节，并正确处理 CSV 的 CRLF 行尾检查。
5. 约 4.13 GB / 3.88 万个待发布文件中，5 个超过 50 MiB 的文件用 Git LFS，其中 2 个超过普通 GitHub 单文件 100 MiB 限制。
6. 发布扫描器逐文件读取暂存内容，并核验、扫描 LFS 实体及 ZIP 内成员，避免只检查指针或一次性将全部文件载入内存。

首次全树扫描发现两类历史数据：4 个带 ZIP / DOCX 后缀的下载失败响应（含附件内副本），
按原始字节扫描并记录；蛋白原表和数据库块中长氨基酸序列被 AWS key 模式子串误匹配，
核对后增加完整标识边界。没有因扫描改写这些原始科学文件。
暂存 diff 的历史文本 / 下载日志保留原空格；源码、脚本与本次修订单独进行空白检查。

本次构建和安装输出在 `/tmp/opencode/bioexplainr-github-review/`。
新检查基于本机 R / 依赖，远程 CI 结果以 GitHub Actions 实际运行记录为准。

## 本次上传权限与网络处理

- GitHub 创建与普通内容写入、5 个 LFS 对象上传成功。
- 初次普通 Git 推送因默认 GitHub IP 连接超时 / 大请求连接中断未完成；通过 GitHub 官方可达 IP 的请求级解析覆盖继续，TLS 校验保持。
- 后续推送被 GitHub 明确拒绝：令牌没有 Workflows 写权限，不能创建 `.github/workflows/R-CMD-check.yaml`。
- 负责人确认“先上传项目”，同意远程先省略工作流。本地 `.github/workflows/R-CMD-check.yaml` 及含工作流的旧分支完整保留；远程发布使用独立历史，文件树与已审计暂存树仅在工作流和本次发布记录上不同。
- 当前远程没有运行自动 CI；未来取得 Workflows 写权限后可补传本地工作流。

## 最终远程核验

- 大目录拆为 39 个小批次，每批提交均经 GitHub API 确认后继续；5 个 LFS 对象全部上传成功，`git lfs fsck` 为 OK。
- 完整研究文件树提交：`2e3738a63f8fb620a92d335b3230ed0883bd002b`。
- GitHub API 返回的 tree 与本地完全一致：`69dfafcd0a1b2bb3c3cccb2c905f2ebf9840c3b7`；该树包含 38,780 个文件。
- 本记录随后独立提交更新发布状态；上述哈希固定对应完整项目文件树，后续文档提交另有自己的哈希。
- 远程默认分支 main，公开且非空；GitHub Actions 实际运行数 0。
- 本次以开发版代码仓库形式上传，正式版本 release / DOI 状态仍以实际归档为准。

## 尚需真实材料的后续工作

- `DESCRIPTION` 的维护者和邮箱仍为占位，正式 CRAN 投稿须提供真实维护者信息。
- 最新以包为主线的应用已有 11 上下文和 77 项声明核对，后续论文新稿尚未撰写；目前最新导出稿为 v0.13。
- 稿件作者、单位等信息及人工科学 / 图稿审阅仍待实际材料。
- 24h 上清处理来源差异和合格成人 ASM 因子 / 上清验证数据仍按交接列出的证据边界处理。

本记录是开发版软件与发布执行的工程检查记录。
