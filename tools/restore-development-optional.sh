#!/usr/bin/env bash
# Restore the observed W13 optional adapter dependencies after the W00 baseline.
set -euo pipefail
root_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if [[ "${1:-}" != "--verify-only" ]]; then
  sudo env DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=l apt-get install -y --no-install-recommends \
    r-bioc-multiassayexperiment=1.28.0+dfsg-1 \
    r-cran-rjson=0.2.21-1 r-cran-magick=2.8.2+dfsg-1build3 r-bioc-biocfilecache=2.10.1+dfsg-1
  archive="$root_dir/research/results/w00_baseline/SpatialExperiment_1.12.0.tar.gz"
  [[ -f "$archive" ]] || { printf '%s\n' 'Restore the saved SpatialExperiment 1.12.0 source archive first.' >&2; exit 1; }
  actual=$(sha256sum "$archive")
  [[ "${actual%% *}" == "c49efa705e32d385b9bdcf3f8d205bf4e55cb1016ed59f0614c6b892f09782e8" ]] || { printf '%s\n' 'SpatialExperiment source SHA-256 mismatch.' >&2; exit 1; }
  sudo R CMD INSTALL "$archive"
fi
Rscript --vanilla -e 'stopifnot(requireNamespace("MultiAssayExperiment", quietly=TRUE), requireNamespace("SpatialExperiment", quietly=TRUE)); stopifnot(packageVersion("MultiAssayExperiment") == "1.28.0", packageVersion("SpatialExperiment") == "1.12.0"); print(sessionInfo())'
