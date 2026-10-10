# Preserve original approximate contrast output; export exact WLS sensitivity.
args<-commandArgs(TRUE);out<-args[1]
if(file.exists(file.path(out,"voom_exact_results.csv")))stop("Refusingoverwrite")
library(jsonlite)
model<-readRDS(file.path(out,"voom_model.rds"));v<-model$voom;x<-model$design;cm<-model$contrasts;fit<-model$fit
map<-read.csv(file.path(out,"gene_alias_verification.csv"),stringsAsFactors=FALSE)
res<-wls<-list()
for(i in seq_len(nrow(map))){
    id<-as.character(map$entrez_id[i]);idx<-match(id,rownames(v$E));stopifnot(!is.na(idx))
    y<-v$E[idx,];w<-v$weights[idx,];cov<-solve(crossprod(x,x*w));beta<-cov%*%crossprod(x,w*y)
    s2<-fit$s2.post[idx];df<-fit$df.total[idx]
    wls[[i]]<-data.frame(symbol=map$frozen_symbol[i],entrez_id=id,sample=colnames(v$E),logCPM=y,weight=w,s2_post=s2,df_total=df)
    for(k in colnames(cm)){
        c<-cm[,k];effect<-sum(c*beta);se<-sqrt(as.numeric(t(c)%*%cov%*%c)*s2);width<-qt(.975,df)*se
        res[[length(res)+1]]<-data.frame(symbol=map$frozen_symbol[i],entrez_id=id,contrast=k,effect=effect,se=se,ci_low=effect-width,ci_high=effect+width,pvalue=2*pt(-abs(effect/se),df))
    }
}
res<-do.call(rbind,res);res$holm_44<-p.adjust(res$pvalue,"holm")
write.csv(res,file.path(out,"voom_exact_results.csv"),row.names=FALSE)
write.csv(do.call(rbind,wls),file.path(out,"voom_exact_wls_inputs.csv"),row.names=FALSE)
write.csv(data.frame(sample=colnames(v$E),x,check.names=FALSE),file.path(out,"voom_exact_design.csv"),row.names=FALSE)
write.csv(data.frame(coefficient=rownames(cm),cm,check.names=FALSE),file.path(out,"voom_exact_contrasts.csv"),row.names=FALSE)
write_json(list(status="completed",reason="Use exact per-gene covariance for nonorthogonal weighted design; originallimmaapproximate output preserved",tests=44L),
    file.path(out,"voom_exact_amendment.json"),auto_unbox=TRUE,pretty=TRUE)
print(res[res$symbol=="PER2",])
