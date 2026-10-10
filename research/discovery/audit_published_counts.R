# Orthogonal source representation: published SE counts vs raw geneCounts matrix.
out <- commandArgs(TRUE)[1]
library(SummarizedExperiment)
obj <- readRDS(file.path(out,"SE.processed.rds"))
tab <- as.matrix(read.delim(gzfile("research/results/discovery_mechanism_v1/geneCounts.tab.gz"),row.names=1,check.names=FALSE))
map <- read.csv(file.path(out,"sample_map.csv"),stringsAsFactors=FALSE)
text <- readLines("research/results/discovery_mechanism_v1/intervention_metadata.txt")
blocks <- split(text,cumsum(grepl("^\\^SAMPLE",text)))
descriptions <- vapply(blocks,function(b) sub("^!Sample_description = ","",b[grepl("^!Sample_description = ",b)])[1],character(1))
gsm <- vapply(blocks,function(b) sub("^\\^SAMPLE = ","",b[grepl("^\\^SAMPLE = ",b)])[1],character(1))
names(descriptions) <- gsm
order <- match(colnames(obj),descriptions[map$gsm]);stopifnot(!anyNA(order))
shared <- intersect(rownames(obj),rownames(tab))
gene_index <- match(shared,rownames(tab));stopifnot(!anyNA(gene_index))
raw <- tab[gene_index,map$sample[order],drop=FALSE]
published <- SummarizedExperiment::assay(obj,"counts")[match(shared,rownames(obj)),,drop=FALSE]
delta <- max(abs(raw-published));stopifnot(delta<.01)
write.csv(data.frame(unmatched_published_id=setdiff(rownames(obj),rownames(tab))),file.path(out,"published_unmatched_gene_ids.csv"),row.names=FALSE)
jsonlite::write_json(list(status="pass",genes=length(shared),samples=ncol(obj),measurements=length(shared)*ncol(obj),
  unmatched_published_ids=nrow(obj)-length(shared),
  maximum_count_difference=delta,candidate_present_in_published_filtered_object="SPARCL1"%in%rownames(obj),
  scope="Counts compared across independently published SE/raw representations; rounding tolerance .01; authors filtered object not our fixed filter"),
  file.path(out,"published_counts_audit.json"),auto_unbox=TRUE,pretty=TRUE)
cat("Published SE/raw counts match:",length(shared)*ncol(obj),"measurements; max diff",delta,"\n")
