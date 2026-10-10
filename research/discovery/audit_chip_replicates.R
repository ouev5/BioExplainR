# Independent replicate and peak summit/distance checks after the full GRanges audit.
source("research/discovery/audit_chip_complete.R")
replicates <- read.csv(file.path(out,"replicate_overlap.csv"),stringsAsFactors=FALSE)
for(i in seq_len(nrow(replicates))) {
  r <- replicates[i,]
  pick <- function(gsm) hits[hits$gsm==gsm&hits$gene==r$gene&hits$window==r$window,]
  a <- pick(r$replicate1); b <- pick(r$replicate2)
  ag <- GRanges(a$chrom,IRanges(a$start+1,a$end)); bg <- GRanges(b$chrom,IRanges(b$start+1,b$end))
  o <- findOverlaps(ag,bg,ignore.strand=TRUE)
  stopifnot(nrow(a)==r$peaks1,nrow(b)==r$peaks2,length(unique(queryHits(o)))==r$peaks1_with_overlap,
    length(unique(subjectHits(o)))==r$peaks2_with_overlap,length(o)==r$overlap_pairs)
}
distances_checked <- 0L
for(i in seq_len(nrow(samples))) {
  s <- samples[i,]; p <- read.delim(gzfile(file.path(source,s$file)),header=FALSE)
  h <- hits[hits$gsm==s$gsm,]
  for(j in seq_len(nrow(h))) {
    row <- h[j,]; peak <- p[row$peak_index,]
    summit <- if(peak$V10>=0) peak$V2+peak$V10 else (peak$V2+peak$V3-1)/2
    stopifnot(row$summit==summit)
    if(row$window=="gene_body") next
    a <- annotation[annotation$name2==row$gene,]
    pos <- unique(ifelse(a$strand=="+",a$txStart,a$txEnd-1))
    width <- as.integer(sub("TSS_","",row$window))
    overlapping <- pos[row$start<pos+width+1 & row$end>pmax(0,pos-width)]
    stopifnot(row$nearest_TSS_distance==min(abs(summit-overlapping)))
    distances_checked <- distances_checked+1L
  }
}
jsonlite::write_json(list(status="pass",replicate_keys=nrow(replicates),summits=nrow(hits),distances_checked=distances_checked),
  file.path(out,"r_replicate_audit.json"),pretty=TRUE,auto_unbox=TRUE)
cat("Replicate overlap / summit / TSS distance checks pass\n")
