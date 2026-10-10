"""Resolve publisher PII formatting; retain failed original URL and original raw response."""
import argparse
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path
import fitz
from validation_sources import utc, record, json_out, fetch


def main(out):
    dest=out / "complete";root=ET.parse(out / "sources/PMC12141081.xml").getroot()
    original=next(el.text for el in root.iter("article-id") if el.get("pub-id-type")=="pii")
    normalized=re.sub(r"[^A-Za-z0-9]","",original)
    url=f"https://ars.els-cdn.com/content/image/1-s2.0-{normalized}-mmc1.pdf"
    json_out(dest / "supplement_amendment.json",dict(utc=utc(),script=record(Path(__file__)),original_pii=original,
        publisher_pii=normalized,url=url,reason="Unnormalized article PII produced404; remove standard publisher PII punctuation; retain first failed attempts"))
    path=out / "sources/EV_publisher_supplement_normalized.bin"
    log=fetch(url,path,timeout=30)
    if path.exists():
        log["pdf_signature"]=path.read_bytes().startswith(b"%PDF")
        if log["pdf_signature"]:
            doc=fitz.open(path);text="\n".join(p.get_text() for p in doc)
            (dest / "EV_supplement_text.txt").write_text(text)
            log.update(pages=len(doc),text_characters=len(text),correspondence_verified="BSM" in text and "Table S2" in text)
    json_out(dest / "supplement_acquisition.json",dict(utc=utc(),records=[log]))
    print(json.dumps(log,ensure_ascii=False,indent=2))


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("output",type=Path);main(p.parse_args().output.resolve())
