# Actual BioExplainR offline contexts with explicit dataset and endpoint scope.
args<-commandArgs(TRUE);out<-args[1]
if(file.exists(file.path(out,"bioexplainr_validation_project.rds")))stop("Refusingoverwrite")
pkgload::load_all(".",quiet=TRUE)
library(jsonlite)
items<-checks<-list()
add<-function(name,r,padj,family,tissue,unit,independent,scale,limitations){
    table<-data.frame(gene=paste(r$symbol,if("contrast"%in%names(r))r$contrast else seq_len(nrow(r)),sep=":"),
        log2FoldChange=r$effect,pvalue=r$pvalue,FWER=r[[padj]])
    ctx<-bio_context(table,analysis_type="differential_expression",source_package="public-validation explicit log-scale contrasts",
        species=if(grepl("mouse",tissue))"Mus musculus" else "Homo sapiens",tissue=tissue,contrast=name,
        design=list(unit_type=unit,independent_units=independent),scope=list(dataset_id=name,comparison_id=name,sample_level=unit),
        p_adjust_method=NULL,thresholds=list(padj=.05,lfc=0),language="zh")
    expected<-sum(is.finite(r$effect)&r[[padj]]<.05&abs(r$effect)>0)
    stopifnot(ctx$facts$n_significant==expected,ctx$facts$n_features==nrow(r))
    ctx$facts$tests_in_family<-family;ctx$facts$endpoint_scale<-scale
    ctx$facts$independent_units<-independent
    ctx$uncertainty<-c(ctx$uncertainty,limitations)
    ctx$facts$scope_limitations<-paste(ctx$uncertainty,collapse=" | ")
    items[[name]]<<-ctx;checks[[name]]<<-data.frame(context=name,input_rows=nrow(r),expected=expected,observed=ctx$facts$n_significant)
}
all<-read.csv(file.path(out,"expression_results.csv"),stringsAsFactors=FALSE)
add("GSE130715_GNAS",all[all$study=="GSE130715",],"holm_44",44L,"adult airway smooth muscle","paired donor",6L,"log2(TPM+1)",
    "Sixadult donor IDs verified against articleTable1, ages19-54. GNASisnotNR3C1; one24h endpoint. Noexactoldlabeloverlap, aliasesnotfullyexcluded. ExactsignHolmnotconfirmed. Do not combine donor totals.")
add("GSE13168_PKI",all[all$study=="GSE13168",],"holm_44",44L,"airway smooth muscle, ageunknown","paired donor",3L,"publishedGCRMAlog2",
    "Threecomplete donors, age/aliasunknown. PKAinhibitortransgeneisnotGRknockdown;8hFPendpoint,notwithin-donortimeseries. Allfamilytestsnotconfirmed.")
r<-read.csv(file.path(out,"voom_exact_results.csv"),stringsAsFactors=FALSE)
add("GSE130715_voom_sensitivity",r,"holm_44",44L,"adult airway smooth muscle","paired donor",6L,"exactWLSweightedlogCPM",
    "Same24libraries/sixdonors asTPM, notanotherbiologicalvalidation;TMM/voomfilterfixed;exactcovariance;noGNASinteractionconfirmed.")
r<-read.csv(file.path(out,"asm_early/early_results.csv"),stringsAsFactors=FALSE)
add("GSE135730_earlyASM",r,"holm_33",33L,"airway smooth muscle, ageunknown","culture replicate",NA_integer_,"log2(RPKM+1)",
    "Anonymousculturelabelsnotconfirmedindependentdonors;3percondition;4hDEX;human/mm9sourceconflictretained,noinferredpairing. PER2earlyinductionnotconfirmed.")
gr<-read.csv(file.path(out,"gr_public/gr_results.csv"),stringsAsFactors=FALSE)
for(study in unique(gr$study))add(study,gr[gr$study==study,],"holm_55",55L,"U2OSosteosarcomacellline","culture replicate",1L,"exactWLSweightedlogCPM",
    "PreprintpublicGRKOrescuevariantsalpha/AF2/IDR;noemptyKOarm. mRNA/TTparallelassayssharesamples. PER2notconfirmed,PER1controlcannotreplacecandidate. NotadultASMcausalvalidation.")
r<-read.csv(file.path(out,"protein_public/protein_results.csv"),stringsAsFactors=FALSE)
r<-r[r$sensitivity=="primary_all32",];r$contrast<-paste(r$phase_label,r$duration_h,sep="_")
add("PXD081613_mouse_annotation",r,"holm_44",44L,"mouse-annotated proteome, sampleoriginunresolved","culture label",NA_integer_,"log2normalizedproteinabundance",
    "PRIDEorganismhumanconflictswithmousesearchandmouseaccessions;cannotclaimhumanASMprotein. PER2notdetectedisnotnegativeeffect. DurationconfoundedwithTMTplex;noimputation.")
r<-read.csv(file.path(out,"human_protein/human_selected_results.csv"),stringsAsFactors=FALSE);r$contrast<-paste0(r$time_h,"h")
add("PMC9562650_human_protein",r,"holm_22",22L,"human testicular peritubular smooth-muscle-like cells","paired donor",6L,"publishedlog2LFQtechnicalmeanperdonor",
    "Cross-tissuehumanprotein,notASM;onlypreselectedarrayspubliclyexposed. METTL7A/positivecontrolFKBP5measurable,otherarraysunavailableP=1placeholder. Donorn=6,not18;post-extractionexploratory;exactsignnotconfirmed.")
project<-bio_project(items,title="公开数据验证：ASM晚期响应、GR遗传交叉检验及人源蛋白支持",
    metadata=list(status="exploratory_public_data_validation",new_wet_experiments=FALSE,
        objective="User requests data-only validation; retain unsupported mechanisms and missing proteins",
        primary_finding="LateadultASMPER2repressionrepeats;earlyinductionandPER2GRgeneticcausalitynotconfirmed;METTL7Ahumanproteinexploratorysupport"))
project<-bio_explain_project(project,use_llm=FALSE,language="zh")
saveRDS(items,file.path(out,"bioexplainr_validation_contexts.rds"));saveRDS(project,file.path(out,"bioexplainr_validation_project.rds"))
bio_report(project,file.path(out,"BioExplainR-validation-zh.html"),language="zh")
bio_report(project,file.path(out,"BioExplainR-validation-en.html"),language="en")
write.csv(do.call(rbind,checks),file.path(out,"bioexplainr_validation_fact_checks.csv"),row.names=FALSE)
write_json(list(status="pass",contexts=length(items),package_version=as.character(packageVersion("BioExplainR")),
    online_model_calls=0L,mode="actualpkgloadlocalsource",scope="Explicitinferenceandunitlimitsstoredinuncertainty"),
    file.path(out,"bioexplainr_validation_workflow.json"),auto_unbox=TRUE,pretty=TRUE)
writeLines(capture.output(sessionInfo()),file.path(out,"bioexplainr_validation_sessionInfo.txt"))
cat("BioExplainR public-validation project and bilingual reports completed\n")
