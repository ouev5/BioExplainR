# One loaded R process, fresh chat per call, serial interleaved frozen schedule.
.libPaths(c("/tmp/opencode/common-performance-R-library", .libPaths()))
pkgload::load_all(".", quiet = TRUE)
options(ellmer_timeout_s = 180, ellmer_max_tries = 1)
args <- commandArgs(TRUE); out <- args[1]; endpoint <- args[2]
jread <- function(p) jsonlite::read_json(p, simplifyVector = FALSE)
jwrite <- function(x,p) jsonlite::write_json(x,p,auto_unbox=TRUE,pretty=TRUE,digits=17,null="null",na="null")
fields <- c("n_features","n_significant","n_up","n_down","n_na_padj")
parse_answer <- function(text, truncated = FALSE) {
  if (truncated) return(list())
  text <- trimws(text)
  if (grepl("^```json\\s", text) && grepl("```$",text)) text <- sub("```$","",sub("^```json\\s*","",text))
  if (!jsonlite::validate(text) || !grepl("^\\s*\\{",text) || grepl("[0-9][.eE]",text)) return(list())
  x <- tryCatch(jsonlite::fromJSON(text,simplifyVector=FALSE),error=function(e) NULL)
  if (is.null(names(x)) || anyDuplicated(names(x))) return(list())
  x <- x[intersect(fields,names(x))]
  x[vapply(x,function(v) is.numeric(v)&&length(v)==1L&&is.finite(v)&&v>=0&&v==floor(v),logical(1))]
}
system <- "Return only one JSON object with integer fields n_features, n_significant, n_up, n_down, n_na_padj. No explanation."
make_user <- function(tab, task, facts = NULL) {
  rules <- sprintf("Count all rows. Significant means padj < %.17g AND abs(log2FoldChange) > %.17g. NA padj is not significant. Up/down means positive/negative significant log2FoldChange. n_na_padj counts NA padj.\n",task$alpha,task$lfc)
  if (is.null(facts)) paste0(rules,"CSV table:\n",paste(capture.output(write.csv(tab,row.names=FALSE,na="NA")),collapse="\n"))
  else paste0(rules,"Complete BioExplainR facts (copy the five requested integers):\n",jsonlite::toJSON(facts,auto_unbox=TRUE,digits=17,null="null",na="null"))
}
call_model <- function(method, user) {
  if (method == "bio_client_facts") {
    cfg <- bio_config("openai_compatible",model="qwen-fixed",base_url=endpoint,api_key="local-only",
      temperature=0,max_tokens=256,timeout=180,max_retries=0,
      extra_body=list(seed=42L,cache_prompt=FALSE))
    z <- bio_llm_chat(cfg,system,user)
    list(text=z$text,finish=z$stop_reason,usage=z$usage,model=z$model)
  } else {
    ch <- ellmer::chat_openai_compatible(system_prompt=system,base_url=endpoint,
      credentials=function() "local-only",model="qwen-fixed",echo="none",
      params=ellmer::params(temperature=0,seed=42L,max_tokens=256),api_args=list(cache_prompt=FALSE))
    text <- as.character(ch$chat(user))
    turn <- ch$last_turn()
    list(text=text,finish=turn@json$choices[[1]]$finish_reason,usage=as.list(ch$get_tokens()[1,]),model=ch$get_model())
  }
}
warm <- data.frame(feature_id=c("warm_a","warm_b"),log2FoldChange=c(2,-.1),padj=c(.001,NA))
jwrite(tryCatch(call_model("ellmer_table",make_user(warm,list(alpha=.05,lfc=1))),error=function(e) list(error=conditionMessage(e))),file.path(out,"warmup.json"))
tasks <- jread(file.path(out,"tasks.json")); schedule <- jread(file.path(out,"schedule.json"))
dir.create(file.path(out,"runs"))
for (run in schedule) {
  task <- tasks[[run$task_index + 1L]]
  t0 <- proc.time()[["elapsed"]]
  user <- NULL
  result <- tryCatch({
    tab <- read.csv(file.path(out,"inputs",task$input),check.names=FALSE)
    method <- run$method; facts <- NULL; user <- NULL
    if (method %in% c("bio_offline","ellmer_facts","bio_client_facts")) {
      ctx <- bio_context(tab,thresholds=list(padj=task$alpha,lfc=task$lfc))
      facts <- ctx$facts
    }
    if (method == "bio_offline") text <- as.character(jsonlite::toJSON(facts[fields],auto_unbox=TRUE))
    else if (method == "base_r") {
      selected <- which(!is.na(tab$padj)&tab$padj<task$alpha&!is.na(tab$log2FoldChange)&abs(tab$log2FoldChange)>task$lfc)
      ans <- list(n_features=nrow(tab),n_significant=length(selected),n_up=sum(tab$log2FoldChange[selected]>0),n_down=sum(tab$log2FoldChange[selected]<0),n_na_padj=sum(is.na(tab$padj)))
      text <- as.character(jsonlite::toJSON(ans,auto_unbox=TRUE))
    } else user <- make_user(tab,task,facts)
    prep <- proc.time()[["elapsed"]]-t0
    z <- if (!is.null(user)) call_model(method,user) else list(text=text,finish="deterministic",usage=NULL,model=NULL)
    called <- proc.time()[["elapsed"]]-t0-prep
    parsed <- parse_answer(z$text,identical(z$finish,"length"))
    list(status="returned",text=z$text,finish=z$finish,usage=z$usage,model=z$model,
      parsed=parsed,system=if(!is.null(user)) system else NULL,user=user,
      preparation_sec=prep,call_sec=called,elapsed_sec=proc.time()[["elapsed"]]-t0)
  },error=function(e) list(status="error",error=conditionMessage(e),text="",parsed=list(),
    system=if(!is.null(user)) system else NULL,user=user,elapsed_sec=proc.time()[["elapsed"]]-t0))
  jwrite(c(run,list(task_id=task$id),result),file.path(out,"runs",sprintf("%03d.json",run$order)))
  cat(run$order,run$method,task$id,result$status,"\n"); flush.console()
}
writeLines(capture.output(sessionInfo()),file.path(out,"sessionInfo.txt"))
