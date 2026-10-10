# Discovery candidate and external experiment

Read `PROTOCOL.md` first. The saved run is `../results/discovery_sparcl1_v1/`.
The candidate was ranked using only the discovery DESeq2 table, then frozen before
reading the candidate's external expression or testing. GEO metadata and the
original paper were examined for feasibility before freeze; this is not a registry
preregistration. New runs require a new directory.

```sh
python3 -m pip install -r research/discovery/requirements.txt
python3 research/discovery/run_discovery.py freeze research/results/discovery_new
python3 research/discovery/run_discovery.py validate research/results/discovery_new
Rscript --vanilla research/discovery/audit_and_report.R research/results/discovery_new
```

`run_discovery.py` downloads complete CRC-verified public GEO inputs, includes every
exact-symbol probe and every published array, and computes prespecified contrasts.
`audit_and_report.R` independently recomputes Welch tests/CI and permutation values,
then creates actual BioExplainR contexts, project and bilingual offline reports.
`audit_saved.py` verifies file hashes and rederives measurements from the gzip matrix,
probe selection from annotation and numerical results from the full saved input.

The primary SPARCL1 contrast is positive. External arrays come from one HASM1 cell
line, so this is an external experimental reanalysis with culture replicates, not
a donor-independent clinical cohort. The candidate's extracellular-matrix function
is a hypothesis for future GR/SPARCL1 perturbation experiments. Neither first
discovery nor causal/protein validation is claimed.
