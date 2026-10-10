# Preserve the frozen identity auditor, correct only Python title-case bool CSVs.
text<-readLines("research/discovery/audit_epithelial_identity.R",warn=FALSE)
line<-which(trimws(text)=='value<-utils::read.csv(...)')
stopifnot(length(line)==1)
text<-append(text,'  for (field in intersect(c("initial_qc","final_qc"),names(value))) value[[field]]<-tolower(value[[field]])=="true"',after=line)
eval(parse(text=text),envir=new.env(parent=globalenv()))
