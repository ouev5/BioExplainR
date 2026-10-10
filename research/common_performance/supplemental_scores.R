# Secondary breakdown and task-all-correct CI from the same frozen bootstrap indices.
out <- commandArgs(TRUE)[1]
s <- read.csv(file.path(out,"scores.csv"))
tasks <- jsonlite::read_json(file.path(out,"tasks.json"),simplifyVector=TRUE)
s$n <- tasks$n[s$task_index+1L]
breakdown <- do.call(rbind,lapply(unique(s$method),function(m) do.call(rbind,lapply(c(50,200),function(n) {
  r <- s[s$method==m&s$n==n,]
  data.frame(method=m,n=n,targets=nrow(r),correct=sum(r$correct),covered=sum(r$covered),accuracy=mean(r$correct),
    answered_accuracy=if(sum(r$covered))sum(r$correct)/sum(r$covered)else NA)
}))))
write.csv(breakdown,file.path(out,"size_breakdown.csv"),row.names=FALSE,na="")
per_run <- aggregate(correct~task_index+method+repeat_id,s,all)
per_task <- aggregate(correct~task_index+method,per_run,mean)
indices <- jsonlite::fromJSON(file.path(out,"bootstrap_indices.json"))+1L
metrics <- do.call(rbind,lapply(c("ellmer_facts","bio_client_facts"),function(m) {
  values <- function(method) {r<-per_task[per_task$method==method,];r$correct[order(r$task_index)]}
  d <- values(m)-values("ellmer_table")
  boot <- apply(indices,1,function(i)mean(d[i]))
  data.frame(comparison=paste(m,"minus ellmer_table"),endpoint="task_all_five_correct",estimate=mean(d),lower=unname(quantile(boot,.025)),upper=unname(quantile(boot,.975)),tasks=24)
}))
write.csv(metrics,file.path(out,"task_bootstrap.csv"),row.names=FALSE)
print(breakdown);print(metrics)
