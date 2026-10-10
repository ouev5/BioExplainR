# Offline error diagnosis --------------------------------------------------------------

.bioc_packages <- c("DESeq2", "edgeR", "limma", "clusterProfiler", "DOSE", "org.Hs.eg.db", "org.Mm.eg.db",
                    "AnnotationDbi", "SummarizedExperiment", "SingleCellExperiment", "scater", "scran",
                    "enrichplot", "ReactomePA", "biomaRt", "GenomicRanges", "S4Vectors", "apeglm",
                    "fgsea", "msigdbr", "tximport", "sva", "Biobase", "GEOquery", "ComplexHeatmap")

.function_home <- c(
  DESeq = "DESeq2", DESeqDataSetFromMatrix = "DESeq2", results = "DESeq2", lfcShrink = "DESeq2", vst = "DESeq2",
  rlog = "DESeq2", lmFit = "limma", eBayes = "limma", topTable = "limma", voom = "limma",
  makeContrasts = "limma", DGEList = "edgeR", calcNormFactors = "edgeR", glmQLFit = "edgeR",
  glmQLFTest = "edgeR", exactTest = "edgeR", enrichGO = "clusterProfiler", enrichKEGG = "clusterProfiler",
  gseGO = "clusterProfiler", bitr = "clusterProfiler", dotplot = "enrichplot", mapIds = "AnnotationDbi",
  CreateSeuratObject = "Seurat", FindMarkers = "Seurat", FindAllMarkers = "Seurat", NormalizeData = "Seurat",
  RunUMAP = "Seurat", FindClusters = "Seurat", DimPlot = "Seurat", ggplot = "ggplot2", aes = "ggplot2",
  geom_point = "ggplot2", `%>%` = "magrittr", mutate = "dplyr", filter = "dplyr", colData = "SummarizedExperiment",
  assay = "SummarizedExperiment", reducedDim = "SingleCellExperiment", logNormCounts = "scuttle")

# Each rule: pattern (regex on message), category, title, explanation, advice(function(m, rec) -> list)
.error_rules <- function() list(
  list(id = "package_missing", pattern = "there is no package called|\u4e0d\u5b58\u5728\u53eb.*\u7684\u7a0b\u8f91\u5305|namespace .* is not available|package .* is not installed|Bioconductor version",
       title = "R \u5305\u672a\u5b89\u88c5\u6216\u7248\u672c\u4e0d\u6ee1\u8db3",
       explain = "\u6240\u9700\u7684\u5305\u5728\u5f53\u524d R \u5e93\u4e2d\u4e0d\u5b58\u5728\uff0c\u6216\u4f9d\u8d56\u7684\u7248\u672c\u4e0d\u6ee1\u8db3\u3002"),
  list(id = "function_missing", pattern = "could not find function|\u6ca1\u6709.*\u8fd9\u4e2a\u51fd\u6570",
       title = "\u627e\u4e0d\u5230\u51fd\u6570",
       explain = "\u51fd\u6570\u540d\u62fc\u5199\u9519\u8bef\uff0c\u6216\u63d0\u4f9b\u8be5\u51fd\u6570\u7684\u5305\u6ca1\u6709\u52a0\u8f7d\uff08library()\uff09\u3002"),
  list(id = "object_missing", pattern = "object '.*' not found|object .* not found|\u627e\u4e0d\u5230\u5bf9\u8c61",
       title = "\u627e\u4e0d\u5230\u5bf9\u8c61",
       explain = "\u5f15\u7528\u7684\u53d8\u91cf\u5728\u5f53\u524d\u73af\u5883\u4e0d\u5b58\u5728\uff1a\u53ef\u80fd\u5c1a\u672a\u8fd0\u884c\u521b\u5efa\u5b83\u7684\u4ee3\u7801\u3001\u62fc\u5199\u9519\u8bef\uff0c\u6216\u5728\u51fd\u6570\u5185\u90e8\u4f5c\u7528\u57df\u4e0d\u540c\u3002"),
  list(id = "column_missing", pattern = "undefined columns selected|\u9009\u62e9\u4e86\u672a\u5b9a\u4e49\u7684\u5217|\u4e0b\u6807\u51fa\u754c|Column `.*` (not found|doesn't exist)|object '.*' not found.*data|Can't subset columns|subscript out of bounds|`.*` not found in",
       title = "\u5217\u540d\u3001\u7d22\u5f15\u6216\u7ef4\u5ea6\u4e0d\u5b58\u5728",
       explain = "\u8bbf\u95ee\u7684\u5217/\u884c/\u5143\u7d20\u4e0d\u5b58\u5728\u3002\u5e38\u89c1\u4e8e\u7ed3\u679c\u8868\u7f3a\u5c11 gene\u3001pvalue \u6216 log2FC \u5217\uff0c\u6216\u7d22\u5f15\u8d85\u51fa\u8303\u56f4\u3002"),
  list(id = "dimension_mismatch", pattern = "non-conformable|\u975e\u6574\u5408|\u53c2\u6570\u503c\u610f\u5473\u7740\u4e0d\u540c\u7684\u884c\u6570|arguments imply differing number of rows|replacement has .* rows?, data has|must have the same (length|number)|lengths? differ|ncol\\(countData\\) == nrow\\(colData\\)|length of .* must equal|Aesthetics must be either length 1 or the same",
       title = "\u7ef4\u5ea6\u6216\u957f\u5ea6\u4e0d\u4e00\u81f4",
       explain = "\u4e24\u4e2a\u5bf9\u8c61\u7684\u884c/\u5217\u6570\u4e0d\u5339\u914d\uff0c\u4f8b\u5982\u8ba1\u6570\u77e9\u9635\u5217\u6570\u4e0e\u6837\u672c\u4fe1\u606f\u884c\u6570\u4e0d\u4e00\u81f4\uff0c\u6216 aes \u957f\u5ea6\u4e0e\u6570\u636e\u4e0d\u7b26\u3002"),
  list(id = "s4_slot_or_method", pattern = "unable to find an inherited method|\u65e0\u6cd5\u4e3a.*\u627e\u5230\u7ee7\u627f\u65b9\u6cd5|no slot of name|no applicable method for|not a valid .* object|is not an S4 object|cannot coerce",
       title = "\u5bf9\u8c61\u7c7b\u578b\u6216 S4 \u65b9\u6cd5/\u69fd\u4f4d\u4e0d\u5339\u914d",
       explain = "\u51fd\u6570\u6536\u5230\u7684\u5bf9\u8c61\u7c7b\u578b\u4e0e\u9884\u671f\u4e0d\u540c\uff08\u4f8b\u5982\u628a data.frame \u5f53\u6210 Seurat/SummarizedExperiment\uff09\uff0c\u6216\u8bbf\u95ee\u4e86\u4e0d\u5b58\u5728\u7684\u69fd\u4f4d/assay\u3002"),
  list(id = "assay_or_layer_missing", pattern = "Cannot find '.*' in this Seurat object|assay .* not (found|present)|invalid name for slot|layer .* not found|No layers found|'assay' .* not in",
       title = "assay / layer / slot \u4e0d\u5b58\u5728",
       explain = "\u5355\u7ec6\u80de\u5bf9\u8c61\u4e2d\u6ca1\u6709\u6240\u8bf7\u6c42\u7684 assay\u3001layer \u6216\u964d\u7ef4\u7ed3\u679c\uff0c\u53ef\u80fd\u662f\u6b65\u9aa4\u672a\u8fd0\u884c\u6216 Seurat v4/v5 API \u5dee\u5f02\u3002"),
  list(id = "gene_id_mapping", pattern = "None of the keys entered are valid keys|No gene can be mapped|--> No gene can be mapped|fail to map|keytype|not valid keys",
       title = "\u57fa\u56e0 ID \u65e0\u6cd5\u6620\u5c04",
       explain = "\u8f93\u5165\u57fa\u56e0 ID \u7c7b\u578b\uff08SYMBOL/ENTREZID/ENSEMBL\uff09\u4e0e\u6ce8\u91ca\u6570\u636e\u5e93\u6216\u51fd\u6570\u671f\u671b\u7684 keyType \u4e0d\u4e00\u81f4\uff0c\u6216\u7269\u79cd\u4e0d\u5bf9\u3002"),
  list(id = "factor_level_contrast", pattern = "contrasts can be applied only to factors with 2 or more levels|is not a level|levels? .* not (found|in)|contrast .* not|not full rank|model matrix is not full rank|the model matrix",
       title = "\u5206\u7ec4\u53d8\u91cf\u3001\u56e0\u5b50\u6c34\u5e73\u6216\u6bd4\u8f83\u65b9\u5411\u95ee\u9898",
       explain = "\u8bbe\u8ba1\u77e9\u9635\u4e2d\u7684\u5206\u7ec4\u56e0\u5b50\u6c34\u5e73\u4e0d\u5b58\u5728\u3001\u53ea\u6709\u4e00\u4e2a\u6c34\u5e73\u3001\u6216\u4e0e\u5176\u4ed6\u53d8\u91cf\u5b8c\u5168\u5171\u7ebf\uff1b\u4e5f\u53ef\u80fd\u662f contrast \u4e2d\u7684\u7ec4\u540d\u62fc\u5199\u4e0d\u4e00\u81f4\u3002"),
  list(id = "count_data_invalid", pattern = "some values in assay are not integers|every gene contains at least one zero|negative values|NA values are not allowed|counts .* integer",
       title = "\u8ba1\u6570\u6570\u636e\u4e0d\u7b26\u5408\u65b9\u6cd5\u8981\u6c42",
       explain = "DESeq2/edgeR \u7b49\u9700\u8981\u539f\u59cb\u6574\u6570\u8ba1\u6570\uff1b\u8f93\u5165\u53ef\u80fd\u5df2\u6807\u51c6\u5316\u3001\u542b\u8d1f\u503c\u6216\u7f3a\u5931\u503c\uff0c\u6216\u5b58\u5728\u5168\u96f6\u95ee\u9898\u3002"),
  list(id = "na_nan_inf", pattern = "NA/NaN/Inf in|\u5916\u63a5\u51fd\u6570\u8c03\u7528\u65f6\u4e0d\u80fd\u6709NA|\u9700\u8981TRUE/FALSE\u503c\u7684\u5730\u65b9\u4e0d\u53ef\u4ee5\u7528\u7f3a\u5c11\u503c|missing values (are )?not allowed|missing value where TRUE/FALSE needed|non-finite",
       title = "\u7f3a\u5931\u503c\u6216\u65e0\u7a77\u503c\u5bfc\u81f4\u5931\u8d25",
       explain = "\u8ba1\u7b97\u4e2d\u51fa\u73b0\u4e86 NA/NaN/Inf\uff0c\u5e38\u89c1\u4e8e log(0)\u3001\u9664\u4ee5 0\u3001\u6216\u6570\u636e\u5408\u5e76\u540e\u4ea7\u751f\u7f3a\u5931\u3002"),
  list(id = "type_mismatch", pattern = "non-numeric argument|\u4e8c\u8fdb\u5217\u8fd0\u7b97\u7b26\u4e2d\u6709\u975e\u6570\u503c\u53c2\u6570|\u975e\u6570\u503c\u53c2\u6570|invalid 'type'|argument is not numeric|must be numeric|cannot be coerced|is not a (numeric|character)|invalid argument to unary operator|'x' must be numeric",
       title = "\u6570\u636e\u7c7b\u578b\u4e0d\u5339\u914d",
       explain = "\u51fd\u6570\u671f\u671b\u6570\u503c\u578b\uff0c\u4f46\u6536\u5230\u5b57\u7b26\u6216\u56e0\u5b50\uff08\u4f8b\u5982\u8bfb\u5165\u8868\u683c\u65f6\u6570\u5b57\u88ab\u8bfb\u6210\u6587\u672c\uff09\u3002"),
  list(id = "argument_issue", pattern = "unused argument|\u53c2\u6570\u6ca1\u6709\u7528|\u7f3a\u5c11\u53c2\u6570.*\u4e5f\u6ca1\u6709\u7f3a\u7701\u503c|argument .* is missing, with no default|formal argument .* matched by multiple|argument .* matches multiple",
       title = "\u51fd\u6570\u53c2\u6570\u9519\u8bef",
       explain = "\u53c2\u6570\u540d\u62fc\u5199\u9519\u8bef\u3001\u7f3a\u5c11\u5fc5\u9700\u53c2\u6570\uff0c\u6216\u5305\u7248\u672c\u66f4\u65b0\u540e\u53c2\u6570\u540d\u53d1\u751f\u53d8\u5316\u3002"),
  list(id = "file_path", pattern = "cannot open file|\u65e0\u6cd5\u6253\u5f00\u6587\u4ef6|\u6ca1\u6709\u90a3\u4e2a\u6587\u4ef6\u6216\u76ee\u5f55|No such file or directory|cannot open the connection|does not exist in current working directory",
       title = "\u6587\u4ef6\u8def\u5f84\u9519\u8bef",
       explain = "\u6587\u4ef6\u4e0d\u5b58\u5728\u6216\u5de5\u4f5c\u76ee\u5f55\u4e0d\u5bf9\u3002"),
  list(id = "memory", pattern = "cannot allocate vector of size|\u65e0\u6cd5\u5206\u914d\u5927\u5c0f\u4e3a|memory exhausted|vector memory",
       title = "\u5185\u5b58\u4e0d\u8db3",
       explain = "\u5bf9\u8c61\u8fc7\u5927\uff0c\u5185\u5b58\u4e0d\u8db3\uff1b\u5e38\u89c1\u4e8e\u628a\u7a00\u758f\u77e9\u9635\u8f6c\u6362\u4e3a\u7a20\u5bc6\u77e9\u9635\u3002"),
  list(id = "network", pattern = "Timeout was reached|Could not resolve host|SSL|HTTP error|cannot open URL|Failed to perform HTTP request",
       title = "\u7f51\u7edc\u6216\u8fdc\u7a0b\u670d\u52a1\u9519\u8bef",
       explain = "\u8bbf\u95ee\u8fdc\u7a0b\u6570\u636e\u5e93/\u7f51\u7edc\u8d44\u6e90\u5931\u8d25\u3002")
)

.localize_rule <- function(r, language) {
  if (identical(language, "en")) {
    txt <- .error_text_en[[r$id]]
    if (!is.null(txt)) { r$title <- txt$title; r$explain <- txt$explain }
  }
  r
}

.classify_error <- function(msg, language = .current_language()) {
  language <- .check_language(language)
  for (r in .error_rules()) if (grepl(r$pattern, msg, ignore.case = FALSE, perl = TRUE)) return(.localize_rule(r, language))
  for (r in .error_rules()) if (grepl(r$pattern, msg, ignore.case = TRUE, perl = TRUE)) return(.localize_rule(r, language))
  .localize_rule(list(id = "unknown", title = "\u672a\u5f52\u7c7b\u7684\u9519\u8bef",
       explain = "\u8be5\u9519\u8bef\u672a\u5339\u914d\u79bb\u7ebf\u89c4\u5219\u5e93\uff0c\u8bf7\u7ed3\u5408\u8c03\u7528\u6808\u3001\u5bf9\u8c61\u6458\u8981\u548c\u51fd\u6570\u6587\u6863\uff08?\u51fd\u6570\u540d\uff09\u6392\u67e5\u3002"), language)
}

.quoted <- function(msg) {
  m <- regmatches(msg, regexpr("['\u2018\u201c`\"][^'\u2019\u201d`\"]+['\u2019\u201d`\"]", msg))
  if (length(m)) substr(m, 2, nchar(m) - 1) else NA_character_
}

.advice <- function(rule, msg, rec, language = .current_language()) {
  language <- .check_language(language)
  if (identical(language, "zh")) .advice_zh(rule, msg, rec) else .advice_en(rule, msg, rec)
}

.advice_zh <- function(rule, msg, rec) {
  q <- .quoted(msg)
  env_names <- rec$environment_names %||% character()
  out <- list()
  add <- function(text, code = NULL) out[[length(out) + 1L]] <<- list(text = text, code = code)
  switch(rule$id,
    package_missing = {
      pkg <- if (!is.na(q)) q else "<pkg>"
      if (pkg %in% .bioc_packages) add(paste0("'", pkg, "' \u662f Bioconductor \u5305\uff0c\u5e94\u4f7f\u7528 BiocManager \u5b89\u88c5\u3002"),
                                       paste0('if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")\nBiocManager::install("', pkg, '")'))
      else add(paste0("\u5b89\u88c5\u7f3a\u5931\u7684\u5305 '", pkg, "'\u3002"), paste0('install.packages("', pkg, '")'))
    },
    function_missing = {
      fn <- if (!is.na(q)) q else "<fun>"
      home <- .function_home[fn]
      if (!is.na(home)) add(paste0("\u51fd\u6570 ", fn, "() \u901a\u5e38\u6765\u81ea ", home, " \u5305\uff1b\u5148\u52a0\u8f7d\u8be5\u5305\u6216\u4f7f\u7528 ", home, "::", fn, "()\u3002"),
                            paste0("library(", home, ")"))
      else add(paste0("\u68c0\u67e5\u51fd\u6570\u540d ", fn, " \u7684\u62fc\u5199\uff0c\u5e76\u786e\u8ba4\u63d0\u4f9b\u5b83\u7684\u5305\u5df2\u7528 library() \u52a0\u8f7d\u3002"),
               paste0('help.search("', fn, '")'))
    },
    object_missing = {
      obj <- if (!is.na(q)) q else "<object>"
      near <- if (length(env_names) && !is.na(q)) utils::head(env_names[utils::adist(obj, env_names) <= 2], 3) else character()
      if (length(near)) add(paste0("\u73af\u5883\u4e2d\u6709\u540d\u79f0\u76f8\u8fd1\u7684\u5bf9\u8c61\uff1a", paste(near, collapse = ", "), "\uff1b\u68c0\u67e5\u662f\u5426\u62fc\u5199\u9519\u8bef\u3002"))
      add("\u786e\u8ba4\u521b\u5efa\u8be5\u5bf9\u8c61\u7684\u4ee3\u7801\u5df2\u7ecf\u8fd0\u884c\uff08\u4f8b\u5982\u5728 bio_record \u4e2d\u5148\u8d4b\u503c\u518d\u4f7f\u7528\uff09\uff0c\u5e76\u7528 ls() \u67e5\u770b\u73b0\u6709\u5bf9\u8c61\u3002", "ls()")
    },
    column_missing = add("\u7528 names()/colnames()/dim() \u67e5\u770b\u5bf9\u8c61\u5b9e\u9645\u7684\u5217\u540d\u4e0e\u7ef4\u5ea6\uff0c\u786e\u8ba4\u5217\u540d\u5927\u5c0f\u5199\u4e0e\u6765\u6e90\u5305\u4e00\u81f4\uff08\u5982 padj vs adj.P.Val\uff09\u3002",
                         "names(res); dim(res)"),
    dimension_mismatch = add("\u6bd4\u8f83\u76f8\u5173\u5bf9\u8c61\u7684\u7ef4\u5ea6\u548c\u6837\u672c\u987a\u5e8f\uff0c\u4f8b\u5982 ncol(counts) \u4e0e nrow(coldata)\uff0c\u5e76\u68c0\u67e5 colnames(counts) \u4e0e rownames(coldata) \u662f\u5426\u4e00\u81f4\u4e14\u540c\u5e8f\u3002",
                             "stopifnot(identical(colnames(counts), rownames(coldata)))"),
    s4_slot_or_method = add("\u7528 class(x)\u3001isVirtualClass/methods::is() \u548c str(x, max.level = 2) \u68c0\u67e5\u5bf9\u8c61\u7c7b\u578b\uff1b\u5fc5\u8981\u65f6\u7528\u6b63\u786e\u7684\u6784\u9020\u51fd\u6570\u8f6c\u6362\u5bf9\u8c61\u3002",
                            "class(x); methods::is(x)"),
    assay_or_layer_missing = add("\u5217\u51fa\u5bf9\u8c61\u4e2d\u73b0\u6709\u7684 assay/layer/\u964d\u7ef4\u540d\u79f0\uff0c\u5e76\u786e\u8ba4\u76f8\u5e94\u6b65\u9aa4\uff08\u5982 NormalizeData\u3001RunPCA\u3001RunUMAP\uff09\u5df2\u8fd0\u884c\u3002",
                                 "SeuratObject::Assays(obj); SeuratObject::Layers(obj); names(obj@reductions)"),
    gene_id_mapping = {
      add("\u68c0\u67e5\u8f93\u5165\u57fa\u56e0 ID \u7684\u7c7b\u578b\uff08\u5982 'TP53' \u662f SYMBOL\uff0c'7157' \u662f ENTREZID\uff0c'ENSG...' \u662f ENSEMBL\uff09\uff0c\u5e76\u5728\u5bcc\u96c6\u51fd\u6570\u4e2d\u8bbe\u7f6e\u4e00\u81f4\u7684 keyType \u548c\u7269\u79cd\u6ce8\u91ca\u5305\u3002")
      add("\u9700\u8981\u65f6\u7528 clusterProfiler::bitr() \u8f6c\u6362 ID\uff0c\u5e76\u62a5\u544a\u65e0\u6cd5\u6620\u5c04\u7684\u6bd4\u4f8b\u3002",
          'clusterProfiler::bitr(genes, fromType = "SYMBOL", toType = "ENTREZID", OrgDb = "org.Hs.eg.db")')
    },
    factor_level_contrast = {
      add("\u68c0\u67e5\u5206\u7ec4\u53d8\u91cf\u7684\u6c34\u5e73\u548c\u6bcf\u7ec4\u6837\u672c\u6570\uff0c\u786e\u8ba4 contrast \u4e2d\u7684\u7ec4\u540d\u4e0e levels \u5b8c\u5168\u4e00\u81f4\u3002", "table(coldata$condition); levels(coldata$condition)")
      add("\u5982\u9700\u6307\u5b9a\u53c2\u8003\u7ec4\uff0c\u7528 relevel() \u663e\u5f0f\u8bbe\u7f6e\uff1b\u6ce8\u610f\u8fd9\u4f1a\u6539\u53d8 log2FC \u7684\u65b9\u5411\uff0c\u4fee\u6539\u540e\u8981\u68c0\u67e5\u6bd4\u8f83\u65b9\u5411\u662f\u5426\u4ecd\u7b26\u5408\u7814\u7a76\u76ee\u7684\u3002",
          'coldata$condition <- relevel(factor(coldata$condition), ref = "control")')
    },
    count_data_invalid = {
      add("\u786e\u8ba4\u8f93\u5165\u662f\u672a\u7ecf\u6807\u51c6\u5316\u7684\u539f\u59cb\u6574\u6570\u8ba1\u6570\uff08\u4e0d\u662f TPM/FPKM/log \u503c\uff09\u3002", "summary(as.vector(counts)); all(counts == round(counts))")
      add("\u4e0d\u8981\u7b80\u5355 round() \u6807\u51c6\u5316\u540e\u7684\u6570\u636e\u6765\u89c4\u907f\u9519\u8bef\u2014\u2014\u8fd9\u6837\u80fd\u8fd0\u884c\u4f46\u7edf\u8ba1\u6a21\u578b\u5047\u8bbe\u5df2\u88ab\u7834\u574f\u3002")
    },
    na_nan_inf = add("\u5b9a\u4f4d\u4ea7\u751f NA/Inf \u7684\u6b65\u9aa4\uff08\u5982 log(0)\uff09\uff0c\u7528 is.na()/is.finite() \u7edf\u8ba1\u6570\u91cf\uff0c\u518d\u51b3\u5b9a\u8fc7\u6ee4\u6216\u52a0\u4f2a\u8ba1\u6570\uff0c\u5e76\u8bb0\u5f55\u8be5\u5904\u7406\u3002",
                     "sum(!is.finite(as.matrix(x)))"),
    type_mismatch = add("\u7528 str() \u67e5\u770b\u5217\u7c7b\u578b\uff1b\u82e5\u6570\u5b57\u88ab\u8bfb\u6210\u5b57\u7b26\uff0c\u7528 as.numeric() \u8f6c\u6362\u5e76\u68c0\u67e5\u662f\u5426\u4ea7\u751f\u4e86 NA\u3002", "str(x)"),
    argument_issue = add("\u7528 args(\u51fd\u6570\u540d) \u6216 ?\u51fd\u6570\u540d \u67e5\u770b\u5f53\u524d\u5b89\u88c5\u7248\u672c\u7684\u53c2\u6570\u5217\u8868\uff0c\u5e76\u6838\u5bf9\u5305\u7248\u672c\u3002",
                         if (!is.na(q)) paste0("args(", q, ")") else NULL),
    file_path = add("\u7528 getwd() \u548c file.exists() \u68c0\u67e5\u8def\u5f84\uff1b\u63a8\u8350\u4f7f\u7528\u9879\u76ee\u5185\u76f8\u5bf9\u8def\u5f84\u3002", 'getwd(); file.exists("path/to/file")'),
    memory = add("\u907f\u514d\u5c06\u7a00\u758f\u77e9\u9635\u8f6c\u4e3a\u7a20\u5bc6\u77e9\u9635\uff0c\u6309\u9700\u5b50\u96c6\u5316\uff0c\u6216\u5728\u66f4\u5927\u5185\u5b58\u7684\u673a\u5668\u4e0a\u8fd0\u884c\u3002"),
    network = add("\u68c0\u67e5\u7f51\u7edc\u8fde\u63a5\u4e0e\u4ee3\u7406\u8bbe\u7f6e\uff0c\u7a0d\u540e\u91cd\u8bd5\uff1b\u5728\u62a5\u544a\u4e2d\u8bb0\u5f55\u6570\u636e\u5e93\u7248\u672c\u4e0e\u8bbf\u95ee\u65f6\u95f4\u3002"),
    add("\u9605\u8bfb\u5b8c\u6574\u8c03\u7528\u6808\uff0c\u4ece\u6700\u5185\u5c42\u7684\u7528\u6237\u4ee3\u7801\u8c03\u7528\u5f00\u59cb\u6392\u67e5\uff1b\u7528 str() \u67e5\u770b\u76f8\u5173\u8f93\u5165\u5bf9\u8c61\u3002")
  )
  out
}

.as_error_input <- function(x) {
  if (is.null(x)) x <- bio_last_error()
  if (is.null(x)) stop("No recorded error. Run code with bio_record({ ... }) first, or pass a condition/message.", call. = FALSE)
  if (inherits(x, "bio_record")) {
    if (is.null(x$error)) stop("This bio_record has no error (status: ", x$status, ").", call. = FALSE)
    return(x)
  }
  if (inherits(x, "condition")) {
    return(structure(list(code = NA_character_, error = list(message = conditionMessage(x),
      call = if (!is.null(conditionCall(x))) paste(deparse(conditionCall(x)), collapse = " ") else NA_character_,
      stack = character(), location = NA_character_, class = class(x)), session = .session_versions()),
      class = "bio_record"))
  }
  if (is.character(x)) {
    return(structure(list(code = NA_character_, error = list(message = paste(x, collapse = "\n"),
      call = NA_character_, stack = character(), location = NA_character_, class = "character"),
      session = .session_versions()), class = "bio_record"))
  }
  stop("x must be a bio_record, condition or error message.", call. = FALSE)
}

#' Diagnose a recorded error
#'
#' Classifies the error with an offline rule base (package/function/object
#' missing, columns/dimensions, S4 class/slot, assay/layer, gene ID mapping,
#' factor levels/contrast, count data, NA/Inf, types, arguments, files, memory,
#' network) and reports the location, call stack and related object summaries.
#' Optionally a configured model adds an explanation; model text is unverified.
#'
#' @param x A \code{bio_record} with an error, a condition, or an error message.
#'   Defaults to \code{\link{bio_last_error}()}.
#' @param config,use_llm,language See \code{\link{bio_explain}}. Default
#'   \code{use_llm = FALSE}. \code{language} is \code{"en"} (default) or
#'   \code{"zh"}; it selects the rule titles, explanations, fix suggestions,
#'   learning tip and printed labels (the offline classifier recognises both
#'   English and Chinese R error messages regardless of this setting).
#' @param include_code Include recorded code in the model request. Off by
#'   default. When enabled, character literals are removed and known keys
#'   are redacted. Recorded calls and stacks are always stripped of literals.
#' @return Object of class \code{bio_error_diagnosis}.
#' @export
#' @examples
#' r <- bio_record(stop("there is no package called 'DESeq2'"))
#' d <- bio_explain_error(r)
#' d$category
bio_explain_error <- function(x = NULL, config = NULL, use_llm = FALSE, language = NULL,
                              include_code = FALSE) {
  config <- config %||% bio_get_config()
  language <- .resolve_language(language, config)
  .local_language(language)
  rec <- .as_error_input(x)
  msg <- rec$error$message
  rule <- .classify_error(msg, language)
  diag <- list(
    language = language,
    category = rule$id,
    title = rule$title,
    message = msg,
    explanation = rule$explain,
    location = rec$error$location,
    call = rec$error$call,
    stack = rec$error$stack,
    code = rec$code,
    purpose = rec$purpose,
    related_objects = c(rec$objects_used, rec$objects_created),
    warnings = rec$warnings,
    session = rec$session[c("r_version", "platform", "bioexplainr")],
    learning_tip = "Read the innermost call related to your own code first, then compare the input objects' class, dimensions, column names and factor levels; do not look only at the last error line." %L%
      "\u5148\u8bfb\u6700\u5185\u5c42\u4e0e\u81ea\u5df1\u4ee3\u7801\u76f8\u5173\u7684\u8c03\u7528\uff0c\u518d\u5bf9\u7167\u8f93\u5165\u5bf9\u8c61\u7684 class\u3001\u7ef4\u5ea6\u3001\u5217\u540d\u548c\u56e0\u5b50\u6c34\u5e73\uff1b\u4e0d\u8981\u53ea\u770b\u6700\u540e\u4e00\u884c\u62a5\u9519\u3002",
    llm = NULL
  )
  if (isTRUE(use_llm)) {
    if (!bio_llm_available(config)) stop("use_llm = TRUE but no model is usable: ", bio_llm_available(config, reason = TRUE), call. = FALSE)
    payload <- .payload_sanitize(list(error_message = bio_redact(msg), error_call = .code_payload(diag$call),
                    location = .code_payload(diag$location),
                    stack = lapply(utils::tail(diag$stack, 15), .code_payload), offline_category = rule$id,
                    code = if (isTRUE(include_code)) .code_payload(rec$code) else NULL, purpose = rec$purpose,
                    objects = lapply(diag$related_objects, function(o) o[setdiff(names(o), "size")]),
                    r_version = rec$session$r_version), bio_payload_policy())
     if (!isTRUE(include_code)) payload$code <- NA_character_
    sys <- paste0("You are an R and bioinformatics debugging tutor. Answer in ",
                  if (identical(language, "zh")) "Simplified Chinese (\u7b80\u4f53\u4e2d\u6587)" else "English",
                  ". Use only the provided error, stack, code and object summaries. Distinguish the direct cause from possible underlying causes. ",
                  "Any code you propose is an UNVERIFIED suggestion; mention what statistical or biological meaning it could change. ",
                  "Return ONLY JSON with keys: direct_cause, possible_causes (array), suggested_steps (array), proposed_code (string or null), semantic_risks (array), learning_tip.")
    res <- bio_llm_chat(config, sys, bio_redact(paste0("Recorded error context:\n", .json(payload, pretty = TRUE))))
    parsed <- .extract_json(res$text)
    diag$llm <- list(content = if (!is.null(parsed)) parsed else list(free_text = res$text),
                     model = config$model, protocol = config$protocol, endpoint_host = res$endpoint_host,
                     status = "model-generated; unverified")
  }
  structure(diag, class = "bio_error_diagnosis")
}

#' @export
print.bio_error_diagnosis <- function(x, ...) {
  .local_language(x$language %||% .default_language)
  cat("== Error diagnosis: " %L% "== \u9519\u8bef\u8bca\u65ad\uff1a", x$title, " [", x$category, "] ==\n", sep = "")
  cat("Error message: " %L% "\u62a5\u9519\u4fe1\u606f\uff1a", x$message, "\n", sep = "")
  if (!is.na(x$location %||% NA)) cat("Location (innermost user-related call): " %L% "\u51fa\u9519\u4f4d\u7f6e\uff08\u6700\u5185\u5c42\u7528\u6237\u76f8\u5173\u8c03\u7528\uff09\uff1a", x$location, "\n", sep = "")
  if (length(x$stack)) {
    cat("Call stack (outer to inner):\n" %L% "\u8c03\u7528\u6808\uff08\u7531\u5916\u5230\u5185\uff09\uff1a\n")
    for (s in utils::tail(x$stack, 10)) cat("  > ", s, "\n", sep = "")
  }
  cat("Possible cause: " %L% "\u53ef\u80fd\u539f\u56e0\uff1a", x$explanation, "\n", sep = "")
  cat("Learning tip: " %L% "\u5b66\u4e60\u63d0\u793a\uff1a", x$learning_tip, "\n", sep = "")
  if (!is.null(x$llm)) cat("[Includes a model diagnosis (" %L% "[\u5305\u542b\u6a21\u578b\u8bca\u65ad\uff08", x$llm$model, ") - unverified]\n" %L% "\uff09\uff0c\u672a\u7ecf\u9a8c\u8bc1]\n", sep = "")
  invisible(x)
}

#' Suggest (unverified) fixes for a recorded error
#'
#' Returns rule-based suggestions, optionally with code snippets. Suggestions
#' are \strong{never executed} automatically and are marked
#' \code{"unverified"}. To check one, pass an explicit expression to
#' \code{\link{bio_validate_fix}} together with named inputs and invariants.
#' If \code{use_llm = TRUE}, model-proposed code is attached as text only.
#'
#' @inheritParams bio_explain_error
#' @return Object of class \code{bio_fix_suggestions}.
#' @export
#' @examples
#' r <- bio_record(stop("could not find function \"DESeq\""))
#' bio_suggest_fix(r)
bio_suggest_fix <- function(x = NULL, config = NULL, use_llm = FALSE, language = NULL) {
  config <- config %||% bio_get_config()
  language <- if (is.null(language) && inherits(x, "bio_error_diagnosis")) x$language %||% .default_language else .resolve_language(language, config)
  .local_language(language)
  diag <- if (inherits(x, "bio_error_diagnosis")) x else bio_explain_error(x, config = config, use_llm = use_llm, language = language)
  rec <- if (inherits(x, "bio_record")) x else .as_error_input(if (inherits(x, "bio_error_diagnosis")) diag$message else x)
  rule <- .classify_error(diag$message, language)
  sugg <- lapply(.advice(rule, diag$message, rec, language), function(s) c(s, list(source = "offline_rules", status = "unverified")))
  if (!is.null(diag$llm)) {
    code <- diag$llm$content$proposed_code
    steps <- diag$llm$content$suggested_steps
    sugg[[length(sugg) + 1L]] <- list(
      text = paste(c(unlist(steps), unlist(diag$llm$content$semantic_risks)), collapse = "\n"),
      code = if (is.character(code) && length(code) == 1 && nzchar(code)) code else NULL,
      source = paste0("llm:", diag$llm$model), status = "unverified (model-generated, not executed)")
  }
  structure(list(category = diag$category, title = diag$title, message = diag$message,
                 suggestions = sugg, diagnosis = diag,
                 language = language,
                 note = "Suggestions have not been run or verified. Check them in a separate R process with bio_validate_fix(expr, inputs = list(...), invariants = list(...))." %L%
                   "\u5efa\u8bae\u672a\u7ecf\u8fd0\u884c\u9a8c\u8bc1\u3002\u8bf7\u7528 bio_validate_fix(expr, inputs = list(...), invariants = list(...)) \u5728\u72ec\u7acb R \u8fdb\u7a0b\u4e2d\u68c0\u67e5\u3002"),
            class = "bio_fix_suggestions")
}

#' @export
print.bio_fix_suggestions <- function(x, ...) {
  .local_language(x$language %||% .default_language)
  cat("== Fix suggestions (" %L% "== \u4fee\u590d\u5efa\u8bae\uff08", x$title, if (.is_zh()) "\uff09==\n" else ") ==\n", sep = "")
  for (i in seq_along(x$suggestions)) {
    s <- x$suggestions[[i]]
    cat(i, ". [", s$status, "] ", s$text, "\n", sep = "")
    if (!is.null(s$code)) cat("   Code:\n" %L% "   \u4ee3\u7801\uff1a\n", paste0("     ", strsplit(s$code, "\n")[[1]], collapse = "\n"), "\n", sep = "")
  }
  cat(x$note, "\n")
  invisible(x)
}
