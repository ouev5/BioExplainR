args<-commandArgs(TRUE);out<-file.path(args[1],"asm_early")
library(jsonlite)
if(file.exists(file.path(out,"r_early_audit.json")))stop("Refuseoverwrite")
mapping<-read.csv(file.path(args[1],"gr_public/gene_mapping.csv"),stringsAsFactors=FALSE)
m<-read.csv(file.path(out,"early_measurements.csv"),stringsAsFactors=FALSE)
near<-function(a,b)stopifnot(isTRUE(all.equal(as.numeric(a),as.numeric(b),tolerance=1e-7)))
for(group in c("UT","DEX","17","17DEX")){
    raw<-read.delim(gzfile(file.path(out,"sources",paste0("GSE135730_SMC_",group,".txt.gz"))),check.names=FALSE)
    rr<-m[m$group==group,]
    for(i in seq_len(nrow(rr))){r<-rr[i,];v<-raw[match(r$feature_id,raw$geneID),r$sample];near(c(v,log2(v+1)),c(r$RPKM,r$value))}
}
rr<-read.csv(file.path(out,"early_results.csv"),stringsAsFactors=FALSE);p<-rep(1,nrow(rr))
for(i in seq_len(nrow(rr))){
    r<-rr[i,];if(r$status!="estimable")next
    vals<-split(m$value[m$symbol==r$symbol],m$group[m$symbol==r$symbol])
    cf<-switch(r$contrast,DEX_noIL17=c(DEX=1,UT=-1),DEX_withIL17=c(`17DEX`=1,`17`=-1),DEX_x_IL17=c(`17DEX`=1,`17`=-1,DEX=-1,UT=1))
    effect<-sum(sapply(names(cf),function(k)mean(vals[[k]])*cf[k]));vars<-sapply(names(cf),function(k)var(vals[[k]])/length(vals[[k]]))
    se<-sqrt(sum(vars));df<-sum(vars)^2/sum(vars^2/2);width<-qt(.975,df)*se;p[i]<-2*pt(-abs(effect/se),df)
    near(c(effect,se,df,effect-width,effect+width,p[i]),c(r$effect,r$se,r$df,r$ci_low,r$ci_high,r$pvalue))
}
near(p.adjust(p,"holm"),rr$holm_33)
write_json(list(status="pass",original_measurements=nrow(m),tests=nrow(rr),scope="Original RPKM, unpaired marginal and four-cell interaction Satterthwaite t/CI/Holm"),
    file.path(out,"r_early_audit.json"),auto_unbox=TRUE,pretty=TRUE)
cat("EarlyASM rawRPKM/contrast audit pass\n")
