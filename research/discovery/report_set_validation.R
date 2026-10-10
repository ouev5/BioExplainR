# Full-set facts and explicit exploratory inference boundaries.
args<-commandArgs(TRUE);out<-args[1];stopifnot(!file.exists(file.path(out,"bioexplainr_set_project.rds")))
pkgload::load_all(".",quiet=TRUE);library(jsonlite)
items<-checks<-list()
for(method in c("tpm","count")) {
    all<-read.csv(file.path(out,paste0(method,"_results.csv")),stringsAsFactors=FALSE)
    for(family in unique(all$family)) {
        r<-all[all$family==family,];name<-paste(method,family,sep="_")
        tbl<-data.frame(gene=paste(r$feature_id,r$contrast,sep=":"),log2FoldChange=r$effect,pvalue=r$pvalue,FWER=r$holm)
        ctx<-bio_context(tbl,analysis_type="differential_expression",source_package="public 54-gene set expansion",
            species="Homo sapiens",tissue="adult airway smooth muscle",contrast=name,
            design=list(unit_type="paired donor",independent_units=6L),scope=list(dataset_id="GSE130715",comparison_id=name,sample_level="paired donor"),
            p_adjust_method=NULL,thresholds=list(padj=.05,lfc=0),language="zh")
        expected<-sum(is.finite(r$effect)&r$holm<.05&abs(r$effect)>0)
        stopifnot(ctx$facts$n_significant==expected,ctx$facts$n_features==nrow(r))
        ctx$uncertainty<-c(ctx$uncertainty,"Exploratory expansion after known six-candidate results. GNAS is not NR3C1; single24h endpoint. TPM/count share six donors; labels/aliases not fully independent across old studies. Missing genes keep P=1 slot, no null claim. Exact six-donor Holm not confirmed.")
        ctx$facts$scope_limitations<-paste(ctx$uncertainty,collapse=" | ")
        items[[name]]<-ctx;checks[[name]]<-data.frame(context=name,n_features=nrow(r),expected=expected,observed=ctx$facts$n_significant)
    }
}
p<-bio_project(items,title="54基因成人ASM扩展检查",metadata=list(status="exploratory_set_validation",online_model_calls=0L,new_wet_experiments=FALSE))
p<-bio_explain_project(p,use_llm=FALSE,language="zh")
saveRDS(items,file.path(out,"bioexplainr_set_contexts.rds"));saveRDS(p,file.path(out,"bioexplainr_set_project.rds"))
bio_report(p,file.path(out,"BioExplainR-set-zh.html"),language="zh");bio_report(p,file.path(out,"BioExplainR-set-en.html"),language="en")
write.csv(do.call(rbind,checks),file.path(out,"bioexplainr_fact_checks.csv"),row.names=FALSE)
write_json(list(status="pass",contexts=4L,online_model_calls=0L,package_version=as.character(packageVersion("BioExplainR")),scope="Actual source-loaded package, complete54/162families and bilingual reports"),file.path(out,"bioexplainr_workflow.json"),auto_unbox=TRUE,pretty=TRUE)
