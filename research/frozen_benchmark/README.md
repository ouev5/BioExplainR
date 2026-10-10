# Frozen benchmark infrastructure

This directory contains the W09 offline runner and audit contracts. It is
infrastructure, not a completed scientific evaluation. Public inputs must not
contain gold labels, expert ratings, adjudications or method names that reveal
the intended answer. The controlled gold directory is represented by a local
fixture only. The runner never reads it; scoring is a separate explicitly
invoked process. The runner is not an operating-system sandbox.

The runner supports `dry-run` and `replay` by default. Live model calls require
an explicit external controller and must write request/response hashes and
failure statuses. A missing gold file produces `unverified`; it never produces
accuracy or a successful score.

Example offline checks from the project root:

```sh
Rscript --vanilla research/frozen_benchmark/run_claim_benchmark.R \
  --mode=dry-run --input=research/frozen_benchmark/fixtures/cases.json \
  --output=/tmp/opencode/bioexplainr-benchmark-new
Rscript --vanilla research/frozen_benchmark/audit_benchmark.R \
  --manifest=/tmp/opencode/bioexplainr-benchmark-new/benchmark_manifest.json
python3 research/test_frozen_benchmark.py
```

The fixture is a protocol test. It does not estimate model quality, biological
generalisation, user benefit or evidence semantics.

Run directories are immutable. Replay accepts `--mode=replay --replay=<CSV>`
with unique `case_id,prediction` rows matching public cases. Missing predictions
remain unanswered; absent replay remains missing_replay. Audits verify artifact
hashes, case/method keys, statuses and missing-gold semantics and exit nonzero
on failure. Controlled scoring reads explicit calls/gold CSV paths in a separate
process and refuses duplicate or missing references. No scientific accuracy is
reported by the runner or audit.
