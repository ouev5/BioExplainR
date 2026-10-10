args <- commandArgs(TRUE); out <- args[1]
library(edgeR); library(limma)
map <- read.csv(file.path(out,"sample_map.csv"),stringsAsFactors=FALSE)
counts <- as.matrix(read.delim(gzfile("research/results/discovery_mechanism_v1/geneCounts.tab.gz"),row.names=1,check.names=FALSE))
stopifnot(!anyDuplicated(map$sample),setequal(map$sample,colnames(counts)),all(is.finite(counts)),all(counts>=0))
map <- map[map$included,]; counts <- counts[,map$sample,drop=FALSE]
map$batch <- factor(map$batch); map$group <- factor(map$group)
design <- model.matrix(~0+group+batch,map)
stopifnot(qr(design)$rank==ncol(design))
y <- DGEList(counts=counts)
keep <- filterByExpr(y,design=design,min.count=10,min.total.count=15,large.n=10,min.prop=.7)
genes <- c("SPARCL1","FKBP5","TSC22D3","NR3C1")
write.csv(data.frame(gene=rownames(counts),kept=keep),file.path(out,"expression_filter.csv"),row.names=FALSE)
write.csv(data.frame(gene=genes,counts[genes,,drop=FALSE],check.names=FALSE),file.path(out,"candidate_raw_counts.csv"),row.names=FALSE)
y <- calcNormFactors(y[keep,,keep.lib.sizes=FALSE],method="TMM")
v <- voom(y,design,plot=FALSE)
fit <- eBayes(lmFit(v,design))
C <- makeContrasts(
  DEX= grouppre_DMSO-groupbaseline_DMSO,
  KH103=(grouppre_KH103-groupbaseline_KH103)-(grouppre_DMSO-groupbaseline_DMSO),
  MIF=(grouppre_MIF-groupbaseline_MIF)-(grouppre_DMSO-groupbaseline_DMSO),
  Cort113=(grouppre_Cort113-groupbaseline_Cort113)-(grouppre_DMSO-groupbaseline_DMSO),
  DEX_KH103=grouppre_KH103-groupbaseline_KH103,
  DEX_MIF=grouppre_MIF-groupbaseline_MIF,
  DEX_Cort113=grouppre_Cort113-groupbaseline_Cort113,
  drug_KH103=groupbaseline_KH103-groupbaseline_DMSO,
  drug_MIF=groupbaseline_MIF-groupbaseline_DMSO,
  drug_Cort113=groupbaseline_Cort113-groupbaseline_DMSO,
  post_KH103=grouppost_KH103-grouppost_DMSO,
  post_MIF=grouppost_MIF-grouppost_DMSO,
  post_Cort113=grouppost_Cort113-grouppost_DMSO,levels=design)
cf <- eBayes(contrasts.fit(lmFit(v,design),C))
rows <- list()
for (g in genes) for (k in colnames(C)) {
  if (g %in% rownames(v$E)) {
    se <- cf$stdev.unscaled[g,k]*sqrt(cf$s2.post[g]); df <- cf$df.total[match(g,rownames(v$E))]
    effect <- cf$coefficients[g,k]
    rows[[length(rows)+1]] <- data.frame(gene=g,contrast=k,status="estimable",log2_effect=effect,se=se,df=df,
      lower=effect-qt(.975,df)*se,upper=effect+qt(.975,df)*se,p=cf$p.value[g,k])
  } else rows[[length(rows)+1]] <- data.frame(gene=g,contrast=k,status="filtered_not_estimable",log2_effect=NA,se=NA,df=NA,lower=NA,upper=NA,p=NA)
}
res <- do.call(rbind,rows); res$holm <- NA_real_
i <- which(res$gene=="SPARCL1"&res$contrast%in%c("KH103","MIF","Cort113"))
res$holm[i] <- p.adjust(res$p[i],"holm",n=3)
write.csv(res,file.path(out,"model_results.csv"),row.names=FALSE,na="")
write.csv(data.frame(sample=map$sample,y$samples),file.path(out,"normalization.csv"),row.names=FALSE)
write.csv(data.frame(sample=map$sample,design),file.path(out,"design_matrix.csv"),row.names=FALSE)
write.csv(data.frame(coefficient=rownames(C),C),file.path(out,"contrasts.csv"),row.names=FALSE)
retained <- intersect(genes,rownames(v$E))
long <- do.call(rbind,lapply(retained,function(g) data.frame(gene=g,sample=map$sample,logCPM=v$E[g,],weight=v$weights[match(g,rownames(v$E)),],row.names=NULL)))
write.csv(long,file.path(out,"voom_measurements.csv"),row.names=FALSE)
write.csv(data.frame(gene=retained,variance_post=fit$s2.post[match(retained,rownames(v$E))],df_total=fit$df.total[match(retained,rownames(v$E))]),file.path(out,"moderation.csv"),row.names=FALSE)
saveRDS(list(y=y,v=v,fit=fit,contrasts=C,contrast_fit=cf,map=map),file.path(out,"model.rds"))
jsonlite::write_json(list(status="completed",samples=ncol(counts),features=nrow(counts),retained=sum(keep),candidate_kept=keep[match("SPARCL1",rownames(counts))],rank=qr(design)$rank,residual_df=nrow(design)-ncol(design),scope="A549 cancer epithelial cell line, not ASM/patients",TMM_voom_independently_reestimated=FALSE),file.path(out,"summary.json"),auto_unbox=TRUE,pretty=TRUE)
writeLines(capture.output(sessionInfo()),file.path(out,"sessionInfo.txt"))
print(res[res$gene=="SPARCL1",])
