# Verify subset and direct-time results from saved raw LFQ donor records.
args<-commandArgs(TRUE);dest<-file.path(args[1],"unselected_protein")
stopifnot(!file.exists(file.path(dest,"r_sensitivity_audit.json")))
library(jsonlite)
read<-function(n)read.csv(file.path(dest,n),stringsAsFactors=FALSE)
close<-function(x,y)stopifnot(isTRUE(all.equal(as.numeric(x),as.numeric(y),tolerance=1e-7)))
effects<-read("donor_effects.csv");scope<-read("donor_scope.csv");checks<-0L
for(filename in c("published_label_sensitivity.csv","direct_time_results.csv")) {
    rr<-read(filename)
    for(i in which(rr$status=="estimable")) {
        r<-rr[i,]
        if(filename=="published_label_sensitivity.csv") {
            labels<-strsplit(scope$published_selected_labels[scope$time_h==r$time_h],"|",fixed=TRUE)[[1]]
            x<-effects$effect[effects$feature_id==r$feature_id&effects$time_h==r$time_h&effects$donor%in%labels&effects$status=="paired"]
        } else {
            a<-effects[effects$feature_id==r$feature_id&effects$time_h==24&effects$status=="paired",]
            b<-effects[effects$feature_id==r$feature_id&effects$time_h==72&effects$status=="paired",]
            common<-sort(intersect(a$donor,b$donor));x<-b$effect[match(common,b$donor)]-a$effect[match(common,a$donor)]
        }
        tt<-t.test(x);signs<-as.matrix(expand.grid(rep(list(c(-1,1)),length(x))))
        exact<-mean(abs(as.numeric(signs%*%x)/length(x))>=abs(mean(x))-1e-12)
        close(c(mean(x),sd(x)/sqrt(length(x)),tt$conf.int,tt$p.value,exact),c(r$effect,r$se,r$ci_low,r$ci_high,r$pvalue,r$exact_pvalue));checks<-checks+1L
    }
    family<-if(filename=="published_label_sensitivity.csv")112 else 56
    close(p.adjust(rr$pvalue,"holm"),rr[[paste0("holm",family)]]);close(p.adjust(rr$exact_pvalue,"holm"),rr[[paste0("exact_holm",family)]])
}
write_json(list(status="pass",estimable_sensitivity_tests=checks,scope="R rederivation of publishedlabelsubset and sharedrawdonordirect time difference; no new independent participants"),file.path(dest,"r_sensitivity_audit.json"),auto_unbox=TRUE,pretty=TRUE)
