"""Create treatment/batch map before reading candidate expression."""
import argparse
import csv
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'research/results/discovery_mechanism_v1'


def metadata(path):
    samples=[]
    for block in path.read_text().split('^SAMPLE = ')[1:]:
        s={'gsm':block.splitlines()[0].strip()}
        for line in block.splitlines()[1:]:
            if ' = ' not in line: continue
            key,value=line.split(' = ',1)
            s.setdefault(key,[]).append(value.strip())
        samples.append(s)
    return samples


def main():
    ap=argparse.ArgumentParser(); ap.add_argument('output',type=Path); a=ap.parse_args(); out=a.output.resolve(); out.mkdir()
    rows=[]; mapping_notes=[]
    for s in metadata(SOURCE/'intervention_metadata.txt'):
        props=dict(x.split(': ',1) for x in s['!Sample_characteristics_ch1'])
        treatment=props['treatment']; batch=props['batch']
        name=re.sub(r'\s','_',treatment.replace('> ','').replace('KH-103','KH103'))+'_'+batch[-1]
        # Title replicate labels are not unique for DMSO; count suffix follows public batch.
        title=s['!Sample_title'][0]
        if not title.endswith('rep'+batch[-1]): mapping_notes.append(dict(gsm=s['gsm'],title=title,batch=batch,count_column=name))
        drug=next((d for d in ['KH103','MIF','Cort113'] if d in name),'DMSO')
        phase='pre' if name.startswith('16h') else 'post' if name.startswith('2h') else 'baseline'
        group=('untreated' if 'untreated' in name else f'{phase}_{drug}')
        rows.append(dict(sample=name,gsm=s['gsm'],title=title,batch=batch,treatment=treatment,drug=drug,phase=phase,group=group,included='TRUE' if 'untreated' not in name else 'FALSE'))
    with (out/'sample_map.csv').open('w') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
    files=[SOURCE/'geneCounts.tab.gz',SOURCE/'intervention_metadata.txt',SOURCE/'PMC10710461.xml',ROOT/'research/discovery/MECHANISM_PROTOCOL.md',ROOT/'research/discovery/run_mechanism.R',ROOT/'research/discovery/audit_mechanism.py',Path(__file__).resolve(),out/'sample_map.csv']
    frozen=dict(frozen_utc=datetime.now(timezone.utc).isoformat(),candidate_expression_read=False,
        notes=mapping_notes,filterByExpr=dict(min_count=10,min_total_count=15,large_n=10,min_prop=.7),
        analysis='batch + 12 treatment/time groups; untreated excluded; all pre/baseline/post samples for voom/eBayes; primary three pre-treatment differences-in-differences; post descriptive only',
        inputs=[dict(path=str(p.relative_to(ROOT)),bytes=p.stat().st_size,sha256=hashlib.file_digest(p.open('rb'),'sha256').hexdigest()) for p in files])
    (out/'analysis_freeze.json').write_text(json.dumps(frozen,indent=2)+'\n')
    print(json.dumps(dict(samples=len(rows),included=sum(r['included']=='TRUE' for r in rows),metadata_notes=mapping_notes),indent=2))


if __name__=='__main__': main()
