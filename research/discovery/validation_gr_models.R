# New GR rescue-variant analysis; exact gene-weighted contrast covariance.
args<-commandArgs(TRUE);root<-args[1];out<-file.path(root,"gr_public")
if(file.exists(file.path(out,"gr_results.csv")))stop("Refusing to overwrite")
library(edgeR);library(limma);library(jsonlite)
ann<-read.csv("research/results/discovery_stable_response_v1/candidate_annotation.csv",stringsAsFactors=FALSE)
mapping<-data.frame(symbol=c("PER2","PER3","METTL7A","MAOA","ANGPTL2","FSTL3","PER1","FKBP5","TSC22D3","DUSP1","NR3C1"),
    feature_id=c("ENSG00000132326","ENSG00000049246","ENSG00000185432","ENSG00000189221","ENSG00000136859","ENSG00000070404",
                 "ENSG00000179094","ENSG00000096060","ENSG00000157514","ENSG00000120129","ENSG00000113580"))
map<-read.csv(file.path(out,"sample_map.csv"),stringsAsFactors=FALSE)
all_results<-all_measure<-all_wls<-list();run<-list()
for(study in unique(map$study)){
    s<-map[map$study==study,];columns<-lapply(s$filename,function(f){
        a<-read.delim(gzfile(file.path(out,"sources",f)),header=FALSE,stringsAsFactors=FALSE)
        stopifnot(nrow(a)==60680L,!anyDuplicated(a$V1));a
    })
    stopifnot(all(vapply(columns,function(a)identical(a$V1,columns[[1]]$V1),TRUE)))
    counts<-do.call(cbind,lapply(columns,`[[`,"V2"));rownames(counts)<-columns[[1]]$V1;colnames(counts)<-s$sample
    stopifnot(all(counts>=0),all(counts==round(counts)))
    # Drop HTSeq summary counters, not biological genes.
    counts<-counts[grepl("^ENSG[0-9]+$",rownames(counts)),,drop=FALSE]
    s$group<-factor(paste(s$genotype,s$drug,sep="_"),levels=c("alpha_DMSO","alpha_CORT","AF2_DMSO","AF2_CORT","IDR398_DMSO","IDR398_CORT"))
    design<-model.matrix(~0+group,s);colnames(design)<-levels(s$group)
    dge<-DGEList(counts);keep<-filterByExpr(dge,design=design)
    dge<-calcNormFactors(dge[keep,,keep.lib.sizes=FALSE]);v<-voom(dge,design,plot=FALSE)
    fit<-eBayes(lmFit(v,design))
    cm<-makeContrasts(CORT_alpha=alpha_CORT-alpha_DMSO,CORT_AF2=AF2_CORT-AF2_DMSO,
        CORT_IDR398=IDR398_CORT-IDR398_DMSO,CORT_x_AF2=(AF2_CORT-AF2_DMSO)-(alpha_CORT-alpha_DMSO),
        CORT_x_IDR398=(IDR398_CORT-IDR398_DMSO)-(alpha_CORT-alpha_DMSO),levels=design)
    output<-list()
    for(i in seq_len(nrow(mapping))){
        id<-mapping$feature_id[i];symbol<-mapping$symbol[i];idx<-match(id,rownames(fit))
        if(!is.na(idx)){
            weights<-v$weights[idx,];y<-v$E[idx,];covariance<-solve(crossprod(design,design*weights))
            coefficient<-fit$coefficients[idx,];s2<-fit$s2.post[idx];df<-fit$df.total[idx]
            all_wls[[length(all_wls)+1]]<-data.frame(study=study,symbol=symbol,feature_id=id,sample=s$sample,logCPM=y,weight=weights,
                s2_post=s2,df_total=df)
        }
        for(k in colnames(cm)){
            if(!is.na(idx)){
                c<-cm[,k];effect<-sum(c*coefficient);se<-sqrt(as.numeric(t(c)%*%covariance%*%c)*s2)
                width<-qt(.975,df)*se;p<-2*pt(-abs(effect/se),df)
                r<-data.frame(study=study,symbol=symbol,feature_id=id,contrast=k,status="estimable",effect=effect,se=se,
                    ci_low=effect-width,ci_high=effect+width,pvalue=p)
            }else r<-data.frame(study=study,symbol=symbol,feature_id=id,contrast=k,status="filtered",effect=NA,se=NA,ci_low=NA,ci_high=NA,pvalue=1)
            output[[length(output)+1]]<-r
        }
        if(id %in% rownames(counts))all_measure[[length(all_measure)+1]]<-data.frame(study=study,symbol=symbol,feature_id=id,
            sample=s$sample,genotype=s$genotype,drug=s$drug,replicate=s$replicate,count=counts[id,])
    }
    output<-do.call(rbind,output);output$holm_55<-p.adjust(output$pvalue,"holm");all_results[[study]]<-output
    write.csv(data.frame(sample=s$sample,design,check.names=FALSE),file.path(out,paste0(study,"_design.csv")),row.names=FALSE)
    write.csv(data.frame(coefficient=rownames(cm),cm,check.names=FALSE),file.path(out,paste0(study,"_contrasts.csv")),row.names=FALSE)
    write.csv(data.frame(feature_id=rownames(counts),keep=keep),file.path(out,paste0(study,"_filter.csv")),row.names=FALSE)
    saveRDS(list(counts=counts,dge=dge,voom=v,fit=fit,design=design,contrasts=cm),file.path(out,paste0(study,"_model.rds")))
    run[[study]]<-list(raw_genes=nrow(counts),retained_genes=sum(keep),libraries=ncol(counts),rank=qr(design)$rank,residual_df=ncol(counts)-ncol(design))
}
write.csv(do.call(rbind,all_results),file.path(out,"gr_results.csv"),row.names=FALSE,na="")
write.csv(do.call(rbind,all_measure),file.path(out,"gr_candidate_counts.csv"),row.names=FALSE)
write.csv(do.call(rbind,all_wls),file.path(out,"gr_wls_inputs.csv"),row.names=FALSE)
write.csv(mapping,file.path(out,"gene_mapping.csv"),row.names=FALSE)
write_json(list(status="completed",studies=run,tests=110L,family=55L,unit="U2OS culture, not donors",
    scope="GR wildtype versus rescue mutants; no empty-KO arm; preprint data; paired assays share samples"),
    file.path(out,"gr_run.json"),auto_unbox=TRUE,pretty=TRUE)
writeLines(capture.output(sessionInfo()),file.path(out,"sessionInfo.txt"))
print(do.call(rbind,all_results)[do.call(rbind,all_results)$symbol %in% c("PER2","PER1"),])
