"""Read-only progress audit; never reports an unfinished study as final performance."""
import argparse
import csv
import hashlib
import json
from pathlib import Path
from audit_benchmark import FIELDS,parse


def main():
    ap=argparse.ArgumentParser();ap.add_argument('output',type=Path);out=ap.parse_args().output
    tasks=json.loads((out/'tasks.json').read_text());schedule=json.loads((out/'schedule.json').read_text())
    root=Path(__file__).resolve().parents[2]
    freeze=json.loads((out/'freeze.json').read_text())
    for row in freeze['inputs']+freeze['scripts']+freeze['design']:
        p=Path(row['path']);p=p if p.is_absolute() else root/p
        assert p.stat().st_size==row['bytes'] and hashlib.file_digest(p.open('rb'),'sha256').hexdigest()==row['sha256']
    completed=[]
    for r in schedule:
        p=out/'runs'/f"{r['order']:03d}.json"
        if not p.exists():continue
        try:z=json.loads(p.read_text())
        except json.JSONDecodeError:continue # Writer can be in-flight, not a final artifact.
        assert all(z[k]==v for k,v in r.items());t=tasks[r['task_index']]
        with (out/'inputs'/t['input']).open() as f:table=list(csv.DictReader(f))
        sig=[x for x in table if x['padj']!='NA' and float(x['padj'])<t['alpha'] and x['log2FoldChange']!='NA' and abs(float(x['log2FoldChange']))>t['lfc']]
        gold=[len(table),len(sig),sum(float(x['log2FoldChange'])>0 for x in sig),sum(float(x['log2FoldChange'])<0 for x in sig),sum(x['padj']=='NA' for x in table)]
        answer=parse(z['text'],z.get('finish')=='length');stored=z['parsed'] or {}
        assert answer==stored
        completed.append(z)
    assert [x['order'] for x in completed]==list(range(1,len(completed)+1))
    print(json.dumps(dict(status='in_progress' if len(completed)<360 else 'ready_for_final_scoring',completed_runs=len(completed),planned_runs=360,
        completed_model_attempts=sum(x['method'] not in ['base_r','bio_offline'] for x in completed),
        failed_model_attempts=sum(x['status']=='error' for x in completed),frozen_files_unchanged=True,
        scope='Progress/integrity only; no final accuracy or ranking'),indent=2))


if __name__=='__main__':main()
