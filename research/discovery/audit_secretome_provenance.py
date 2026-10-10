"""Independent XLSX OOXML parser validates complete published inputs and search scope."""
import argparse
import json
import re
import zipfile
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta
from pathlib import Path

from secretome_provenance_complete import rows
from secretome_provenance import HUMAN
from validation_sources import record, utc, json_out

S = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
R = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}"


def workbook(path):
    with zipfile.ZipFile(path) as z:
        styles=ET.fromstring(z.read("xl/styles.xml"))
        formats={int(n.get("numFmtId")):n.get("formatCode") for n in styles.iter(S+"numFmt")}
        date_styles=[]
        for style in styles.find(S+"cellXfs"):
            n=int(style.get("numFmtId","0"));code=formats.get(n,"").lower()
            date_styles.append(n in range(14,23) or n in [45,46,47] or bool(re.search(r"[yd]",code)))
        strings=[]
        if "xl/sharedStrings.xml" in z.namelist():
            for si in ET.fromstring(z.read("xl/sharedStrings.xml")).findall(S+"si"):
                strings.append("".join(t.text or "" for t in si.iter(S+"t")))
        relations={r.get("Id"):r.get("Target") for r in ET.fromstring(z.read("xl/_rels/workbook.xml.rels"))}
        output={}
        for sh in ET.fromstring(z.read("xl/workbook.xml")).find(S+"sheets"):
            target=relations[sh.get(R+"id")]
            target=target.lstrip("/") if target.startswith("/") else "xl/"+target
            data={}
            for row in ET.fromstring(z.read(target)).iter(S+"row"):
                values={}
                for c in row.findall(S+"c"):
                    ref=c.get("r");col=re.match("[A-Z]+",ref)[0]
                    index=0
                    for char in col:
                        index=index*26+ord(char)-64
                    v=c.find(S+"v");text=v.text if v is not None else None
                    kind=c.get("t")
                    if kind=="s": value=strings[int(text)]
                    elif kind=="inlineStr": value="".join(t.text or "" for t in c.iter(S+"t"))
                    elif kind in ["str","e"]:value=text
                    else:
                        value=float(text) if text is not None else None
                        if value is not None and date_styles[int(c.get("s","0"))]:
                            value=str(datetime(1899,12,30)+timedelta(days=value))
                    values[index-1]=value
                data[int(row.get("r"))]=values
            output[sh.get("name")]=data
        return output


def main(out):
    dest=out / "complete"; wb=workbook(HUMAN / "Table S2.xlsx")
    published=rows(out / "published_measurements.csv")
    expected=[]
    for sheet,data in wb.items():
        if "DiffAbundant" not in sheet:
            continue
        h=next(n for n,row in data.items() if row.get(0)=="Protein Name")
        columns=[]
        for j,v in data[h].items():
            m=re.fullmatch(r"(\d{2}\.\d{2}\.\d{2})_?(co|dex)([123])",v) if isinstance(v,str) else None
            if m:columns.append((j,m))
        assert len(columns)==36
        for i,r in data.items():
            if i<=h or not r.get(2):continue
            for j,m in columns:
                expected.append((sheet,str(i),r[7],r[1],m[1],m[2],m[3],r[j]))
    actual=[(r["sheet"],r["published_row"],r["protein_ids"],r["symbol"],r["donor"],r["condition"],r["technical_rep"],float(r["published_log2"])) for r in published]
    assert len(expected)==len(actual),(len(expected),len(actual))
    for i,(e,a) in enumerate(zip(expected,actual)):
        assert e[:-1]==a[:-1] and abs(e[-1]-a[-1])<1e-12,(i,e,a)
    allrows=rows(out / "all_intensity_cross_array.csv")
    for r in allrows:
        p=wb[r["sheet"]][int(r["published_row"])]
        assert r["protein_ids"]==p[0] and float(r["published_intensity"])==p[3]
    linkage=workbook(out / "sources/PXD055968_Link_between_files.xlsx")
    subjects={}; n=0
    for data in linkage.values():
        for row in data.values():
            if isinstance(row.get(0),str) and row[0].startswith("pe210308_"):
                subjects.setdefault(str(row[3]),set()).add(row[5]);n+=1
    assert n==18 and len(subjects)==6 and all(len(v)==3 for v in subjects.values())
    original_hashes=[record(out/f"sources/pride_search_{i}.json")["sha256"] for i in range(1,5)]
    assert len(set(original_hashes))==1
    corrected=[json.loads((out/f"sources/pride_corrected_{i}.json").read_text()) for i in range(1,6)]
    assert corrected[-1]==[] and all(len(r)<100 for r in corrected)
    papers={};search=[]
    for path in sorted((out / "sources").glob("epmc_*.json")):
        data=json.loads(path.read_text());hits=data["resultList"]["result"]
        assert data["hitCount"]==len(hits)
        search.append(dict(path=record(path)["path"],hits=len(hits)))
        for r in hits:papers[r["source"]+":"+r["id"]]=r
    assert len(papers)==len(rows(out / "literature_records.csv"))
    r_audit=json.loads((dest / "r_audit.json").read_text());assert r_audit["status"]=="pass"
    json_out(dest / "independent_audit.json",dict(status="pass",utc=utc(),script=record(Path(__file__)),
        workbook_measurements=len(expected),all_workbook_comparisons=len(allrows),
        EV_independent_donor_labels=len(subjects),EV_runs=n,EV_replications_per_label=3,
        EV_scope="No GC/vehicle factor; three runs/label even though original linkage calls them biologicalreplicates. Do not count18 independent donors.",
        literature_unique=len(papers),search=search,pride_corrected_hits=[len(r) for r in corrected],
        pride_unique_projects=len({r['accession'] for group in corrected for r in group}),
        first_pride_endpoint_ignored_keyword=True,r_audit=record(dest / "r_audit.json")))
    print(json.dumps(dict(status="pass",published_measurements=len(expected),EV_subjects=len(subjects),papers=len(papers))))


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("output",type=Path);main(p.parse_args().output.resolve())
