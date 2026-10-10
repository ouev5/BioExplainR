"""Acquire additional final-export leads without inspecting candidate measurements."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path
import urllib.error
import urllib.parse
import urllib.request

from validation_sources import ROOT, HERE, utc, record, json_out
from seal_asm_ev_export import verify as verify_export, previous as verify_older

OUT = ROOT / "research/results/discovery_asm_ev_materials_v1"
MANIFEST = OUT / "materials_manifest.json"
DOI = "10.1016/j.isci.2025.112546"
TITLE = "Bronchial smooth muscle extracellular vesicles interfere with bronchial epithelium metabolism and function in asthma"


def query(base, **params):
    return base + "?" + urllib.parse.urlencode(params)


def requests():
    rows = [
        ("hal_doi.json", query("https://api.archives-ouvertes.fr/search/", q=f'doiId_s:"{DOI}"', rows=100, wt="json")),
        ("hal_accession.json", query("https://api.archives-ouvertes.fr/search/", q='text:"PXD055968"', rows=100, wt="json")),
        ("hal_title.json", query("https://api.archives-ouvertes.fr/search/", q=f'title_t:"{TITLE}"', rows=100, wt="json")),
        ("rdg_accession.json", query("https://entrepot.recherche.data.gouv.fr/api/search", q="PXD055968", per_page=100)),
        ("rdg_doi.json", query("https://entrepot.recherche.data.gouv.fr/api/search", q=f'"{DOI}"', per_page=100)),
        ("openaire_doi.json", query("https://api.openaire.eu/search/publications", doi=DOI, format="json")),
        ("figshare_doi.json", query("https://api.figshare.com/v2/articles", resource_doi=DOI, page_size=100)),
    ]
    for acc in ["PXD055968", "PXD055949", "PXD059603"]:
        rows.append((acc + "_project.json", f"https://www.ebi.ac.uk/pride/ws/archive/v2/projects/{acc}"))
        rows.append((acc + "_files.json", f"https://www.ebi.ac.uk/pride/ws/archive/v2/projects/{acc}/files?pageSize=100&page=0"))
    return rows


def fetch_one(item):
    name, url = item
    path = OUT / "sources" / name
    if path.exists():
        raise ValueError(f"Refusing overwrite {path}")
    log = dict(name=name, url=url, started_utc=utc())
    req = urllib.request.Request(url, headers={
        "User-Agent": "BioExplainR-final-materials/0.4", "Accept-Encoding": "identity"})
    try:
        with urllib.request.urlopen(req, timeout=25) as response:
            log.update(http_status=response.status, final_url=response.url, headers=dict(response.headers))
            blob = response.read(20 * 1024 * 1024 + 1)
        if len(blob) > 20 * 1024 * 1024:
            log.update(status="response_size_limit", note="Not a complete response")
        else:
            log["status"] = "retrieved"
    except urllib.error.HTTPError as exc:
        log.update(status="http_error", http_status=exc.code, final_url=exc.url, headers=dict(exc.headers), error=str(exc))
        blob = exc.read(20 * 1024 * 1024 + 1)
    except Exception as exc:
        log.update(status="failed", error=str(exc), completed_utc=utc())
        return log
    path.write_bytes(blob)
    log.update(response=record(path), completed_utc=utc())
    return log


def acquire():
    if OUT.exists():
        raise ValueError(f"Refusing overwrite {OUT}")
    prior = verify_export()
    OUT.mkdir()
    (OUT / "sources").mkdir()
    snapshot = OUT / "rgo_before_materials.md"
    snapshot.write_bytes((ROOT / "rgo.md").read_bytes())
    json_out(OUT / "prior_verification.json", dict(utc=utc(), result=prior))
    plan = requests()
    json_out(OUT / "acquisition_plan.json", dict(utc=utc(), script=record(Path(__file__)),
        protocol=record(HERE / "ASM_EV_MATERIALS_PROTOCOL.md"), snapshot=record(snapshot), requests=plan,
        scope="Source/attachment metadata only; no candidate measurements", candidate_identity_started=False))
    with ThreadPoolExecutor(max_workers=4) as pool:
        logs = list(pool.map(fetch_one, plan))
    json_out(OUT / "acquisition.json", dict(utc=utc(), records=logs))
    print(json.dumps([dict(name=r["name"], status=r["status"], http_status=r.get("http_status")) for r in logs], indent=2))


def follow(plan_name):
    plan = json.loads((OUT / plan_name).read_text())
    for r in plan["source_evidence"]:
        assert record(ROOT / r["path"]) == r, r["path"]
    assert record(Path(__file__)) == plan["script"]
    with ThreadPoolExecutor(max_workers=4) as pool:
        logs = list(pool.map(fetch_one, plan["requests"]))
    json_out(OUT / (Path(plan_name).stem + "_acquisition.json"), dict(utc=utc(), records=logs))
    print(json.dumps([dict(name=r["name"], status=r["status"], http_status=r.get("http_status")) for r in logs], indent=2))


def prior_with_snapshot():
    path = ROOT / "docs/asm_ev_export_v1/export_manifest.json"
    m = json.loads(path.read_text())
    n = 0
    for group in ["files", "source_code", "dependencies", "documentation"]:
        for r in m[group]:
            p = OUT / "rgo_before_materials.md" if r["path"] == "rgo.md" else ROOT / r["path"]
            actual = record(p)
            assert (actual["bytes"], actual["sha256"]) == (r["bytes"], r["sha256"]), r["path"]
            n += 1
    from seal_set_validation import check_archive
    assert record(ROOT / m["archive"]["path"]) == m["archive"]
    check_archive(ROOT / m["archive"]["path"], m["archive_members"])
    return dict(status="pass", export_records=n, export_archive_members=len(m["archive_members"]),
        snapshot_policy="Only preceding export root rgo dependency uses exact pre-materials snapshot; all other original paths/hash",
        nested=verify_older())


def verify():
    m = json.loads(MANIFEST.read_text())
    for r in m["files"] + m["source_code"] + m["dependencies"] + m["documentation"]:
        assert record(ROOT / r["path"]) == r, r["path"]
    plan = json.loads((OUT / "acquisition_plan.json").read_text())
    assert record(HERE / "ASM_EV_MATERIALS_PROTOCOL.md") == plan["protocol"]
    assert record(Path(__file__)) == plan["script"]
    assert record(OUT / "rgo_before_materials.md") == plan["snapshot"]
    previous = prior_with_snapshot()
    status = json.loads((OUT / "final_status.json").read_text())
    assert status["status"] == "blocked_missing_final_export"
    assert status["correct_full_export_acquired"] is False
    assert status["candidate_identity_started"] is False
    result = dict(status="pass", files=len(m["files"]), scientific_status=status["status"],
        candidate_identity_started=False, previous_evidence=previous)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return result


def seal():
    if MANIFEST.exists() or (OUT / "verification.json").exists():
        raise ValueError("Refusing overwrite sealed materials evidence")
    prior = prior_with_snapshot()
    files = [record(p) for p in sorted(OUT.rglob("*")) if p.is_file()]
    json_out(MANIFEST, dict(utc=utc(), status="sealed", files=files,
        source_code=[record(Path(__file__)), record(HERE / "ASM_EV_MATERIALS_PROTOCOL.md")],
        dependencies=[record(ROOT / "docs/asm_ev_export_v1/export_manifest.json")],
        documentation=[record(ROOT / "rgo.md"), record(ROOT / "docs/asm_ev_materials_v1/README.md")],
        previous_evidence=prior, candidate_identity_started=False, author_contact="draft_only_not_sent",
        scope="Additional repository/related-project metadata; no complete quantitative array or candidate analysis"))
    result = verify()
    json_out(OUT / "verification.json", dict(utc=utc(), result=result,
        note="Verification output excluded from own manifest; verify recomputes indexed hashes"))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action", choices=["acquire", "follow", "seal", "verify"])
    p.add_argument("--plan")
    args = p.parse_args()
    if args.action == "follow":
        if not args.plan:
            p.error("follow requires --plan")
        follow(args.plan)
    else:
        globals()[args.action]()
