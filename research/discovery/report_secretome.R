# Actual BioExplainR application preserving whole-array and candidate denominators.
args <- commandArgs(TRUE); out <- normalizePath(args[1])
stopifnot(!file.exists(file.path(out,"bioexplainr_project.rds")))
pkgload::load_all(".",quiet=TRUE); library(jsonlite)
full <- read.csv(file.path(out,"all_results.csv"),stringsAsFactors=FALSE)
candidates <- read.csv(file.path(out,"candidate_results.csv"),stringsAsFactors=FALSE)
make <- function(r,id,adjusted,label) {
    t <- data.frame(gene=id,log2FoldChange=r$effect,pvalue=r$pvalue,padj=adjusted)
    context <- bio_context(t,analysis_type="differential_expression",source_package="MaxQuant_original_secretome_LFQ",
        species="Homo sapiens",tissue="human testicular peritubular cells",
        contrast="DEX minus solvent control at 24h and 72h; pooled multiplicity",
        design=list(unit_type="paired biopsy-date donor label"),
        scope=list(dataset_id="PXD033504",comparison_id=label,sample_level="paired donor label"),
        p_adjust_method=NULL,thresholds=list(padj=.05,lfc=0),language="zh")
    expected <- sum(is.finite(r$effect)&adjusted<.05&abs(r$effect)>0)
    stopifnot(context$facts$n_features==nrow(r),context$facts$n_significant==expected)
    context$uncertainty <- c(context$uncertainty,
        "Complete unselected extracellular protein arrays; zeros missing, no imputation. At least 2/3 technical measurements per condition, at least 3 paired donor labels. Technical repeats not independent n. Original and published sample scopes checked per assay; same HTPC source as prior proteome, not new ASM cohort.",
        "Extracellular LFQ abundance is not secretion rate or causal function. Missing effects are unavailable, P=1 family placeholders are not null observations. Separate pooled BH and fixed112 Holm families; exact small-sample correction unconfirmed.")
    context$facts$scope_limitations <- paste(context$uncertainty,collapse=" | ")
    context
}
contexts <- list(full_secretome=make(full,full$group_id,full$pooled_BH,"complete_QC_groups_pooled_BH"),
    fixed_candidates=make(candidates,paste(candidates$feature_id,candidates$time_h,sep=":"),candidates$holm112,"fixed56genes_two_timepoints_Holm112"))
p <- bio_project(contexts,title="PXD033504完整分泌蛋白组与候选证据",metadata=list(status="exploratory_public_secretome_reanalysis",online_model_calls=0L))
p <- bio_explain_project(p,use_llm=FALSE,language="zh")
saveRDS(p,file.path(out,"bioexplainr_project.rds"))
bio_report(p,file.path(out,"BioExplainR-secretome-zh.html"),language="zh")
bio_report(p,file.path(out,"BioExplainR-secretome-en.html"),language="en")
write_json(list(status="pass",contexts=2L,full_family=nrow(full),full_significant=sum(full$pooled_BH<.05),
    candidate_family=nrow(candidates),candidate_significant=sum(candidates$holm112<.05),online_model_calls=0L,
    package_version=as.character(packageVersion("BioExplainR"))),file.path(out,"bioexplainr_workflow.json"),auto_unbox=TRUE,pretty=TRUE)
writeLines(capture.output(sessionInfo()),file.path(out,"sessionInfo.txt"))
