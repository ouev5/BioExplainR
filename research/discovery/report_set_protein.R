# Actual R package application on unselected original human protein array results.
args<-commandArgs(TRUE);out<-args[1];dest<-file.path(out,"unselected_protein")
stopifnot(!file.exists(file.path(dest,"bioexplainr_project.rds")))
pkgload::load_all(".",quiet=TRUE);library(jsonlite)
r<-read.csv(file.path(dest,"results.csv"),stringsAsFactors=FALSE)
tbl<-data.frame(gene=paste(r$feature_id,r$time_h,sep=":"),log2FoldChange=r$effect,pvalue=r$pvalue,FWER=r$holm112)
ctx<-bio_context(tbl,analysis_type="differential_expression",source_package="originalunselectedMaxQuantLFQ",
    species="Homo sapiens",tissue="testicular peritubular smooth-muscle-like cells",contrast="DEXminuscontrolat24/72h",
    design=list(unit_type="paired donor label"),scope=list(dataset_id="PXD033514_PXD033534",comparison_id="56genes_twoassays",sample_level="paired donor"),
    p_adjust_method=NULL,thresholds=list(padj=.05,lfc=0),language="zh")
expected<-sum(is.finite(r$effect)&r$holm112<.05&abs(r$effect)>0)
stopifnot(ctx$facts$n_features==112L,ctx$facts$n_significant==expected)
ctx$uncertainty<-c(ctx$uncertainty,"OriginalcompleteMaxQuantarrays, zerosmissing/noimputation, >=2technicalmeasurementspercondition required, actualbiopsydate labels. SameHTPCcohort asoldselectedtables, notnewindependentdonors; extraunselectedlabels age notfullyverified. Cross-tissue, notASMproteinevidence; separate112Holmfamily, exactsmall-sample limits.")
ctx$facts$scope_limitations<-paste(ctx$uncertainty,collapse=" | ")
p<-bio_project(list(unselectedhumanprotein=ctx),title="人源完整LFQ数组的候选检查",metadata=list(status="exploratory_unselected_array_reanalysis",online_model_calls=0L))
p<-bio_explain_project(p,use_llm=FALSE,language="zh")
saveRDS(p,file.path(dest,"bioexplainr_project.rds"));bio_report(p,file.path(dest,"BioExplainR-unselected-zh.html"),language="zh")
bio_report(p,file.path(dest,"BioExplainR-unselected-en.html"),language="en")
write_json(list(status="pass",contexts=1L,complete_family=112L,n_significant=expected,online_model_calls=0L,
    package_version=as.character(packageVersion("BioExplainR"))),file.path(dest,"bioexplainr_workflow.json"),auto_unbox=TRUE,pretty=TRUE)
