#!/usr/bin/env bash
# Restore the observed W00 Ubuntu 24.04 package selection, with recorded versions.
set -euo pipefail
root_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
snapshot="$root_dir/research/results/w00_baseline/system_packages.tsv"
[[ -f "$snapshot" ]] || { printf '%s\n' 'The W00 system package snapshot is missing.' >&2; exit 1; }
packages=(r-base r-base-dev r-cran-jsonlite r-cran-httr2 r-cran-testthat r-cran-pkgload
  r-cran-roxygen2 r-cran-callr r-cran-withr r-cran-ggplot2 r-cran-shiny r-cran-rlang
  r-cran-digest r-bioc-s4vectors r-bioc-summarizedexperiment r-bioc-singlecellexperiment
  r-bioc-biobase r-bioc-deseq2 r-bioc-limma r-bioc-edger r-cran-seuratobject r-cran-uwot
  r-bioc-biocversion r-cran-biocmanager pandoc python3-venv python3-docx python3-openpyxl
  python3-pil python3-matplotlib)
pinned=()
for wanted in "${packages[@]}"; do
  selected=''
  while IFS=$'\t' read -r package version; do
    if [[ "$package" == "$wanted" ]]; then selected="$package=$version"; break; fi
  done < "$snapshot"
  [[ -n "$selected" ]] || { printf 'Missing observed version: %s\n' "$wanted" >&2; exit 1; }
  pinned+=("$selected")
done
if [[ "${1:-}" == "--print" ]]; then
  printf '%s\n' "${pinned[@]}"
  exit 0
fi
sudo env DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=l apt-get install -y --no-install-recommends "${pinned[@]}"
workspace="${BIOEXPLAINR_TOOL_ENV:-/tmp/opencode}"
mkdir -p "$workspace"
python3 -m venv "$workspace/paper-venv"
"$workspace/paper-venv/bin/pip" install -r "$root_dir/tools/paper-requirements.txt"
npm install --prefix "$workspace" playwright@1.56.1 pngjs@7.0.0
bash "$root_dir/tools/server-R" --version
