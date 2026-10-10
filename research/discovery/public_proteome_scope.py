"""Record narrative corrections and explicit additional-page exclusion evidence."""
import csv
import gzip
import json
import re
import textwrap
import xml.etree.ElementTree as ET
from pathlib import Path

from public_proteome_continue import OUT, check_frozen
from validation_sources import record, json_out, csv_out, utc

check_frozen()
checks = json.loads((OUT / "imported_processed_file_checks.json").read_text())["checks"]
compression = []
for r in checks:
    path = Path(__file__).resolve().parents[2] / r["file"]["path"]
    if path.name.endswith(".gz"):
        expanded = gzip.decompress(path.read_bytes())
        compression.append(dict(file=record(path), compressed_bytes=path.stat().st_size,
            uncompressed_bytes=len(expanded), PRIDE_size_bytes=r["expected_bytes"],
            PRIDE_size_matches_uncompressed=len(expanded)==r["expected_bytes"],
            upstream_SHA1_matches_compressed=r["upstream_sha1_matches"]))
json_out(OUT / "mztab_compression_checks.json", dict(checks=compression))
summary = json.loads((OUT / "search_summary.json").read_text())
projects = {p["accession"]: p for p in json.loads((OUT / "unique_projects.json").read_text())}
reasons = {
    "PXD002927": "Mouse adipose phosphoproteome; DEX appears in3T3L1 validation protocol; not adultASM",
    "PXD002217": "One22yearold donor MSC-derived adipocytes; DEX part of shared differentiation cocktail; comparison washing vs serumfree method",
    "PXD001252": "Arabidopsis DEX-inducible transgenic promoter; not humanGC receptor response",
    "PXD000773": "HumanLX2 hepatic stellate cell line; MDI multiple-compound cocktail; notASM",
    "PXD004073": "Mouse hippocampus stress model; GR expression mentioned; notASMGC factor",
    "PXD002252": "HeLa nuclear-extract DNA pulldown ofGR binding exclusion sequences; not totalASM or secretome",
    "PXD002190": "C.elegans SGK1 IP interactome; kinase name containsglucocorticoid; notASMGC treatment",
    "PXD001737": "cAbl Aha1 Hsp90 biochemical protein interaction; notASMGC candidate quantitative design",
    "PXD001063": "Mouse3T3L1 adipocyte differentiation cAMP PKA Epac; notASM",
}
added = []
for label, accs in summary["added_beyond_old_page0"].items():
    for acc in accs:
        p = projects[acc]
        reason = reasons.get(acc, "HumanPBMC three volunteers nuclear cytoplasmic or secreted fractions; notASM; nine related condition/fraction projects not nine independent cohorts")
        added.append(dict(query=label, accession=acc, title=p["title"], reason=reason,
            scope="not_eligible_for_adult_ASM_GC_validation", evidence="sources/" + label + "_page_1.json"))
csv_out(OUT / "additional_page_design_review.csv", added)
sections = []
for name in ["PMC11161633.xml", "PMC8688760.xml"]:
    root = ET.fromstring((OUT / "sources" / name).read_bytes())
    for section in root.iter("sec"):
        title = section.find("title")
        heading = " ".join("".join(title.itertext()).split()) if title is not None else ""
        if re.search(r"data avail|cell culture|study population|cell treatment|clinical|mass spectrom|proteom", heading, re.I):
            text = " ".join("".join(section.itertext()).split())
            sections.append(dict(article=name, heading=heading, text=text))
csv_out(OUT / "key_article_sections.csv", sections, fields=["article", "heading", "text"])
(OUT / "key_article_sections.md").write_text("\n\n".join("## " + r["article"] + " / " + r["heading"] + "\n\n" + textwrap.fill(r["text"], 100) for r in sections)+"\n")
linkage = json.loads((OUT / "epithelium_linkage_readout.json").read_text())["rows"]
(OUT / "epithelium_linkage_readout.md").write_text("# PXD015604 原OOXML单元格值\n\n" + "\n".join(" | ".join(r["cell"]+":"+r["value"] for r in row) for row in linkage)+"\n")
print(json.dumps(compression, indent=2))
