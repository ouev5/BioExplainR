"""Correct a narrative field count using exact sealed-document snapshots."""
import argparse
import ast
import json
from pathlib import Path

import asm_ev_materials as materials
from seal_asm_ev_materials import verify as verify_materials
from validation_sources import ROOT, HERE, utc, record, json_out

OUT = materials.OUT
CORRECTION = OUT / "handoff_correction"
MANIFEST = OUT / "handoff_manifest.json"
DOCS = {
    "rgo.md": "rgo_before_field_count_correction.md",
    "research/results/discovery_asm_ev_materials_v1/FINDINGS.md": "FINDINGS_before_field_count_correction.md",
    "research/results/discovery_asm_ev_materials_v1/EXECUTION_NOTES.md": "EXECUTION_NOTES_before_final_checks.md",
}


def snapshot():
    if CORRECTION.exists():
        raise ValueError(f"Refusing overwrite {CORRECTION}")
    previous = verify_materials()
    CORRECTION.mkdir()
    snapshots = []
    for original, name in DOCS.items():
        dest = CORRECTION / name
        dest.write_bytes((ROOT / original).read_bytes())
        snapshots.append(dict(original=record(ROOT / original), snapshot=record(dest)))
    json_out(CORRECTION / "correction_plan.json", dict(utc=utc(), script=record(Path(__file__)),
        previous_verification=previous, snapshots=snapshots,
        reason="Narrative counted HAL metadata as260; acquired original JSON and machine review report262. Correct only narrative and append final check notes. Scientific source/hash unchanged."))


def preceding():
    plan = json.loads((CORRECTION / "correction_plan.json").read_text())
    for r in plan["snapshots"]:
        assert record(ROOT / r["snapshot"]["path"]) == r["snapshot"]
        assert (r["original"]["bytes"], r["original"]["sha256"]) == (r["snapshot"]["bytes"], r["snapshot"]["sha256"])
    original_record = materials.record
    mapping = {(ROOT / old).resolve(): CORRECTION / name for old, name in DOCS.items()}

    def snapshot_record(path):
        path = path.resolve()
        actual = original_record(mapping.get(path, path))
        if path in mapping:
            actual = dict(actual, path=path.relative_to(ROOT).as_posix())
        return actual

    materials.record = snapshot_record
    try:
        return verify_materials()
    finally:
        materials.record = original_record


def verify():
    manifest = json.loads(MANIFEST.read_text())
    for r in manifest["files"] + manifest["source_code"] + manifest["documentation"] + manifest["dependencies"]:
        assert record(ROOT / r["path"]) == r, r["path"]
    prior = preceding()
    fields = json.loads((OUT / "hal_source_review.json").read_text())["metadata_fields"]
    assert fields == 262
    for name in [ROOT / "rgo.md", OUT / "FINDINGS.md"]:
        text = name.read_text()
        assert "262" in text
    result = dict(status="pass", files=len(manifest["files"]),
        scientific_status="blocked_missing_final_export", candidate_identity_started=False,
        corrected_HAL_metadata_fields=fields, previous_evidence=prior)
    print(json.dumps({k: v for k, v in result.items() if k != "previous_evidence"}, ensure_ascii=False, indent=2))
    return result


def seal():
    if MANIFEST.exists() or (OUT / "handoff_verification.json").exists():
        raise ValueError("Refusing overwrite final handoff evidence")
    prior = preceding()
    ast.parse(Path(__file__).read_text())
    json_out(MANIFEST, dict(utc=utc(), status="sealed",
        files=[record(p) for p in sorted(CORRECTION.rglob("*")) if p.is_file()],
        source_code=[record(Path(__file__))],
        documentation=[record(ROOT / "rgo.md"), record(OUT / "FINDINGS.md"), record(OUT / "EXECUTION_NOTES.md"),
            record(ROOT / "docs/asm_ev_materials_v1/README.md")],
        dependencies=[record(materials.MANIFEST)],
        previous_evidence=prior, scientific_status="blocked_missing_final_export",
        candidate_identity_started=False,
        snapshot_policy="Exact snapshots only for three revised narrative documents; all scientific source original paths/hash"))
    result = verify()
    json_out(OUT / "handoff_verification.json", dict(utc=utc(), result=result,
        note="Verification output excluded from own manifest"))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action", choices=["snapshot", "seal", "verify"])
    globals()[p.parse_args().action]()
