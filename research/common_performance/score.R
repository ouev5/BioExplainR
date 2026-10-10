# Primary scorer recomputes reference independently of BioExplainR.
out <- commandArgs(TRUE)[1]
readj <- function(p) jsonlite::read_json(file.path(out,p),simplifyVector=FALSE)
fields <- c("n_features","n_significant","n_up","n_down","n_na_padj")
tasks <- readj("tasks.json"); schedule <- readj("schedule.json")
rows <- lapply(schedule,function(s) {
  t <- tasks[[s$task_index+1]]; z <- readj(sprintf("runs/%03d.json",s$order))
  x <- read.csv(file.path(out,"inputs",t$input))
  keep <- !is.na(x$padj)&x$padj<t$alpha&!is.na(x$log2FoldChange)&abs(x$log2FoldChange)>t$lfc
  gold <- c(nrow(x),sum(keep),sum(keep&x$log2FoldChange>0),sum(keep&x$log2FoldChange<0),sum(is.na(x$padj)))
  answer <- vapply(fields,function(k) if(is.null(z$parsed[[k]])) NA_real_ else z$parsed[[k]],numeric(1))
  data.frame(order=s$order,task_index=s$task_index,task_id=t$id,method=s$method,repeat_id=s[["repeat"]],
    fact=fields,expected=gold,answer=answer,covered=!is.na(answer),correct=!is.na(answer)&answer==gold,
    elapsed_sec=z$elapsed_sec)
})
scores <- do.call(rbind,rows)
write.csv(scores,file.path(out,"scores.csv"),row.names=FALSE,na="")
summary <- do.call(rbind,lapply(unique(scores$method),function(m) {
  s <- scores[scores$method==m,]; r <- s[!duplicated(s$order),]
  per_run <- aggregate(correct~order,s,all)
  data.frame(method=m,targets=nrow(s),correct=sum(s$correct),covered=sum(s$covered),
    accuracy=mean(s$correct),coverage=mean(s$covered),answered_accuracy=if(sum(s$covered)) sum(s$correct)/sum(s$covered) else NA,
    runs=nrow(r),all_correct=sum(per_run$correct),task_accuracy=mean(per_run$correct),
    median_sec=median(r$elapsed_sec),p95_sec=unname(quantile(r$elapsed_sec,.95)))
}))
write.csv(summary,file.path(out,"summary.csv"),row.names=FALSE,na="")
indices <- do.call(rbind,readj("bootstrap_indices.json"))+1L
diffs <- do.call(rbind,lapply(c("ellmer_facts","bio_client_facts"),function(m) {
  metric <- function(method) vapply(0:23,function(i) mean(scores$correct[scores$method==method&scores$task_index==i]),numeric(1))
  delta <- metric(m)-metric("ellmer_table")
  boot <- apply(indices,1,function(i) mean(delta[i]))
  data.frame(comparison=paste(m,"minus ellmer_table"),estimate=mean(delta),lower=unname(quantile(boot,.025)),upper=unname(quantile(boot,.975)),independent_units=24)
}))
write.csv(diffs,file.path(out,"paired_bootstrap.csv"),row.names=FALSE)
print(summary); print(diffs)
