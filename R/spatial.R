# Explicit spatial neighbor construction --------------------------------------

#' Construct a bounded spatial neighbor graph
#'
#' Coordinates are interpreted in their declared units. Sections are never
#' connected unless the caller explicitly sets \code{cross_section = TRUE}.
#' This helper computes a graph only; it does not infer tissue masks or a
#' biological mechanism.
#'
#' @param coords Numeric matrix/data.frame with at least two coordinate columns.
#' @param mode \code{"knn"} or \code{"radius"}.
#' @param k Number of nearest neighbors per observation for kNN mode.
#' @param radius Maximum distance for radius mode.
#' @param section Optional section/slide identifier per observation.
#' @param units Coordinate units recorded in the result.
#' @param cross_section Whether edges may cross section identifiers.
#' @return A \code{bio_spatial_neighbors} object with an edge table.
#' @export
bio_spatial_neighbors <- function(coords, mode = c("knn", "radius"), k = 6,
                                  radius = NULL, section = NULL, units = NULL,
                                  cross_section = FALSE) {
  mode <- match.arg(mode)
  z <- as.matrix(coords)
  if (!is.numeric(z) || ncol(z) < 2L || !nrow(z)) stop("coords must be a non-empty numeric table with at least two columns.", call. = FALSE)
  if (any(!is.finite(z))) stop("coords must contain only finite values.", call. = FALSE)
  n <- nrow(z)
  if (!is.logical(cross_section) || length(cross_section) != 1L || is.na(cross_section)) stop("cross_section must be TRUE or FALSE.", call. = FALSE)
  if (n > 10000L) stop("Refusing a dense neighbor computation for more than 10000 observations; provide an existing graph or a sparse implementation.", call. = FALSE)
  if (is.null(section)) section <- rep("section_1", n)
  section <- as.character(section)
  if (length(section) != n || anyNA(section) || any(!nzchar(section))) stop("section must have one non-missing value per coordinate row.", call. = FALSE)
  if (mode == "knn") {
    if (!is.numeric(k) || length(k) != 1L || is.na(k) || !is.finite(k) || k < 1 || k != floor(k)) stop("k must be a positive whole number.", call. = FALSE)
    k <- min(as.integer(k), n - 1L)
  } else {
    if (!is.numeric(radius) || length(radius) != 1L || is.na(radius) || !is.finite(radius) || radius <= 0) stop("radius must be positive and finite.", call. = FALSE)
  }
  from <- integer(); to <- integer(); distance <- numeric()
  for (i in seq_len(n)) {
    same <- if (isTRUE(cross_section)) rep(TRUE, n) else section == section[i]
    same[i] <- FALSE
    d <- sqrt(rowSums((z - matrix(z[i, ], nrow = n, ncol = ncol(z), byrow = TRUE))^2))
    keep <- which(same & is.finite(d))
    if (mode == "knn" && length(keep)) keep <- keep[order(d[keep], keep)][seq_len(min(k, length(keep)))]
    if (mode == "radius") keep <- keep[d[keep] <= radius]
    if (length(keep)) {
      from <- c(from, rep.int(i, length(keep))); to <- c(to, keep); distance <- c(distance, d[keep])
    }
  }
  edges <- data.frame(from = from, to = to, distance = distance,
                      from_section = section[from], to_section = section[to], stringsAsFactors = FALSE)
  structure(list(edges = edges, mode = mode, k = if (mode == "knn") k else NULL,
                 radius = if (mode == "radius") radius else NULL, units = units %||% NA_character_,
                 cross_section = isTRUE(cross_section), n_observations = n,
                 note = "Neighbor edges are geometric and do not establish spatial biological dependence."),
            class = "bio_spatial_neighbors")
}

#' @export
print.bio_spatial_neighbors <- function(x, ...) {
  cat("<bio_spatial_neighbors> ", x$n_observations, " observations, ", nrow(x$edges), " directed edges [", x$mode, "]\n", sep = "")
  invisible(x)
}
