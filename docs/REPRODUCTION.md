# 当前基线复现与结果审计

2026-10-08最新修订：当前稿`paper_cn_v2/`为v0.9（9页主稿/16页补充、六工具比较、SPARCL1固定候选/外部培养实验），详细记录见`implementation_records/PAPER_RELEASE_CONTINUATION.md`。源码/包记录采用`revision-source`、`revision-package-check`；新交付为r8。新发现分析依赖`research/discovery/requirements.txt`（SciPy1.17.1/NumPy1.26.4）。公开GitHub创建被令牌权限403阻塞，DOI未签发；状态见`RELEASE_ARCHIVE.md`。下述v0.8/r7及更早信息为历史范围。

2026-10-08论文续改：当前中文稿为`docs/paper_cn_v1/`的v0.8（23页/8图/0嵌入表），9份CSV/XLSX外置；本轮45项airway数值、15开发场景与工作台项目/PDF修复记录见`implementation_records/PAPER_CN_CONTINUATION.md`。新开发审阅包为r7，当前manifest采用`paper-cn-source`和`paper-cn-package-check`；下文r6和v0.7相关数字保留历史范围。当前模型无PDF/图片直接视觉能力，几何检查不等同人工图稿审阅。

W00 历史软件基线为 BioExplainR 0.3.1；当前开发版为 BioExplainR 0.4.0.9000。当前结果入口为 `research/results/current_manifest.json`，实际执行记录见 `implementation_records/`。Git 尚无 HEAD，manifest 的 commit SHA 为 null；版本通过文件清单 SHA-256 固定。

## 环境

本轮恢复 **Ubuntu 24.04.4、系统 R 4.3.3 / Bioconductor 3.18**，无需旧 `/tmp/opencode/r-env.sh`。`tools/server-R` 在配置临时 runtime 时使用它，否则回退系统 R。

| 依赖 | 本轮实际版本 |
|---|---|
| jsonlite / httr2 | 1.8.8 / 1.0.0 |
| testthat / pkgload / roxygen2 / xfun | 3.2.1 / 1.3.4 / 7.3.1 / 0.41 |
| callr / ggplot2 / shiny / uwot | 3.7.5 / 3.4.4 / 1.8.0 / 0.1.16 |
| DESeq2 / limma / edgeR | 1.42.0 / 3.58.1 / 4.0.16 |
| Biobase / S4Vectors / SE / SCE / SeuratObject | 2.62.0 / 0.40.2 / 1.32.0 / 1.24.0 / 5.0.1 |
| Python / Pandoc / LibreOffice | 3.12.3 / 3.1.3 / 24.2.7.2 |
| Node / Playwright / pngjs | 22.23.0 / 1.56.1 / 7.0.0 |
| python-docx / openpyxl / PyMuPDF / Pillow / matplotlib / numpy | 1.2.0 / 3.1.2 / 1.26.5 / 10.2.0 / 3.6.3 / 1.26.4 |

完整 R 包清单、dpkg 版本、工具导入验证分别在 `research/results/w00_baseline/r_packages.csv`、`system_packages.tsv`、`supplemental_tools.json`。Python 使用隔离 venv，直接依赖定义为 `tools/paper-requirements.txt`，实际完整 freeze 为 `paper_python_requirements.txt`；Node 实際 lock 保存为 `node_package_lock.json`。Ubuntu 的 python3-docx 为 1.1.0，但审计 venv 显式安装 1.2.0，不依赖用户 site-packages。Ubuntu 包直接安装的来源由 dpkg 记录；R DESCRIPTION 的 Repository 缺失不能据此宣称是另一个来源。

`tools/restore-baseline.sh` 使用保存的 Ubuntu 直接依赖版本及 Python/Node 精确版本恢复；`--print` 只打印包版本。系统 xfun 0.41 与同源 roxygen2 7.3.1 已实测通过，不要求把旧临时 runtime 的 xfun 0.53 pin 套到系统环境。脚本依赖对应发行版仓库仍提供版本；当前不是容器或完整 transitive lock，**干净环境复现留给 W13**。Chrome 已存在，浏览器完整版本记录在 environment.json。

```sh
# 在 Ubuntu 24.04 且有安装权限的环境，先确认软件源并 apt-get update：
bash tools/restore-baseline.sh --print
bash tools/restore-baseline.sh
bash tools/ensure-server-r-dev.sh
```

本轮曾有一次默认 apt 推荐依赖下载超时，随后使用 `--no-install-recommends` 成功恢复；dpkg --audit 无问题。成功安装日志在 W00 目录，未把超时过程记为通过。

## 当前与历史结果

| 类别 | 保存入口 | 本轮核对范围 |
|---|---|---|
| 当前主实验 | `research/results/main_scale_480/` | 120 cases、480 唯一目标、3 方法×3 重复；1,080 请求、4,320 scores；响应/claims/评分/CSV/manifest 对照 |
| 当前双模型 | `research/results/common_task_scale_480/` | StepFun、DeepSeek 各 120 请求、480/480；完整 600 case-method 记录与 2,400 scores，其中含非 API/缺失条件 |
| 五个公开数据集 | `research/results/public_datasets/` | airway、PBMC3k、pasilla、ALL、bladderbatch 保存状态 5/5 pass；本轮不重跑上游分析 |
| 独立数值参考 | `research/results/related_tools/pasilla_fact_checks.csv` | 六组阈值 30/30 actual=expected |
| 外部评价 | `research/results/human_evaluation/` | 720 外部评分、150 功能评分的聚合计数及均值一致性；原始评分不在项目内 |
| 论文 | `docs/submission_assets/` 和稿件 DOCX/PDF/HTML | 38 references、35 Figure PDF、13 主稿表、4 补充表、2,770 ZIP 记录；重新执行内容/几何和浏览器核对 |
| historical 六案例实验 | `research/results/experiment_manifest.json`、根目录 model/calls/scores | 54 请求、225 scores、90 claims、9 plots；旧审计保留为 historical 模式 |
| historical 预实验/小共同任务 | `research/results/pilot_precision/`、`common_task/` | 原文件保留、逐文件索引；不合并进当前主实验分母 |
| 既有辅助记录 | 根目录 browser/compatibility/complex_plot 等 | 历史或辅助来源，完整入口见 historical_files.csv；不是新运行的效果研究 |

主实验匹配率：direct_bounded 437/1,440，覆盖 516/1,440，已回答准确率 437/516；facts-only 和 facts-evidence 各 1,440/1,440。此为程序生成案例的协议/传输测试，不能当作独立科学解释准确率。

共同任务记录保留 `configured_code_agent=not_configured`、`saved_facts_only=missing`：runner 的 replay 指向历史六案例路径，规模 case 在那里不存在。240 次实际模型请求不能被其 600 条 case-method 行替代；这两个条件没有新的结果。

旧目录按索引分类，保持原路径。论文可继续引用历史消融，但须标清来源。2,905 个已有结果/交付文件的执行前清单在 `original_records.csv`，当前审计逐文件证明未变。

## 离线复核命令

以下命令在项目根目录执行；当前 manifest 已交付，不必先重建它。

```sh
R --vanilla --slave -f tools/check.R
R CMD build .
R CMD check --no-manual --no-vignettes --no-build-vignettes BioExplainR_0.4.0.9000.tar.gz
R --vanilla --slave -f research/audit_results.R --args --mode=current
R --vanilla --slave -f research/audit_results.R --args --mode=historical
python3 research/test_current_audit.py
```

默认 `research/audit_results.R` 运行 current。current 需要 Python 标准库，不需要模型配置或 R 生信依赖；也可直接 `python3 research/audit_current_results.py`。historical 保留原 R 检查，需要 jsonlite。审计只写 W00 审计结果，不修改保存实验。

`tools/check.R` 含 roxygen 文档生成；继续开发时检查其实际差异。W00 历史源码为 **531 项：530 pass、1 skip**；10-05 开发验收为 **648 项：647 pass、1 skip**，10-07 增加映射覆盖和方向接口后为 **677 项：676 pass、1 skip**。分别见 `w00_baseline/acceptance-source.txt/json` 和 `improvement-source.txt/json`；两轮包检查均 **Status: OK**，以对应 `acceptance-package-check.*` / `improvement-package-check.*` 为准。唯一跳过是已安装真实 DESeq2 时不重新定义模拟 S4 类；当前采用的日志由 manifest 的 software_check_records 指定。

当前实际构建产物 `BioExplainR_0.4.0.9000.tar.gz` 的路径、字节和 SHA-256 在 current manifest 的 `source.archive`；历史 0.3.1 tar 保留。源码 tar 成员与 package_source_files.csv 对照，DESCRIPTION 的 Packaged 元数据由 R CMD build 添加。重新构建 tar 的时间戳会改变 archive hash，文件内容基线用 package_code_hash 区分。

## 论文工具复核

```sh
/tmp/opencode/paper-venv/bin/python research/audit_submission.py --output research/results/w00_baseline/submission-audit.json
NODE_PATH=/tmp/opencode/node_modules BIOEXPLAINR_PAPER_RESULTS_DIR=research/results/w00_baseline/paper_browser node research/paper_smoke.cjs
```

两种视口为 1440×1000、390×844，均为 7 图/13 表、无横向溢出；Word PDF 65/10 页。新输出与历史 submission-audit/browser 分开；未重导出稿件或图表。工具依赖路径由 restore 脚本建立，依赖定义与实际版本保存于项目，不以临时目录本身作为环境定义。

旧 `docs/BioExplainR-submission-bundle.zip` 保留为过期包：210 成员、132 内容与当时当前树不一致、2 旧路径缺失；`bundle_inspection.json` 保存历史 hash/差异。当前开发审阅包在 `docs/BioExplainR-development-delivery-0.4.0.9000-r6.zip`，外部 hash/逐成员审计为 `review-delivery-audit-result.json`。r1/r2/r3/r4/r5 保留历史文件，r5 外部审计仍为 `continuation-delivery-audit-result.json`；最终发布/投稿 sign-off 仍未完成。

## 更新基线的规则

`python3 research/manage_baseline.py run <唯一label> -- <命令...>` 保存命令、UTC 起止、退出码和日志 hash；label 不覆盖旧执行记录。snapshot 仅执行一次并拒绝覆盖。

新增源码/文档检查完成后，可运行 environment、inspect_bundle、manifest 更新明确的当前基线，再执行 current/historical 审计。原始结果清单不能重写。源码/文档清单、结果分组清单和 baseline_artifacts 的所有路径相对项目根目录；manifest 不引用自身或包含自身的 ZIP。审计输出保存 manifest 的 SHA-256，使后续修改可被发现。

W01–W08 的工程入口为 `DATA_CONTRACTS.md`、`MIGRATION.md`、`inst/schema/` 和 `docs/implementation_records/`；W09/W12 离线入口见 `research/frozen_benchmark/` 和 `research/w12_challenges/`。没有新增专家、正式用户任务、模型规模实验或 release/DOI。

## 续接：完整可选依赖与隔离库

实际安装了 MultiAssayExperiment 1.28.0 和 SpatialExperiment 1.12.0（Bioc 3.18）；所有 DESCRIPTION Suggests 均可加载。当前完整 R/dpkg 清单在 `continuation-r-packages.csv`、`continuation-system-packages.tsv`，可选依赖状态在 `continuation-optional-dependencies.csv`。MAE/Spatial 的专项结果来自小型手算对象，非 W10 真实主案例。

在恢复 W00 环境后，可使用 `bash tools/restore-development-optional.sh` 恢复新增直接依赖，`--verify-only` 检查实际加载版本。SpatialExperiment 的真实下载来源、5,407,232 bytes 源归档和 SHA-256 `c49efa705e32d385b9bdcf3f8d205bf4e55cb1016ed59f0614c6b892f09782e8` 已保存。此恢复入口固定新增直接包和归档，不宣称完整 transitive lock；未在干净 OS 上运行。

```sh
# 新目录不能已经存在；链接当前系统的 Imports 及其依赖，排除可选生信/UI 库
python3 tools/isolated-library-check.py --archive BioExplainR_0.4.0.9000.tar.gz --output /tmp/opencode/bioexplainr-core-new
# 完整依赖库中使用已 check 安装的包
R_LIBS=BioExplainR.Rcheck Rscript --vanilla tools/offline-smoke.R /tmp/opencode/bioexplainr-full-new
Rscript --vanilla inst/fixtures/contracts/validate_fixtures.R
python3 research/test_frozen_benchmark.py
```

两个安装包 smoke 已实际通过。隔离库为同一 Ubuntu/R 上的新 library tree，依赖链接已有系统安装；不是 fresh OS/lockfile 测试。bwrap 实测只读输入/越界写入拒绝、独立 scratch、gold/home 不挂载、无 host 网络、资源限制/timeout；记录为 `acceptance-sandbox-result.json`。它是工程边界探针，不是完整 clean rootfs 或正式代码代理效果研究。Ubuntu/macOS × R release/oldrel-1 的远程 CI 配置已有，实际矩阵 not_run。

新增可复核工程入口（输出使用新文件/新目录）：

```sh
python3 tools/http-transport-smoke.py --output /tmp/opencode/http-check-new.json
python3 tools/shiny-acceptance.py --output /tmp/opencode/shiny-check-new
python3 tools/sandbox-boundary-check.py --library /tmp/opencode/bioexplainr-core-new/library --output /tmp/opencode/sandbox-check-new.json
Rscript --vanilla tools/legacy-interface-check.R /tmp/opencode/legacy-api-check-new.json
```

HTTP/Shiny runner 自动启动并终止测试服务。sandbox 使用 sudo bwrap 与 host runtime、2 GiB 地址空间、20 秒 CPU、1024 文件句柄和 controller timeout，受控 gold 不挂载。实际源码/依赖和原始结果清单仍按 current manifest 审计；这些 fixture 不是科学 test/gold。

W09 runner 运行目录不可覆盖；显式 `--mode=replay --replay=<public_predictions.csv>` 读取保存预测，无 replay 返回 missing_replay。audit 校验 public_cases/calls/replay hash、主键和状态并在失败时返回非零。`score_benchmark.R` 是外部显式评分进程，要求完整唯一 gold；runner 不读取 gold，仍不是 OS 隔离控制器。命令示例使用 `Rscript --vanilla`，参数直接追加。

## miniACC 公开开发案例

`research/results/miniacc_development_v1/` 保存公开 TCGA-ACC 的原始对象、样本映射、分期、配对测量、结果、RDS 和双语报告。方案及运行/数值复核入口见 `research/multiomics/README.md`。这是开发应用，不能作为独立 test/gold；Python 复核覆盖效应、方向、覆盖及 BH，未独立重算 Wilcoxon 原始 p 值。公开数据由执行者选择；专家评价后置，用户研究 deferred。

10-08 安装包重跑在 `research/results/miniacc_installed_review/`；源码 677 项（676 pass/1 skip）、包 check OK、历史 API 源码和安装包各74/74及 HTTP/Shiny/bwrap 新日志统一为 `review-*`。90个实际安装接口在 `review-api-inventory.csv`，最新 R/dpkg/Suggests 清单为 `review-r-packages.csv`、`review-system-packages.tsv`、`review-optional-dependencies.csv`。Imports-only smoke 包括手算映射覆盖和 exact-token 方向关系；miniACC 原目录与异地目录均可复核，完整成员/主键反例见 `test_audit_miniacc.py`。具体范围见 [REVIEW_CONTINUATION.md](implementation_records/REVIEW_CONTINUATION.md)。
