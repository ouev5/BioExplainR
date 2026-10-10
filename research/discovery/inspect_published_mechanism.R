# Cross-check published processed object's sample annotation, not its statistical labels.
out <- commandArgs(TRUE)[1]
path <- file.path(out,"SE.processed.rds")
obj <- readRDS(path)
metadata <- as.data.frame(SummarizedExperiment::colData(obj))
write.csv(data.frame(sample=rownames(metadata),metadata,check.names=FALSE),file.path(out,"published_sample_annotation.csv"),row.names=FALSE)
writeLines(capture.output(str(metadata)),file.path(out,"published_annotation_structure.txt"))
cat("Published object class:",class(obj),"\n")
print(metadata)
