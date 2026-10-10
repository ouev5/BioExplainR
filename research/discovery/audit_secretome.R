# Independent R reconstruction from original proteinGroups, decoding and summary.
args <- commandArgs(TRUE); out <- normalizePath(args[1])
library(jsonlite)
stopifnot(!file.exists(file.path(out,"r_numeric_audit.json")))
read <- function(name) read.csv(file.path(out,name),check.names=FALSE,stringsAsFactors=FALSE)
close <- function(a,b) {
    a <- as.numeric(a); b <- as.numeric(b)
    stopifnot(length(a)==length(b),identical(is.na(a),is.na(b)))
    good <- !is.na(a)
    stopifnot(all(abs(a[good]-b[good]) <= 1e-9+1e-7*abs(b[good])))
}
summary_stat <- function(x) {
    if(length(x)<3) return(c(n_pairs=length(x),effect=NA,se=NA,ci_low=NA,ci_high=NA,
                            pvalue=1,exact_pvalue=1,positive_donors=NA,negative_donors=NA))
    se <- sd(x)/sqrt(length(x)); effect <- mean(x)
    p <- if(se==0) if(effect==0) 1 else 0 else 2*pt(-abs(effect/se),length(x)-1)
    width <- qt(.975,length(x)-1)*se
    signs <- as.matrix(expand.grid(rep(list(c(-1,1)),length(x))))
    exact <- mean(abs(as.numeric(signs%*%x)/length(x)) >= abs(effect)-1e-12)
    c(n_pairs=length(x),effect=effect,se=se,ci_low=effect-width,ci_high=effect+width,
      pvalue=p,exact_pvalue=exact,positive_donors=sum(x>0),negative_donors=sum(x<0))
}
donor_effects <- function(v,s,min_tech=2,allowed=NULL) {
    donors <- sort(unique(s$donor)); if(!is.null(allowed)) donors <- intersect(donors,allowed)
    answer <- list()
    for(d in donors) {
        co <- log2(v[s$donor==d & s$condition=="co" & v>0])
        dex <- log2(v[s$donor==d & s$condition=="dex" & v>0])
        good <- length(co)>=min_tech && length(dex)>=min_tech
        answer[[length(answer)+1]] <- data.frame(donor=d,control_technical_observed=length(co),
            DEX_technical_observed=length(dex),control_log2_mean=if(length(co)>=min_tech)mean(co)else NA,
            DEX_log2_mean=if(length(dex)>=min_tech)mean(dex)else NA,
            effect=if(good)mean(dex)-mean(co)else NA,status=if(good)"paired"else"insufficient_LFQ")
    }
    do.call(rbind,answer)
}
samples <- read("sample_map.csv"); genes <- read("frozen_genes.csv")
full <- read("all_results.csv"); qc <- read("group_QC.csv"); measurements <- read("all_measurements.csv")
effects <- read("all_donor_effects.csv"); candidates <- read("candidate_results.csv")
detection <- read("candidate_detection.csv"); sensitivities <- read("candidate_sensitivity.csv")
design <- read_json(file.path(out,"design_freeze.json"),simplifyVector=TRUE)
independent <- list(); rebuilt_effects <- list(); raw <- list(); maps <- list(); stat_checks <- 0L
for(time in c(24,72)) {
    completed <- read_json(file.path(out,"archives",paste0(time,"h"),"extraction.json"),simplifyVector=TRUE)
    stopifnot(completed$status=="pass",completed$whole_archive_SHA1_verified)
    path <- completed$outputs$path[grepl("proteinGroups.txt$",completed$outputs$member)]
    table <- read.delim(path,check.names=FALSE,stringsAsFactors=FALSE,quote="",comment.char="",colClasses="character")
    decoder_path <- completed$outputs$path[grepl("SampleName",completed$outputs$member)]
    lines <- readLines(decoder_path,warn=FALSE)
    lines <- lines[grepl("^([0-9]{2}\\.[0-9]{2}\\.[0-9]{2}|[0-9]+)\\.\\.\\.[[:space:]]*=",lines)]
    labels <- sub("^([0-9]{2}\\.[0-9]{2}\\.[0-9]{2}|[0-9]+)\\.\\.\\..*$","\\1",lines)
    dates <- sub("^[^=]*=[[:space:]]*([0-9]{2}\\.[0-9]{2}\\.[0-9]{2}).*$","\\1",lines)
    columns <- names(table)[grepl("^LFQ intensity ",names(table))]
    experiments <- sub("^LFQ intensity ","",columns)
    rawlabels <- sub("^([0-9]{2}\\.[0-9]{2}\\.[0-9]{2}|[0-9]+)_?(co|c|dex)[123]$","\\1",experiments)
    condition <- sub("^([0-9]{2}\\.[0-9]{2}\\.[0-9]{2}|[0-9]+)_?(co|c|dex)[123]$","\\2",experiments); condition[condition=="c"] <- "co"
    reps <- as.integer(sub("^.*([123])$","\\1",experiments))
    donor <- dates[match(rawlabels,labels)]; stopifnot(!anyNA(donor),!anyDuplicated(paste(donor,condition,reps)))
    s <- data.frame(time_h=time,source_column=columns,experiment=experiments,donor=donor,raw_donor_label=rawlabels,
                    condition=condition,technical_rep=reps,stringsAsFactors=FALSE)
    summary_path <- completed$outputs$path[grepl("summary.txt$",completed$outputs$member)]
    original_summary <- read.delim(summary_path,check.names=FALSE,stringsAsFactors=FALSE,quote="",comment.char="")
    s$raw_file <- original_summary$`Raw file`[match(s$experiment,original_summary$Experiment)]
    s$deposited_raw_file <- ifelse(grepl("\\.",rawlabels),paste0(s$raw_file,".raw"),paste0(donor,"_",condition,reps,".raw"))
    expect <- samples[samples$time_h==time,]; stopifnot(nrow(s)==nrow(expect))
    for(k in names(s)) stopifnot(identical(as.character(s[[k]]),as.character(expect[[k]])))
    maps[[as.character(time)]] <- s; raw[[as.character(time)]] <- table
    keep <- !(table$Reverse=="+" | table$`Potential contaminant`=="+" | table$`Only identified by site`=="+")
    expected_qc <- qc[qc$time_h==time,]
    stopifnot(nrow(expected_qc)==nrow(table),identical(keep,expected_qc$QC_status=="pass"))
    for(i in which(keep)) {
        key <- paste0(time,"h:",i+1L)
        v <- as.numeric(table[i,columns]); stopifnot(all(is.finite(v)),all(v>=0))
        m <- measurements[measurements$group_id==key,]
        stopifnot(nrow(m)==length(v),all(m$protein_ids==table$`Protein IDs`[i]))
        close(v,m$raw_LFQ); close(ifelse(v>0,log2(v),NA),m$log2_LFQ)
        e <- donor_effects(v,s); expected <- effects[effects$group_id==key,]
        stopifnot(identical(e$donor,expected$donor),identical(e$status,expected$status))
        for(k in c("control_technical_observed","DEX_technical_observed","control_log2_mean","DEX_log2_mean","effect"))close(e[[k]],expected[[k]])
        stat <- summary_stat(e$effect[e$status=="paired"])
        r <- full[full$group_id==key,]; stopifnot(nrow(r)==1L)
        close(stat,unlist(r[names(stat)])); stat_checks <- stat_checks+1L
        independent[[length(independent)+1]] <- data.frame(group_id=key,time_h=time,t(stat),check.names=FALSE)
        rebuilt_effects[[key]] <- e
    }
}
independent <- do.call(rbind,independent)
stopifnot(nrow(independent)==nrow(full),identical(independent$group_id,full$group_id))
close(p.adjust(independent$pvalue,"BH"),full$pooled_BH)
close(p.adjust(independent$exact_pvalue,"BH"),full$exact_pooled_BH)
candidate_stats <- list(); sensitivity_stats <- list(); direct_stats <- list(); candidate_e <- list()
for(i in seq_len(nrow(candidates))) {
    r <- candidates[i,]; time <- as.character(r$time_h); table <- raw[[time]]; s <- maps[[time]]
    aliases <- c(r$symbol,if(r$symbol=="TMT1A")"METTL7A",if(r$symbol=="BMAL1")"ARNTL")
    keep <- !(table$Reverse=="+" | table$`Potential contaminant`=="+" | table$`Only identified by site`=="+")
    hits <- which(keep & table$`Gene names`%in%aliases)
    det <- detection[detection$feature_id==r$feature_id & detection$time_h==r$time_h,]
    stopifnot(length(hits)==det$singleton_groups)
    if(length(hits)==1) {
        key <- paste0(time,"h:",hits+1L); stopifnot(r$group_id==key)
        v <- as.numeric(table[hits,s$source_column]); e <- donor_effects(v,s)
        stat <- summary_stat(e$effect[e$status=="paired"])
        candidate_e[[paste(r$feature_id,time)]] <- e
    } else { v <- NULL; stat <- summary_stat(numeric()) }
    close(stat,unlist(r[names(stat)]))
    candidate_stats[[i]] <- data.frame(feature_id=r$feature_id,time_h=r$time_h,t(stat),check.names=FALSE)
    for(kind in c("published_six","strict_three")) {
        allowed <- if(kind=="published_six") design$published_donors[[time]] else NULL
        e <- if(is.null(v))NULL else donor_effects(v,s,if(kind=="strict_three")3 else 2,allowed)
        stat2 <- summary_stat(if(is.null(e))numeric()else e$effect[e$status=="paired"])
        sr <- sensitivities[sensitivities$feature_id==r$feature_id & sensitivities$time_h==r$time_h & sensitivities$analysis==kind,]
        close(stat2,unlist(sr[names(stat2)]))
        sensitivity_stats[[length(sensitivity_stats)+1]] <- data.frame(feature_id=r$feature_id,time_h=r$time_h,analysis=kind,t(stat2),check.names=FALSE)
    }
}
candidate_stats <- do.call(rbind,candidate_stats); sensitivity_stats <- do.call(rbind,sensitivity_stats)
close(p.adjust(candidate_stats$pvalue,"holm"),candidates$holm112)
close(p.adjust(candidate_stats$exact_pvalue,"holm"),candidates$exact_holm112)
for(kind in c("published_six","strict_three")) {
    idx <- sensitivity_stats$analysis==kind; expected <- sensitivities[sensitivities$analysis==kind,]
    close(p.adjust(sensitivity_stats$pvalue[idx],"holm"),expected$holm112)
    close(p.adjust(sensitivity_stats$exact_pvalue[idx],"holm"),expected$exact_holm112)
}
direct <- read("candidate_direct_time.csv"); direct_effects <- read("candidate_direct_donor_effects.csv")
for(i in seq_len(nrow(genes))) {
    id <- genes$feature_id[i]; early <- candidate_e[[paste(id,24)]]; late <- candidate_e[[paste(id,72)]]
    shared <- if(is.null(early)||is.null(late))character()else intersect(early$donor[early$status=="paired"],late$donor[late$status=="paired"])
    x <- if(!length(shared))numeric()else late$effect[match(shared,late$donor)]-early$effect[match(shared,early$donor)]
    exp <- direct_effects[direct_effects$feature_id==id,]; stopifnot(identical(shared,exp$donor)); close(x,exp$effect)
    stat <- summary_stat(x); r <- direct[direct$feature_id==id,]; close(stat,unlist(r[names(stat)]))
    direct_stats[[i]] <- data.frame(feature_id=id,t(stat),check.names=FALSE)
}
direct_stats <- do.call(rbind,direct_stats)
close(p.adjust(direct_stats$pvalue,"holm"),direct$holm56)
close(p.adjust(direct_stats$exact_pvalue,"holm"),direct$exact_holm56)
loo <- read("candidate_leave_one.csv")
for(i in seq_len(nrow(loo))) {
    r <- loo[i,]; e <- candidate_e[[paste(r$feature_id,r$time_h)]]
    x <- e$effect[e$status=="paired" & e$donor!=r$excluded_donor]
    close(mean(x),r$mean_effect); stopifnot(length(x)==r$n_remaining)
}
write.csv(independent,file.path(out,"r_all_statistics.csv"),row.names=FALSE)
write.csv(candidate_stats,file.path(out,"r_candidate_statistics.csv"),row.names=FALSE)
write_json(list(status="pass",utc=format(Sys.time(),tz="UTC",usetz=TRUE),raw_measurements=nrow(measurements),
    donor_rows=nrow(effects),full_family=nrow(full),candidate_family=nrow(candidates),sensitivity_statistics=nrow(sensitivities),
    direct_time_statistics=nrow(direct),leave_one_rows=nrow(loo),independent_sample_mapping=TRUE,
    scope="Independent R original arrays/decoders/summary, all QC/measurements/technical means/donor pairs/t/CI/exact/pooledBH and fixedHolm; same public source"),
    file.path(out,"r_numeric_audit.json"),auto_unbox=TRUE,pretty=TRUE)
print(candidates[candidates$symbol%in%c("ANGPTL2","FSTL3"),])
