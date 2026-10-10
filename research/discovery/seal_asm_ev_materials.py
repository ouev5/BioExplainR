"""Seal/verify final-materials source follow-up and its unchanged preceding evidence."""
import argparse
import ast
import json
from pathlib import Path

from asm_ev_materials import OUT, MANIFEST, prior_with_snapshot, verify as verify_files
from validation_sources import ROOT, HERE, record, utc, json_out


def check_sources():
    logs = []
    for name in ["acquisition.json", "hal_followup_plan_acquisition.json"]:
        logs.extend(json.loads((OUT / name).read_text())["records"])
    assert len(logs) == 19
    for log in logs:
        if "response" in log:
            assert record(ROOT / log["response"]["path"]) == log["response"]
        if log["status"] == "retrieved":
            assert log["http_status"] == 200
    for name in ["hal_followup_plan.json", "hal_pdf_plan.json", "hal_pdf_resume_plan.json"]:
        plan = json.loads((OUT / name).read_text())
        assert record(HERE / "asm_ev_materials.py") == plan["script"]
        for r in plan["source_evidence"]:
            assert record(ROOT / r["path"]) == r
    frozen = json.loads((OUT / "review_freeze.json").read_text())
    assert record(HERE / "asm_ev_materials_review.py") == frozen["script"]
    for r in frozen["inputs"]:
        assert record(ROOT / r["path"]) == r
    curl_plan = json.loads((OUT / "hal_pdf_curl_plan.json").read_text())
    curl = json.loads((OUT / "hal_pdf_curl_acquisition.json").read_text())
    assert record(HERE / "asm_ev_materials_review.py") == curl_plan["script"]
    assert record(ROOT / curl_plan["source"]["path"]) == curl_plan["source"]
    assert curl["command"] == curl_plan["command"]
    assert record(ROOT / curl["response"]["path"]) == curl["response"]
    assert curl["exit_code"] == 28 and curl["status"] == "failed_or_partial"
    # Interrupted urllib commands have no completion record and no complete PDF.
    assert not (OUT / "hal_pdf_plan_acquisition.json").exists()
    assert not (OUT / "hal_pdf_resume_plan_acquisition.json").exists()
    assert not (OUT / "sources/hal_author_article.pdf").exists()
    assert not (OUT / "sources/hal_author_article_retry.pdf").exists()
    counts = {}
    for acc, expected in [("PXD055968", 56), ("PXD055949", 48), ("PXD059603", 38)]:
        files = json.loads((OUT / "sources" / (acc + "_files.json")).read_text())
        log = next(r for r in logs if r["name"] == acc + "_files.json")
        headers = {k.lower(): v for k, v in log["headers"].items()}
        assert len(files) == int(headers["total_records"]) == expected
        counts[acc] = len(files)
    hal = json.loads((OUT / "sources/hal_record_full.json").read_text())["response"]
    assert hal["numFound"] == len(hal["docs"]) == 1
    assert hal["docs"][0]["doiId_s"] == "10.1016/j.isci.2025.112546"
    assert len(hal["docs"][0]["files_s"]) == 1
    assert hal["docs"][0]["files_s"][0].endswith(".pdf")
    summary = json.loads((OUT / "review_summary.json").read_text())
    assert summary["completed_requests"] == 20 and summary["project_files"] == sum(counts.values())
    assert summary["correct_full_export_acquired"] is False
    state = json.loads((OUT / "final_status.json").read_text())
    assert state["correct_full_export_acquired"] is False and state["candidate_identity_started"] is False
    assert state["author_contact"] == "draft_only_not_sent"
    assert state["candidate_identity_freeze_created"] is False
    return dict(status="pass", completed_request_records=20, interrupted_attempts=2,
        retrieved_metadata_responses=sum(r["status"] == "retrieved" for r in logs), project_files=counts,
        complete_quantitative_exports=0, complete_hal_pdf=False)


def verify():
    result = verify_files()
    result["source_checks"] = check_sources()
    print(json.dumps(result["source_checks"], ensure_ascii=False, indent=2))
    return result


def seal():
    if MANIFEST.exists() or (OUT / "verification.json").exists():
        raise ValueError("Refusing overwrite sealed materials evidence")
    checks = check_sources()
    prior = prior_with_snapshot()
    code = [HERE / n for n in ["asm_ev_materials.py", "asm_ev_materials_review.py",
        "seal_asm_ev_materials.py", "ASM_EV_MATERIALS_PROTOCOL.md", "validation_sources.py"]]
    for p in code:
        if p.suffix == ".py":
            ast.parse(p.read_text(), filename=str(p))
    json_out(MANIFEST, dict(utc=utc(), status="sealed",
        files=[record(p) for p in sorted(OUT.rglob("*")) if p.is_file()],
        source_code=[record(p) for p in code],
        dependencies=[record(ROOT / "docs/asm_ev_export_v1/export_manifest.json")],
        documentation=[record(ROOT / "rgo.md"), record(ROOT / "docs/asm_ev_materials_v1/README.md")],
        source_checks=checks, previous_evidence=prior,
        correct_full_export_acquired=False, candidate_identity_started=False,
        candidate_identity_freeze_created=False, author_contact="draft_only_not_sent", publication="paused",
        scope="Repository and related-project metadata only; final quantitative export and workflow still missing"))
    result = verify()
    json_out(OUT / "verification.json", dict(utc=utc(), result=result,
        note="Verification output excluded from own manifest; verify recomputes indexed evidence"))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action", choices=["seal", "verify"])
    globals()[p.parse_args().action]()
