# Export-only repair: limma's s2.post is unnamed; index it by gene position.
# Preserve the frozen fit and original incomplete CSV; no model refitting.
out <- commandArgs(TRUE)[1]
model <- readRDS(file.path(out,"model.rds"))
res <- read.csv(file.path(out,"model_results.csv"),stringsAsFactors=FALSE)
cf <- model$contrast_fit
for (i in which(res$status=="estimable")) {
  g <- res$gene[i]; k <- res$contrast[i]; index <- match(g,rownames(cf$coefficients))
  se <- cf$stdev.unscaled[g,k]*sqrt(cf$s2.post[index]); df <- cf$df.total[index]
  res$se[i] <- se; res$lower[i] <- res$log2_effect[i]-qt(.975,df)*se; res$upper[i] <- res$log2_effect[i]+qt(.975,df)*se
}
write.csv(res,file.path(out,"model_results_complete.csv"),row.names=FALSE,na="")
write.csv(data.frame(coefficient=rownames(model$fit$cov.coefficients),cov2cor(model$fit$cov.coefficients)),file.path(out,"contrast_correlation.csv"),row.names=FALSE)
retained <- intersect(c("SPARCL1","FKBP5","TSC22D3","NR3C1"),rownames(model$fit$coefficients))
write.csv(data.frame(gene=retained,model$fit$stdev.unscaled[retained,,drop=FALSE]),file.path(out,"coefficient_unscaled.csv"),row.names=FALSE)
print(res[res$gene=="FKBP5",])
