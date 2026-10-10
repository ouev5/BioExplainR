"""Check the scientific outcome ledger and seal both follow-up directories."""
import csv
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]


def table(p):
    with p.open(newline="") as f: return list(csv.DictReader(f))


def record(p):
    return {"path": p.name, "bytes": p.stat().st_size, "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}


def verify(out):
    for r in json.loads((out / "input_manifest.json").read_text())["inputs"]:
        assert record(out / r["path"]) == {k: r[k] for k in ["path", "bytes", "sha256"]}
    assert json.loads((out / "audit.json").read_text())["status"] == "pass"


def main():
    context = ROOT / "research/results/discovery_context_v1"
    donors = ROOT / "research/results/discovery_donors_v1"
    verify(context); verify(donors)
    ms = table(context / "model_results.csv")
    interactions = [r for r in ms if r["symbol"] == "SPARCL1" and r["holm_candidate_interactions"]]
    assert len(interactions) == 3 and all(float(r["holm_candidate_interactions"]) >= .05 for r in interactions)
    results = table(donors / "results.csv")
    assert [(int(r["n_donors_a"]), int(r["positive_donors"])) for r in results[:2]] == [(7, 7), (9, 9)]
    assert all(float(r["holm_three_tests"]) < .05 and float(r["permutation_p"]) < .05 for r in results[:2])
    assert float(results[2]["holm_three_tests"]) >= .05
    dm = table(donors / "donor_effects.csv")
    candidate = [r for r in dm if r["symbol"] == "SPARCL1"]
    assert len(candidate) == 16 and all(float(r[f"effect_pc{pc}"]) > 0 for r in candidate for pc in [1, .5, .1])
    donor_ids = {r["donor"] for r in table(donors / "samples.csv")}
    context_ids = {r["donor"] for r in table(context / "samples.csv")}
    overlap = sorted(donor_ids & context_ids)
    assert overlap == ["N010912", "N051911", "N061311"]
    novelty = []
    for run, filename in [(context, "PMC4057123.xml"), (donors, "PMC6604213.xml")]:
        tree = ET.parse(run / filename)
        hits = [" ".join(r.itertext()) for r in tree.iter("tr") if "SPARCL1" in " ".join(r.itertext())]
        assert hits
        novelty.append({"source": filename, "original_table_rows": hits})
    for name in ["followup_report_zh_v2.html", "followup_report_en_v2.html"]:
        text = (context / name).read_text()
        assert all(s in text for s in ["GSE94335", "GSE146017", "SPARCL1", "interaction_supported"])
    ledger = {"status": "pass", "finished_utc": datetime.now(timezone.utc).isoformat(),
        "candidate": "SPARCL1", "positive_paired_donors": 16,
        "candidate_interactions_supported": 0, "asthma_response_difference_supported": False,
        "named_donor_overlap_between_followups": overlap, "do_not_pool_independent_donors": True,
        "novelty": "response already published; new donor distribution and null-interaction reanalysis, not first mechanistic discovery",
        "original_evidence": novelty,
        "pseudocount_direction_sensitivity": {str(pc): {g: sum(float(r[f"effect_pc{pc}"]) for r in candidate if r["disease"] == g)/sum(r["disease"] == g for r in candidate)
            for g in ["non_asthma", "fatal_asthma"]} for pc in [1, .5, .1]},
        "implementation": "R independent TPM/paired/t/Welch/exact/Holm; Python count-model algebra and donor sensitivity, not independent DESeq2 fit"}
    (context / "scientific_ledger.json").write_text(json.dumps(ledger, ensure_ascii=False, indent=2)+"\n")
    for out in [context, donors]:
        files = [record(p) for p in sorted(out.iterdir()) if p.is_file() and p.name != "files_manifest.json"]
        (out / "files_manifest.json").write_text(json.dumps({"files": files, "partial_transport_artifacts": "Not used as scientific input; chunk directories excluded"}, indent=2)+"\n")
    print(json.dumps({k: v for k, v in ledger.items() if k != "original_evidence"}, indent=2))


if __name__ == "__main__": main()
