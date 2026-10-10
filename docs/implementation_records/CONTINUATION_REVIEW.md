# 续接审阅与工程验收

日期：2026-10-05；开发版本：0.4.0.9000；schema：1.0。

本轮为代码复核、修复和本机工程验收，不是领域专家 sign-off、第三方复现或新科学研究。W01–W09/W12 保留 ready_for_review，W10/W11 blocked_external，W13 in_progress。仅需负责人本人完成的事项集中于 [USER_ACTIONS_REQUIRED.md](../USER_ACTIONS_REQUIRED.md)。

## 修复范围

| 范围 | 复现的问题 | 实际修复 |
|---|---|---|
| W01 identity/fixtures | finalize 改变 context_id，legacy 读取补造 hash，反例只 parse 不校验 | identity 幂等、legacy 缺失保留；结构/枚举/duplicate ID fixture 接受与拒绝 |
| W02 payload/manifest | list 数组变对象，嵌套 ID/路径/凭据泄漏，任意配置可进入 manifest；后续过滤误删 token usage 和公开 URL | 保留结构、递归策略/public allowlist；用量计数保留；结构化 URL 去 user/password/secret query/fragment；公开 URL 和 fact source_path 保留 |
| W02 HTTP | body 默认序列化与 17 位 facts 策略不同；hash 没有真实传输验证 | 实际 HTTP JSON body digits=17/null 策略，bytes/hash scope 分开；loopback 两协议捕获实际 body 核对 |
| W03 typed aggregate | typed schema/type/scope/unit 失败被旧 pass 掩盖 | typed/evidence findings 决定总状态，保留 legacy_status；精确 integer、类型、路径、scope、方向、unit 检查；模型原文未覆盖时最多 partial |
| W04 support | contradictory/irrelevant/definition relation 可成为 pass；scope fail 被忽略 | pair 级失败/unknown 聚合；候选不升级 expert；review/content provenance 检查 |
| W05 map/MAE | technical 标签允许冲突 biological unit；缺失 modality 未核对；child 只存 hash | 重复键约束、双侧 observed 检查、child context/facts 与 alignment 保留 |
| W06 spatial/neighbors | 空 imgData 当图像，非有限范围异常，旧测试 all(NULL) | 真实 SpatialExperiment 专项、空图像/范围 missing 语义、实际 edges/非空检查 |
| W07 docking | 缺列底层异常，higher-is-better 仍升序，RMSD 列等于参考定义 | 明确缺列、方向排序，unit/reference/controls provenance；不赋机制 pass |
| W08 integration | 项目/诊断/证据 prompt 隐私策略不一致，新模态落 generic，本地 auto evidence 被提前拒绝 | 本地新模态模板、完整 project facts、统一 prompt 过滤；auto retrieval 回归；Shiny 详情/i18n/报告接入 |
| W09 artifacts/score | 运行覆盖、行数代替主键/hash 检查、replay 空实现、score 未读取输入、缺 gold 可计算 accuracy | 不可覆盖运行、public label 检查、输入/calls/replay hash/主键/status audit；显式评分进程、缺 gold 不产 accuracy、correct 重算 |

## 实际验收

结果均位于 `research/results/w00_baseline/`，命令通过 `research/manage_baseline.py run` 保存 UTC、退出码及 log hash。

| 验收 | 结果 | 记录 |
|---|---|---|
| 源码 | 648 项：647 pass、1 skip、0 fail/error/warning | `acceptance-source.txt/json` |
| 构建/检查 | R CMD build 成功，check Status: OK，0 ERROR/WARNING/NOTE | `acceptance-build.txt/json`、`acceptance-package-check.txt/json` |
| 历史 API | 74/74 导出名称、位置参数顺序通过；不是全部行为等价证明 | `acceptance-legacy-api-result.json` |
| HTTP 实际传输 | OpenAI/Anthropic bytes/hash/极小 p/PCA/null/usage；503 两次、401 一次 | `acceptance-http-result.json` |
| Shiny 浏览器 | typed/evidence/payload/manifest、外部文本转义、双语言、下载、MAE alignment、双会话；1440/390 均无溢出 | `acceptance-shiny-browser/summary.json`、截图/下载文件 |
| 隔离库 | 真实 tar 安装，Imports-only context→typed→project→report；可选生信/UI 库不可加载 | `acceptance-imports-only.txt/json`、`continuation-core-*` |
| bwrap smoke | 真实安装库、user/network namespace、只读根、临时 report | `acceptance-bwrap-final.txt/json`、`continuation-bwrap-offline-smoke-status.txt` |
| 执行边界 | 只读 input、越界写入拒绝、gold/host home 不挂载、host listener 不可达、scratch report、2 GiB/20 CPU s/1024 files、timeout exit 124 | `acceptance-sandbox-result.json` |
| fixture/benchmark | 5 个正反例按预期接受/拒绝；3 个 W09 流程测试；W12 仍 template | 前轮 fixture/benchmark 日志及对应脚本 |
| 稿件/结果 | Word/Excel/PDF/记录 hash 与稿件双视口；current/historical 均 pass | `continuation-submission-audit-result.json`、paper browser、current/historical audit |

测试全部使用手写工程 fixture 或实际安装包；没有在线 provider、正式 test/gold、专家或用户研究。未回答/unknown 不转为效果结果。历史 2,905 个原文件由原保护清单核对。

## 失败记录与边界

早期 bwrap 非特权失败、0700 public fixture 不可读、R 启动要求的 fd limit、Rcheck 并发安装和 API 空参数表示问题，均保留真实失败日志；成功记录以表中入口为准。API 检查修正的是 `NULL` 与空参数向量表示，未改写旧 API 顺序。

隔离探针只挂载 host runtime、包库和公开输入，project/home/gold 不挂载；限制与 timeout 有实测。它不是 fresh Ubuntu/container image/transitive lock 重建，也不是独立模型代码代理效果研究。Shiny 仍是本地共享 R/文件/网络权限工具，不应用 bwrap 探针替其宣称多租户沙箱。

## 尚未覆盖

- 全部 API 行为的独立 sign-off、自动全覆盖分块协议、跨模态方向联合检查、Seurat spatial/复杂空间图层及真实引擎格式/version fixture仍无完整验收。
- W09 正式独立 test/gold、W10 真实案例、W11 人员/伦理/原评分、W12 独立标签与模型代理正式评测尚缺真实材料。
- 全新 OS/lockfile/远程 R/Bioc/macOS 矩阵、独立第三方身份复现、最终人工图稿审核与公开发布仍待相应输入。

用户事项只包含科学材料/决定、人员参与和授权；以上未覆盖的工程项由工程流程持续维护，不要求用户运行脚本。
