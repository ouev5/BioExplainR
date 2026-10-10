# Formal common-task benchmark

Read `PROTOCOL.md` and `IMPLEMENTATION.md`. The completed run is
`../results/common_performance_v4/`; previous v1–v3 attempts are preserved as
interrupted/failed and excluded from formal scores. The report is
`../../docs/research_followup_v1/README.md`.

Five methods × 24 tasks × three repeats = 360 runs, 1,800 target scores.
BioExplainR offline/base R/ellmer-facts/BioExplainR-facts each matched 360/360;
ellmer-table matched 8/360 with 175/360 coverage, zero all-correct runs and
37 actual timeouts. All 200-row direct-table requests timed out. This describes
a fixed, known-development counting/transmission task on the specified small
CPU model and 180-second budget, not comprehensive tool quality or general reasoning.

`audit_benchmark.py` independently recomputes source counts, strict JSON parsing,
HTTP parameters/prompt identity, scores, tokens, timing and paired bootstrap.
`audit_selection.py` checks rows against the original saved source tables;
`audit_supplemental_scores.py` checks size breakdown/task-all-correct intervals.
`test_scoring_boundaries.py` probes duplicate keys, truncation and full denominators.

Exact model/runtime/source restoration uses `restore_formal_runtime.py` and the
saved runtime manifest. ellmer 0.5.0 is required in the isolated library;
`install_comparator.R` documents the original local libcurl build setup. To run
again use a new output directory with `run_benchmark.py`; never reuse completed
model responses as new inference.
