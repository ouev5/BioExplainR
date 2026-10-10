"""Freeze final, bounded article routes from already acquired publication metadata."""
import json
from pathlib import Path
import urllib.parse

from public_proteome_continue import OUT, check_frozen
from validation_sources import record, json_out, utc

check_frozen()
requests = [dict(name="PMC8688760.xml", url="https://www.ebi.ac.uk/europepmc/webservices/rest/PMC8688760/fullTextXML")]
for pmc, doi in [("PMC11299423", "10.1096/fj.202400452r"), ("PMC9361782", "10.1096/fj.202100835r"),
                 ("PMC5105184", "10.1165/rcmb.2016-0068oc")]:
    requests.append(dict(name=pmc + "_publisher.html", url="https://doi.org/" + doi))
requests.append(dict(name="intrapulmonary_publisher.pdf", url="https://erj.ersjournals.com/content/erj/56/1/1902178.full.pdf"))
requests.append(dict(name="zedoarondiol_supplement.pdf", url="https://static-content.springer-cdn.com/esm/art%3A10.1038%2Fs41598-024-63970-4/MediaObjects/41598_2024_63970_MOESM1_ESM.pdf"))
json_out(OUT / "final_article_routes_plan.json", dict(utc=utc(), script=record(Path(__file__)),
    source_evidence=[record(OUT / "imported/article_34950134.json"), record(OUT / "imported/papers_asm_protein_summary.json"),
        record(OUT / "imported/papers_lung_gc_protein_summary.json"), record(OUT / "sources/intrapulmonary_article.json"),
        record(OUT / "sources/PMC11161633.xml")], requests=requests,
    reason="Original EPMC fulltext/DOI/publisher media routes; capture final acquisition and design only, no candidate measurements"))
