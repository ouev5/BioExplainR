# Independent original MaxQuant extraction and donor/statistical recomputation.
args<-commandArgs(TRUE);out<-args[1];dest<-file.path(out,"unselected_protein")
stopifnot(!file.exists(file.path(dest,"r_audit.json")))
library(jsonlite)
read<-function(n)read.csv(file.path(dest,n),stringsAsFactors=FALSE,check.names=FALSE)
close<-function(a,b)stopifnot(isTRUE(all.equal(as.numeric(a),as.numeric(b),tolerance=1e-7)))
mapping<-read("sample_map.csv");measure<-read("measurements.csv");effects<-read("donor_effects.csv");results<-read("results.csv")
raw<-list();checks<-list();statistics<-list()
for(acc in c("PXD033514","PXD033534")) {
    directory<-file.path(out,"protein_full_tables_small",acc)
    manifest<-if(file.exists(file.path(directory,"extraction_verified.json")))file.path(directory,"extraction_verified.json") else file.path(directory,"extraction.json")
    completion<-read_json(manifest,simplifyVector=TRUE);stopifnot(completion$status=="pass")
    entry<-completion$outputs[grepl("proteinGroups.txt$",completion$outputs$member),]
    raw[[acc]]<-read.delim(entry$path,check.names=FALSE,stringsAsFactors=FALSE,quote="",comment.char="")
}
for(i in seq_len(nrow(measure))) {
    r<-measure[i,];table<-raw[[r$source_project]];row<-as.integer(r$source_row)-1L
    stopifnot(table$`Protein IDs`[row]==r$protein_ids,!any(unlist(table[row,c("Reverse","Potential contaminant","Only identified by site")])=="+"))
    value<-as.numeric(table[row,r$source_column]);close(value,r$raw_LFQ)
    if(value>0)close(log2(value),r$log2_LFQ) else stopifnot(is.na(r$log2_LFQ))
    checks[[i]]<-data.frame(feature_id=r$feature_id,time_h=r$time_h,donor=r$donor,raw=value)
}
for(i in seq_len(nrow(effects))) {
    r<-effects[i,];z<-measure[measure$feature_id==r$feature_id&measure$time_h==r$time_h&measure$donor==r$donor,]
    co<-log2(z$raw_LFQ[z$condition=="co"&z$raw_LFQ>0]);dex<-log2(z$raw_LFQ[z$condition=="dex"&z$raw_LFQ>0])
    stopifnot(length(co)==r$control_technical_observed,length(dex)==r$DEX_technical_observed)
    if(length(co)>=2&&length(dex)>=2)close(mean(dex)-mean(co),r$effect) else stopifnot(r$status=="insufficient_LFQ",is.na(r$effect))
}
for(i in which(results$status=="estimable")) {
    r<-results[i,];x<-effects$effect[effects$feature_id==r$feature_id&effects$time_h==r$time_h&effects$status=="paired"]
    stopifnot(length(x)==r$n_donors);tt<-t.test(x);signs<-as.matrix(expand.grid(rep(list(c(-1,1)),length(x))))
    exact<-mean(abs(as.numeric(signs%*%x)/length(x))>=abs(mean(x))-1e-12)
    close(c(mean(x),sd(x)/sqrt(length(x)),tt$conf.int,tt$p.value,exact),c(r$effect,r$se,r$ci_low,r$ci_high,r$pvalue,r$exact_pvalue))
    statistics[[length(statistics)+1]]<-data.frame(symbol=r$symbol,time_h=r$time_h,effect=mean(x),pvalue=tt$p.value,exact=exact)
}
close(p.adjust(results$pvalue,"holm"),results$holm112);close(p.adjust(results$exact_pvalue,"holm"),results$exact_holm112)
write.csv(do.call(rbind,checks),file.path(dest,"r_measurement_checks.csv"),row.names=FALSE)
write.csv(do.call(rbind,statistics),file.path(dest,"r_statistical_checks.csv"),row.names=FALSE)
write_json(list(status="pass",raw_LFQ_measurements=length(checks),donor_rows=nrow(effects),estimable_statistics=length(statistics),family_size=112L,
    scope="IndependentRoriginalproteinGroupsvalues/QC, technicalmeans,donorpairing,t/CI/exact/Holm; sameHTPCsource"),file.path(dest,"r_audit.json"),auto_unbox=TRUE,pretty=TRUE)
print(results[results$symbol%in%c("TMT1A","PER2","FKBP5","NR3C1"),])
