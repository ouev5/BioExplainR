# Start the optional BioExplainR local browser workbench.
# Install once with: install.packages(c("shiny", "ggplot2"))
# Add uwot if you want BioExplainR to calculate UMAP from an expression matrix.

library(BioExplainR)

# Objects already present in this environment are copied into the browser
# session. The code console can then call the upstream packages you use.
bio_run_app(envir = environment())
