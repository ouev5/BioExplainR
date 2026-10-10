"""Independent original-source row selection and task/repeat/method coverage check."""
import csv
import itertools
import json
from pathlib import Path
import numpy as np

ROOT=Path(__file__).resolve().parents[2]
out=ROOT/'research/results/common_performance_v4'
read=lambda p:list(csv.DictReader(p.open()))
airway=read(ROOT/'research/results/paper_cn_cases_v1/airway_de.csv')
pasilla=read(ROOT/'research/results/related_tools/pasilla_volcano.csv')
with (ROOT/'research/cache/pasilla/inst/extdata/pasilla_gene_counts.tsv').open() as f:
    rows=list(csv.reader(f,delimiter='\t'));ids=[r[0] for r in rows[1:]]
assert len(ids)==len(pasilla)==14599 and len(set(ids))==len(ids)
sources={'airway':airway,'pasilla':[dict(feature_id=i,log2FoldChange=r['log2FC'],padj=r['padj']) for i,r in zip(ids,pasilla)]}
def equal_numeric(a,b):
    return (a in ['NA',''] and b=='NA') or (a not in ['NA',''] and np.isclose(float(a),float(b),rtol=1e-14,atol=0))
for dataset,source in sources.items():
    source.sort(key=lambda r:r['feature_id'])
    for size in [50,200]:
        index=np.rint(np.linspace(0,len(source)-1,size)).astype(int)
        selected=read(out/'inputs'/f'{dataset}_{size}.csv')
        assert len(selected)==size
        for a,b in zip([source[i] for i in index],selected):
            assert a['feature_id']==b['feature_id']
            assert equal_numeric(a['padj'],b['padj']) and equal_numeric(a['log2FoldChange'],b['log2FoldChange'])
tasks=json.loads((out/'tasks.json').read_text());schedule=json.loads((out/'schedule.json').read_text())
assert {(x['dataset'],x['n'],x['alpha'],x['lfc']) for x in tasks}==set(itertools.product(['airway','pasilla'],[50,200],[.01,.05,.1],[0,1]))
methods=['bio_offline','base_r','ellmer_table','ellmer_facts','bio_client_facts']
assert len(schedule)==360 and {(x['task_index'],x['repeat'],x['method']) for x in schedule}==set(itertools.product(range(24),range(1,4),methods))
assert [r['order'] for r in schedule]==list(range(1,361))
result=dict(status='pass',source_rows_checked=500,tasks=24,scheduled_runs=360,source='Saved airway full DE CSV/pasilla volcano plus original count-table IDs; no upstream DE refit',
            independent_selection=True,all_task_method_repeat_keys=True)
(out/'selection_audit.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
