"""Seal and verify this biological analysis independently of older current manifests."""
import ast
import csv
import hashlib
import json
import sys
import zipfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "docs/biology_discovery_v2"
MANIFEST = REPORT / "discovery_manifest.json"
ARCHIVE = REPORT / "BioExplainR-biological-discovery-results-v1.zip"
DIRECTORIES = ["research/results/discovery_genome_v1", "research/results/discovery_genome_v2",
               "research/results/discovery_stable_response_v1", "docs/biology_discovery_v1", "docs/biology_discovery_v2"]
SCRIPT_NAMES = ["GENOME_PROTOCOL.md", "RESPONSE_PROTOCOL.md", "RESPONSE_TIME_AMENDMENT.md", "freeze_genome.py",
                "screen_genome.R", "screen_response.R", "validate_response.py", "response_mechanism.R",
                "response_time.py", "response_late_gr.R", "response_temporal_difference.R", "response_literature.py",
                "summarize_response_literature.py", "read_response_fulltexts.py", "audit_response_external.R",
                "audit_response.py", "report_response.R", "build_response_report.py", "browser_response.cjs",
                "audit_response_report.py", "seal_response.py", "README.md"]
INPUTS = ["research/results/discovery_context_v1/" + s for s in ["model.rds", "counts.txt.gz", "samples.csv", "size_factors.csv"]]
INPUTS += ["research/results/discovery_donors_v1/" + s for s in ["tpm.txt.gz", "samples.csv", "supplement_text.txt", "original_supplement_verified.pdf"]]
INPUTS += ["research/results/discovery_mechanism_fit_v4/model.rds"]
INPUTS += ["research/results/discovery_sparcl1_v1/" + s for s in ["GSE34313_series_matrix.txt.gz", "GPL6480.annot.gz"]]


def record(p):
    h = hashlib.sha256()
    with p.open("rb") as stream:
        for data in iter(lambda: stream.read(1024*1024), b""):
            h.update(data)
    return {"path": p.relative_to(ROOT).as_posix(), "bytes": p.stat().st_size, "sha256": h.hexdigest()}


def write_json(p, obj):
    p.write_text(json.dumps(obj, ensure_ascii=False, indent=2)+"\n")


def verify():
    data = json.loads(MANIFEST.read_text())
    for group in ["analysis_files", "original_inputs", "package_source"]:
        for r in data[group]:
            assert record(ROOT / r["path"]) == r, r["path"]
    assert record(ARCHIVE) == data["archive"]
    with zipfile.ZipFile(ARCHIVE) as archive:
        assert len(archive.namelist()) == len(set(archive.namelist()))
        assert not archive.testzip()
        expected = {r["path"]: r for r in data["archive_members"]}
        assert set(archive.namelist()) == set(expected)
        for path, r in expected.items():
            blob = archive.read(path)
            assert len(blob) == r["bytes"] and hashlib.sha256(blob).hexdigest() == r["sha256"]
    print(json.dumps({"status": "pass", "analysis_files": len(data["analysis_files"]), "original_inputs": len(data["original_inputs"]),
        "package_source_files": len(data["package_source"]), "archive_members": len(data["archive_members"]),
        "manifest_sha256": record(MANIFEST)["sha256"]}, indent=2))


def seal():
    if MANIFEST.exists() or ARCHIVE.exists():
        raise ValueError("Refusing to overwrite sealed analysis or archive")
    # Scientific passes are actual recorded outcomes, not inferred from a file existing.
    for p in [ROOT / "research/results/discovery_stable_response_v1/numeric_audit.json",
              ROOT / "research/results/discovery_stable_response_v1/external_r_audit.json",
              REPORT / "audit.json", REPORT / "browser/audit.json"]:
        assert json.loads(p.read_text())["status"] == "pass"
    original_inventory = ROOT / "research/results/w00_baseline/original_records.csv"
    with original_inventory.open(newline="") as stream:
        protected = list(csv.DictReader(stream))
    for r in protected:
        actual = record(ROOT / r["path"])
        assert actual["sha256"] == r["sha256"] and actual["bytes"] == int(r["bytes"]), r["path"]
    paths = []
    for directory in DIRECTORIES:
        paths.extend(p for p in (ROOT / directory).rglob("*") if p.is_file())
    paths += [ROOT / "research/discovery" / n for n in SCRIPT_NAMES]
    paths += [ROOT / "research/discovery/run_discovery.py", ROOT / "research/discovery/run_donors.py", ROOT / "rgo.md"]
    files = sorted(set(paths))
    for p in files:
        if p.suffix == ".py":
            ast.parse(p.read_text(), filename=str(p))
        if p.suffix in [".py", ".R", ".md", ".cjs"]:
            for n, line in enumerate(p.read_text().splitlines(), 1):
                assert line == line.rstrip(), (p, n, "trailing whitespace")
    analysis = [record(p) for p in files]
    inputs = [record(ROOT / p) for p in INPUTS]
    package_files = [ROOT / "DESCRIPTION", ROOT / "NAMESPACE"] + sorted((ROOT / "R").glob("*.R"))
    package = [record(p) for p in package_files]
    # Include complete current outputs/scripts/small original inputs; old source model
    # inputs remain content-hash references to the prior local delivery to avoid duplication.
    old_reference_inputs = {p for p in INPUTS if p.endswith("model.rds") or p.endswith("tpm.txt.gz")}
    small_inputs = [r for r in inputs if r["path"] not in old_reference_inputs]
    member_records = analysis + package + small_inputs
    # These paths are disjoint; ensure no accidental duplicated ZIP member.
    member_records = list({r["path"]: r for r in member_records}.values())
    with zipfile.ZipFile(ARCHIVE, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for r in member_records:
            archive.write(ROOT / r["path"], arcname=r["path"])
    report = {"status": "sealed", "sealed_utc": datetime.now(timezone.utc).isoformat(),
        "scope": "This genome/retained-response analysis and report only; not the entire project's old current manifest",
        "analysis_files": analysis, "original_inputs": inputs, "package_source": package,
        "archive": record(ARCHIVE), "archive_members": member_records,
        "original_protected_files_checked": len(protected), "original_protected_files_unchanged": True,
        "external_reference_inputs": [r for r in inputs if r["path"] in old_reference_inputs],
        "tpm_recovery_url": "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE94nnn/GSE94335/suppl/GSE94335_PostQC_all_sample_TPM.txt.gz",
        "source_model_recovery": "Use earlier r11/r13 delivery or locally preserved source model.rds paths. ZIP includes new alternative_model.rds but not earlier DESeq2/A549 source models.",
        "syntax": "All newly added Python parsed; source/text files have no trailing whitespace",
        "visual_review": "not performed; numeric, browser and PDF geometry audits supplied"}
    write_json(MANIFEST, report)
    verify()


if __name__ == "__main__":
    {"seal": seal, "verify": verify}[sys.argv[1]]()
