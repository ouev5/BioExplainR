"""Independently reconstruct secondary task-all-correct and size summaries."""
import csv
import json
from pathlib import Path
import numpy as np
from audit_benchmark import parse,FIELDS

out=Path('research/results/common_performance_v4')
tasks=json.loads((out/'tasks.json').read_text());schedule=json.loads((out/'schedule.json').read_text())
records=[]
for s in schedule:
    task=tasks[s['task_index']];z=json.loads((out/'runs'/f"{s['order']:03d}.json").read_text());answer=parse(z['text'],z.get('finish')=='length')
    with (out/'inputs'/task['input']).open() as f:rows=list(csv.DictReader(f))
    sig=[r for r in rows if r['padj']!='NA' and float(r['padj'])<task['alpha'] and r['log2FoldChange']!='NA' and abs(float(r['log2FoldChange']))>task['lfc']]
    gold=[len(rows),len(sig),sum(float(r['log2FoldChange'])>0 for r in sig),sum(float(r['log2FoldChange'])<0 for r in sig),sum(r['padj']=='NA' for r in rows)]
    records.append(dict(method=s['method'],task=s['task_index'],n=task['n'],correct=sum(answer.get(k)==v for k,v in zip(FIELDS,gold)),covered=len(answer)))
with (out/'size_breakdown.csv').open() as f:
    for r in csv.DictReader(f):
        rows=[x for x in records if x['method']==r['method'] and x['n']==int(r['n'])]
        assert sum(x['correct'] for x in rows)==int(r['correct']) and sum(x['covered'] for x in rows)==int(r['covered']) and len(rows)*5==int(r['targets'])
indices=np.array(json.loads((out/'bootstrap_indices.json').read_text()))
metric=lambda m:np.array([np.mean([x['correct']==5 for x in records if x['method']==m and x['task']==i]) for i in range(24)])
with (out/'task_bootstrap.csv').open() as f:
    for r in csv.DictReader(f):
        delta=metric(r['comparison'].split()[0])-metric('ellmer_table');boot=delta[indices].mean(axis=1)
        assert np.allclose([float(r[k]) for k in ['estimate','lower','upper']],[delta.mean(),*np.quantile(boot,[.025,.975])])
(out/'supplemental_audit.json').write_text(json.dumps(dict(status='pass',endpoints=['size-specific target accuracy','task-all-correct paired bootstrap'],
    independent_from_raw_outputs=True,tasks=24,bootstrap_resamples=2000),indent=2)+'\n')
print('Secondary size/task-all-correct endpoints independently verified')
