"""Auditable public-proteome pagination and design follow-up; no candidate tests."""
import argparse
import contextlib
import csv
from concurrent.futures import ThreadPoolExecutor
import hashlib
import io
import json
from pathlib import Path
import re
import time
import urllib.error
import urllib.parse
import urllib.request

from validation_sources import ROOT, HERE, utc, record, json_out, csv_out

OUT = ROOT / "research/results/discovery_public_proteome_v1"
OLD = Path("/tmp/opencode/rgo_public_search_20261010")
OLD_SNAPSHOT = Path("/tmp/opencode/rgo_before_public_search_20261010.md")
PROTOCOL = HERE / "PUBLIC_PROTEOME_CONTINUATION_PROTOCOL.md"
SCRIPT = Path(__file__).resolve()
KEYWORDS = {
    "airway": "airway smooth muscle", "bronchial": "bronchial smooth muscle",
    "hasm": "HASM", "hbsmc": "HBSMC", "dex": "dexamethasone",
    "bud": "budesonide", "gc": "glucocorticoid", "intrapulmonary": "intrapulmonary",
    "airway_proteome": "airway proteome", "actin": "airway actin",
    "smooth_muscle": "smooth muscle", "lung_smooth_muscle": "lung smooth muscle",
    "fluticasone": "fluticasone", "hydrocortisone": "hydrocortisone",
    "control": "BioExplainR_unrelated_negative_control_9f3f",
}
MAX_BYTES = 25 * 1024 * 1024
ASM = re.compile(r"smooth[ -]?muscle|\bHASM\b|\bHBSMC\b", re.I)
LUNG = re.compile(r"airway|bronch|lung|trache|pulmonary|\bHASM\b|\bHBSMC\b", re.I)


def check_frozen():
    plan = json.loads((OUT / "acquisition_plan.json").read_text())
    assert record(SCRIPT) == plan["script"]
    assert record(PROTOCOL) == plan["protocol"]
    for r in plan["imported_inputs"]:
        assert record(ROOT / r["path"]) == r, r["path"]
    return plan


def preceding():
    """Override only the latest handoff's changed root-document dependency."""
    import asm_ev_materials_handoff as handoff
    snapshot = OUT / "rgo_before_public_search.md"
    manifest = json.loads(handoff.MANIFEST.read_text())
    expected = next(r for r in manifest["documentation"] if r["path"] == "rgo.md")
    saved = record(snapshot)
    assert (saved["bytes"], saved["sha256"]) == (expected["bytes"], expected["sha256"])
    original = handoff.record

    def snapshot_record(path):
        if path.resolve() == (ROOT / "rgo.md").resolve():
            return dict(original(snapshot), path="rgo.md")
        return original(path)

    handoff.record = snapshot_record
    try:
        with contextlib.redirect_stdout(io.StringIO()):
            result = handoff.verify()
    finally:
        handoff.record = original
    return result


def fetch(name, url):
    path = OUT / "sources" / name
    logpath = OUT / "requests" / (name + ".request.json")
    if path.exists() or logpath.exists():
        raise ValueError(f"Refusing overwrite: {name}")
    log = dict(name=name, url=url, started_utc=utc())
    blob = bytearray()
    started = time.monotonic()
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "BioExplainR-public-proteome/0.4",
            "Accept-Encoding": "identity"})
        with urllib.request.urlopen(req, timeout=20) as response:
            log.update(http_status=response.status, final_url=response.url, headers=dict(response.headers))
            while True:
                part = response.read(65536)
                if not part:
                    break
                blob.extend(part)
                if len(blob) > MAX_BYTES or time.monotonic() - started > 120:
                    raise ValueError("Response size/time limit; partial bytes only")
            log["status"] = "retrieved"
    except urllib.error.HTTPError as exc:
        log.update(status="http_error", http_status=exc.code, headers=dict(exc.headers), error=str(exc))
        blob.extend(exc.read(MAX_BYTES + 1))
    except Exception as exc:
        log.update(status="failed_or_partial", error=repr(exc))
    if blob or log.get("status") == "retrieved":
        path.write_bytes(blob)
        log["response"] = record(path)
    log.update(completed_utc=utc(), seconds=time.monotonic() - started)
    json_out(logpath, log)
    return log


def paginated(label, base, params):
    logs, items = [], []
    complete = False
    for page in range(50):
        url = base + "?" + urllib.parse.urlencode(dict(params, pageSize=100, page=page))
        log = fetch(f"{label}_page_{page}.json", url)
        logs.append(log)
        if log["status"] != "retrieved":
            break
        data = json.loads((ROOT / log["response"]["path"]).read_text())
        if not isinstance(data, list):
            raise ValueError(f"Non-list page: {label}")
        items.extend(data)
        if len(data) < 100:
            complete = True
            break
    return dict(label=label, parameters=params, complete_to_short_page=complete,
        records=logs, returned=len(items), unique_accessions=len({p["accession"] for p in items}), items=items)


def acquire():
    if OUT.exists():
        raise ValueError(f"Refusing overwrite: {OUT}")
    OUT.mkdir()
    for name in ["sources", "requests", "imported"]:
        (OUT / name).mkdir()
    (OUT / "rgo_before_continuation.md").write_bytes((ROOT / "rgo.md").read_bytes())
    (OUT / "rgo_before_public_search.md").write_bytes(OLD_SNAPSHOT.read_bytes())
    imported = []
    for path in sorted(OLD.iterdir()):
        if path.is_file():
            dest = OUT / "imported" / path.name
            dest.write_bytes(path.read_bytes())
            imported.append(record(dest))
    for name in ["rgo_public_search_20261010.py", "rgo_public_leads_20261010.py", "rgo_public_verify_20261010.py"]:
        path = OLD.parent / name
        dest = OUT / "imported" / name
        dest.write_bytes(path.read_bytes())
        imported.append(record(dest))
    prior = preceding()
    json_out(OUT / "prior_verification.json", dict(utc=utc(), result=prior,
        policy="Latest handoff root rgo only uses exact pre-public-search snapshot; all scientific paths/hash original"))
    json_out(OUT / "acquisition_plan.json", dict(utc=utc(), script=record(SCRIPT), protocol=record(PROTOCOL),
        imported_inputs=imported, keywords=KEYWORDS, max_pages=50, page_size=100,
        scope="Metadata/file-integrity/design only; no candidate statistics",
        candidate_statistics_started=False, candidate_identity_started=False))
    base = "https://www.ebi.ac.uk/pride/ws/archive/v2/search/projects"
    with ThreadPoolExecutor(max_workers=4) as pool:
        results = list(pool.map(lambda kv: paginated("pride_" + kv[0], base, dict(keyword=kv[1])), KEYWORDS.items()))
    summary = [{k: v for k, v in r.items() if k != "items"} for r in results]
    json_out(OUT / "search_acquisition.json", dict(utc=utc(), searches=summary))
    summarize()


def project_text(p):
    return "\n".join(str(p.get(k, "")) for k in ["title", "projectDescription", "sampleProcessingProtocol", "dataProcessingProtocol", "keywords"])


def summarize():
    check_frozen()
    searches = json.loads((OUT / "search_acquisition.json").read_text())["searches"]
    projects, membership = {}, {}
    rows = []
    for s in searches:
        for log in s["records"]:
            if log["status"] != "retrieved":
                continue
            data = json.loads((ROOT / log["response"]["path"]).read_text())
            for p in data:
                acc = p["accession"]
                projects.setdefault(acc, p)
                membership.setdefault(acc, set()).add(s["label"])
        rows.append(dict(keyword=s["parameters"]["keyword"], pages=len(s["records"]),
            returned=s["returned"], unique_accessions=s["unique_accessions"], complete=s["complete_to_short_page"]))
    csv_out(OUT / "search_coverage.csv", rows)
    json_out(OUT / "unique_projects.json", [projects[k] for k in sorted(projects)])
    selected = []
    for acc, p in sorted(projects.items()):
        text = project_text(p)
        airway_asm = bool(ASM.search(text) and LUNG.search(text))
        selected.append(dict(accession=acc, title=p["title"], queries=";".join(sorted(membership[acc])),
            airway_asm_text_match=airway_asm, sample_processing=p.get("sampleProcessingProtocol", ""),
            description=p.get("projectDescription", ""), data_processing=p.get("dataProcessingProtocol", "")))
    csv_out(OUT / "project_screen.csv", selected)
    csv_out(OUT / "airway_asm_leads.csv", [r for r in selected if r["airway_asm_text_match"]], fields=list(selected[0]))
    old = {}
    for name in ["pride_dex.json", "pride_gc.json"]:
        old[name] = {p["accession"] for p in json.loads((OUT / "imported" / name).read_text())}
    added = {label: [p["accession"] for p in projects.values()
        if label in membership[p["accession"]] and p["accession"] not in old[label + ".json"]]
        for label in ["pride_dex", "pride_gc"]}
    json_out(OUT / "search_summary.json", dict(utc=utc(), searches=rows, unique_projects=len(projects),
        airway_asm_text_leads=sum(r["airway_asm_text_match"] for r in selected), added_beyond_old_page0=added))
    print(json.dumps(dict(searches=rows, unique_projects=len(projects), airway_asm_text_leads=sum(r["airway_asm_text_match"] for r in selected)), indent=2))
    for r in selected:
        if r["airway_asm_text_match"]:
            print(r["accession"] + " | " + r["title"])


def follow(plan_name):
    check_frozen()
    planpath = OUT / plan_name
    plan = json.loads(planpath.read_text())
    for r in plan["source_evidence"]:
        assert record(ROOT / r["path"]) == r
    with ThreadPoolExecutor(max_workers=4) as pool:
        results = list(pool.map(lambda j: fetch(j["name"], j["url"]), plan["requests"]))
    json_out(OUT / (planpath.stem + "_acquisition.json"), dict(utc=utc(), plan=record(planpath), records=results))
    print(json.dumps([dict(name=r["name"], status=r["status"], bytes=r.get("response", {}).get("bytes"), error=r.get("error")) for r in results], indent=2))


def inventory(plan_name):
    check_frozen()
    planpath = OUT / plan_name
    plan = json.loads(planpath.read_text())
    for r in plan["source_evidence"]:
        assert record(ROOT / r["path"]) == r

    def one(acc):
        base = "https://www.ebi.ac.uk/pride/ws/archive/v2/projects/" + acc
        metadata = fetch(acc + "_project.json", base)
        files = paginated(acc + "_files", base + "/files", {})
        json_out(OUT / (acc + "_inventory.json"), files["items"])
        return dict(accession=acc, metadata=metadata, files={k: v for k, v in files.items() if k != "items"})

    with ThreadPoolExecutor(max_workers=4) as pool:
        results = list(pool.map(one, plan["projects"]))
    json_out(OUT / (planpath.stem + "_acquisition.json"), dict(utc=utc(), plan=record(planpath), projects=results))
    for r in results:
        data = json.loads((OUT / (r["accession"] + "_inventory.json")).read_text())
        small = [{"name": p["fileName"], "bytes": p["fileSizeBytes"]} for p in data
            if not p["fileName"].lower().endswith((".raw", ".mzml", ".mgf", ".pdresult", ".msf", ".wiff", ".wiff.scan"))]
        print(json.dumps(dict(accession=r["accession"], total=len(data), complete=r["files"]["complete_to_short_page"], small=small), ensure_ascii=False))


def seal():
    check_frozen()
    prior = preceding()
    files = [record(p) for p in sorted(OUT.rglob("*")) if p.is_file()]
    json_out(OUT / "public_proteome_manifest.json", dict(utc=utc(), status="sealed", files=files,
        source_code=[record(SCRIPT), record(PROTOCOL), record(HERE / "audit_public_proteome.py")],
        documentation=[record(ROOT / "rgo.md")],
        dependencies=[record(ROOT / "research/results/discovery_asm_ev_materials_v1/handoff_manifest.json")],
        previous_evidence=prior, candidate_statistics_started=False, candidate_identity_started=False,
        author_contact="draft_only_not_sent", publication="paused", scope="Public-source completeness, file integrity and design eligibility"))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action", choices=["acquire", "follow", "inventory", "seal"])
    p.add_argument("--plan")
    args = p.parse_args()
    if args.action in ["follow", "inventory"]:
        if not args.plan:
            p.error("--plan required")
        globals()[args.action](args.plan)
    else:
        globals()[args.action]()
