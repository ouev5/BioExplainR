# Independent original-table reconstruction of full cross-array diagnostics.
args <- commandArgs(TRUE)
out <- normalizePath(args[1]); root <- normalizePath("."); dest <- file.path(out,"complete")
stopifnot(!file.exists(file.path(dest,"r_audit.json")))
library(jsonlite)
freeze <- fromJSON(file.path(dest,"freeze.json"))
paths <- c(
 secretome24="research/results/discovery_secretome_v1/archives/24h/extracted/txt/proteinGroups.txt",
 secretome72="research/results/discovery_secretome_v1/archives/72h/extracted/txt/proteinGroups.txt",
 proteome24="research/results/discovery_set_validation_v1/protein_full_tables_small/PXD033514/extracted_verified/txt/proteinGroups.txt",
 proteome72="research/results/discovery_set_validation_v1/protein_full_tables_small/PXD033534/extracted/txt/proteinGroups.txt")
map_paths <- c(
 secretome24="research/results/discovery_secretome_v1/archives/24h/extracted/SampleNameEncription_Secretome24h.txt",
 secretome72="research/results/discovery_secretome_v1/archives/72h/extracted/SampleNameEncription_Secretome72h.txt",
 proteome24="research/results/discovery_set_validation_v1/protein_full_tables_small/PXD033514/extracted_verified/SampleNameEncription_Proteome24h.txt",
 proteome72="research/results/discovery_set_validation_v1/protein_full_tables_small/PXD033534/extracted/SampleNameEncription_Proteome72h.txt")
rd <- function(p) {
 d <- read.csv(p,stringsAsFactors=FALSE,check.names=FALSE,na.strings="")
 for (n in intersect(c("matches_rounding","equal","matched"),names(d))) {
  if (is.character(d[[n]]) && all(na.omit(d[[n]]) %in% c("True","False","TRUE","FALSE"))) d[[n]] <- as.logical(d[[n]])
 }
 d
}
x <- rd(file.path(dest,"diff_measurement_cross_array.csv"))
a <- rd(file.path(out,"all_intensity_cross_array.csv"))
samples <- rd(file.path(dest,"sample_map.csv"))
summary <- rd(file.path(dest,"cross_array_summary.csv"))
formula <- rd(file.path(dest,"scale_formula_comparisons.csv"))
tol <- function(actual,expected) {
 stopifnot(identical(is.na(actual),is.na(expected)))
 stopifnot(all(abs(actual[!is.na(actual)]-expected[!is.na(expected)]) <= 1e-10 * pmax(1,abs(expected[!is.na(expected)]))))
}
raw_tables <- list(); audit <- list(); sample_count <- 0L
for (key in names(paths)) {
 raw <- read.delim(paths[[key]],check.names=FALSE,stringsAsFactors=FALSE,quote="",comment.char="",na.strings="")
 raw_tables[[key]] <- raw
 # Decode original patient labels; independent regex and per-column mapping.
 lines <- readLines(map_paths[[key]])
 matched <- regexec("^([0-9.]+)\\.\\.\\.[[:space:]]*=[[:space:]]*([0-9]{2}\\.[0-9]{2}\\.[0-9]{2})",lines)
 parts <- regmatches(lines,matched); parts <- parts[lengths(parts)>0]
 decode <- setNames(vapply(parts,`[`,"",3),vapply(parts,`[`,"",2))
 cols <- names(raw)[startsWith(names(raw),"LFQ intensity ")]
 exp <- substring(cols,15)
 parts <- regmatches(exp,regexec("^([0-9.]+)_?(co|c|dex)([123])$",exp))
 stopifnot(all(lengths(parts)==4))
 donor <- decode[vapply(parts,`[`,"",2)]
 cond <- vapply(parts,`[`,"",3);cond[cond=="c"] <- "co"
 rep <- as.integer(vapply(parts,`[`,"",4))
 skey <- paste(donor,cond,rep,sep="|")
 stopifnot(!anyNA(donor),!anyDuplicated(skey))
 s <- samples[samples$array==key,]
 m <- match(paste(s$donor,s$condition,s$technical_rep,sep="|"),skey)
 stopifnot(!anyNA(m),identical(s$source_column,cols[m]),identical(s$experiment,exp[m]))
 sample_count <- sample_count+nrow(s)
 resolve <- function(ids) {
  exact <- match(ids,raw[["Protein IDs"]])
  multiple <- ids %in% raw[["Protein IDs"]][duplicated(raw[["Protein IDs"]])]
  exact[multiple] <- NA_integer_
  major <- match(ids,raw[["Majority protein IDs"]])
  major[ids %in% raw[["Majority protein IDs"]][duplicated(raw[["Majority protein IDs"]])]] <- NA_integer_
  # Only absent exact IDs may use Majority IDs; ambiguous exact IDs unresolved.
  fallback <- !ids %in% raw[["Protein IDs"]]
  exact[fallback] <- major[fallback]
  exact
 }
 z <- x[x$array==key,]
 ri <- resolve(z$protein_ids)
 ci <- match(z$source_column,names(raw))
 # Reconstruct expected sample columns independently; no values used in matching.
 expected_exp <- exp[match(paste(z$donor,z$condition,z$technical_rep,sep="|"),skey)]
 expected_col <- ifelse(is.na(expected_exp),NA_character_,paste(z$measure,expected_exp))
 stopifnot(identical(is.na(z$source_column),is.na(expected_col)))
 stopifnot(all(z$source_column[!is.na(expected_col)]==expected_col[!is.na(expected_col)]))
 value <- rep(NA_real_,nrow(z)); good <- !is.na(ri)&!is.na(ci)
 matrix <- as.matrix(raw[,unique(ci[!is.na(ci)]),drop=FALSE]);storage.mode(matrix) <- "numeric"
 mc <- match(z$source_column,colnames(matrix))
 value[good] <- matrix[cbind(ri[good],mc[good])]
 tol(value,z$original)
 logval <- ifelse(value>0,log2(value),NA_real_)
 tol(logval,z$original_log2);tol(logval-z$published_log2,z$delta)
 match_round <- !is.na(logval)&abs(logval-z$published_log2)<=.000051
 stopifnot(all(match_round==z$matches_rounding))
 za <- a[a$array==key,];ia <- resolve(za$protein_ids)
 intensity <- raw[["Intensity"]][ia]
 tol(intensity,za$original_intensity)
 stopifnot(all((!is.na(intensity)&intensity==za$published_intensity)==za$equal))
 for (expected in unique(summary$expected_array)) for (measure in unique(summary$measure)) {
  d <- z[z$expected_array==expected&z$measure==measure,]
  e <- za[za$expected_array==expected,]
  sums <- c(selected_cells=nrow(d),original_nonzero=sum(d$original>0,na.rm=TRUE),matches_rounding=sum(d$matches_rounding),
   original_zero=sum(d$original==0,na.rm=TRUE),unmapped=sum(is.na(d$original)),all_rows=nrow(e),
   all_resolved=sum(e$mapping!="unresolved"),all_intensity_equal=sum(e$equal),all_positive_equal=sum(e$equal&e$published_intensity>0))
  sr <- summary[summary$array==key&summary$expected_array==expected&summary$measure==measure,]
  stopifnot(nrow(sr)==1L)
  good <- vapply(names(sums),function(n) sr[[n]]==sums[[n]],logical(1))
  if (!all(good)) stop(paste(key,expected,measure,paste(names(sums)[!good],sums[!good],unlist(sr[names(sums)[!good]]),collapse=";")))
 }
 audit[[key]] <- list(raw_rows=nrow(raw),selected_comparisons=nrow(z),all_comparisons=nrow(za),sample_columns=length(cols))
}
raw <- raw_tables$secretome24
ri <- match(formula$protein_ids,raw[["Protein IDs"]]);stopifnot(!anyNA(ri))
den <- vapply(seq_len(nrow(formula)),function(i) as.numeric(raw[[formula$denominator[i]]][ri[i]]),numeric(1))
tol(den,formula$denominator_value)
# Raw values were independently reconstructed above. Match to that audited full comparison table.
z <- x[x$expected_array=="secretome24"&x$array=="secretome24",]
k <- paste(z$protein_ids,z$donor,z$condition,z$technical_rep,z$measure,sep="|")
fkey <- paste(formula$protein_ids,formula$donor,formula$condition,formula$technical_rep,formula$measure,sep="|")
fi <- match(fkey,k);stopifnot(!anyNA(fi))
tol(z$original[fi],formula$raw_value)
logval <- ifelse(formula$raw_value>0&den>0,log2(formula$raw_value/den),NA_real_)
tol(logval,formula$transformed_log2);tol(logval-formula$published_log2,formula$error)
stopifnot(all((!is.na(logval)&abs(logval-formula$published_log2)<=.000051)==formula$matched))
write_json(list(status="pass",utc=format(Sys.time(),tz="UTC",usetz=TRUE),arrays=audit,
 selected_comparisons=nrow(x),all_comparisons=nrow(a),sample_columns=sample_count,
 formula_comparisons=nrow(formula),summary_rows=nrow(summary),
 scope="Independent R original MaxQuant tables, decoding, direct/majority identities, numeric transforms/counts; published workbook export verified separately by OOXML parser; no new independent biological evidence"),
 file.path(dest,"r_audit.json"),auto_unbox=TRUE,pretty=TRUE)
writeLines(capture.output(sessionInfo()),file.path(dest,"r_audit_sessionInfo.txt"))
print(list(status="pass",selected=nrow(x),all=nrow(a),formulas=nrow(formula)))
