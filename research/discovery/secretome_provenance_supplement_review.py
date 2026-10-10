"""Verify acquired supplement identity and report only selected-table scope."""
import argparse
import re
import json
from pathlib import Path
import fitz
from validation_sources import utc, record, json_out, csv_out


def main(out):
    dest=out / "complete";path=out / "sources/EV_publisher_supplement_normalized.bin"
    doc=fitz.open(path);pages=[p.get_text() for p in doc]
    text="\n".join(pages)
    assert "Bronchial smooth muscle extracellular vesicles" in pages[0]
    assert "Elisa Celle" in pages[0] and "Supplemental table 2" in text
    scope=[]
    for i,t in enumerate(pages,1):
        scope.append(dict(page=i,text_characters=len(t),contains_table1="Supplemental table 1" in t,
            contains_table2="Supplemental table 2" in t,
            contains_ANGPTL2=bool(re.search(r"\bANGPTL2\b",t)),contains_FSTL3=bool(re.search(r"\bFSTL3\b",t)),
            contains_FBN2=bool(re.search(r"\bFBN2\b",t))))
    csv_out(dest / "EV_supplement_scope.csv",scope)
    json_out(dest / "supplement_review.json",dict(status="pass",utc=utc(),script=record(Path(__file__)),input=record(path),
        pages=len(doc),identity="Original title and firstauthor on supplement cover match acquired Cells/iScience source; canonical PII +mmc1 mapping",
        correction="First automatic correspondence test false because text says Supplemental table2, notTableS2. Raw acquisition result preserved; sourceidentity checked here.",
        scope="FiguresS1-S8 and selected IPA pathways/table2 glycolysis proteins, not full unselected protein quantification; no target absence inference",
        target_hits={gene:sum(r['contains_'+gene] for r in scope) for gene in ['ANGPTL2','FSTL3','FBN2']}))
    print(json.dumps(dict(status="pass",pages=len(doc),final_page=pages[-1]),ensure_ascii=False,indent=2))


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("output",type=Path);main(p.parse_args().output.resolve())
