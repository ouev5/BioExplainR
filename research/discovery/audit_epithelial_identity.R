# All-member protein identity correction, implemented independently in base R.
# Evaluate the byte-preserved original auditor after inserting identity reconstruction.
args<-commandArgs(TRUE)
out<-if (length(args)) args[1] else "research/results/discovery_epithelial_protein_v1/complete"
text<-readLines("research/discovery/audit_epithelial_protein.R",warn=FALSE)
line<-which(text=="hqc <- hclean & nzchar(hgenes)")
stopifnot(length(line)==1)
insertion<-c(
  'exact_map<-list();canonical_map<-list()',
  'for (header in h[["Fasta.headers"]]) {',
  '  for (part in strsplit(ifelse(is.na(header),"",header),";",fixed=TRUE)[[1]]) {',
  '    part<-trimws(part)',
  '    if (!grepl("^NX_\\\\S+\\\\s+\\\\S+\\\\s+(\\\\S+)\\\\s+",part,perl=TRUE)) next',
  '    token<-strsplit(part,"[[:space:]]+",perl=TRUE)[[1]]',
  '    accession<-token[1];gene<-token[3];key<-sub("-[0-9]+$","",accession)',
  '    exact_map[[accession]]<-unique(c(exact_map[[accession]],gene))',
  '    canonical_map[[key]]<-unique(c(canonical_map[[key]],gene))',
  '  }',
  '}',
  'identity_detail<-read_csv("HBEC_all_member_identity.csv")',
  'for (i in seq_len(nrow(h))) {',
  '  names<-character();unresolved<-character()',
  '  for (accession in strsplit(h[["Protein.IDs"]][i],";",fixed=TRUE)[[1]]) {',
  '    match<-exact_map[[accession]]',
  '    if (!length(match)) match<-canonical_map[[sub("-[0-9]+$","",accession)]]',
  '    if (!startsWith(accession,"NX_") || length(match)!=1L) unresolved<-c(unresolved,accession)',
  '    names<-unique(c(names,match))',
  '  }',
  '  complete<-!length(unresolved) && length(names)==1L && identical(unname(names),unname(hgenes[i]))',
  '  hqc[i]<-hqc[i] && complete',
  '  r<-identity_detail[i, ];stopifnot(r$source_row==i+1L,r$final_qc==hqc[i])',
  '  close_num(nchar(paste(unresolved,collapse="|")),nchar(ifelse(is.na(r$unresolved_ids),"",r$unresolved_ids)),"unresolved IDs")',
  '  stopifnot(paste(sort(names),collapse="|")==ifelse(is.na(r$all_member_genes),"",r$all_member_genes))',
  '}'
)
# The literal insertion contains regex escapes for an R source string. Replace with
# a simpler token parser to avoid quoting differences; parse tokens directly.
insertion[grep("if \\(!grepl",insertion)] <- '    if (!startsWith(part,"NX_") || length(strsplit(part,"[[:space:]]+",perl=TRUE)[[1]])<4L) next'
text<-append(text,insertion,after=line)
execution<-new.env(parent=globalenv())
execution$read.csv<-function(...) {
  value<-utils::read.csv(...)
  if ("gene" %in% names(value)) value$gene[is.na(value$gene)]<-""
  value
}
eval(parse(text=text),envir=execution)
