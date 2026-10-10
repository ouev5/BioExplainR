"""Correct all-member HBEC protein identity, retaining the first frozen analysis."""
import argparse
from collections import defaultdict
import json
import math
from pathlib import Path
import re

import epithelial_protein as analysis
from validation_sources import ROOT, record, utc, json_out, csv_out

INITIAL = analysis.OUT
FINAL = INITIAL / "complete"
NEW_CODE = ["EPITHELIAL_IDENTITY_AMENDMENT.md", "epithelial_identity.py",
            "audit_epithelial_identity.R", "report_epithelial_identity.R", "finish_epithelial_identity.py"]


def revised_hbec():
    raw = analysis.rows(analysis.HBEC,"\t")
    exact, canonical = defaultdict(set), defaultdict(set)
    for row in raw:
        for part in row["Fasta.headers"].split(";"):
            match = re.match(r"^(NX_\S+)\s+\S+\s+(\S+)\s+",part.strip())
            if match:
                exact[match[1]].add(match[2])
                canonical[re.sub(r"-\d+$","",match[1])].add(match[2])
    samples = analysis.rows(FINAL / "HBEC_samples.csv")
    base, _ = ORIGINAL_HBEC()
    details = []
    for d, r in zip(base,raw):
        assert r["Protein.IDs"] == d["protein_ids"]
        names, unresolved = set(), []
        for accession in r["Protein.IDs"].split(";"):
            match = exact.get(accession,set())
            if not match:
                match = canonical.get(re.sub(r"-\d+$","",accession),set())
            if not accession.startswith("NX_") or len(match)!=1:
                unresolved.append(accession)
            names |= match
        complete = not unresolved and len(names)==1 and names=={d["gene"]}
        old = d["qc"]
        if old and not complete:
            d["qc"] = False
            d["reason"] = "unresolved_all_member_identity" if unresolved else "mixed_all_member_identity"
        details.append(dict(source_row=d["source_row"], protein_ids=r["Protein.IDs"],
            majority_protein_ids=r["Majority.protein.IDs"], header_gene=d["gene"],
            all_member_genes="|".join(sorted(names)), unresolved_ids="|".join(unresolved),
            initial_qc=old, final_qc=d["qc"], final_reason=d["reason"]))
    csv_out(FINAL / "HBEC_all_member_identity.csv",details)
    json_out(FINAL / "identity_index.json",dict(exact={k:sorted(v) for k,v in sorted(exact.items())},
        canonical={k:sorted(v) for k,v in sorted(canonical.items())}))
    return base,samples


ORIGINAL_HBEC = analysis.hbec_table


def freeze():
    if FINAL.exists():
        raise ValueError("Refusing overwrite final results")
    first = analysis.check_freeze()
    FINAL.mkdir()
    for name in ["frozen_genes.csv","HBEC_samples.csv","rgo_before_epithelial.md"]:
        (FINAL/name).write_bytes((INITIAL/name).read_bytes())
    code = first["source_code"]+[record(analysis.HERE/n) for n in NEW_CODE]
    superseded = [record(p) for p in sorted(INITIAL.iterdir()) if p.is_file()]
    json_out(FINAL / "analysis_freeze.json",dict(utc=utc(),prior=first["prior"],inputs=first["inputs"]+superseded,
        source_code=code,genes=record(FINAL/"frozen_genes.csv"),samples=record(FINAL/"HBEC_samples.csv"),
        snapshot=record(FINAL/"rgo_before_epithelial.md"),
        superseded_files=superseded,
        timing="All first-pass results known; systematic all-member identity correction before corrected reanalysis; exploratory, not blinded",
        family_sizes=first["family_sizes"],online_model_calls=0,author_contact=False,PXD055968="skipped_by_user"))
    print("Frozen complete Protein.IDs identity correction; first outputs retained")


def analyze():
    analysis.OUT = FINAL
    analysis.hbec_table = revised_hbec
    analysis.analyze()


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action",choices=["freeze","analyze"])
    globals()[p.parse_args().action]()
