# Live public evidence retrieval (explicit opt-in) ---------------------------------
#
# Nothing in this file runs unless the user calls bio_fetch_evidence() /
# bio_evidence_for_context() or passes evidence_sources to bio_explain().
# These calls go to public, unauthenticated databases only; they never use the
# user's LLM key and never send analysis data, only the query terms.

.live_sources <- c("europepmc", "go", "reactome", "kegg", "uniprot")

.live_endpoints <- c(
  europepmc = "https://www.ebi.ac.uk/europepmc/webservices/rest",
  go = "https://www.ebi.ac.uk/QuickGO/services/ontology/go",
  reactome = "https://reactome.org/ContentService/data",
  kegg = "https://rest.kegg.jp",
  uniprot = "https://rest.uniprot.org/uniprotkb"
)

.taxon_ids <- c("homo sapiens" = "9606", human = "9606", "mus musculus" = "10090", mouse = "10090",
                "rattus norvegicus" = "10116", rat = "10116", "danio rerio" = "7955", zebrafish = "7955",
                "drosophila melanogaster" = "7227", "caenorhabditis elegans" = "6239",
                "saccharomyces cerevisiae" = "559292", "arabidopsis thaliana" = "3702")

# Created lazily: utils.R (which defines .pkg_env) is collated after this file.
.ev_cache <- function() {
  if (is.null(.pkg_env$evidence_cache)) .pkg_env$evidence_cache <- new.env(parent = emptyenv())
  .pkg_env$evidence_cache
}

.evidence_error <- function(msg, source, status = NA_integer_) {
  structure(class = c("bio_evidence_error", "error", "condition"),
            list(message = bio_redact(msg), call = NULL, source = source, status = status))
}

.check_endpoint <- function(url, source) {
  p <- tryCatch(httr2::url_parse(url), error = function(e) NULL)
  local <- !is.null(p) && p$hostname %in% c("localhost", "127.0.0.1", "::1")
  if (is.null(p) || is.null(p$hostname) || !(identical(p$scheme, "https") || (local && identical(p$scheme, "http")))) {
    stop(.evidence_error(paste0("Invalid base_url for source '", source,
                                "': an https URL (or http on localhost) is required."), source))
  }
  if (!is.null(p$username) || !is.null(p$password)) {
    stop(.evidence_error("base_url must not contain credentials; public sources need none.", source))
  }
  sub("/+$", "", url)
}

# One bounded GET with retries on network failure / HTTP 429 / 5xx.
.http_get <- function(url, query = list(), timeout = 15, retries = 2, accept = "application/json",
                      source = "") {
  req <- httr2::request(url)
  if (length(query)) req <- do.call(httr2::req_url_query, c(list(req), query))
  req <- httr2::req_user_agent(req, paste0("BioExplainR/", .this_version() %||% "dev", " (public evidence lookup)"))
  req <- httr2::req_headers(req, Accept = accept)
  req <- httr2::req_timeout(req, timeout)
  req <- httr2::req_error(req, is_error = function(resp) FALSE)
  last <- NULL
  for (attempt in seq_len(retries + 1)) {
    resp <- tryCatch(httr2::req_perform(req), error = function(e) e)
    if (inherits(resp, "error")) {
      last <- paste0("network failure: ", conditionMessage(resp))
    } else {
      st <- httr2::resp_status(resp)
      if (!(st == 429 || st >= 500)) {
        return(list(status = st, text = httr2::resp_body_string(resp), resp = resp,
                    url = .public_url(url)))
      }
      last <- paste0("HTTP ", st)
    }
    if (attempt <= retries) Sys.sleep(min(0.5 * 2^(attempt - 1), 4))
  }
  stop(.evidence_error(paste0(source, " request to ", .public_url(url), " failed after ",
                              retries + 1, " attempt(s): ", last), source))
}

.parse_json_body <- function(r, source) {
  out <- tryCatch(jsonlite::fromJSON(r$text, simplifyVector = FALSE), error = function(e) NULL)
  if (is.null(out) || !is.list(out)) {
    stop(.evidence_error(paste0("Invalid response from ", source, ": body is not valid JSON object."),
                         source, r$status))
  }
  out
}

.http_fail <- function(r, source) {
  stop(.evidence_error(paste0(source, " returned HTTP ", r$status, " for ", r$url, ": ",
                              .truncate_chr(gsub("\\s+", " ", r$text), 160)), source, r$status))
}

.ev_now <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")

.live_evidence <- function(source, id, title, claim, url, type, version, note, extra = list()) {
  e <- bio_evidence(source, id = id, title = title, claim = claim, url = url, type = type,
                    version = version, accessed = .ev_now(), note = note)
  e$supplied_by <- paste0("retrieved:", source)
  for (n in names(extra)) e[[n]] <- extra[[n]]
  e
}

.chr1 <- function(x, default = NA_character_) {
  if (is.null(x) || length(x) == 0) return(default)
  v <- tryCatch(as.character(x[[1]]), error = function(e) default)
  if (length(v) == 0 || is.na(v)) default else v
}

# --- Europe PMC ---------------------------------------------------------------
.fetch_europepmc <- function(q, limit, timeout, retries, base, ...) {
  r <- .http_get(paste0(base, "/search"), list(query = q, format = "json", resultType = "lite",
                                              pageSize = limit), timeout, retries, source = "europepmc")
  if (r$status != 200) .http_fail(r, "Europe PMC")
  j <- .parse_json_body(r, "Europe PMC")
  if (is.null(j$resultList) || !is.list(j$resultList)) {
    stop(.evidence_error("Invalid response from Europe PMC: missing 'resultList'.", "europepmc", r$status))
  }
  hits <- utils::head(j$resultList$result %||% list(), limit)
  ver <- .chr1(j$version, NA_character_)
  lapply(hits, function(h) {
    src <- .chr1(h$source, "MED"); id <- .chr1(h$id)
    if (is.na(id)) stop(.evidence_error("Invalid response from Europe PMC: record without id.", "europepmc", r$status))
    journal <- .chr1(h$journalTitle, "")
    .live_evidence("EuropePMC", paste0(src, ":", id), .chr1(h$title, "(no title)"),
      paste0("Literature search hit: " %L% "\u6587\u732e\u68c0\u7d22\u547d\u4e2d\uff1a", .chr1(h$title, "(no title)"),
             if (nzchar(journal)) paste0(if (.is_zh()) "\uff08" else " (", journal, " ", .chr1(h$pubYear, ""), if (.is_zh()) "\uff09" else ")"),
             ". This only means the article matches the search terms; BioExplainR has not assessed whether its conclusions support any specific claim." %L%
               "\u3002\u4ec5\u8868\u793a\u8be5\u6587\u732e\u5339\u914d\u68c0\u7d22\u8bcd\uff0cBioExplainR \u672a\u8bc4\u4f30\u5176\u7ed3\u8bba\u662f\u5426\u652f\u6301\u4efb\u4f55\u5177\u4f53\u8bba\u65ad\u3002"),
      paste0("https://europepmc.org/article/", src, "/", id), "literature",
      if (is.na(ver)) "Europe PMC REST (release not reported)" else paste0("Europe PMC REST v", ver),
      paste0("query: ", q),
      list(pmid = .chr1(h$pmid), doi = .chr1(h$doi), authors = .truncate_chr(.chr1(h$authorString, ""), 120)))
  })
}

# --- QuickGO (term definitions only) --------------------------------------------
.fetch_go <- function(q, limit, timeout, retries, base, ...) {
  if (!grepl("^GO:[0-9]{7}$", q)) {
    stop(.evidence_error(paste0("GO lookup needs a GO term ID such as 'GO:0006954', got '", q, "'."), "go"))
  }
  r <- .http_get(paste0(base, "/terms/", q), list(), timeout, retries, source = "go")
  if (r$status == 404) return(list())
  if (r$status != 200) .http_fail(r, "QuickGO")
  j <- .parse_json_body(r, "QuickGO")
  if (!is.list(j$results)) stop(.evidence_error("Invalid response from QuickGO: missing 'results'.", "go", r$status))
  lapply(utils::head(j$results, limit), function(t) {
    id <- .chr1(t$id)
    if (is.na(id)) stop(.evidence_error("Invalid response from QuickGO: term without id.", "go", r$status))
    def <- .chr1(t$definition$text, "(no definition)")
    obs <- isTRUE(t$isObsolete)
    .live_evidence("GO", id, .chr1(t$name), paste0(
      "GO term definition (" %L% "GO \u672f\u8bed\u5b9a\u4e49\uff08", .chr1(t$aspect, "?"), "): " %L% "\uff09\uff1a", .chr1(t$name),
      if (.is_zh()) " \u2014\u2014 " else " - ", def,
      if (obs) "[This term is obsolete]" %L% "\u3010\u8be5\u672f\u8bed\u5df2\u5e9f\u5f03\u3011" else "",
      " This only explains the meaning of the term; it does not say whether any gene is annotated to it, nor pathway activity." %L%
        " \u4ec5\u8bf4\u660e\u672f\u8bed\u542b\u4e49\uff1b\u4e0d\u8bf4\u660e\u4efb\u4f55\u57fa\u56e0\u662f\u5426\u6ce8\u91ca\u5230\u8be5\u672f\u8bed\uff0c\u4e5f\u4e0d\u8bf4\u660e\u901a\u8def\u6d3b\u6027\u3002"),
      paste0("https://www.ebi.ac.uk/QuickGO/term/", id), "database", "QuickGO live service (release not reported)",
      "term definition only; gene membership requires gene annotations (e.g. UniProt)",
      list(aspect = .chr1(t$aspect), is_obsolete = obs))
  })
}

# --- Reactome Content Service (pathway definitions only) --------------------------
.fetch_reactome <- function(q, limit, timeout, retries, base, ...) {
  if (!grepl("^R-[A-Z]{3}-[0-9]+(\\.[0-9]+)?$", q)) {
    stop(.evidence_error(paste0("Reactome lookup needs a stable ID such as 'R-HSA-69278', got '", q, "'."), "reactome"))
  }
  r <- .http_get(paste0(base, "/query/", q), list(), timeout, retries, source = "reactome")
  if (r$status == 404) return(list())
  if (r$status != 200) .http_fail(r, "Reactome")
  j <- .parse_json_body(r, "Reactome")
  if (is.null(j$stId) || is.null(j$displayName)) {
    stop(.evidence_error("Invalid response from Reactome: missing 'stId'/'displayName'.", "reactome", r$status))
  }
  summ <- paste(vapply(j$summation %||% list(), function(s) .chr1(s$text, ""), ""), collapse = " ")
  summ <- .truncate_chr(gsub("<[^>]+>", "", summ), 500)
  sp <- .chr1(j$speciesName, "")
  list(.live_evidence("Reactome", j$stId, j$displayName, paste0(
    "Reactome entry definition (" %L% "Reactome \u6761\u76ee\u5b9a\u4e49\uff08", .chr1(j$schemaClass, "event"),
    if (nzchar(sp)) paste0(if (.is_zh()) "\uff1b" else "; ", sp), "): " %L% "\uff09\uff1a", j$displayName,
    if (nzchar(summ)) paste0(if (.is_zh()) " \u2014\u2014 " else " - ", summ),
    " This only explains the meaning of the entry; it does not say whether the input genes belong to this pathway or whether it is activated." %L%
      " \u4ec5\u8bf4\u660e\u6761\u76ee\u542b\u4e49\uff1b\u4e0d\u8bf4\u660e\u8f93\u5165\u57fa\u56e0\u662f\u5426\u5c5e\u4e8e\u8be5\u901a\u8def\u6216\u8be5\u901a\u8def\u662f\u5426\u88ab\u6fc0\u6d3b\u3002"),
    paste0("https://reactome.org/content/detail/", j$stId), "database",
    .chr1(j$stIdVersion, "Reactome live service (version not reported)"),
    "pathway definition only", list(species = sp)))
}

# --- KEGG REST (pathway entry text) ------------------------------------------------
.fetch_kegg <- function(q, limit, timeout, retries, base, ...) {
  if (!grepl("^(map|ko|[a-z]{2,4})[0-9]{5}$", q)) {
    stop(.evidence_error(paste0("KEGG lookup needs a pathway ID such as 'hsa04110', got '", q, "'."), "kegg"))
  }
  r <- .http_get(paste0(base, "/get/", q), list(), timeout, retries, accept = "text/plain", source = "kegg")
  if (r$status == 404) return(list())
  if (r$status != 200) .http_fail(r, "KEGG")
  lines <- strsplit(r$text, "\n", fixed = TRUE)[[1]]
  field <- function(k) {
    i <- which(startsWith(lines, k))
    if (!length(i)) return(NA_character_)
    trimws(sub(paste0("^", k, "\\s*"), "", lines[i[1]]))
  }
  entry <- field("ENTRY"); name <- field("NAME")
  if (is.na(entry) || is.na(name)) {
    stop(.evidence_error("Invalid response from KEGG: no ENTRY/NAME lines.", "kegg", r$status))
  }
  id <- strsplit(entry, "\\s+")[[1]][1]
  desc <- field("DESCRIPTION")
  list(.live_evidence("KEGG", id, name, paste0(
    "KEGG pathway entry: " %L% "KEGG \u901a\u8def\u6761\u76ee\uff1a", name,
    if (!is.na(desc)) paste0(if (.is_zh()) " \u2014\u2014 " else " - ", .truncate_chr(desc, 400)),
    " This only explains the meaning of the entry; it does not say whether the input genes are pathway members, nor pathway activity. KEGG data have licence restrictions; follow its terms when citing." %L%
      " \u4ec5\u8bf4\u660e\u6761\u76ee\u542b\u4e49\uff1b\u4e0d\u8bf4\u660e\u8f93\u5165\u57fa\u56e0\u7684\u901a\u8def\u6210\u5458\u5173\u7cfb\u6216\u901a\u8def\u6d3b\u6027\u3002KEGG \u6570\u636e\u6709\u4f7f\u7528\u8bb8\u53ef\u9650\u5236\uff0c\u5f15\u7528\u65f6\u8bf7\u9075\u5faa\u5176\u6761\u6b3e\u3002"),
    paste0("https://www.kegg.jp/entry/", id), "database", "KEGG live service (release not queried)",
    "pathway entry only; KEGG license terms apply", list(class = field("CLASS"))))
}

# --- UniProt (gene/protein search or accession lookup) ------------------------------------
.uniprot_fields <- "accession,id,gene_names,protein_name,organism_name,organism_id,cc_function,go"
.uniprot_acc <- "^([OPQ][0-9][A-Z0-9]{3}[0-9]|[A-NR-Z][0-9]([A-Z][A-Z0-9]{2}[0-9]){1,2})$"

.taxon_id <- function(organism) {
  if (is.null(organism)) return(NULL)
  o <- tolower(trimws(as.character(organism)[1]))
  if (grepl("^[0-9]+$", o)) return(o)
  id <- unname(.taxon_ids[o])
  if (is.na(id)) stop(.evidence_error(paste0("Unknown organism '", organism,
                                            "'; supply a numeric NCBI taxon ID (e.g. 9606)."), "uniprot"))
  id
}

.uniprot_entry <- function(r) {
  acc <- .chr1(r$primaryAccession)
  if (is.na(acc)) stop(.evidence_error("Invalid response from UniProt: entry without primaryAccession.", "uniprot"))
  genes <- unlist(lapply(r$genes %||% list(), function(g) .chr1(g$geneName$value, NA_character_)))
  genes <- genes[!is.na(genes)]
  pname <- .chr1(r$proteinDescription$recommendedName$fullName$value,
                 .chr1(r$proteinDescription$submissionNames[[1]]$fullName$value, "(unnamed protein)"))
  org <- .chr1(r$organism$scientificName, "unknown organism")
  reviewed <- grepl("reviewed", .chr1(r$entryType, ""), ignore.case = TRUE) &&
    !grepl("unreviewed", .chr1(r$entryType, ""), ignore.case = TRUE)
  fn <- NA_character_
  for (cm in r$comments %||% list()) {
    if (identical(cm$commentType, "FUNCTION")) { fn <- .chr1(cm$texts[[1]]$value); break }
  }
  refs <- Filter(function(x) identical(x$database, "GO"), r$uniProtKBCrossReferences %||% list())
  ann <- if (length(refs)) do.call(rbind, lapply(refs, function(x) {
    prop <- function(k) {
      v <- Filter(function(p) identical(p$key, k), x$properties %||% list())
      if (length(v)) .chr1(v[[1]]$value) else NA_character_
    }
    term <- prop("GoTerm")
    data.frame(accession = acc, gene = if (length(genes)) genes[1] else NA_character_, go_id = .chr1(x$id),
               aspect = if (!is.na(term)) sub(":.*$", "", term) else NA_character_,
               term = if (!is.na(term)) sub("^[A-Z]:", "", term) else NA_character_,
               evidence_code = prop("GoEvidenceType"), stringsAsFactors = FALSE)
  })) else data.frame(accession = character(), gene = character(), go_id = character(), aspect = character(),
                      term = character(), evidence_code = character(), stringsAsFactors = FALSE)
  claim <- if (.is_zh()) paste0("UniProt \u6761\u76ee ", acc, "\uff08\u57fa\u56e0\uff1a", if (length(genes)) paste(genes, collapse = "/") else "\u672a\u5217\u51fa",
                  "\uff1b\u86cb\u767d\uff1a", pname, "\uff1b\u7269\u79cd\uff1a", org, "\uff1b", if (reviewed) "Swiss-Prot \u4eba\u5de5\u5ba1\u9605" else "TrEMBL \u672a\u5ba1\u9605", "\uff09",
                  "\u542b ", nrow(ann), " \u6761 GO \u4ea4\u53c9\u5f15\u7528\uff08\u6bcf\u6761\u5e26\u8bc1\u636e\u4ee3\u7801\uff0c\u5176\u4e2d\u53ef\u80fd\u542b\u7535\u5b50\u63a8\u65ad IEA\uff09\u3002",
                  if (!is.na(fn)) paste0(" FUNCTION \u6ce8\u91ca\uff1a", .truncate_chr(fn, 400)))
  else paste0("UniProt entry ", acc, " (gene: ", if (length(genes)) paste(genes, collapse = "/") else "not listed",
              "; protein: ", pname, "; organism: ", org, "; ", if (reviewed) "Swiss-Prot, manually reviewed" else "TrEMBL, unreviewed", "). ",
              "It carries ", nrow(ann), " GO cross-references (each with an evidence code; these may include electronic IEA inference).",
              if (!is.na(fn)) paste0(" FUNCTION annotation: ", .truncate_chr(fn, 400)))
  list(acc = acc, genes = genes, title = paste0(pname, " [", org, "]"), claim = claim, ann = ann, reviewed = reviewed)
}

.fetch_uniprot <- function(q, limit, timeout, retries, base, organism = NULL,
                           mode = c("auto", "gene", "protein", "accession"), reviewed = TRUE, ...) {
  mode <- match.arg(mode)
  if (mode == "auto") mode <- if (grepl(.uniprot_acc, q)) "accession" else "gene"
  if (mode == "gene" && !grepl("^[A-Za-z0-9._-]+$", q)) {
    stop(.evidence_error(paste0("'", q, "' is not a valid gene symbol; use mode = 'protein' for free text."), "uniprot"))
  }
  tax <- .taxon_id(organism)
  if (mode == "accession") {
    if (!grepl(.uniprot_acc, q)) stop(.evidence_error(paste0("'", q, "' is not a UniProt accession."), "uniprot"))
    r <- .http_get(paste0(base, "/", q, ".json"), list(fields = .uniprot_fields), timeout, retries, source = "uniprot")
    if (r$status == 404) return(list())
    if (r$status != 200) .http_fail(r, "UniProt")
    entries <- list(.parse_json_body(r, "UniProt"))
  } else {
    qq <- if (mode == "gene") paste0("gene_exact:", q) else paste0("(", q, ")")
    if (!is.null(tax)) qq <- paste0(qq, " AND organism_id:", tax)
    if (isTRUE(reviewed)) qq <- paste0(qq, " AND reviewed:true")
    r <- .http_get(paste0(base, "/search"), list(query = qq, fields = .uniprot_fields, size = limit, format = "json"),
                   timeout, retries, source = "uniprot")
    if (r$status != 200) .http_fail(r, "UniProt")
    j <- .parse_json_body(r, "UniProt")
    if (!is.list(j$results)) stop(.evidence_error("Invalid response from UniProt: missing 'results'.", "uniprot", r$status))
    entries <- utils::head(j$results, limit)
  }
  rel <- tryCatch(httr2::resp_header(r$resp, "X-UniProt-Release"), error = function(e) NULL)
  lapply(entries, function(en) {
    p <- .uniprot_entry(en)
    .live_evidence("UniProt", p$acc, p$title, p$claim, paste0("https://www.uniprot.org/uniprotkb/", p$acc),
      "database", if (!is.null(rel) && !is.na(rel)) paste0("UniProt release ", rel) else "UniProt live service (release header absent)",
      paste0("query: ", q, if (is.null(tax)) "; no organism filter applied" else paste0("; organism_id ", tax)),
      list(genes = p$genes, reviewed = p$reviewed, annotations = p$ann))
  })
}

.live_fetchers <- list(europepmc = .fetch_europepmc, go = .fetch_go, reactome = .fetch_reactome,
                       kegg = .fetch_kegg, uniprot = .fetch_uniprot)

#' Fetch traceable evidence from public databases (explicit, opt-in)
#'
#' Queries one public source and returns \code{\link{bio_evidence}} objects with
#' IDs, URLs, version information (when the service reports one) and access
#' time. Nothing is retrieved unless you call this function (or pass
#' \code{evidence_sources} to \code{\link{bio_explain}}). Requests are public and
#' unauthenticated, are separate from any LLM configuration, and send only the
#' query text, never analysis data.
#'
#' What each source can and cannot support:
#' \describe{
#'   \item{\code{"europepmc"}}{Literature search (\code{query} is an Europe PMC
#'     query string). A hit means the paper matches the search terms, not that it
#'     supports any particular claim.}
#'   \item{\code{"go"}}{QuickGO term lookup; \code{query} is a GO ID such as
#'     \code{"GO:0006954"}. Establishes the term name/definition only; it says
#'     nothing about which genes belong to the term.}
#'   \item{\code{"reactome"}}{Reactome Content Service entry for a stable ID such
#'     as \code{"R-HSA-69278"}. Definition only, not membership or activation.}
#'   \item{\code{"kegg"}}{KEGG REST \code{get} for a pathway ID such as
#'     \code{"hsa04110"}. KEGG data are subject to KEGG licence terms.}
#'   \item{\code{"uniprot"}}{Gene symbol search (\code{mode = "gene"}, default for
#'     non-accession queries), free-text protein search, or accession lookup.
#'     Each evidence object carries an \code{annotations} data.frame of GO
#'     cross-references with evidence codes (see \code{\link{bio_go_annotations}});
#'     this is the source for gene-to-GO membership. Set \code{organism} (name or
#'     NCBI taxon ID) to avoid cross-species hits.}
#' }
#' Results are cached for the R session by source, query and all options;
#' \code{cache = FALSE} forces a new request. Cached evidence keeps its original
#' access time.
#'
#' @param query Character vector of queries (at most 50), one request each.
#' @param source One of \code{"europepmc"}, \code{"go"}, \code{"reactome"},
#'   \code{"kegg"}, \code{"uniprot"}.
#' @param limit Maximum evidence objects per query (1-100).
#' @param timeout Per-request timeout in seconds.
#' @param cache Use the per-session cache.
#' @param retries Extra attempts after a network failure, HTTP 429 or 5xx
#'   (0-5, exponential back-off).
#' @param organism UniProt only: species name or NCBI taxon ID.
#' @param mode UniProt only: \code{"auto"}, \code{"gene"}, \code{"protein"} or
#'   \code{"accession"}.
#' @param reviewed UniProt search only: restrict to reviewed (Swiss-Prot) entries.
#' @param base_url Override the service root (mirror or local test server);
#'   https, or http on localhost only, without credentials.
#' @param register Also register results with \code{\link{bio_evidence_register}}.
#' @param on_error \code{"stop"} (default) or \code{"warn"} to keep results of the
#'   other queries and report failures in \code{attr(, "errors")}.
#' @return A list of \code{bio_evidence} objects (empty when nothing is found),
#'   with attributes \code{retrieval} (per-query hits, cache use) and
#'   \code{errors}.
#' @export
#' @examples
#' \donttest{
#' # Needs internet; sends only the query text to the public service.
#' if (interactive()) {
#'   bio_fetch_evidence("GO:0006954", source = "go")
#'   bio_fetch_evidence("IL6", source = "uniprot", organism = "Homo sapiens", limit = 1)
#'   bio_fetch_evidence("single-cell RNA-seq pseudoreplication", source = "europepmc", limit = 3)
#' }
#' }
bio_fetch_evidence <- function(query, source = c("europepmc", "go", "reactome", "kegg", "uniprot"),
                               limit = 5, timeout = 15, cache = TRUE, retries = 2, organism = NULL,
                               mode = c("auto", "gene", "protein", "accession"), reviewed = TRUE,
                               base_url = NULL, register = FALSE, on_error = c("stop", "warn")) {
  source <- match.arg(source)
  mode <- match.arg(mode)
  on_error <- match.arg(on_error)
  query <- unique(trimws(as.character(query)))
  query <- query[!is.na(query) & nzchar(query)]
  if (!length(query)) stop("query must contain at least one non-empty string.", call. = FALSE)
  if (length(query) > 50) stop("At most 50 queries per call.", call. = FALSE)
  num <- function(v, nm, lo, hi) {
    if (!is.numeric(v) || length(v) != 1 || is.na(v) || !is.finite(v) || v < lo || v > hi || v != floor(v) && nm != "timeout") {
      stop(nm, " must be a number between ", lo, " and ", hi, ".", call. = FALSE)
    }
  }
  num(limit, "limit", 1, 100); num(retries, "retries", 0, 5); num(timeout, "timeout", 1, 300)
  base <- .check_endpoint(base_url %||% .live_endpoints[[source]], source)
  fetch <- .live_fetchers[[source]]
  opts <- paste(source, base, limit, organism %||% "", mode, reviewed, sep = "|")
  out <- list(); log <- list(); errs <- list()
  for (q in query) {
    key <- paste(opts, q, sep = "\r")
    hit <- if (isTRUE(cache)) .ev_cache()[[key]] else NULL
    res <- hit
    err <- NULL
    if (is.null(res)) {
      res <- tryCatch(fetch(q, limit = limit, timeout = timeout, retries = retries, base = base,
                            organism = organism, mode = mode, reviewed = reviewed),
                      error = function(e) e)
      if (inherits(res, "error")) {
        err <- res
        if (on_error == "stop") stop(err)
        warning(conditionMessage(err), call. = FALSE)
        errs[[length(errs) + 1]] <- data.frame(source = source, query = q, message = conditionMessage(err),
                                              stringsAsFactors = FALSE)
        res <- list()
      } else if (isTRUE(cache)) assign(key, res, envir = .ev_cache())
    }
    log[[length(log) + 1]] <- data.frame(source = source, query = q, n_hits = length(res),
                                         from_cache = !is.null(hit), failed = !is.null(err),
                                         stringsAsFactors = FALSE)
    out <- c(out, res)
  }
  if (register && length(out)) bio_evidence_register(out)
  structure(out, retrieval = do.call(rbind, log),
            errors = if (length(errs)) do.call(rbind, errs) else NULL)
}

#' Clear the per-session live evidence cache
#' @return Invisibly \code{TRUE}.
#' @export
bio_evidence_cache_clear <- function() {
  rm(list = ls(.ev_cache(), all.names = TRUE), envir = .ev_cache())
  invisible(TRUE)
}

#' Register the public live sources as evidence providers
#'
#' Makes \code{"europepmc"}, \code{"go"}, \code{"reactome"}, \code{"kegg"} and
#' \code{"uniprot"} available to \code{\link{bio_evidence_lookup}} by name. This
#' is optional: \code{bio_evidence_lookup()} also resolves these names on demand.
#' Registering does not perform any request. Default arguments (for example
#' \code{organism}, \code{limit}) can be fixed per provider.
#'
#' @param sources Which sources to register.
#' @param overwrite Replace an existing provider of the same name.
#' @param ... Default arguments passed to \code{\link{bio_fetch_evidence}}.
#' @return Invisibly, the names of all registered providers.
#' @export
#' @examples
#' bio_register_live_providers("uniprot", organism = "Homo sapiens")
#' bio_evidence_providers()
bio_register_live_providers <- function(sources = .live_sources, overwrite = FALSE, ...) {
  sources <- match.arg(sources, .live_sources, several.ok = TRUE)
  defaults <- list(...)
  for (s in sources) {
    if (!overwrite && !is.null(.pkg_env$evidence_providers[[s]])) next
    local({
      src <- s
      .pkg_env$evidence_providers[[src]] <- function(query, ...) {
        args <- utils::modifyList(defaults, list(...))
        do.call(bio_fetch_evidence, c(list(query = query, source = src), args))
      }
    })
  }
  invisible(names(.pkg_env$evidence_providers))
}

#' List evidence provider names
#' @return Character vector: registered providers plus the built-in live sources.
#' @export
bio_evidence_providers <- function() unique(c(names(.pkg_env$evidence_providers), .live_sources))

.live_provider <- function(name) {
  if (!name %in% .live_sources) return(NULL)
  function(query, ...) bio_fetch_evidence(query, source = name, ...)
}

#' GO annotations (gene-to-term memberships) from retrieved UniProt evidence
#'
#' Collects the \code{annotations} tables of UniProt evidence objects. Each row
#' is a curated cross-reference with its GO evidence code; electronic
#' annotations (\code{IEA}) are inferred, not manually reviewed.
#'
#' @param evidence List of \code{bio_evidence} (or one) from
#'   \code{bio_fetch_evidence(source = "uniprot")}.
#' @param go_ids Optional GO IDs to keep.
#' @return data.frame: accession, gene, go_id, aspect, term, evidence_code.
#' @export
bio_go_annotations <- function(evidence, go_ids = NULL) {
  if (inherits(evidence, "bio_evidence")) evidence <- list(evidence)
  parts <- lapply(evidence, function(e) e$annotations)
  parts <- parts[vapply(parts, is.data.frame, logical(1))]
  df <- if (length(parts)) do.call(rbind, parts) else
    data.frame(accession = character(), gene = character(), go_id = character(), aspect = character(),
               term = character(), evidence_code = character(), stringsAsFactors = FALSE)
  if (!is.null(go_ids)) df <- df[df$go_id %in% go_ids, , drop = FALSE]
  rownames(df) <- NULL
  df
}

#' Retrieve evidence for the top features of a context (explicit opt-in)
#'
#' Derives queries from a \code{\link{bio_context}} and calls
#' \code{\link{bio_fetch_evidence}}: top genes go to UniProt (and, as a
#' literature query together with species/tissue, to Europe PMC); GO,
#' Reactome and KEGG IDs found in enrichment top terms (or given in
#' \code{ids}) go to their sources. Sources without applicable queries are
#' reported in \code{attr(, "skipped")}. Failures become warnings and are listed
#' in \code{attr(, "errors")}; the explanation is never blocked by a database
#' outage. \code{\link{bio_explain}} calls this when \code{evidence_sources} is
#' set; live retrieval is never enabled by default.
#'
#' @param ctx A \code{bio_context}.
#' @param sources Subset of the five live sources.
#' @param n_genes Top genes to look up.
#' @param ids Extra GO / Reactome / KEGG IDs (auto-assigned by pattern).
#' @param organism Species for UniProt; default is mapped from
#'   \code{ctx$metadata$species} when known, otherwise no organism filter is
#'   applied (and the evidence note says so).
#' @param limit Evidence objects per query.
#' @param ... Passed to \code{\link{bio_fetch_evidence}} (\code{timeout},
#'   \code{retries}, \code{cache}, \code{base_url} is not allowed here).
#' @return A list of \code{bio_evidence} with attributes \code{retrieval},
#'   \code{errors}, \code{skipped}.
#' @export
bio_evidence_for_context <- function(ctx, sources = .live_sources, n_genes = 5, ids = NULL,
                                     organism = NULL, limit = 3, ...) {
  stopifnot(inherits(ctx, "bio_context"))
  sources <- match.arg(sources, .live_sources, several.ok = TRUE)
  top <- ctx$top_features
  genes <- character()
  if (!is.null(top) && "feature" %in% names(top) && ctx$analysis_type %in% c("differential_expression", "markers")) {
    genes <- utils::head(unique(as.character(top$feature)), n_genes)
  }
  all_ids <- unique(c(if (!is.null(top) && "id" %in% names(top)) as.character(top$id), ids))
  all_ids <- all_ids[!is.na(all_ids)]
  species <- ctx$metadata$species
  organism <- organism %||% if (!is.null(species) && tolower(species) %in% names(.taxon_ids)) species else NULL
  lit <- character()
  if (length(genes)) {
    ctxt <- paste0('"', c(species, ctx$metadata$tissue), '"', collapse = " AND ")
    lit <- paste0('"', utils::head(genes, 3), '"', if (nzchar(ctxt) && ctxt != '""') paste0(" AND ", ctxt) else "")
  }
  if (!is.null(top) && "term" %in% names(top) && ctx$analysis_type %in% c("enrichment_ora", "enrichment_gsea")) {
    terms <- utils::head(unique(as.character(top$term)), 2)
    lit <- c(lit, paste0('"', terms, '"', if (!is.null(species)) paste0(' AND "', species, '"') else ""))
  }
  plan <- list(
    europepmc = lit,
    go = grep("^GO:[0-9]{7}$", all_ids, value = TRUE),
    reactome = grep("^R-[A-Z]{3}-[0-9]+", all_ids, value = TRUE),
    kegg = grep("^(map|ko|[a-z]{2,4})[0-9]{5}$", all_ids, value = TRUE),
    uniprot = genes)
  out <- list(); logs <- list(); errs <- list(); skipped <- character()
  for (s in sources) {
    q <- plan[[s]]
    if (!length(q)) { skipped <- c(skipped, s); next }
    extra <- if (s == "uniprot") list(organism = organism, mode = "gene") else list()
    r <- do.call(bio_fetch_evidence, c(list(query = q, source = s, limit = limit, on_error = "warn"), extra, list(...)))
    out <- c(out, r)
    logs[[length(logs) + 1]] <- attr(r, "retrieval")
    if (!is.null(attr(r, "errors"))) errs[[length(errs) + 1]] <- attr(r, "errors")
  }
  structure(out, retrieval = if (length(logs)) do.call(rbind, logs) else NULL,
            errors = if (length(errs)) do.call(rbind, errs) else NULL,
            skipped = skipped)
}
