# GenomicRanges independent reimplementation directly from original narrowPeak/RefSeq.
args <- commandArgs(TRUE); source <- args[1]; out <- args[2]
library(GenomicRanges)
freeze <- jsonlite::read_json(file.path(out,"analysis_freeze.json"),simplifyVector=TRUE)
for(i in seq_len(nrow(freeze$inputs))) {
  r <- freeze$inputs[i,]; stopifnot(file.info(r$path)$size==r$bytes,digest::digest(file=r$path,algo="sha256")==r$sha256)
}
samples <- jsonlite::read_json(file.path(source,"peak_samples.json"),simplifyVector=TRUE)
files <- list.files(source,pattern="^hg19_ncbiRefSeq_chr.*json$",full.names=TRUE)
annotation <- do.call(rbind,lapply(files,function(f) jsonlite::read_json(f,simplifyVector=TRUE)$ncbiRefSeq))
genes <- c("SPARCL1","FKBP5","TSC22D3","KLF15")
windows <- do.call(rbind,lapply(genes,function(g) {
  a <- annotation[annotation$name2==g,]; stopifnot(nrow(a)>0)
  tss <- unique(ifelse(a$strand=="+",a$txStart,a$txEnd-1))
  rbind(do.call(rbind,lapply(c(5000,20000,100000),function(w) data.frame(gene=g,window=paste0("TSS_",w),chrom=a$chrom[1],start=pmax(0,tss-w),end=tss+w+1))),
    data.frame(gene=g,window="gene_body",chrom=a$chrom[1],start=min(a$txStart),end=max(a$txEnd)))
}))
wg <- GRanges(windows$chrom,IRanges(windows$start+1,windows$end))
counts <- read.csv(file.path(out,"peak_counts.csv")); hits <- read.csv(file.path(out,"peak_hits.csv"))
keys_checked <- 0L; hits_checked <- 0L; build_results <- list()
sizes <- lapply(c("hg18","hg19","hg38","mm9"),function(b) {r <- read.table(file.path(source,paste0(b,".chrom.sizes")));setNames(r$V2,r$V1)})
names(sizes) <- c("hg18","hg19","hg38","mm9")
build_oob <- setNames(integer(4),names(sizes)); build_unknown <- setNames(integer(4),names(sizes))
for(i in seq_len(nrow(samples))) {
  s <- samples[i,]; p <- read.delim(gzfile(file.path(source,s$file)),header=FALSE)
  for(b in names(sizes)) {
    lengths <- unname(sizes[[b]][p$V1]); build_unknown[b] <- build_unknown[b]+sum(is.na(lengths));build_oob[b] <- build_oob[b]+sum(p$V3>lengths,na.rm=TRUE)
  }
  ok <- which(p$V9>=log10(20));pg <- GRanges(p$V1[ok],IRanges(p$V2[ok]+1,p$V3[ok]))
  overlap <- findOverlaps(pg,wg,ignore.strand=TRUE)
  for(g in genes) for(w in c("TSS_5000","TSS_20000","TSS_100000","gene_body")) {
    wh <- which(windows$gene==g&windows$window==w)
    index <- sort(unique(ok[queryHits(overlap)[subjectHits(overlap)%in%wh]]))
    r <- counts[counts$gsm==s$gsm&counts$gene==g&counts$window==w,];stopifnot(nrow(r)==1,r$count==length(index))
    h <- hits[hits$gsm==s$gsm&hits$gene==g&hits$window==w,];stopifnot(identical(as.integer(sort(h$peak_index)),as.integer(index)))
    if(length(index)) {
      h <- h[order(h$peak_index),];stopifnot(all(h$chrom==p$V1[index]),all(h$start==p$V2[index]),all(h$end==p$V3[index]),all(h$log10q==p$V9[index]),all(h$signalValue==p$V7[index]))
    }
    keys_checked <- keys_checked+1L;hits_checked <- hits_checked+nrow(h)
  }
}
stopifnot(build_oob['hg19']==0,build_unknown['hg19']==0,all(build_oob[c('hg18','hg38','mm9')]>0))
result <- list(status="pass",count_keys_checked=keys_checked,peak_window_hits_checked=hits_checked,
  independent_RefSeq_TSS_and_GenomicRanges=TRUE,coordinate_system="BED->1-based inclusive GRanges",build_out_of_bounds=as.list(build_oob),
  interpretation="Coordinate verification supports hg19; metadata mm9 conflict retained; no author confirmation; no differential occupancy inference")
jsonlite::write_json(result,file.path(out,"r_audit.json"),pretty=TRUE,auto_unbox=TRUE)
print(result)
