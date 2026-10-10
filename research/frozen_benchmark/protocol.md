# W09 benchmark protocol template

Status: infrastructure template; no final independent test set or labels have
been collected. Before a live run, the study owner must fill in the protocol
version, data sources, primary endpoint, denominator, missing-response rule,
model budget, evidence snapshot, reviewer process and analysis plan.

## Required freeze

- `dataset_id`, `study_id`, release/accession, download hash and independence
  cluster;
- dev/validation/test split and the date/hash at which the test set is frozen;
- case, claim, evidence-pair and repeat IDs;
- method name, model actually reported by the provider, prompt hash, JSON mode,
  retry count, revision budget and maximum cost;
- gold reference location outside the runner input and its separate hash;
- primary endpoint, coverage floor, case-level clustering and confidence
  interval method.

## Input and gold separation

Runner inputs contain only the question, facts and candidate evidence. Gold
labels and adjudications remain in a controlled location. A method cannot read
the gold directory, and the public manifest contains only a redacted reference
or `missing`.

## Planned endpoints

The final protocol may report fixed-claim error rate, required-answer
completion, all-target accuracy, answered accuracy, unsupported-claim rate,
claim extraction recall, support precision/recall, false-pass and cost. Case or
dataset is the inferential cluster; repeated calls and claims from one object
are not independent biological samples.

No threshold in the roadmap is a software pass condition. If a target is not
met, the recorded result remains unchanged and is reported as such.
