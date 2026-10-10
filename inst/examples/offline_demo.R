# BioExplainR 离线演示脚本 ---------------------------------------------------------
# 无需网络、无需 API key、无需 Bioconductor。运行：
#   source(system.file("examples", "offline_demo.R", package = "BioExplainR"))
# 生成的报告写入临时目录。

library(BioExplainR)
bio_configure("local")   # 显式本地模式：不会发出任何网络请求
set.seed(2026)

# 1. 模拟一个 DESeq2 风格的差异表达结果表 ---------------------------------------
n <- 2000
deg <- data.frame(
  baseMean = rexp(n, 1 / 200),
  log2FoldChange = rnorm(n, sd = 1.2),
  lfcSE = runif(n, 0.1, 0.5),
  pvalue = runif(n)^4,
  row.names = sprintf("GENE%04d", seq_len(n))
)
deg$padj <- p.adjust(deg$pvalue, "BH")
deg$padj[sample(n, 80)] <- NA   # 模拟独立过滤产生的 NA

ctx <- bio_context(deg, species = "Homo sapiens", tissue = "PBMC",
                   contrast = "treated vs control（treated 为分子）",
                   thresholds = list(padj = 0.05, lfc = 1))
print(ctx)
ex_deg <- bio_explain(ctx)
print(ex_deg)

# 只有原始 p 值时：不会被当作 FDR
raw_only <- deg[, c("log2FoldChange", "pvalue")]
print(bio_context(raw_only)$facts$p_value_basis)          # "raw_only"
print(bio_context(raw_only, p_adjust_method = "BH")$facts$p_value_basis)  # "computed_BH"

# 2. 模拟一个 clusterProfiler 风格的 ORA 结果表 ----------------------------------
enr <- data.frame(
  ID = sprintf("GO:%07d", 1:15),
  Description = c("inflammatory response", "cytokine-mediated signaling pathway",
                  "response to lipopolysaccharide", sprintf("example term %d", 4:15)),
  GeneRatio = paste0(25:11, "/180"), BgRatio = paste0(seq(400, 260, by = -10), "/18800"),
  pvalue = 10^-(seq(9, 1.5, length.out = 15)), stringsAsFactors = FALSE
)
enr$p.adjust <- p.adjust(enr$pvalue, "BH")
enr$qvalue <- enr$p.adjust
enr$geneID <- "IL6/TNF/IL1B/CXCL8/CCL2/NFKBIA/SOCS3"
enr$Count <- 25:11
ex_enr <- bio_explain(enr, data_dependencies = "deg", species = "Homo sapiens")
print(ex_enr)

# 3. 用户提供的证据 -----------------------------------------------------------------
bio_evidence_register(bio_evidence(
  "DOI", id = "10.1186/s13059-014-0550-8", title = "DESeq2 (Love, Huber & Anders 2014)",
  claim = "DESeq2 的收缩估计与 Wald 检验", type = "literature",
  url = "https://doi.org/10.1186/s13059-014-0550-8"))

# 4. 运行记录与错误诊断 -------------------------------------------------------------
coldata <- data.frame(condition = c("treated", "control", "treated", "control"))
run <- bio_record({
  design_levels <- levels(factor(coldata$condition))
  contrast_check <- coldata$conditon == "treated"   # 拼写错误：conditon
  if (!any(contrast_check)) stop("contrasts can be applied only to factors with 2 or more levels")
}, label = "设计检查", purpose = "检查分组变量")
print(run)
print(bio_explain_error(run))
print(bio_suggest_fix(run))

# 5. 在独立 R 进程中验证用户显式给出的修复（需要 callr）----------------------------
validation <- NULL
if (requireNamespace("callr", quietly = TRUE)) {
  validation <- bio_validate_fix(
    quote({
      coldata$condition <- relevel(factor(coldata$condition), ref = "control")
      coldata
    }),
    inputs = list(coldata = coldata),
    invariants = list(
      inv_factor_levels("condition", c("control", "treated")),  # 比较方向：treated vs control
      inv_same_nrow_as_input("coldata")                          # 样本没有丢失
    ))
  print(validation)
}

# 6. 报告 -----------------------------------------------------------------------------
items <- list(差异表达 = ex_deg, 富集分析 = ex_enr, 运行记录 = run)
if (!is.null(validation)) items$修复验证 <- validation
md_file <- file.path(tempdir(), "bioexplainr_demo.md")
html_file <- file.path(tempdir(), "bioexplainr_demo.html")
bio_report(items, file = md_file)
bio_report(items, file = html_file)
cat("Markdown:", md_file, "\nHTML:", html_file, "\n")
bio_evidence_clear()
