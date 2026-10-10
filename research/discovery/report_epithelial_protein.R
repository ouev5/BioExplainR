# Apply actual BioExplainR source to complete fixed result families, offline.
args<-commandArgs(TRUE)
out<-if (length(args)) args[1] else "research/results/discovery_epithelial_protein_v1"
stopifnot(!file.exists(file.path(out,"bioexplainr_project.rds")))
pkgload::load_all(".",quiet=TRUE)
library(jsonlite)
r<-read.csv(file.path(out,"candidate_results.csv"),stringsAsFactors=FALSE)
contexts<-list();checks<-list()
for (family in unique(r$family)) {
  s<-r[r$family==family, ];is_a<-family=="A549_primary_56"
  tbl<-data.frame(gene=paste(s$feature_id,s$contrast,sep=":"),log2FoldChange=s$effect,pvalue=s$pvalue,FWER=s$holm)
  ctx<-bio_context(tbl,analysis_type="differential_expression",source_package="savedpublicepithelialproteomics",
    species="Homo sapiens",tissue=if (is_a) "A549 lung adenocarcinoma epithelial cell line" else "primary human bronchial epithelium",
    contrast=if (is_a) "DEX minus untreated at 48h" else if (family=="HBEC_primary_56") "clinical postICS minus preICS, unstimulated" else "clinical postICS minus preICS under polyIC and direct interaction",
    design=list(unit_type=if (is_a) "culture wells, unpaired" else "paired individuals"),
    scope=list(dataset_id=if (is_a) "PXD063431" else "PXD029135",comparison_id=family,
      sample_level=if (is_a) "culture well, not donor" else "individual"),
    p_adjust_method=NULL,thresholds=list(padj=.05,lfc=0),language="zh")
  expected<-sum(is.finite(s$effect)&s$holm<.05&abs(s$effect)>0)
  stopifnot(ctx$facts$n_features==nrow(s),ctx$facts$n_significant==expected)
  limitations<-if (is_a) "A549 cancer-derived cell line; four culture wells per group, not four donors; no proven suffix pairing; Welch model; log2 median centering, raw-log2 sensitivity. Not ASM or secretome, no time interaction or GR genetic intervention." else "Clinical ICS before/after association in bronchial epithelium, not controlled GC versus vehicle or ASM. Supplied median-normalized export units; exact conversion log unavailable. Direct polyIC interaction compares same-individual four cells; no antiviral or infection outcome. No imputation, missing and ambiguous slots retained."
  ctx$uncertainty<-c(ctx$uncertainty,limitations,"Exploratory fixed 54 genes plus PER1/NR3C1 controls; separate full Holm families and exact small-sample inference, pointwise CI. Not independent replication of adult ASM protein response; no causal/functional conclusion.")
  ctx$facts$scope_limitations<-paste(ctx$uncertainty,collapse=" | ")
  contexts[[family]]<-ctx
  checks[[family]]<-list(family=family,n_features=nrow(s),n_significant=expected,n_estimable=sum(is.finite(s$effect)))
}
project<-bio_project(contexts,title="已下载上皮蛋白数组的固定候选集合检查",metadata=list(status="exploratory_cross_cell_type_protein_analysis",online_model_calls=0L))
project<-bio_explain_project(project,use_llm=FALSE,language="zh")
saveRDS(project,file.path(out,"bioexplainr_project.rds"))
bio_report(project,file.path(out,"BioExplainR-epithelial-zh.html"),language="zh")
bio_report(project,file.path(out,"BioExplainR-epithelial-en.html"),language="en")
write_json(list(status="pass",package_version=as.character(packageVersion("BioExplainR")),contexts=checks,
  online_model_calls=0L,scope="exploratory epithelial protein results, not ASM controlled validation"),
  file.path(out,"bioexplainr_workflow.json"),auto_unbox=TRUE,pretty=TRUE)
print(checks)
