# Discovery candidate and external experiment

## New genome-wide biological analysis (2026-10-09)

Read [the biological results report](../../docs/biology_discovery_v2/README.md).
`GENOME_PROTOCOL.md`, `RESPONSE_PROTOCOL.md` and `RESPONSE_TIME_AMENDMENT.md`
define the new exploratory work. Saved runs: `discovery_genome_v2/` (82,227
interaction tests, none pass pooled BH) and `discovery_stable_response_v1/`
(54 genes retained across four ASM contexts, fixed top12; 11 measurable genes
repeat in 13 paired donors after removing three known overlapping lines).
PER2 has short-term A549 induction sensitive to GR perturbations, later decline,
and late ASM repression. Direct time contrasts were tested. This motivates
temporal/context hypotheses, not a tissue-specific causal or first-clock claim.
Actual BioExplainR nine-context projects, v2 bilingual reports, original-data
R/Python numeric checks, five vector PDF/PNG figures and a seven-page Chinese
Word/PDF/HTML results report are saved. LINC00607 missing external annotation and
TEF microarray non-replication remain explicit. Old SPARCL1 analyses below are
historical inputs, not newly generated evidence.

## Formal receptor and ChIP follow-up (2026-10-09)

Read `MECHANISM_PROTOCOL.md` and `../../docs/research_followup_v1/README.md`.
Saved fit: `../results/discovery_mechanism_fit_v4/` (A549, SPARCL1 failed fixed filter;
three candidate interactions not estimable). Saved ChIP inputs/analysis:
`discovery_chip_v1/`, `discovery_chip_analysis_v1/` (coordinate-verified hg19,
GEO mm9 conflict retained, author confirmation absent). Python/R independently
checked original counts/design/WLS and all RefSeq windows/peaks/replicate overlaps.
Published peak overlap is not a differential occupancy or direct regulatory test.

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

## Candidate follow-up (v0.10)

Read `CONTEXT_PROTOCOL.md`, `DONOR_PROTOCOL.md` and `DONOR_DESIGN_AMENDMENT.md`.
The saved runs are `../results/discovery_context_v1/` (GSE146017 factorial counts)
and `../results/discovery_donors_v1/` (GSE94335 paired TPM, verified against the
original Supplement Table E1). All 16 paired donors have positive SPARCL1 responses;
the disease-group difference and three prespecified interactions are unsupported.
At least three culture cell lines are shared between these two experiments, so
their donor counts are not pooled. `scientific_ledger.json` preserves these limits.

The r11 delivery includes the full fitted count model, results, bilingual reports,
protocols and original pairing evidence. Only the 121,575,832-byte raw TPM gzip is
excluded. The ZIP's `delivery_manifest.json` lists its URL, exact SHA-256 and
download command under `excluded_inputs`. Its `--preserve-report` flag restores a
missing input, verifies the recorded SHA-256 and retains the historical download
report byte-for-byte. Existing saved runs and
their sealed manifests should not be overwritten during new analyses.
