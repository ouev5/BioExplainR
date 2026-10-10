# Independent R original-table extraction and Welch/CI/Holm audit.
args<-commandArgs(TRUE);out<-file.path(args[1],"protein_public")
if(file.exists(file.path(out,"r_protein_audit.json")))stop("Refusing to overwrite audit")
library(jsonlite)
raw<-read.delim(file.path(out,"original_proteins.txt"),check.names=FALSE,stringsAsFactors=FALSE)
measured<-read.csv(file.path(out,"protein_measurements.csv"),stringsAsFactors=FALSE)
results<-read.csv(file.path(out,"protein_results.csv"),stringsAsFactors=FALSE)
annotation<-read.csv(file.path(out,"protein_candidate_annotation.csv"),stringsAsFactors=FALSE)
stopifnot(nrow(raw)==7274L,nrow(annotation)==11L,sum(annotation$status=="measured_mouse_annotation")==5L)
near<-function(a,b)stopifnot(isTRUE(all.equal(as.numeric(a),as.numeric(b),tolerance=1e-7)))
for(i in seq_len(nrow(measured))){
    r<-measured[i,];idx<-which(raw$Accession==r$accession)
    stopifnot(length(idx)==1L,grepl("OX=10090",raw$Description[idx]),raw$Master[idx]=="IsMasterProtein")
    value<-raw[idx,r$source_column];near(value,r$raw_abundance);near(log2(value),r$log2_abundance)
}
checks<-list()
for(sensitivity in unique(results$sensitivity)){
    rr<-results[results$sensitivity==sensitivity,];p<-rep(1,nrow(rr))
    for(i in seq_len(nrow(rr))){
        r<-rr[i,];m<-measured[measured$symbol==r$symbol & measured$phase_label==r$phase_label & measured$duration_h==r$duration_h,]
        if(sensitivity=="omit_source_star29")m<-m[m$starred_in_source=="False",]
        if(r$status!="estimable"){stopifnot(nrow(m)==0L,r$pvalue==1);next}
        x<-m$log2_abundance[m$drug=="CORT"];y<-m$log2_abundance[m$drug=="DMSO"]
        test<-t.test(x,y,var.equal=FALSE);se<-sqrt(var(x)/length(x)+var(y)/length(y))
        near(c(mean(x)-mean(y),se,test$conf.int,test$parameter,test$p.value),c(r$effect,r$se,r$ci_low,r$ci_high,r$df,r$pvalue))
        p[i]<-test$p.value;checks[[length(checks)+1]]<-data.frame(symbol=r$symbol,phase=r$phase_label,duration=r$duration_h,sensitivity=sensitivity,pvalue=test$p.value)
    }
    near(p.adjust(p,"holm"),rr$holm_44)
}
write.csv(do.call(rbind,checks),file.path(out,"r_protein_numeric_checks.csv"),row.names=FALSE)
write_json(list(status="pass",original_proteins=nrow(raw),original_measurements=nrow(measured),estimable_tests=length(checks),
    all_tests=nrow(results),missing_kept_in_family=TRUE,species="mouse annotated; human PRIDE organism conflict unresolved",
    scope="Original protein array, quality selection, unpaired Welch, pointwiseCI and Holm; no raw spectrum reanalysis"),
    file.path(out,"r_protein_audit.json"),auto_unbox=TRUE,pretty=TRUE)
cat("Independent original-protein numeric audit pass\n")
