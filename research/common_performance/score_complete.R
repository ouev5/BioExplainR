# Retain frozen scorer; repair only list->integer conversion of frozen indices.
expressions <- parse("research/common_performance/score.R")
index <- which(vapply(expressions,function(x) is.call(x)&&identical(x[[1]],as.name("<-"))&&identical(x[[2]],as.name("indices")),logical(1)))
stopifnot(length(index)==1L)
expressions[[index]] <- quote(indices <- do.call(rbind,lapply(readj("bootstrap_indices.json"),unlist))+1L)
eval(expressions)
