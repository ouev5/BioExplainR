"""Cross-check GEO mapping against authors' independent processed sample annotation."""
import csv
import json
from pathlib import Path
import re

out=Path('research/results/discovery_mechanism_fit_v4')
load=lambda p:list(csv.DictReader(p.open()))
published={r['sample']:r for r in load(out/'published_sample_annotation.csv')}
blocks=Path('research/results/discovery_mechanism_v1/intervention_metadata.txt').read_text().split('^SAMPLE = ')[1:]
geo={b.splitlines()[0].strip():b for b in blocks}
mapping=load(out/'sample_map.csv')
normalize=lambda x:re.sub('[^a-zA-Z0-9+]','',x)
for r in mapping:
    block=geo[r['gsm']];description=re.search(r'!Sample_description = (\S+)',block).group(1)
    p=published[description]
    assert p['batch']==r['batch'] and normalize(p['condition'])==normalize(r['treatment'])
assert len(published)==len(mapping)==51 and 'MG_15' not in published
(out/'published_mapping_audit.json').write_text(json.dumps(dict(status='pass',samples=51,source='Authors SE.processed.rds colData vs GEO Sample_description MG ID, batch, condition',
    missing_control='MG_15/DMSO set2 absent in both published sources',DMSO_set3_set4='Published MG_28/MG_41 confirm batch despite GEO title rep2/rep3',
    fitted_model_unchanged=True),indent=2)+'\n')
print('Published object independent mapping: 51/51 pass; absent MG_15 confirmed')
