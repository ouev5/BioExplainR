"""From published counts, independently check mapping, logCPM/WLS/t/CI/Holm."""
import argparse
import csv
import gzip
import hashlib
import json
from pathlib import Path
import numpy as np
from scipy.stats import t


def read(p):
    with p.open() as f: return list(csv.DictReader(f))


def main():
    ap=argparse.ArgumentParser(); ap.add_argument('output',type=Path); out=ap.parse_args().output
    root=Path(__file__).resolve().parents[2]
    frozen=json.loads((out/'analysis_freeze.json').read_text())
    for r in frozen['inputs']:
        p=root/r['path']; assert p.stat().st_size==r['bytes'] and hashlib.file_digest(p.open('rb'),'sha256').hexdigest()==r['sha256']
    maps=read(out/'sample_map.csv'); included=[x for x in maps if x['included']=='TRUE']; samples=[x['sample'] for x in included]
    genes=['SPARCL1','FKBP5','TSC22D3','NR3C1']; measured={}; totals=np.zeros(len(samples))
    kept={x['gene']:x['kept']=='TRUE' for x in read(out/'expression_filter.csv')}
    with gzip.open(root/'research/results/discovery_mechanism_v1/geneCounts.tab.gz','rt') as f:
        reader=csv.DictReader(f,delimiter='\t'); assert set(reader.fieldnames[1:])=={x['sample'] for x in maps}
        for row in reader:
            v=np.array([float(row[s]) for s in samples]); g=row['Gene']
            if kept[g]: totals+=v
            if g in genes: measured[g]=v
    raw={x['gene']:x for x in read(out/'candidate_raw_counts.csv')}
    for g,v in measured.items(): assert np.allclose(v,[float(raw[g][s]) for s in samples])
    norm=read(out/'normalization.csv'); assert [x['sample'] for x in norm]==samples
    assert np.allclose(totals,[float(x['lib.size']) for x in norm])
    assert np.isclose(np.prod([float(x['norm.factors']) for x in norm]),1)
    effective=totals*np.array([float(x['norm.factors']) for x in norm])
    design_rows=read(out/'design_matrix.csv'); names=[k for k in design_rows[0] if k!='sample']
    assert [x['sample'] for x in design_rows]==samples
    X=np.array([[float(x[k]) for k in names] for x in design_rows])
    for i,m in enumerate(included):
        assert X[i,names.index('group'+m['group'])]==1
        for b in ['set2','set3','set4']: assert X[i,names.index('batch'+b)]==int(m['batch']==b)
    assert np.linalg.matrix_rank(X)==X.shape[1]
    contrast_rows=read(out/'contrasts.csv'); assert [r['coefficient'] for r in contrast_rows]==names
    contrasts={k:np.array([float(r[k]) for r in contrast_rows]) for k in contrast_rows[0] if k!='coefficient'}
    for drug in ['KH103','MIF','Cort113']:
        expected=np.zeros(len(names))
        for name,sign in [('grouppre_'+drug,1),('groupbaseline_'+drug,-1),('grouppre_DMSO',-1),('groupbaseline_DMSO',1)]: expected[names.index(name)]=sign
        assert np.array_equal(contrasts[drug],expected)
    voom=read(out/'voom_measurements.csv'); mod={r['gene']:r for r in read(out/'moderation.csv')}
    results=read(out/'model_results.csv'); count=0
    for g in genes:
        if not kept[g]:
            assert all(r['status']=='filtered_not_estimable' for r in results if r['gene']==g); continue
        rows=[r for r in voom if r['gene']==g]; assert [r['sample'] for r in rows]==samples
        y=np.array([float(r['logCPM']) for r in rows]); w=np.array([float(r['weight']) for r in rows])
        expected=np.log2((measured[g]+.5)/(effective+1)*1e6)
        assert np.allclose(y,expected,rtol=1e-10,atol=1e-10)
        cov=np.linalg.inv(X.T@(w[:,None]*X)); beta=cov@X.T@(w*y)
        for r in results:
            if r['gene']!=g: continue
            c=contrasts[r['contrast']]; effect=c@beta; se=np.sqrt(c@cov@c*float(mod[g]['variance_post'])); df=float(mod[g]['df_total'])
            vals=[effect,se,df,effect-t.ppf(.975,df)*se,effect+t.ppf(.975,df)*se,2*t.sf(abs(effect/se),df)]
            assert np.allclose(vals,[float(r[k]) for k in ['log2_effect','se','df','lower','upper','p']],rtol=1e-6,atol=1e-8),(g,r,vals)
            count+=1
    primary=[r for r in results if r['gene']=='SPARCL1' and r['contrast'] in ['KH103','MIF','Cort113']]
    if kept['SPARCL1']:
        ordered=sorted(primary,key=lambda r:float(r['p'])); last=0
        for i,r in enumerate(ordered):
            last=max(last,min(1,(3-i)*float(r['p']))); assert np.isclose(last,float(r['holm']))
    result=dict(status='pass',published_count_measurements_checked=4*len(samples),WLS_contrasts_checked=count,
                independent_mapping_design_contrasts=True,independent_logCPM_WLS_t_CI_Holm=True,
                TMM_voom_eBayes_independently_reestimated=False,candidate_kept=kept['SPARCL1'])
    (out/'audit.json').write_text(json.dumps(result,indent=2)+'\n'); print(json.dumps(result,indent=2))


if __name__=='__main__': main()
