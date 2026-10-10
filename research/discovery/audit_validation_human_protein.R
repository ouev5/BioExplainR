# Independently recompute donor aggregation/test/CI/Holm from original-row exports.
args<-commandArgs(TRUE);out<-file.path(args[1],"human_protein")
library(jsonlite)
if(file.exists(file.path(out,"r_human_protein_audit.json")))stop("Refusing overwrite")
measured<-read.csv(file.path(out,"human_selected_measurements.csv"),stringsAsFactors=FALSE)
for(sheet in unique(measured$source_sheet)){
    original<-read.csv(file.path(out,paste0(sheet,".csv")),stringsAsFactors=FALSE,check.names=FALSE)
    rr<-measured[measured$source_sheet==sheet,]
    for(i in seq_len(nrow(rr)))stopifnot(abs(as.numeric(original[rr$source_row[i],rr$source_column[i]])-rr$value[i])<1e-9)
}
near<-function(a,b)stopifnot(isTRUE(all.equal(as.numeric(a),as.numeric(b),tolerance=1e-7)))
derived<-aggregate(value~time_h+symbol+donor+drug,measured,mean)
wide<-reshape(derived,idvar=c("time_h","symbol","donor"),timevar="drug",direction="wide")
wide$effect<-wide$value.dex-wide$value.co
saved<-read.csv(file.path(out,"human_selected_donor_effects.csv"),stringsAsFactors=FALSE)
keys<-function(d)paste(d$time_h,d$symbol,d$donor,sep="|")
near(saved$effect,wide$effect[match(keys(saved),keys(wide))])
results<-read.csv(file.path(out,"human_selected_results.csv"),stringsAsFactors=FALSE)
direct<-read.csv(file.path(out,"human_direct_results.csv"),stringsAsFactors=FALSE)
checks<-0L
for(kind in c("response","direct")){
    rr<-if(kind=="response")results else direct;p<-ep<-rep(1,nrow(rr))
    for(i in seq_len(nrow(rr))){
        r<-rr[i,];if(r$status=="arrays_unavailable")next
        if(kind=="response")x<-wide$effect[wide$symbol==r$symbol & wide$time_h==r$time_h]
        else {
            a<-wide[wide$symbol==r$symbol & wide$time_h==24,];b<-wide[wide$symbol==r$symbol & wide$time_h==72,]
            a<-a[a$donor %in% b$donor,];x<-b$effect[match(a$donor,b$donor)]-a$effect
        }
        t<-t.test(x);signs<-as.matrix(expand.grid(rep(list(c(-1,1)),length(x))))
        exact<-mean(abs(signs%*%x/length(x))>=abs(mean(x))-1e-12)
        near(c(mean(x),sd(x)/sqrt(length(x)),t$conf.int,t$p.value,exact),c(r$effect,r$se,r$ci_low,r$ci_high,r$pvalue,r$exact_pvalue))
        p[i]<-t$p.value;ep[i]<-exact;checks<-checks+1L
    }
    near(p.adjust(p,"holm"),if(kind=="response")rr$holm_22 else rr$holm_11)
    near(p.adjust(ep,"holm"),if(kind=="response")rr$exact_holm_22 else rr$exact_holm_11)
}
write_json(list(status="pass",measurements=nrow(measured),donor_effects=nrow(wide),estimable_tests=checks,
    scope="Original selected-table CSV export measurements, technical means, donor contrasts, t/CI/exactsign/Holm; XLSX export fidelity separately checked in Python; cannot audit absent unselected arrays"),
    file.path(out,"r_human_protein_audit.json"),auto_unbox=TRUE,pretty=TRUE)
cat("Human protein donor-level audit pass\n")
