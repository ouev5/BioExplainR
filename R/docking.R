# External structural result parser and audit context ---------------------------

.docking_required <- c("receptor", "ligand", "score")

.read_docking_table <- function(x) {
  if (is.data.frame(x)) return(x)
  if (!is.character(x) || length(x) != 1L || !file.exists(x)) stop("result must be a data.frame or an existing table path.", call. = FALSE)
  ext <- tolower(tools::file_ext(x))
  if (ext == "csv") utils::read.csv(x, stringsAsFactors = FALSE, check.names = FALSE)
  else utils::read.delim(x, stringsAsFactors = FALSE, check.names = FALSE)
}

.docking_col <- function(df, aliases) .find_col(df, aliases)

#' Parse a docking result table into a traceable context
#'
#' The parser reads tabular results and never runs an external docking engine.
#' Missing provenance remains explicit and prevents a mechanism-level pass.
#'
#' @param result Data frame or CSV/TSV path.
#' @param engine Engine name.
#' @param engine_version Engine version, if known.
#' @param receptor,ligand,score Optional column names.
#' @param provenance Structure/source metadata and file hashes.
#' @param species Species declaration.
#' @param ... Additional metadata.
#' @return A \code{bio_context} of type \code{"docking"}.
#' @export
bio_docking_context <- function(result, engine = NULL, engine_version = NULL,
                                 receptor = NULL, ligand = NULL, score = NULL,
                                 provenance = list(), species = NULL, ...) {
  tab <- .read_docking_table(result)
  receptor <- receptor %||% .docking_col(tab, c("receptor", "receptor_id", "target", "protein"))
  ligand <- ligand %||% .docking_col(tab, c("ligand", "ligand_id", "compound", "molecule"))
  score <- score %||% .docking_col(tab, c("score", "affinity", "binding_affinity", "energy"))
  cols <- list(receptor = receptor, ligand = ligand, score = score)
  miss <- names(cols)[vapply(cols, function(v) is.null(v) || length(v) != 1L || is.na(v) || !v %in% names(tab), logical(1))]
  if (length(miss)) stop("Docking table is missing required columns: ", paste(miss, collapse = ", "), call. = FALSE)
  vals <- suppressWarnings(as.numeric(tab[[score]]))
  facts <- list(n_poses = nrow(tab), n_receptors = length(unique(as.character(tab[[receptor]]))),
                n_ligands = length(unique(as.character(tab[[ligand]]))), score_column = score,
                 score_range = if (any(is.finite(vals))) range(vals[is.finite(vals)]) else c(NA_real_, NA_real_),
                score_direction = provenance$score_direction %||% NA_character_,
                pose_column = .docking_col(tab, c("pose", "pose_id")),
                cluster_column = .docking_col(tab, c("cluster", "cluster_id")),
                rmsd_column = .docking_col(tab, c("rmsd", "rmsd_to_reference")),
                contact_column = .docking_col(tab, c("contacts", "contact_residues")))
  source_hash <- provenance$source_hash
  if (is.character(result) && file.exists(result)) source_hash <- source_hash %||% .sha256(readBin(result, "raw", file.info(result)$size))
  prov <- utils::modifyList(list(engine = engine %||% NA_character_, engine_version = engine_version %||% NA_character_,
                                 source_hash = source_hash %||% NA_character_, result_format = "tabular",
                                 parser = "BioExplainR::bio_docking_context"), provenance)
  unc <- c(if (is.null(engine)) "Docking engine was not declared." else NULL,
           if (is.null(engine_version)) "Docking engine version was not declared." else NULL,
           if (is.na(facts$score_direction)) "Score direction was not declared; scores cannot be compared or ranked mechanistically.",
           if (is.null(facts$rmsd_column)) "No RMSD/reference-conformation column was supplied.",
           "Parsing a score table does not establish physical binding, mechanism, specificity or biological effect.")
  direction <- provenance$score_direction %||% "unknown"
  top <- if (direction %in% c("lower", "lower_is_better")) tab[order(vals, na.last = NA), , drop = FALSE] else
    if (direction %in% c("higher", "higher_is_better")) tab[order(vals, decreasing = TRUE, na.last = NA), , drop = FALSE] else tab
  top <- utils::head(top, 10)
  new_bio_context("docking", class(tab), "BioExplainR", "user_declared", facts = facts,
                  top_features = top, metadata = c(list(species = species), list(...)),
                  provenance = prov, uncertainty = unc)
}

#' Audit required provenance fields for a docking context
#'
#' @param ctx A docking context.
#' @return A validation result.
#' @export
bio_docking_audit <- function(ctx) {
  stopifnot(inherits(ctx, "bio_context"), identical(ctx$analysis_type, "docking"))
  p <- ctx$provenance
  known <- function(v) !is.null(v) && length(v) == 1L && !is.na(v) && nzchar(as.character(v)) && v != "unknown"
  rows <- data.frame(check = c("engine", "engine_version", "source_hash", "score_direction", "score_unit", "rmsd_reference", "controls"),
                     status = c(if (!is.na(p$engine %||% NA)) "pass" else "unverified",
                                if (!is.na(p$engine_version %||% NA)) "pass" else "unverified",
                                if (!is.na(p$source_hash %||% NA)) "pass" else "unverified",
                                 if (ctx$facts$score_direction %in% c("lower", "lower_is_better", "higher", "higher_is_better")) "pass" else "unverified",
                                 if (known(p$score_unit)) "pass" else "unverified",
                                 if (!is.null(ctx$facts$rmsd_column) && known(p$rmsd_reference)) "pass" else "unverified",
                                 if (known(p$controls) && ctx$facts$n_poses > 1) "pass" else "unverified"),
                      detail = c("engine identity", "engine version", "source file hash", "score direction", "score unit",
                                 "RMSD reference definition", "declared controls; not a mechanism check"), stringsAsFactors = FALSE)
  structure(list(status = if (any(rows$status == "unverified")) "partial" else "pass", findings = rows),
            class = "bio_docking_audit")
}
