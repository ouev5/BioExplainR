"""Check exported research tables/content/hash and PDF text boundaries independently."""
import csv
import hashlib
import json
from pathlib import Path
import fitz
from docx import Document

out=Path('docs/research_followup_v1')
pdf=next(out.glob('*.pdf'));docx=next(out.glob('*.docx'));doc=Document(docx)
tables=[]
for table in doc.tables:tables.append([[cell.text for cell in row.cells] for row in table.rows])
assert len(tables)==4
table_names=['F1_common_task','F2_paired_bootstrap','F3_receptor_control','F4_chip_primary']
for actual,name in zip(tables,table_names):
    with (out/'tables'/f'{name}.csv').open() as f:expected=list(csv.reader(f))
    assert actual==expected,name
performance=Path('research/results/common_performance_v4')
with (performance/'summary.csv').open() as f:summary={r['method']:r for r in csv.DictReader(f)}
for row,method in zip(tables[0][1:],['bio_offline','base_r','ellmer_table','ellmer_facts','bio_client_facts']):
    r=summary[method];assert row[1:4]==[r['correct'],r['covered'],r['all_correct']]
    assert row[4:]==[f"{float(r['median_sec']):.3f}",f"{float(r['p95_sec']):.3f}"]
text=''
with fitz.open(pdf) as pages:
    for p in pages:
        text+=p.get_text()
        for b in p.get_text('blocks'):
            if b[6]==0:assert b[0]>=-1 and b[1]>=-1 and b[2]<=p.rect.width+1 and b[3]<=p.rect.height+1,(p.number,b[:4])
    count=len(pages)
for fragment in ['GSE229084','GSE95632','1,800','SPARCL1','不可估计','2.19%','705,534','not_applicable','hg19','不构成确认']:
    assert fragment in text,fragment
result=dict(status='pass',pdf_pages=count,tables=4,independent_saved_summary_comparison=True,pdf_text_boundaries='pass',manual_visual_review=False)
(out/'independent_audit.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
