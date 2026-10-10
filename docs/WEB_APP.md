# BioExplainR 本地浏览器工作台

`bio_run_app()` 是 BioExplainR 面向初级生物信息学研究员的可选图形入口。它运行在本地 R 进程中，浏览器只负责显示界面和发送用户点击或代码文本。

## 安装和启动

```r
install.packages(c("shiny", "ggplot2"))
# 只有需要从表达矩阵计算 UMAP 时才需要：
install.packages("uwot")

library(BioExplainR)
bio_configure("local")
bio_run_app()
```

默认监听 `127.0.0.1`。如果本机有多个 R 环境，应在启动工作台的同一个 R 会话中先加载 BioExplainR 和需要使用的上游包：

```r
library(BioExplainR)
library(DESeq2)
bio_run_app(envir = environment())
```

默认地址只接受本机连接。若将 `host` 改为 `0.0.0.0` 或公网 IP，应由部署者自行配置认证、TLS 和反向代理；Shiny 不是多租户隔离。不同浏览器连接的工作区可分开，但仍共享 R 进程的包、网络和文件权限。

启动时，调用环境中的对象会复制到当前浏览器会话的工作区。浏览器中后续创建的对象只属于这一会话；点击“刷新环境信息”可以更新对象和包表。

## 页面工作流

1. 在“模型设置”中选择 `local`、OpenAI-compatible、Anthropic、DeepSeek 或 Ollama 预设，填写自己的服务地址和模型 ID。API key 推荐使用环境变量名，页面只显示 key 的状态，不显示 key 内容。
2. 在“R 环境与运行记录”中查看 R 版本、搜索路径、已加载包、已安装包、工作区对象摘要和代码运行历史。
3. 在“代码执行”中输入自己的 R 代码。点击执行后，代码通过 `bio_record_code()` 运行，页面保留状态、警告、错误、调用位置、返回值类型、创建对象和包函数使用。
4. 在“Natural-language result analysis”中选中对象，填写物种、组织、比较方向和阈值，点击分析。默认使用 BioExplainR 的 English 规则；在模型设置中选择简体中文后，界面、离线解释、模型提示和报告随之切换。
5. 在“常用图形”中选择对象并生成 PCA、UMAP/嵌入、富集气泡图或表达热图。图形也可以在 R 中继续修改，然后传给 `bio_context()` 或 `bio_explain()`。

0.4.0.9000 论文续改支持直接选择 `bio_project`：分析页保留项目摘要、依赖、主病例分母、完全观测病例、模态覆盖、两两交集及方向关系 findings，报告下载使用同一项目。原始样本映射和病例 ID 不进入这些页面。绘图成功后可点击“下载当前图形（PDF）”，获得 Cairo 矢量 PDF；失败时旧图与下载入口清空。

0.3.1 支持在绘图时选择元数据、分组列和图形对象名。图形会保存回当前工作区；
在分析页可选“图形源结果”执行数值核对，预期只绘制部分通路时勾选允许子集。
模型设置支持输出 token 上限、JSON mode 和 DeepSeek thinking。模型声明和图形核对状态显示在分析页。
每个连接的工作区、页面配置和记录独立；R 进程的已加载包仍共享。

真实浏览器测试记录见 `research/results/browser/summary.json`，测试包括页面 DeepSeek 解释、
实际对象、图像像素、下载及两个浏览器连接的对象隔离。

## 可复用的 R 接口

```r
rec <- bio_record_code("res <- DESeq2::results(dds); res")
bio_object_inventory()
bio_runtime_info()
bio_package_usage()

pca <- bio_plot_pca(counts, metadata = sample_info, group = "condition")
umap <- bio_plot_umap(umap_coordinates, metadata = cell_metadata, group = "cluster")
dot <- bio_plot_enrichment(ora_table)
hm <- bio_plot_heatmap(expression_matrix, metadata = sample_info, top_n = 50)
bio_explain(pca, use_llm = FALSE)
```

`bio_package_usage()` 的 `argument_values` 是脱敏后的表达式摘要：字符常量会显示为 `[string omitted]`，其他表达式会截断。完整代码只在当前 `bio_record` 对象中保留，生成报告时仍会经过代码脱敏。

## 解释边界

PCA 的方差解释率由 R 从输入矩阵计算。UMAP 只提供低维坐标和可视化邻近关系。富集气泡图的横坐标、颜色和点大小来自输入表的列。热图颜色表示输入值或行标准化后的相对值。任何图形都不能单独证明通路激活、细胞谱系、因果机制或处理有效性；应结合完整源结果、实验设计和证据进行判断。

浏览器代码与当前 R 会话具有相同的文件和网络权限，`bio_run_app()` 不是操作系统级安全沙箱。模型不会自动执行生成的代码。
