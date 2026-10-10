# Versioned contracts, serialization and bounded model payloads -----------------

.bio_schema_version <- "1.0"
.bio_serialization_version <- "jsonlite-17-null-1"

.sha256 <- function(x) {
  if (!requireNamespace("digest", quietly = TRUE))
    stop("The 'digest' package is required for BioExplainR manifests.", call. = FALSE)
  if (is.raw(x)) digest::digest(x, algo = "sha256", serialize = FALSE)
  else digest::digest(enc2utf8(as.character(x)), algo = "sha256", serialize = FALSE)
}

.canonicalize <- function(x) {
  if (is.data.frame(x)) {
    # Table rows retain observation order; named object keys are canonicalized.
    return(lapply(seq_len(nrow(x)), function(i) {
      .canonicalize(as.list(x[i, , drop = FALSE], all = TRUE))
    }))
  }
  if (is.list(x)) {
    n <- names(x)
    if (!is.null(n) && all(nzchar(n))) {
      x <- x[order(n)]
      names(x) <- sort(n)
    }
    return(lapply(x, .canonicalize))
  }
  if (is.factor(x)) return(as.character(x))
  # bit64 values are optional; detect them by class without importing bit64.
  if (inherits(x, "integer64")) return(as.character(x))
  if (is.atomic(x) && !is.null(names(x)) && all(nzchar(names(x)))) return(.canonicalize(as.list(x)))
  if (is.atomic(x)) return(unname(x))
  x
}

.canonical_json <- function(x) {
  jsonlite::toJSON(.canonicalize(x), auto_unbox = TRUE, null = "null", na = "null",
                   digits = 17, force = TRUE, POSIXt = "ISO8601")
}

.hash_object <- function(x) .sha256(.canonical_json(x))

.sensitive_name <- function(name) {
  if (tolower(name) %in% c("source_path", "fact_path", "path_tokens", "request_hash_scope",
      "prompt_tokens", "completion_tokens", "total_tokens", "input_tokens", "output_tokens",
      "cached_tokens", "prompt_cache_hit_tokens", "prompt_cache_miss_tokens")) return(FALSE)
  grepl("(?i)(patient|subject|donor|barcode|cell.?id|sample.?(id|name)|file|path|token|secret|password|api.?key|credential|authorization)",
        name, perl = TRUE)
}

.sensitive_value <- function(x) {
  if (is.factor(x)) x <- as.character(x)
  if (!is.character(x)) return(x)
  y <- bio_redact(x)
  urls <- gregexpr("(?i)https?://[^\\s,;\"']+", y, perl = TRUE)
  regmatches(y, urls) <- lapply(regmatches(y, urls), function(values) vapply(values, function(value) {
    tryCatch({
      u <- httr2::url_parse(value)
      u$username <- u$password <- u$fragment <- NULL
      if (length(u$query)) u$query <- u$query[!vapply(names(u$query), .sensitive_name, logical(1))]
      httr2::url_build(u)
    }, error = function(e) "[URL_REDACTED]")
  }, ""))
  y <- gsub("(?i)(/home/|/tmp/|(?<![A-Za-z0-9])[A-Za-z]:[/\\\\])[^\\s,;]+", "[LOCAL_PATH]", y, perl = TRUE)
  y
}

.payload_sanitize <- function(x, policy, name = "") {
  if (.sensitive_name(name) && !isTRUE(policy$allow_sensitive_labels)) return(NULL)
  if (is.data.frame(x)) {
    keep <- isTRUE(policy$allow_sensitive_labels) | !vapply(names(x), .sensitive_name, logical(1))
    x <- x[, keep, drop = FALSE]
    if (ncol(x)) x[] <- lapply(x, function(v) .payload_sanitize(v, policy))
    return(x)
  }
  if (is.list(x)) {
    out <- list()
    nms <- names(x)
    for (i in seq_along(x)) {
      nm <- if (is.null(nms)) "" else nms[i]
      val <- .payload_sanitize(x[[i]], policy, nm)
      if (!is.null(val)) {
        out[length(out) + 1L] <- list(val)
        if (!is.null(nms)) names(out)[length(out)] <- nm
      } else if (is.null(nms)) out[length(out) + 1L] <- list(NULL)
    }
    return(out)
  }
  if (!is.null(names(x)) && !isTRUE(policy$allow_sensitive_labels)) x <- x[!vapply(names(x), .sensitive_name, logical(1))]
  .sensitive_value(x)
}

.payload_metadata <- function(metadata, policy) {
  if (!length(metadata)) return(list())
  allowed <- policy$metadata_allowlist
  out <- metadata[names(metadata) %in% allowed]
  .payload_sanitize(out, policy)
}

#' Define an explicit model payload policy
#'
#' @param max_top Maximum number of preview rows.
#' @param max_chars UTF-8 character budget for the complete payload.
#' @param include_features Whether preview rows may be included.
#' @param fact_mode Either \code{"complete"} or explicit \code{"chunked"}.
#' @param max_fact_items Maximum items retained per fact in chunked mode.
#' @param metadata_allowlist Metadata keys permitted in a model payload.
#' @param allow_sensitive_labels Whether keys that look like identifiers may pass.
#' @return A \code{bio_payload_policy} object.
#' @export
bio_payload_policy <- function(max_top = 10, max_chars = 12000, include_features = TRUE,
                               fact_mode = c("complete", "chunked"), max_fact_items = 20,
                               metadata_allowlist = c("species", "tissue", "contrast", "gene_id_type",
                                                       "design", "background", "source_package", "notes",
                                                      "data_dependencies", "analysis_type_hint", "coefficient"),
                               allow_sensitive_labels = FALSE) {
  fact_mode <- match.arg(fact_mode)
  whole <- function(x, label) {
    if (!is.numeric(x) || length(x) != 1L || is.na(x) || !is.finite(x) || x < 0 || x > .Machine$integer.max || x != floor(x))
      stop(label, " must be a finite non-negative whole number.", call. = FALSE)
    as.integer(x)
  }
  max_top <- whole(max_top, "max_top")
  max_fact_items <- whole(max_fact_items, "max_fact_items")
  if (!is.numeric(max_chars) || length(max_chars) != 1L || is.na(max_chars) ||
      !is.finite(max_chars) || max_chars < 1 || max_chars > .Machine$integer.max) stop("max_chars must be positive and finite within the integer range.", call. = FALSE)
  if (!is.logical(include_features) || length(include_features) != 1L || is.na(include_features))
    stop("include_features must be TRUE or FALSE.", call. = FALSE)
  if (!is.logical(allow_sensitive_labels) || length(allow_sensitive_labels) != 1L || is.na(allow_sensitive_labels))
    stop("allow_sensitive_labels must be TRUE or FALSE.", call. = FALSE)
  out <- structure(list(max_top = max_top, max_chars = as.integer(max_chars),
                        include_features = include_features, fact_mode = fact_mode,
                        max_fact_items = max_fact_items,
                        metadata_allowlist = unique(as.character(metadata_allowlist)),
                        allow_sensitive_labels = allow_sensitive_labels,
                        schema_version = .bio_schema_version), class = "bio_payload_policy")
  out$policy_id <- .hash_object(out)
  out
}

#' @export
print.bio_payload_policy <- function(x, ...) {
  cat("<bio_payload_policy> ", x$policy_id, " [", x$fact_mode, "]\n", sep = "")
  invisible(x)
}

.fact_descriptors <- function(facts, prefix = character()) {
  out <- list()
  for (nm in names(facts) %||% character()) {
    value <- facts[[nm]]
    path <- c(prefix, nm)
    key <- paste(path, collapse = ".")
    if (is.list(value) && !is.data.frame(value) && length(value) &&
        !is.null(names(value))) out <- c(out, .fact_descriptors(value, path))
    else out[[key]] <- list(value_type = if (is.numeric(value)) "number" else typeof(value),
                            source_path = key, computation = "adapter_defined",
                            inspection = "full_fact", completeness = "complete")
  }
  out
}

.finalize_context <- function(ctx) {
  if (is.null(ctx$schema_version)) ctx$schema_version <- "legacy"
  if (is.null(ctx$scope)) ctx$scope <- list()
  if (is.null(ctx$design)) ctx$design <- list()
  if (is.null(ctx$fact_descriptors) || !length(ctx$fact_descriptors))
    ctx$fact_descriptors <- .fact_descriptors(ctx$facts)
  ctx$facts_hash <- .hash_object(ctx$facts)
  semantic <- ctx
  semantic$context_id <- NULL
  semantic$created <- NULL
  if (length(semantic$provenance)) semantic$provenance$created <- NULL
  ctx$context_id <- .hash_object(semantic)
  ctx
}

#' Build a versioned manifest for a context, payload and model call
#'
#' @param ctx A \code{bio_context}.
#' @param payload Optional actual model payload.
#' @param request Optional request body or request manifest.
#' @param response Optional saved response representation.
#' @param run_id Identifier for the calling run.
#' @param status Call status.
#' @param request_hash Hash captured from the final request body, when available.
#' @param response_hash Hash captured from the parsed response, when available.
#' @param ... Additional public metadata such as model and usage.
#' @return A \code{bio_manifest} list.
#' @export
bio_context_manifest <- function(ctx, payload = NULL, request = NULL, response = NULL,
                                 run_id = NULL, status = "not_run", request_hash = NULL,
                                 response_hash = NULL, ...) {
  stopifnot(inherits(ctx, "bio_context"))
  # A legacy object has no recorded identity; do not invent one on read.
  if (is.null(payload)) payload <- bio_context_payload(ctx)
  clean_request <- if (is.null(request)) NULL else .payload_sanitize(request,
    bio_payload_policy(max_top = 0, max_chars = 1e8, metadata_allowlist = character(),
                        allow_sensitive_labels = FALSE))
  clean_response <- if (is.null(response)) NULL else bio_redact(.canonical_json(response))
  extra <- list(...)
  public <- c("model", "provider", "model_requested", "model_reported", "provider_host",
              "usage", "elapsed_sec", "attempt", "config_version", "failure_reason",
              "request_bytes", "request_hash_scope", "response_hash_scope")
  extra <- .payload_sanitize(extra[names(extra) %in% public], bio_payload_policy())
  out <- c(list(manifest_version = "1.0", run_id = run_id %||% paste0("run-", format(Sys.time(), "%Y%m%d%H%M%S")),
                context_id = ctx$context_id, facts_hash = ctx$facts_hash,
                payload_hash = attr(payload, "payload_hash") %||% .hash_object(payload),
                request_hash = request_hash %||% if (is.null(clean_request)) NULL else .hash_object(clean_request),
                response_hash = response_hash %||% if (is.null(clean_response)) NULL else .sha256(clean_response),
                schema_version = ctx$schema_version, serialization_version = .bio_serialization_version,
                numeric_policy = list(digits = 17, na = "null", null = "null"),
                policy_id = attr(payload, "policy_id") %||% NULL, created = .now(), status = status), extra)
  structure(out, class = "bio_manifest")
}

#' @export
print.bio_manifest <- function(x, ...) {
  cat("<bio_manifest> ", x$run_id, " status=", x$status, "\n", sep = "")
  invisible(x)
}
