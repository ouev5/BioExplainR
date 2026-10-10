# Actual generic BioExplainR contexts: diagnostic counts are not p-values.
args <- commandArgs(TRUE); out <- normalizePath(args[1]); input <- file.path(out,"complete")
dest <- if (length(args)>1 && args[2]=="--complete") file.path(input,"report_final") else input
if (dest!=input) dir.create(dest,showWarnings=FALSE)
stopifnot(!file.exists(file.path(dest,"bioexplainr_project.rds")))
pkgload::load_all(".",quiet=TRUE);library(jsonlite)
s <- read.csv(file.path(input,"cross_array_summary.csv"),stringsAsFactors=FALSE)
a <- fromJSON(file.path(input,"independent_audit.json"));r <- fromJSON(file.path(input,"r_audit.json"))
stopifnot(a$status=="pass",r$status=="pass")
lfq <- s[s$measure=="LFQ intensity"&s$expected_array==s$array,]
z <- lfq[lfq$array=="secretome24",];stopifnot(z$matches_rounding==0,z$original_nonzero==803,z$all_positive_equal==0)
facts <- list(n_arrays=4L,n_decoded_run_columns=r$sample_columns,n_original_published_measurements=a$workbook_measurements,
 n_cross_measurement_checks=r$selected_comparisons,n_total_intensity_checks=r$all_comparisons,
 secretome24_nonzero_LFQ_checks=z$original_nonzero,secretome24_matched_LFQ=z$matches_rounding,
 secretome24_published_ALL_positions=z$all_rows,secretome24_matched_positive_total_intensity=z$all_positive_equal,
 secretome24_both_zero_total_intensity=z$all_intensity_equal,scientific_scope="Original-published source diagnostics; no new effect tests")
facts$scope_limitations <- paste("Post-result source diagnostics; complete comparison counts, no new candidateP or independent biological sample.",
 "Originalzeros remain missing. The9ALL matches are zero-zero only. Processingcause unknown; no repaired publishedvalues.")
top <- data.frame(array=lfq$array,original_nonzero_LFQ=as.character(lfq$original_nonzero),
 matched_rounding=as.character(lfq$matches_rounding),published_ALL=as.character(lfq$all_rows),
 matched_positive_ALL=as.character(lfq$all_positive_equal),stringsAsFactors=FALSE)
c1 <- new_bio_context("generic",source_class="cross_array_provenance_counts",source_package="MaxQuant_original_and_published_TableS2",
 source_status="user_declared",facts=facts,top_features=top,
 metadata=list(species="Homo sapiens",tissue="human testicular peritubular cells",contrast="Original vs published processed arrays"),
 scope=list(dataset_id="PXD033504/PXD033514/PXD033534",comparison_id="source_provenance_diagnostics"),
 design=list(unit_type="comparison position, not independent donor"),
 uncertainty=c("Post-result provenance diagnostics; counts/correlation do not resolve processing cause and are not significance tests.",
 "Same HTPC source as old studies. Preserve original zeros as missing; zero-zero intensity matches are not positive source evidence. No new independent ASM GC candidate protein evidence."))
c2 <- new_bio_context("generic",source_class="scoped_public_source_feasibility",source_status="user_declared",
 facts=list(literature_unique_records=a$literature_unique,pride_unique_projects=a$pride_unique_projects,
  ASM_EV_donor_labels=a$EV_independent_donor_labels,ASM_EV_runs=a$EV_runs,qualifying_GC_candidate_arrays_obtained=0L,
  EV_selected_glycolysis_rows=8L,EV_selected_reported_P_under05=0L,
  online_model_calls=0L,scientific_scope="Scoped metadata and original-paper review; EV identity lead, not GC causal validation",
  scope_limitations=paste("NoGCvehicle; six patients not18independent donors, originalsamepatientreplicates.",
   "Fullunselectedquantifiedarray notanalyzed; PRIDE2.5MascotProline vs article3.0CHIMERYSversions conflict.",
   "Selected8glycolysisproteinExprP>.05, expectedUp and pathwayP not8significantproteinclaims.",
   "PTX3priorASMELISA/RU486 supports thatcandidate only; no rawdonorvalues, age/timingconflicts and noNR3C1geneticcause.")),
 metadata=list(species="Homo sapiens",tissue="bronchial smooth muscle extracellular vesicles"),
 scope=list(dataset_id="PXD055968",comparison_id="asthmatic_vs_nonasthmatic_metadata_only"),
 design=list(unit_type="six original patient labels; three runs per label"),
 uncertainty=c("No randomized GC/vehicle factor; clinical ICS treatment cannot replace in-vitro paired drug contrast. Full unselected quantified protein array not analyzed.",
 "Original linkage says biological replicates; repeated runs per same patient cannot be eighteen independent donors. Study total43 participants does not equal six proteomic labels. Original/PRIDE processing versions differ.",
 "Scoped search no-hit or material failure is not proof data absent. PTX3 published ASM ELISA supports only that candidate and pharmacological GR association; unavailable raw donor values/age and textual timing conflicts retained."))
p <- bio_project(list(provenance=c1,public_source=c2),title="分泌蛋白来源诊断与ASM公共材料续接",metadata=list(status="diagnostic_public_source_followup",online_model_calls=0L))
p <- bio_explain_project(p,use_llm=FALSE,language="zh")
saveRDS(p,file.path(dest,"bioexplainr_project.rds"))
bio_report(p,file.path(dest,"BioExplainR-provenance-zh.html"),language="zh")
bio_report(p,file.path(dest,"BioExplainR-provenance-en.html"),language="en")
for (lang in c("zh","en")) {
 path <- file.path(dest,paste0("BioExplainR-provenance-",lang,".html"))
 text <- paste(readLines(path,warn=FALSE),collapse="\n")
 # Presentation-only responsive wrapper; untouched factual content retained in RDS.
 text <- sub("</head>",paste0("<meta name='viewport' content='width=device-width, initial-scale=1'>",
  "<style>body{overflow-wrap:anywhere}table{max-width:100%}.bio-table-wrap{max-width:100%;overflow-x:auto}",
  "@media(max-width:600px){body{margin:1em auto;padding:0 .75em}h1{font-size:25px}}</style></head>"),text,fixed=TRUE)
 text <- gsub("<table>","<div class='bio-table-wrap'><table>",text,fixed=TRUE)
 text <- gsub("</table>","</table></div>",text,fixed=TRUE)
 writeLines(text,path)
 stopifnot(grepl("14829",text,fixed=TRUE),grepl("scope_limitations",text,fixed=TRUE))
}
write_json(list(status="pass",contexts=2L,package_version=as.character(packageVersion("BioExplainR")),
 factual_counts=facts,online_model_calls=0L,new_GC_candidate_tests=0L),file.path(dest,"bioexplainr_workflow.json"),auto_unbox=TRUE,pretty=TRUE)
writeLines(capture.output(sessionInfo()),file.path(dest,"sessionInfo.txt"))
