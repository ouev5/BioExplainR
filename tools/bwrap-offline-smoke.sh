#!/usr/bin/env bash
# Run an installed-package smoke with user/network namespaces and read-only root.
set -euo pipefail
output=${1:-/tmp/opencode/bioexplainr-bwrap-smoke}
library_path=${2:-/tmp/opencode/bioexplainr-continuation-core-final/library}
uid=$(id -u)
gid=$(id -g)
mkdir -p "$output"
[[ -d "$library_path/BioExplainR" ]] || { printf '%s\n' "Installed BioExplainR library is missing: $library_path" >&2; exit 1; }
sudo -n bwrap --unshare-user --unshare-net --die-with-parent --new-session \
  --ro-bind / / --ro-bind "$library_path" /usr/local/lib/R/site-library --tmpfs /tmp --proc /proc --dev /dev \
  --uid "$uid" --gid "$gid" --cap-drop ALL -- \
  env R_LIBS_SITE=/usr/local/lib/R/site-library R_LIBS_USER=/usr/local/lib/R/site-library \
  /usr/bin/Rscript --vanilla -e "library(BioExplainR); bio_configure('local'); x <- bio_context(data.frame(log2FoldChange=c(2,-2,.1), padj=c(.01,.02,.8))); e <- bio_explain(x,use_llm=FALSE); stopifnot(identical(e\$context\$context_id,x\$context_id)); report <- tempfile(fileext='.html'); bio_report(e,file=report); stopifnot(file.exists(report), file.info(report)\$size > 0); cat(R.version.string,'\\nnetwork_namespace=unshared\\nstatus=pass\\n')" > "$output/status.txt"
printf '%s\n' "bwrap offline smoke passed; output: $output/status.txt"
