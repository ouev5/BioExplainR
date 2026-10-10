"""Derive source integrity, sample mapping and eligibility without candidate effects."""
from collections import Counter, defaultdict
import csv
import gzip
import hashlib
import io
import json
import re
import textwrap
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

from public_proteome_continue import OUT, check_frozen
from validation_sources import ROOT, HERE, record, json_out, csv_out, utc


def tsv(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.reader(stream, delimiter="\t"))


def xlsx_rows(path):
    ns = {"s": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None
        strings = ["".join(e.itertext()) for e in ET.fromstring(z.read("xl/sharedStrings.xml")).findall("s:si", ns)]
        root = ET.fromstring(z.read("xl/worksheets/sheet1.xml"))
        rows = []
        for r in root.findall(".//s:sheetData/s:row", ns):
            values = []
            for c in r.findall("s:c", ns):
                v = c.find("s:v", ns)
                text = v.text if v is not None else ""
                if c.get("t") == "s":
                    text = strings[int(text)]
                values.append(dict(cell=c.get("r"), value=text))
            rows.append(values)
    return rows


def main():
    check_frozen()
    code = [HERE / name for name in ["public_proteome_continue.py", "public_proteome_review.py", "public_proteome_resume.py",
        "public_proteome_final_sources.py", "public_proteome_finalize.py", "PUBLIC_PROTEOME_CONTINUATION_PROTOCOL.md"]]
    inputs = [p for directory in [OUT / "sources", OUT / "requests", OUT / "imported"] for p in sorted(directory.iterdir()) if p.is_file()]
    inputs += [OUT / name for name in ["search_acquisition.json", "unique_projects.json", "search_summary.json", "asm_inventory_plan_acquisition.json"]]
    json_out(OUT / "design_review_freeze.json", dict(utc=utc(), source_code=[record(p) for p in code], inputs=[record(p) for p in inputs],
        candidate_statistics_started=False, reason="Freeze acquired bytes and design-only rules before final structural checks; no candidate-specific effect estimation"))
    table = OUT / "sources/PXD029135_median-normalized_complete.txt"
    rows = tsv(table)
    header = rows[0]
    item = json.loads((OUT / "processed_and_article_plan.json").read_text())["requests"][0]["expected_file"]
    raw = table.read_bytes()
    assert len(raw) == item["fileSizeBytes"]
    assert hashlib.sha1(raw).hexdigest() == item["checksum"].zfill(40)
    assert len(rows) == 3073 and len(header) == 46 and all(len(r) == 46 for r in rows[1:])
    assert header[3:] == ["Sample_" + str(n) for n in range(1, 44)]
    samplemeta = tsv(OUT / "imported/PXD029135_SRDF_File.txt")
    community = tsv(OUT / "imported/PXD029135_PXD029135_community_annotated.sdrf.tsv")
    cidx = {k: community[0].index(k) for k in ["assay name", "characteristics[individual]", "characteristics[treatment]",
        "characteristics[compound]", "characteristics[phenotype]", "comment[data file]", "comment[instrument]"]}
    cmap = {r[cidx["assay name"]]: r for r in community[1:]}
    inventory = json.loads((OUT / "imported/PXD029135_inventory.json").read_text())
    names = {f["fileName"] for f in inventory}
    decoded = []
    counts = Counter()
    for r in samplemeta[1:]:
        assay = r[0].replace(" ", "_")
        c = cmap[assay]
        individual, post, poly, imi, high = r[1:]
        assert c[cidx["characteristics[individual]"]] == individual
        treatment = "after ICS (budesonide) treatment" if post == "1" else "before ICS treatment"
        compound = "poly(I:C)" if poly == "1" else "imiquimod" if imi == "1" else "not applicable"
        phenotype = "T2-high asthma" if high == "1" else "T2-low asthma"
        assert c[cidx["characteristics[treatment]"]] == treatment
        assert c[cidx["characteristics[compound]"]] == compound
        assert c[cidx["characteristics[phenotype]"]] == phenotype
        counts[(post, poly, imi, high)] += 1
        decoded.append(dict(assay=assay, individual=individual, post_ICS=int(post), polyIC=int(poly), imiquimod=int(imi), T2high=int(high),
            source_name=c[0], raw_file=c[cidx["comment[data file]"]], raw_name_matches_inventory=c[cidx["comment[data file]"]] in names,
            instrument=c[cidx["comment[instrument]"]]))
    csv_out(OUT / "HBEC_sample_decode.csv", decoded)
    cells = [dict(post_ICS=int(k[0]), polyIC=int(k[1]), imiquimod=int(k[2]), T2high=int(k[3]), samples=v) for k, v in sorted(counts.items())]
    csv_out(OUT / "HBEC_design_counts.csv", cells)
    main_counts = [r for r in cells if r["imiquimod"] == 0]
    assert len(main_counts) == 8 and all(r["samples"] == 5 for r in main_counts)
    nvals = Counter(v == "NA" for row in rows[1:] for v in row[3:])
    check = dict(file=record(table), expected_bytes=item["fileSizeBytes"], upstream_sha1=item["checksum"], upstream_sha1_matches=True,
        data_rows=3072, columns=46, samples=43, individuals=len({r["individual"] for r in decoded}),
        numeric_values=nvals[False], NA_values=nvals[True], matched_metadata_assays=43,
        main_ICS_polyIC_T2_cells=main_counts, unmatched_raw_names=[r for r in decoded if not r["raw_name_matches_inventory"]],
        instrument_metadata_conflict="PRIDE project Q Exactive HF; community SDRF Q Exactive HF-X", candidate_statistics_started=False)
    json_out(OUT / "HBEC_table_design_checks.json", check)
    # Import validation is a local recheck, not a fabricated missing old download log.
    known_checks = []
    for acc, filename in [("PXD063431", "240221_PB_ProteomeDiscoverer_all_Proteins_A549.txt"),
                          ("PXD003963", "NHDF_con_sn_1_1.pride.mztab.gz"), ("PXD003965", "NHDF_IL1beta_sn_1_1.pride.mztab.gz"),
                          ("PXD003971", "NHDF_IL1beta_Dex_sn_1_1.pride.mztab.gz")]:
        path = OUT / "imported" / (acc + "_" + filename)
        f = next(p for p in json.loads((OUT / "imported" / (acc + "_inventory.json")).read_text()) if p["fileName"] == filename)
        raw = path.read_bytes()
        value = dict(file=record(path), expected_bytes=f["fileSizeBytes"], size_matches=len(raw) == f["fileSizeBytes"],
            upstream_sha1=f["checksum"], upstream_sha1_matches=hashlib.sha1(raw).hexdigest() == f["checksum"].zfill(40) if f["checksum"] else None)
        if filename.endswith(".gz"):
            parsed = list(csv.reader(io.StringIO(gzip.decompress(raw).decode("utf-8-sig")), delimiter="\t"))
            value.update(row_counts={k: sum(bool(r) and r[0] == k for r in parsed) for k in ["PRT", "PSM"]},
                protein_header=next(r for r in parsed if r and r[0] == "PRH"), gzip_crc_passed=True)
        else:
            parsed = tsv(path)
            value.update(data_rows=len(parsed)-1, columns=len(parsed[0]), header=parsed[0])
        known_checks.append(value)
    json_out(OUT / "imported_processed_file_checks.json", dict(utc=utc(), checks=known_checks,
        missing_old_verification_log=True, old_HBEC_median_table_absent=True,
        meaning="Checks from present bytes; no claim that an absent old download/completion record exists"))
    # Checked inventory comparisons, excluding mutable download counters.
    oldev = json.loads((OUT / "imported/PXD055968_inventory.json").read_text())
    newev = json.loads((OUT / "PXD055968_inventory.json").read_text())
    identity = lambda p: (p["fileName"], p["fileSizeBytes"], p["accession"], p.get("checksum", ""))
    assert sorted(map(identity, oldev)) == sorted(map(identity, newev))
    json_out(OUT / "EV_inventory_recheck.json", dict(status="pass", files=56, identity_fields=["fileName", "fileSizeBytes", "accession", "checksum"],
        required_materials=record(ROOT / "research/results/discovery_asm_ev_export_v1/required_materials.csv"),
        author_request=record(ROOT / "research/results/discovery_asm_ev_export_v1/AUTHOR_MATERIAL_REQUEST.md"),
        candidate_identity_started=False, author_request_sent=False))
    metadata_checks = []
    alt = json.loads((OUT / "alternative_sources_plan.json").read_text())
    for job in alt["requests"]:
        if "expected_file" not in job:
            continue
        path = OUT / "sources" / job["name"]
        f = job["expected_file"]
        raw = path.read_bytes()
        metadata_checks.append(dict(file=record(path), expected_bytes=f["fileSizeBytes"], size_matches=len(raw)==f["fileSizeBytes"],
            upstream_sha1=f["checksum"], upstream_sha1_matches=hashlib.sha1(raw).hexdigest()==f["checksum"].zfill(40) if f["checksum"] else None))
    linkage = xlsx_rows(OUT / "sources/PXD015604_Link_between_files.xlsx")
    json_out(OUT / "epithelium_linkage_readout.json", dict(file=record(OUT / "sources/PXD015604_Link_between_files.xlsx"), rows=linkage))
    lcm_summary = tsv(OUT / "sources/PXD014171_summary.txt")
    lcm_sdrf = tsv(OUT / "sources/PXD014171_PXD014171_community_annotated.sdrf.tsv")
    raw_names = {r[0]+".raw" for r in lcm_summary[1:] if r[0].startswith("Emma_")}
    sdrf_names = {r[lcm_sdrf[0].index("comment[data file]")] for r in lcm_sdrf[1:]}
    assert raw_names == sdrf_names and len(raw_names) == 19
    json_out(OUT / "metadata_file_checks.json", dict(checks=metadata_checks, PXD014171_run_count=19, summary_SDRF_run_names_match=True,
        PXD014171_published_lesions=15, PXD014171_patients=4, note="19 runs are not 19 independent patients; no GC/vehicle factor"))
    passages, links = [], []
    for name in ["PMC11161633.xml", "PMC8688760.xml"]:
        root = ET.fromstring((OUT / "sources" / name).read_bytes())
        for e in root.iter():
            if e.tag in ["p", "table-wrap"]:
                text = " ".join("".join(e.itertext()).split())
                if re.search(r"proteom|mass spectrom|data availab|\bPXD|\bGSE|dexamethasone|budesonide|donor|volunteer|RNA sequenc", text, re.I):
                    passages.append(dict(article=name, section=e.tag, text=text))
            href = e.get("{http://www.w3.org/1999/xlink}href")
            if href and e.tag in ["ext-link", "media", "supplementary-material"]:
                links.append(dict(article=name, tag=e.tag, href=href, text=" ".join("".join(e.itertext()).split())))
    csv_out(OUT / "article_design_passages.csv", passages, fields=["article", "section", "text"])
    csv_out(OUT / "article_links.csv", links, fields=["article", "tag", "href", "text"])
    output = ["# 取得的有效全文设计段落"]
    for r in passages:
        output += ["## " + r["article"] + " / " + r["section"], textwrap.fill(r["text"], 100)]
    (OUT / "article_design_readout.md").write_text("\n\n".join(output)+"\n")
    logs = [json.loads(p.read_text()) for p in sorted((OUT / "requests").iterdir())]
    statuses = Counter(r["status"] for r in logs)
    json_out(OUT / "request_summary.json", dict(utc=utc(), request_records=len(logs), transport_status_counts=dict(statuses),
        retrieved_HTML_challenges=["PMC5105184_article.html"], valid_fulltext_XML=["PMC11161633.xml", "PMC8688760.xml"],
        note="retrieved is a transport status; challenge HTML/partial content never treated as article/table"))
    (OUT / "code_snapshot").mkdir()
    for p in code:
        (OUT / "code_snapshot" / p.name).write_bytes(p.read_bytes())
    print(json.dumps(dict(HBEC=check, metadata=metadata_checks, requests=dict(statuses), request_records=len(logs)), ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
