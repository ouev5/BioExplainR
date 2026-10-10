# Actual package application to corrected results; preserve first reports.
args<-commandArgs(TRUE)
out<-if (length(args)) args[1] else "research/results/discovery_epithelial_protein_v1/complete"
sys.source("research/discovery/report_epithelial_protein.R",envir=globalenv())
scope<-paste0('<section id="complete-study-scope"><h2>完整研究范围 / Complete study scope</h2><p>',
  'A549 (PXD063431): cancer-derived epithelial cell line, four culture wells per group, not donors; suffix pairing and independent experiment batches not established. ',
  'Welch DEX48h versus untreated effect on median-centered log2 protein intensity; raw-log2 sensitivity and exact permutation limits are reported. ',
  'HBEC (PXD029135): clinical ICS before/after association, not controlled GC/vehicle and not ASM; source normalized export units, not independently verified log2 fold changes. ',
  'The BioExplainR log2FoldChange input column is an adapter field name: HBEC effects are only supplied-scale differences and must not be interpreted as confirmed fold changes. ',
  'All protein-group members must have a unique concordant gene identity, not just majority FASTA members. ',
  'No missing-value imputation; fixed56/56/112 Holm families, missing and ambiguous positions retained; pointwise CI and exact inference included. ',
  'No infection or viral replication outcome. No ASM protein, secretome, GR genetic, circadian or functional validation. ',
  'No online model calls. 科学结果与精确检验及归一敏感性请读取同目录 FINDINGS.md 和完整结果表。</p></section>')
for (language in c("zh","en")) {
  path<-file.path(out,paste0("BioExplainR-epithelial-",language,".html"))
  content<-paste(readLines(path,warn=FALSE,encoding="UTF-8"),collapse="\n")
  stopifnot(grepl("</body>",content,fixed=TRUE))
  content<-sub("</body>",paste0(scope,"</body>"),content,fixed=TRUE)
  writeLines(content,path,useBytes=TRUE)
}
