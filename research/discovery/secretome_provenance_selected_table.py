"""Extract the original selected glycolysis table; preserve publication/text discrepancy."""
import argparse
import re
from pathlib import Path
import fitz
from validation_sources import record, utc, csv_out, json_out


def main(out):
    dest=out / "complete";path=out / "sources/EV_publisher_supplement_normalized.bin"
    doc=fitz.open(path); text=doc[-1].get_text();lines=[s.strip() for s in text.splitlines() if s.strip()]
    assert lines[:5]==["Symbol","Entrez Gene Name","Expr Fold Change","Expr p-value","Expected"]
    data=lines[5:-1];assert lines[-1]=="Supplemental table 2" and len(data)==40
    records=[]
    for i in range(0,len(data),5):
        symbol,name,fold,p,direction=data[i:i+5]
        records.append(dict(symbol=symbol,name=name,published_fold_change=float(fold.replace(",",".")),
            published_pvalue=float(p.replace(",",".")),published_expected=direction,source_page=len(doc),
            source_table="Supplemental table2: selected glycolysis proteins, not wholearray",reported_pvalue_below_05=float(p.replace(",","."))<.05))
    # Independently verify table columns using PDF word coordinates, not the linear block parser.
    words=doc[-1].get_text("words")
    for r in records:
        sw=[w for w in words if w[4]==r["symbol"]];assert len(sw)==1
        line=[w for w in words if abs(w[1]-sw[0][1])<1.5]
        tokens=[w[4] for w in sorted(line,key=lambda w:w[0])]
        nums=[t for t in tokens if re.fullmatch(r"\d+,\d+(?:E[+-]\d+)?",t)]
        assert len(nums)==2
        assert [float(t.replace(",",".")) for t in nums]==[r["published_fold_change"],r["published_pvalue"]]
    csv_out(dest / "EV_selected_glycolysis.csv",records)
    json_out(dest / "EV_selected_table_audit.json",dict(status="pass",utc=utc(),script=record(Path(__file__)),input=record(path),
        selected_rows=len(records),pvalue_below_05=sum(r["reported_pvalue_below_05"] for r in records),
        observed_pvalue_min=min(r["published_pvalue"] for r in records),observed_pvalue_max=max(r["published_pvalue"] for r in records),
        discrepancy="Original body says8significativeupregulated proteins; actualsupplementselectedtable allreportedExprP>.05 (.0912-.590). ExpectedUp is IPA annotation, not evidence8significantgenes. Do not substitute pathwayP orZ for proteinP.",
        limitations="Published selected table only; no originaldonorarray or fullfamily correction. No independent effectre-estimation."))
    print(records)


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("output",type=Path);main(p.parse_args().output.resolve())
