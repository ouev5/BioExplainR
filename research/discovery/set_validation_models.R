# New count-model and six donor omissions, plus independent original-TPM audit.
args <- commandArgs(TRUE); out <- normalizePath(args[1], mustWork = TRUE)
stopifnot(!file.exists(file.path(out, "count_run.json")))
suppressPackageStartupMessages({library(edgeR); library(limma); library(jsonlite)})
read <- function(n) read.csv(file.path(out,n), stringsAsFactors=FALSE, check.names=FALSE)
write <- function(x,n) write.csv(x,file.path(out,n),row.names=FALSE,na="")
close <- function(x,y) stopifnot(isTRUE(all.equal(as.numeric(x),as.numeric(y),tolerance=1e-7)))
map <- read("annotation.csv"); samples <- read("samples.csv")
samples$donor <- factor(samples$donor); samples$kd <- as.integer(samples$perturbation); samples$gc <- as.integer(samples$gc)
original <- "research/results/discovery_validation_v2/sources"
tpm <- read.delim(gzfile(file.path(original,"GSE130715_tpm.txt.gz")),row.names=1,check.names=FALSE)
measure <- read("tpm_measurements.csv"); checks <- list()
for(i in seq_len(nrow(measure))) {
    r <- measure[i,]; col <- grep(samples$sample_key[match(r$sample,samples$sample)],colnames(tpm),fixed=TRUE)
    stopifnot(length(col)==1); raw <- tpm[as.character(r$entrez_id),col]
    close(raw,r$raw_TPM); close(log2(raw+1),r$log2_TPM_plus1)
}
res <- read("tpm_results.csv")
for(i in which(res$status=="estimable")) {
    r<-res[i,]; id<-as.character(r$entrez_id)
    x<-sapply(levels(samples$donor),function(d) {
        s<-samples[samples$donor==d,]; vals<-log2(as.numeric(tpm[id,sapply(s$sample_key,function(k)grep(k,colnames(tpm),fixed=TRUE))])+1)
        v<-function(g,k) vals[s$gc==g & s$kd==k]
        switch(r$contrast,GC_control=v(1,0)-v(0,0),GC_perturbed=v(1,1)-v(0,1),
            GC_x_perturbation=v(1,1)-v(0,1)-v(1,0)+v(0,0),perturbation_vehicle=v(0,1)-v(0,0))
    })
    tt<-t.test(x); signs<-as.matrix(expand.grid(rep(list(c(-1,1)),length(x))))
    exact<-mean(abs(as.numeric(signs%*%x)/length(x))>=abs(mean(x))-1e-12)
    close(c(mean(x),sd(x)/sqrt(length(x)),tt$conf.int,tt$p.value,exact),c(r$effect,r$se,r$ci_low,r$ci_high,r$pvalue,r$exact_pvalue))
    checks[[length(checks)+1]]<-data.frame(feature_id=r$feature_id,contrast=r$contrast,effect=mean(x),pvalue=tt$p.value,exact_pvalue=exact)
}
for(f in unique(res$family)) {
    z<-res[res$family==f,];close(p.adjust(z$pvalue,"holm"),z$holm);close(p.adjust(z$exact_pvalue,"holm"),z$exact_holm)
}
write(do.call(rbind,checks),"r_tpm_checks.csv")
write_json(list(status="pass",raw_measurements=nrow(measure),paired_tests=length(checks),
    scope="Independent R extraction from original TPM, donor pairing, t/CI, exact sign-flips and Holm"),file.path(out,"r_tpm_audit.json"),auto_unbox=TRUE,pretty=TRUE)
counts<-read.delim(gzfile(file.path(original,"GSE130715_counts.txt.gz")),row.names=1,check.names=FALSE)
cols<-sapply(samples$sample_key,function(k)grep(k,colnames(counts),fixed=TRUE))
stopifnot(length(unique(cols))==24L,nrow(counts)==28395L)
ct<-as.matrix(counts[,cols]);colnames(ct)<-samples$sample
stopifnot(all(ct>=0),all(ct==round(ct)))
contrasts<-c("GC_control","GC_perturbed","GC_x_perturbation","perturbation_vehicle")
fit_model<-function(ct,s) {
    x<-model.matrix(~donor+kd*gc,s);stopifnot(qr(x)$rank==ncol(x))
    d<-DGEList(ct);keep<-filterByExpr(d,design=x);d<-calcNormFactors(d[keep,,keep.lib.sizes=FALSE])
    v<-voom(d,x,plot=FALSE);fit<-eBayes(lmFit(v,x))
    cm<-matrix(0,nrow=ncol(x),ncol=4,dimnames=list(colnames(x),contrasts))
    cm["gc",1:2]<-1;cm["kd:gc",2:3]<-1;cm["kd",4]<-1
    list(dge=d,voom=v,fit=fit,design=x,contrasts=cm,keep=keep)
}
extract<-function(model,primary_only=FALSE) {
    result<-list();wls<-list();v<-model$voom;x<-model$design;fit<-model$fit
    for(i in seq_len(nrow(map))) {
        id<-as.character(map$entrez_id[i]);idx<-if(map$status[i]=="mapped")match(id,rownames(v$E)) else NA_integer_
        if(!is.na(idx)) {
            y<-v$E[idx,];w<-v$weights[idx,];cov<-solve(crossprod(x,x*w));beta<-cov%*%crossprod(x,w*y)
            s2<-fit$s2.post[idx];df<-fit$df.total[idx]
            wls[[length(wls)+1]]<-data.frame(feature_id=map$feature_id[i],entrez_id=id,sample=colnames(v$E),
                logCPM=y,weight=w,s2_post=s2,df_total=df,raw_count=ct[id,colnames(v$E)])
        }
        for(k in if(primary_only) "GC_control" else contrasts) {
            r<-data.frame(feature_id=map$feature_id[i],symbol=map$symbol[i],entrez_id=id,
                contrast=k,family=if(k=="GC_control")"primary_54" else "secondary_162",
                status=if(is.na(idx))"filtered_or_missing" else "estimable",effect=NA,se=NA,ci_low=NA,ci_high=NA,pvalue=1)
            if(!is.na(idx)) {
                c<-model$contrasts[,k];effect<-sum(c*beta);se<-sqrt(as.numeric(t(c)%*%cov%*%c)*s2);width<-qt(.975,df)*se
                r[,c("effect","se","ci_low","ci_high","pvalue")]<-c(effect,se,effect-width,effect+width,2*pt(-abs(effect/se),df))
            }
            result[[length(result)+1]]<-r
        }
    }
    r<-do.call(rbind,result)
    for(f in unique(r$family))r$holm[r$family==f]<-p.adjust(r$pvalue[r$family==f],"holm")
    list(results=r,wls=do.call(rbind,wls))
}
model<-fit_model(ct,samples);stopifnot(ncol(model$design)==9L)
output<-extract(model)
write(output$results,"count_results.csv");write(output$wls,"count_wls_inputs.csv")
write(data.frame(sample=colnames(ct),model$design,check.names=FALSE),"count_design.csv")
write(data.frame(coefficient=rownames(model$contrasts),model$contrasts,check.names=FALSE),"count_contrasts.csv")
write(data.frame(entrez_id=rownames(ct),keep=model$keep),"count_filter.csv")
saveRDS(model,file.path(out,"count_model.rds"))
loo<-details<-list()
for(d in levels(samples$donor)) {
    use<-samples$donor!=d;s<-droplevels(samples[use,]);m<-fit_model(ct[,use],s)
    r<-extract(m,TRUE)$results;r$excluded_donor<-d
    r$direction_matches<-is.finite(r$effect)&sign(r$effect)==as.integer(map$discovery_direction[match(r$feature_id,map$feature_id)])
    loo[[d]]<-r;details[[d]]<-data.frame(excluded_donor=d,libraries=sum(use),retained_genes=sum(m$keep),rank=ncol(m$design),residual_df=sum(use)-ncol(m$design))
}
write(do.call(rbind,loo),"count_leave_one_donor.csv");write(do.call(rbind,details),"count_leave_one_design.csv")
writeLines(capture.output(sessionInfo()),file.path(out,"sessionInfo.txt"))
write_json(list(status="completed",raw_genes=nrow(ct),retained_genes=sum(model$keep),libraries=ncol(ct),donors=6L,
    rank=ncol(model$design),residual_df=ncol(ct)-ncol(model$design),tests=nrow(output$results),leave_one_runs=6L,
    precise_covariance=TRUE,scope="Fresh TMM/voom/eBayes; same donors as TPM; exploratory full-set expansion"),
    file.path(out,"count_run.json"),auto_unbox=TRUE,pretty=TRUE)
cat("Original TPM audit and fresh all-gene count-model plus six omissions completed\n")
