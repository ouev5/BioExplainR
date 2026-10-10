# 安装和运行

## 标准 R 环境

要求 R >= 4.1，必需依赖为 `httr2`、`jsonlite` 与 `digest`；实际本地验证为 R 4.3.3/Bioc 3.18，版本矩阵由 CI 单列记录。

```r
install.packages(c("httr2", "jsonlite", "digest", "callr"))
install.packages("/path/to/BioExplainR_0.4.0.9000.tar.gz", repos = NULL, type = "source")
library(BioExplainR)
bio_configure("local")
source(system.file("examples", "full_workflow.R", package = "BioExplainR"))
```

也可以在源码目录运行 `R CMD INSTALL .`。

## 生信对象的可选依赖

```r
install.packages(c("BiocManager", "SeuratObject", "ggplot2", "Matrix"))
BiocManager::install(c("DESeq2", "limma", "edgeR", "SingleCellExperiment", "SummarizedExperiment",
                      "MultiAssayExperiment", "SpatialExperiment"))
source(system.file("examples", "real_objects.R", package = "BioExplainR"))
```

如需本地浏览器工作台和常用图形：

```r
install.packages(c("shiny", "ggplot2"))
# 从表达矩阵计算 UMAP 时再安装：
install.packages("uwot")
library(BioExplainR)
bio_run_app()
```

工作台只监听本机地址 `127.0.0.1`，也可以通过 `bio_run_app(host = ..., port = ...)`
显式指定监听参数。浏览器中执行的代码属于当前 R 会话；代码通过 `bio_record_code()` 记录，
模型不会自动生成或执行代码。

读取已经生成的普通结果表不要求安装这些上游包。

## 当前服务器

2026-10-05 W00 已恢复系统 R 4.3.3 和 Bioconductor 3.18 的开发/可选依赖；旧用户态临时 runtime 不再是当前环境。
`tools/server-R` 优先使用显式配置的临时环境，没有配置时回退系统 R：

```sh
bash tools/server-R --version
bash tools/server-R --vanilla --slave -f tools/check.R
bash tools/server-R CMD INSTALL .
bash tools/server-R --vanilla --slave -e 'library(BioExplainR); source(system.file("examples", "full_workflow.R", package="BioExplainR"))'
```

完整实际版本、日志及恢复脚本见 [REPRODUCTION.md](REPRODUCTION.md)；Python/Node 依赖定义已保存，临时 venv/node_modules 可按定义重建。正式部署仍使用正常源码包安装。

## 模型连接

本包支持两种 HTTP 协议。服务名、模型 ID 和账号权限由实际供应商决定。

```r
# 建议在 ~/.Renviron 设置 MY_LLM_KEY，随后重启 R
bio_configure("openai_compatible",
  base_url = "https://your-service.example/v1",
  api_key_env = "MY_LLM_KEY", model = "your-model-id")

# 原生 Anthropic Messages 或同协议代理
bio_configure("anthropic",
  base_url = "https://your-service.example",
  api_key_env = "MY_LLM_KEY", model = "your-claude-id")

bio_llm_available(reason = TRUE)
bio_explain(result, use_llm = TRUE)
```

`endpoint` 可覆盖完整路径；`base_url` 可含 `/v1`、其他版本路径及查询参数。
密钥会在请求时读取，打印配置和生成报告时不会显示密钥。
内置连接预设可以用 `bio_presets()` 查看，机构自建预设用 `bio_register_preset()` 注册。

## 开发检查

```r
install.packages(c("testthat", "pkgload", "roxygen2", "withr"))
source("tools/check.R")
```

```sh
R CMD build .
R CMD check --no-manual BioExplainR_0.4.0.9000.tar.gz
```

测试不调用付费模型；模型协议用模拟服务验证。公共证据检索由用户显式调用。

2026-10-05 W00：系统环境中的 Shiny 1.8.0、httpuv 1.6.14 和 uwot 0.1.16 均已恢复；源码 530 pass/1 skip、完整包检查 `Status: OK`，日志为 `research/results/w00_baseline/`。真实数据和付费模型实验需要单独显式运行研究脚本，W00 仅离线审计保存结果。
