# Independent raw-input rederivation plus new all-gene TMM/voom sensitivity.
args <- commandArgs(TRUE); out <- args[1]
if (file.exists(file.path(out, "r_expression_audit.json"))) stop("Refusing to overwrite audit")
library(jsonlite); library(limma); library(edgeR)
map <- read.csv(file.path(out, "expression_sample_map.csv"), stringsAsFactors = FALSE)
ann <- read.csv(file.path(out, "expression_annotation.csv"), stringsAsFactors = FALSE)
mapping <- read.csv(file.path(out, "gene_alias_verification.csv"), stringsAsFactors = FALSE)
published <- read.csv(gzfile(file.path(out, "sources/GSE130715_tpm.txt.gz")), sep = "\t", check.names = FALSE, row.names = 1)
stopifnot(nrow(published) == 28395L, ncol(published) == 24L)
measured <- read.csv(file.path(out, "expression_gene_measurements.csv"), stringsAsFactors = FALSE)
probe <- read.csv(file.path(out, "expression_probe_measurements.csv"), stringsAsFactors = FALSE)
checks <- list()
close_num <- function(a,b) stopifnot(isTRUE(all.equal(as.numeric(a), as.numeric(b), tolerance = 1e-8)))
for (i in seq_len(nrow(measured))) {
    r <- measured[i, ]; s <- map[map$sample == r$sample, ]
    if (r$study == "GSE130715") {
        col <- grep(s$sample_key, colnames(published), fixed = TRUE)
        id <- mapping$entrez_id[mapping$frozen_symbol == r$symbol]
        value <- log2(as.numeric(published[as.character(id), col]) + 1)
    } else {
        # Independent SOFT parser, not the exported Python measurements.
        if (!exists("soft")) soft <- readLines(gzfile(file.path(out, "sources/GSE13168_family.soft.gz")), warn = FALSE)
        begin <- which(soft == paste("^SAMPLE =", r$sample))
        stopifnot(length(begin) == 1)
        start <- begin + which(soft[(begin + 1):length(soft)] == "!sample_table_begin")[1]
        end <- start + which(soft[(start + 1):length(soft)] == "!sample_table_end")[1]
        data <- read.delim(textConnection(paste(soft[(start + 1):(end - 1)], collapse = "\n")), check.names = FALSE)
        ids <- strsplit(ann$feature_id[ann$study == r$study & ann$symbol == r$symbol], "|", fixed = TRUE)[[1]]
        value <- median(data$VALUE[match(ids, data$ID_REF)])
        close_num(data$VALUE[match(ids, data$ID_REF)], probe$value[probe$sample == r$sample & probe$symbol == r$symbol])
    }
    close_num(value, r$value)
    checks[[length(checks) + 1]] <- data.frame(study=r$study,symbol=r$symbol,sample=r$sample,value=value)
}
results <- read.csv(file.path(out, "expression_results.csv"), stringsAsFactors = FALSE)
donor_effects <- read.csv(file.path(out, "expression_donor_effects.csv"), stringsAsFactors = FALSE)
numeric_checks <- list()
for (study in unique(results$study)) {
    rr <- results[results$study == study, ]; p <- ep <- numeric(nrow(rr))
    for (i in seq_len(nrow(rr))) {
        r <- rr[i, ]; m <- measured[measured$study == study & measured$symbol == r$symbol, ]
        differences <- sapply(sort(unique(m$donor)), function(d) {
            z <- m[m$donor == d, ]; v <- function(g,k) z$value[z$gc == g & z$perturbation == k]
            switch(r$contrast, GC_control = v(1,0)-v(0,0), GC_perturbed = v(1,1)-v(0,1),
                   GC_x_perturbation = (v(1,1)-v(0,1))-(v(1,0)-v(0,0)), perturbation_vehicle = v(0,1)-v(0,0))
        })
        close_num(differences, donor_effects$effect[donor_effects$study == study & donor_effects$symbol == r$symbol & donor_effects$contrast == r$contrast])
        test <- t.test(differences)
        signs <- as.matrix(expand.grid(rep(list(c(-1,1)), length(differences))))
        exact <- mean(abs(as.numeric(signs %*% differences)/length(differences)) >= abs(mean(differences))-1e-12)
        close_num(c(mean(differences), sd(differences)/sqrt(length(differences)), test$conf.int, test$p.value, exact),
                  c(r$effect,r$se,r$ci_low,r$ci_high,r$pvalue,r$exact_pvalue))
        p[i] <- test$p.value; ep[i] <- exact
        numeric_checks[[length(numeric_checks)+1]] <- data.frame(study=study,symbol=r$symbol,contrast=r$contrast,effect=mean(differences),pvalue=p[i],exact_pvalue=exact)
    }
    close_num(p.adjust(p,"holm"), rr$holm_44); close_num(p.adjust(ep,"holm"), rr$exact_holm_44)
}
write.csv(do.call(rbind, checks),file.path(out,"r_raw_measurement_checks.csv"),row.names=FALSE)
write.csv(do.call(rbind,numeric_checks),file.path(out,"r_statistical_checks.csv"),row.names=FALSE)
write_json(list(status="pass",raw_gene_measurements=length(checks),paired_contrasts=length(numeric_checks),
    original_TPM_genes=28395L,original_SOFT_arrays=54L,family_size=44L,
    scope="Independent original TPM/SOFT extraction and median, pairing, t/CI, exact sign flips and Holm"),
    file.path(out,"r_expression_audit.json"),auto_unbox=TRUE,pretty=TRUE)

# A separate fixed count-model sensitivity (declared before fitting).
freeze <- list(utc=format(Sys.time(),tz="UTC",usetz=TRUE),formula="~ donor + kd * gc",
    filter="edgeR filterByExpr with full donor+kd*gc design",normalization="TMM",model="voom + limma eBayes",
    tests="11 frozen genes x four contrasts, Holm=44; filtered genes P=1",timing="After paired TPM results, before count fitting; exploratory sensitivity")
write_json(freeze,file.path(out,"voom_sensitivity_freeze.json"),auto_unbox=TRUE,pretty=TRUE)
counts <- read.delim(gzfile(file.path(out,"sources/GSE130715_counts.txt.gz")),row.names=1,check.names=FALSE)
stopifnot(all(as.matrix(counts)>=0),all(as.matrix(counts)==round(as.matrix(counts))))
s <- map[map$study=="GSE130715", ]; cols <- sapply(s$sample_key,function(k) grep(k,colnames(counts),fixed=TRUE))
stopifnot(length(unique(cols))==24L)
counts <- as.matrix(counts[,cols]); colnames(counts)<-s$sample
s$donor<-factor(s$donor);s$kd<-s$perturbation;s$gc<-as.integer(s$gc)
design<-model.matrix(~donor+kd*gc,s);stopifnot(qr(design)$rank==9L)
dge<-DGEList(counts);keep<-filterByExpr(dge,design=design)
dge<-calcNormFactors(dge[keep,,keep.lib.sizes=FALSE]);v<-voom(dge,design,plot=FALSE)
cm<-matrix(0,nrow=ncol(design),ncol=4,dimnames=list(colnames(design),c("GC_control","GC_perturbed","GC_x_perturbation","perturbation_vehicle")))
cm["gc",1:2]<-1;cm["kd:gc",2:3]<-1;cm["kd",4]<-1
fit<-eBayes(contrasts.fit(lmFit(v,design),cm));output<-list()
for(i in seq_len(nrow(mapping)))for(k in colnames(cm)){
    id<-as.character(mapping$entrez_id[i]); symbol<-mapping$frozen_symbol[i]
    if(id %in% rownames(fit)){
        se<-fit$stdev.unscaled[id,k]*sqrt(fit$s2.post[match(id,rownames(fit))]);df<-fit$df.total[match(id,rownames(fit))]
        effect<-fit$coefficients[id,k];width<-qt(.975,df)*se
        r<-data.frame(symbol=symbol,entrez_id=id,contrast=k,status="estimable",effect=effect,se=se,ci_low=effect-width,ci_high=effect+width,pvalue=fit$p.value[id,k])
    } else r<-data.frame(symbol=symbol,entrez_id=id,contrast=k,status="filtered",effect=NA,se=NA,ci_low=NA,ci_high=NA,pvalue=1)
    output[[length(output)+1]]<-r
}
output<-do.call(rbind,output);output$holm_44<-p.adjust(output$pvalue,"holm")
write.csv(output,file.path(out,"voom_sensitivity_results.csv"),row.names=FALSE,na="")
write.csv(data.frame(entrez_id=rownames(counts),keep=keep),file.path(out,"voom_filter.csv"),row.names=FALSE)
saveRDS(list(dge=dge,voom=v,fit=fit,design=design,contrasts=cm),file.path(out,"voom_model.rds"))
write_json(list(status="completed",raw_genes=nrow(counts),retained_genes=sum(keep),libraries=ncol(counts),donors=6L,rank=9L,
    residual_df=15L,scope="One count-model sensitivity on same six donors; not new independent biological replication"),
    file.path(out,"voom_run.json"),auto_unbox=TRUE,pretty=TRUE)
writeLines(capture.output(sessionInfo()),file.path(out,"r_validation_sessionInfo.txt"))
cat("Raw-input independent audit passed; TMM/voom sensitivity completed\n")
