# Independent R confirmation of identification and original/selected scale diagnostics.
args <- commandArgs(TRUE); out <- args[1]; library(jsonlite)
stopifnot(!file.exists(file.path(out,"r_diagnostics_audit.json")))
read <- function(n)read.csv(file.path(out,n),check.names=FALSE,stringsAsFactors=FALSE)
close <- function(a,b)stopifnot(all(abs(as.numeric(a)-as.numeric(b))<=1e-9+1e-7*abs(as.numeric(b))))
raw <- list()
for(time in c(24,72)) {
    m <- read_json(file.path(out,"archives",paste0(time,"h"),"extraction.json"),simplifyVector=TRUE)
    p <- m$outputs$path[grepl("proteinGroups.txt$",m$outputs$member)]
    raw[[as.character(time)]] <- read.delim(p,check.names=FALSE,stringsAsFactors=FALSE,quote="",comment.char="",colClasses="character")
}
measure <- read("candidate_raw_intensity_diagnostics.csv"); identify <- read("candidate_identification.csv")
for(i in seq_len(nrow(identify))) {
    r <- identify[i,]; t <- raw[[as.character(r$time_h)]]; n <- as.integer(sub("^[^:]*:","",r$group_id))-1L
    stopifnot(t$`Protein IDs`[n]==r$protein_ids)
    close(c(t$Peptides[n],t$`Razor + unique peptides`[n],t$`Unique peptides`[n],t$`Sequence coverage [%]`[n],t$Intensity[n],t$Score[n]),
          c(r$peptides,r$razor_unique_peptides,r$unique_peptides,r$sequence_coverage_percent,r$total_intensity,r$score))
}
for(i in seq_len(nrow(measure))) {
    r <- measure[i,]; t <- raw[[as.character(r$time_h)]]; n <- as.integer(sub("^[^:]*:","",r$group_id))-1L
    close(c(t[n,paste0("Intensity ",r$experiment)],t[n,r$source_column],t[n,paste0("Peptides ",r$experiment)],
            t[n,paste0("Razor + unique peptides ",r$experiment)],t[n,paste0("Unique peptides ",r$experiment)]),
          c(r$raw_Intensity,r$raw_LFQ,r$identified_peptides,r$razor_unique_peptides,r$unique_peptides))
}
scale <- read("published_scale_diagnostics.csv"); sample <- read("sample_map.csv")
for(i in seq_len(nrow(scale))) {
    r <- scale[i,]; t <- raw[[as.character(r$time_h)]]; n <- as.integer(sub("^[^:]*:","",r$group_id))-1L
    s <- sample[sample$time_h==r$time_h & sample$donor==r$donor & sample$condition==r$condition & sample$technical_rep==r$technical_rep,]
    stopifnot(nrow(s)==1L)
    v <- as.numeric(t[n,paste0("Intensity ",s$experiment)]); lfq <- as.numeric(t[n,s$source_column]); close(v,r$raw_Intensity);close(lfq,r$raw_LFQ)
    if(v>0) {close(log2(v),r$log2_Intensity);stopifnot((abs(log2(v)-r$published_log2)<=.000051)==(r$Intensity_matches_published=="True"))}
    if(lfq>0)close(log2(lfq)-r$published_log2,r$raw_log2_minus_published)
}
write_json(list(status="pass",identification_rows=nrow(identify),candidate_intensity_measurements=nrow(measure),
    published_scale_comparisons=nrow(scale),scope="IndependentR from original arrays, not new statistical test or author normalization reconstruction"),
    file.path(out,"r_diagnostics_audit.json"),auto_unbox=TRUE,pretty=TRUE)
