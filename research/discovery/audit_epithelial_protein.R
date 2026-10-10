# Independent base-R reconstruction from original tables and original author SRDF.
args <- commandArgs(TRUE)
out <- if (length(args)) args[1] else "research/results/discovery_epithelial_protein_v1"
stopifnot(!file.exists(file.path(out, "r_audit.json")))
library(jsonlite)
read_csv <- function(name) read.csv(file.path(out, name), check.names=FALSE, stringsAsFactors=FALSE, na.strings=c("", "NA"))
genes <- read_csv("frozen_genes.csv")
saved <- read_csv("candidate_results.csv")
full <- read_csv("all_protein_results.csv")
measurement <- read_csv("measurements.csv")
public <- "research/results/discovery_public_proteome_v1"
a <- read.delim(file.path(public, "imported/PXD063431_240221_PB_ProteomeDiscoverer_all_Proteins_A549.txt"), check.names=FALSE, stringsAsFactors=FALSE)
h <- read.delim(file.path(public, "sources/PXD029135_median-normalized_complete.txt"), check.names=FALSE, stringsAsFactors=FALSE)
meta <- read.delim(file.path(public, "imported/PXD029135_SRDF_File.txt"), check.names=FALSE, stringsAsFactors=FALSE)
stopifnot(nrow(a)==5428L, nrow(h)==3072L, nrow(genes)==56L, nrow(meta)==43L)
meta <- meta[meta[[5]]==0, ]
colnames(meta) <- c("sample", "individual", "post", "poly", "imiquimod", "T2")
meta$sample <- gsub(" ", "_", meta$sample, fixed=TRUE)
stopifnot(nrow(meta)==40L, length(unique(meta$individual))==10L)
decoded <- read_csv("HBEC_samples.csv")
stopifnot(identical(meta$sample,decoded$assay), identical(meta$individual,decoded$individual),
          identical(as.integer(meta$post),as.integer(decoded$post_ICS)), identical(as.integer(meta$poly),as.integer(decoded$polyIC)))
for (id in unique(meta$individual)) stopifnot(identical(sort(paste(meta$post[meta$individual==id],meta$poly[meta$individual==id])),c("0 0","0 1","1 0","1 1")))
close_num <- function(x,y,label) {
  x <- as.numeric(x); y <- as.numeric(y)
  stopifnot(length(x)==length(y), identical(is.na(x),is.na(y)))
  good <- !is.na(x)
  if (any(abs(x[good]-y[good]) > 2e-8*pmax(1,abs(x[good]),abs(y[good])))) stop(label)
}
blank <- function(n1=0,n2=0) list(status="insufficient_observations",n_control=n1,n_treated=n2,n_pairs=0,
  effect=NA_real_,se=NA_real_,df=NA_real_,ci_low=NA_real_,ci_high=NA_real_,pvalue=1,exact_pvalue=1,positive_units=0,negative_units=0)
sign_matrices <- lapply(0:10,function(n) if (n) as.matrix(expand.grid(rep(list(c(-1,1)),n))) else matrix(0,1,0))
one_sample <- function(v) {
  x <- v[is.finite(v)]; n <- length(x); r <- blank(n,n); r$n_pairs<-n
  r$positive_units <- sum(x>0); r$negative_units <- sum(x<0)
  if (n<3) return(r)
  if (sd(x)==0) {r$status<-"zero_variance_unestimable";return(r)}
  test <- t.test(x,mu=0)
  r$status<-"estimable"; r$effect<-unname(test$estimate);r$se<-sd(x)/sqrt(n);r$df<-n-1
  r$ci_low<-test$conf.int[1];r$ci_high<-test$conf.int[2];r$pvalue<-test$p.value
  r$exact_pvalue<-mean(abs(sign_matrices[[n+1]]%*%x/n)>=abs(mean(x))-1e-12)
  r
}
two_sample <- function(c,t) {
  c<-c[is.finite(c)];t<-t[is.finite(t)];r<-blank(length(c),length(t))
  if (min(length(c),length(t))<3) return(r)
  if (var(c)+var(t)==0) {r$status<-"zero_variance_unestimable";return(r)}
  test<-t.test(t,c,var.equal=FALSE);v<-c(c,t);n<-length(t)
  permutations<-combn(seq_along(v),n,FUN=function(idx) mean(v[idx])-mean(v[-idx]))
  r$status<-"estimable";r$effect<-mean(t)-mean(c);r$se<-sqrt(var(c)/length(c)+var(t)/length(t));r$df<-unname(test$parameter)
  r$ci_low<-test$conf.int[1];r$ci_high<-test$conf.int[2];r$pvalue<-test$p.value
  r$exact_pvalue<-mean(abs(permutations)>=abs(r$effect)-1e-12);r
}
acol<-unlist(lapply(c("NT","dexa"),function(c) paste0("A549_",c,"_",c(1,3,4,5))))
amat<-as.matrix(a[,acol]); storage.mode(amat)<-"double"
amat[amat<=0]<-NA_real_;alogs<-log2(amat)
aqc<-tolower(trimws(as.character(a$Contaminant)))=="false" & !is.na(a[["Exp q-value Combined"]]) & a[["Exp q-value Combined"]]<=.01 & !is.na(a[["Number of Unique Peptides"]]) & a[["Number of Unique Peptides"]]>=1
reference<-aqc & rowSums(is.finite(alogs))==8
medians<-apply(alogs[reference,,drop=FALSE],2,median);offset<-medians-mean(medians)
anormal<-sweep(alogs,2,offset,"-")
norm<-read_csv("A549_normalization.csv")
close_num(norm$median,medians,"normalization medians");close_num(norm$offset,offset,"normalization offsets")
stopifnot(all(norm$reference_rows==sum(reference)))
hgenes <- vapply(h[["Fasta.headers"]],function(header) {
  parts<-trimws(strsplit(ifelse(is.na(header),"",header),";",fixed=TRUE)[[1]])
  parts<-parts[nzchar(parts)]
  if (!length(parts) || any(!grepl("^NX_\\S+\\s+\\S+\\s+(\\S+)\\s+",parts,perl=TRUE))) return("")
  names<-unique(sub("^NX_\\S+\\s+\\S+\\s+(\\S+)\\s+.*$","\\1",parts,perl=TRUE))
  if (length(names)==1) names else ""
},character(1))
hclean <- !grepl("(^|;)(CON__|CONTAM_|REV__)",h[["Protein.IDs"]],perl=TRUE)
hqc <- hclean & nzchar(hgenes)
hmat<-as.matrix(h[,meta$sample]);storage.mode(hmat)<-"double"
contrasts<-c("ICS_unstimulated","ICS_polyIC","ICS_x_polyIC")
individuals<-sort(unique(meta$individual))
get_effects <- function(v,contrast) {
  ret<-setNames(rep(NA_real_,length(individuals)),individuals)
  for (id in individuals) {
    sub<-meta[meta$individual==id, ];x<-v[match(sub$sample,meta$sample)]
    names(x)<-paste(sub$post,sub$poly,sep="_")
    ret[id]<-if (contrast==contrasts[1]) x["1_0"]-x["0_0"] else if (contrast==contrasts[2]) x["1_1"]-x["0_1"] else x["1_1"]-x["0_1"]-x["1_0"]+x["0_0"]
  }
  ret
}
fields<-setdiff(names(blank()),"status")
rebuilt<-vector("list",nrow(full))
for (i in seq_len(nrow(full))) {
  r<-full[i, ];row<-r$source_row-1L
  if (r$dataset=="A549") {
    stopifnot(aqc[row],r$protein_ids==a$Accession[row],r$gene==trimws(a[["Gene Name"]][row]))
    z<-two_sample(anormal[row,1:4],anormal[row,5:8])
  } else {
    stopifnot(hqc[row],r$protein_ids==h[["Protein.IDs"]][row],r$gene==hgenes[row])
    z<-one_sample(get_effects(hmat[row, ],r$contrast))
  }
  stopifnot(z$status==r$status)
  for (f in fields) close_num(z[[f]],r[[f]],paste("global",i,f))
  rebuilt[[i]]<-z
}
stopifnot(nrow(full)==sum(aqc)+3L*sum(hqc))
for (dataset in c("A549","HBEC")) {
  index<-which(full$dataset==dataset)
  close_num(full$global_BH[index],p.adjust(vapply(rebuilt[index],`[[`,numeric(1),"pvalue"),"BH"),paste(dataset,"all array BH"))
  stopifnot(all(full$global_family_size[index]==length(index)))
}
detection<-read_csv("detection.csv");source_rows<-list()
for (i in seq_len(nrow(detection))) {
  r<-detection[i, ];symbol<-r$symbol
  aliases<-if (symbol=="TMT1A") c("TMT1A","METTL7A") else if (symbol=="BMAL1") c("BMAL1","ARNTL") else symbol
  raw_candidates<-if (r$dataset=="A549") which(trimws(a[["Gene Name"]])%in%aliases) else which(hgenes%in%aliases)
  good<-raw_candidates[if (r$dataset=="A549") aqc[raw_candidates] else hqc[raw_candidates]]
  identity<-if (length(good)==1) "unique_group" else if (length(good)>1) "ambiguous_groups" else if (length(raw_candidates)) "excluded_by_QC" else "not_detected"
  stopifnot(identity==r$identity_status,length(good)==r$qc_matches)
  if (length(good)) stopifnot(paste(good+1L,collapse="|")==r$matched_rows)
  source_rows[[paste(r$dataset,r$feature_id,sep=":")]]<-if (length(good)==1) good else integer()
}
for (i in seq_len(nrow(measurement))) {
  r<-measurement[i, ];row<-source_rows[[paste(r$dataset,r$feature_id,sep=":")]]
  stopifnot(length(row)==1,r$source_row==row+1L)
  j<-match(r$column,if (r$dataset=="A549") acol else meta$sample)
  raw<-if (r$dataset=="A549") as.numeric(a[row,r$column]) else hmat[row,j]
  value<-if (r$dataset=="A549") anormal[row,j] else hmat[row,j]
  close_num(r$raw_value,raw,"raw candidate measurement");close_num(r$analysis_value,value,"analysis candidate measurement")
}
effects<-read_csv("individual_effects.csv")
for (i in seq_len(nrow(effects))) {
  r<-effects[i, ];row<-source_rows[[paste("HBEC",r$feature_id,sep=":")]]
  value<-if (length(row)) get_effects(hmat[row, ],r$contrast)[r$individual] else NA_real_
  close_num(r$effect,value,"individual direct difference")
}
candidate_checks<-list()
for (i in seq_len(nrow(saved))) {
  r<-saved[i, ];row<-source_rows[[paste(r$dataset,r$feature_id,sep=":")]]
  if (length(row)) {
    z<-if (r$dataset=="A549") two_sample(anormal[row,1:4],anormal[row,5:8]) else one_sample(get_effects(hmat[row, ],r$contrast))
    stopifnot(r$status==z$status)
    for (f in fields) close_num(r[[f]],z[[f]],paste("candidate",i,f))
    k<-which(full$dataset==r$dataset & full$source_row==row+1L & full$contrast==r$contrast)
    stopifnot(length(k)==1);close_num(r$global_BH,full$global_BH[k],"candidate global BH")
  } else {stopifnot(is.na(r$effect),r$pvalue==1,r$exact_pvalue==1)}
  candidate_checks[[i]]<-data.frame(dataset=r$dataset,symbol=r$symbol,contrast=r$contrast,status=r$status,pvalue=r$pvalue,passed=TRUE)
}
for (family in unique(saved$family)) {
  index<-which(saved$family==family)
  stopifnot(length(index)==if (family=="HBEC_secondary_112") 112L else 56L)
  close_num(saved$holm[index],p.adjust(saved$pvalue[index],"holm"),"candidate Holm")
  close_num(saved$exact_holm[index],p.adjust(saved$exact_pvalue[index],"holm"),"candidate exact Holm")
}
sensitivity<-read_csv("sensitivity.csv")
for (i in seq_len(nrow(sensitivity))) {
  r<-sensitivity[i, ];row<-source_rows[[paste(r$dataset,r$feature_id,sep=":")]]
  if (!length(row)) next
  z<-if (r$dataset=="A549") two_sample(alogs[row,1:4],alogs[row,5:8]) else {
    v<-get_effects(hmat[row, ],r$contrast);one_sample(v[names(v)!=r$parameter])
  }
  stopifnot(r$status==z$status)
  for (f in fields) close_num(r[[f]],z[[f]],paste("sensitivity",i,f))
}
index<-which(sensitivity$dataset=="A549")
close_num(sensitivity$holm_sensitivity_56[index],p.adjust(sensitivity$pvalue[index],"holm"),"sensitivity Holm56")
stratified<-read_csv("T2_descriptive.csv")
for (i in seq_len(nrow(stratified))) {
  r<-stratified[i, ];row<-source_rows[[paste("HBEC",r$feature_id,sep=":")]]
  if (length(row)) {
    v<-get_effects(hmat[row, ],r$contrast);ids<-unique(meta$individual[meta$T2==r$T2high]);v<-v[names(v)%in%ids];v<-v[is.finite(v)]
  } else v<-numeric()
  stopifnot(length(v)==r$n_individuals)
  close_num(r$effect,if (length(v)) mean(v) else NA_real_,"T2 descriptive mean")
}
summary<-read_csv("summary.csv")
for (i in seq_len(nrow(summary))) {
  r<-summary[i, ];z<-saved[saved$dataset==r$dataset & saved$contrast==r$contrast, ]
  f<-full[full$dataset==r$dataset & full$contrast==r$contrast, ]
  stopifnot(r$frozen_positions==nrow(z),r$estimable==sum(z$status=="estimable"),r$holm_pass==sum(z$holm<.05),
            r$exact_holm_pass==sum(z$exact_holm<.05),r$global_estimable==sum(f$status=="estimable"),r$global_BH_pass==sum(f$global_BH<.05))
}
write.csv(do.call(rbind,candidate_checks),file.path(out,"r_candidate_checks.csv"),row.names=FALSE,na="")
writeLines(capture.output(sessionInfo()),file.path(out,"r_sessionInfo.txt"))
audit<-list(status="pass",implemented_with="independent base R read.delim / t.test / p.adjust / exact enumeration",
  original_table_rows=c(A549=nrow(a),HBEC=nrow(h)),QC_rows=c(A549=sum(aqc),HBEC=sum(hqc)),
  global_tests=nrow(full),candidate_tests=nrow(saved),measurement_cells=nrow(measurement),
  individual_positions=nrow(effects),sensitivity_tests=nrow(sensitivity),T2_descriptive_rows=nrow(stratified),
  families=c(56L,56L,112L),online_model_calls=0L)
write_json(audit,file.path(out,"r_audit.json"),auto_unbox=TRUE,pretty=TRUE)
print(audit)
