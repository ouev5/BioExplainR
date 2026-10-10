"""Audit frozen original scripts, then run original numerical audit on repaired CI export."""
import argparse
import hashlib
import json
from pathlib import Path
import audit_mechanism
import numpy as np
from scipy.stats import t


def main():
    ap=argparse.ArgumentParser(); ap.add_argument('output',type=Path); out=ap.parse_args().output.resolve()
    root=Path(__file__).resolve().parents[2]
    # The original audit and model remain frozen, including their original failure.
    frozen=json.loads((out/'analysis_freeze.json').read_text())
    for r in frozen['inputs']:
        p=root/r['path']; assert p.stat().st_size==r['bytes'] and hashlib.file_digest(p.open('rb'),'sha256').hexdigest()==r['sha256']
    read=audit_mechanism.read
    # Reuse source/mapping checks, but independently reconstruct the documented
    # limma contrasts.fit SE approximation as well as exact weighted covariance.
    # Original audit is retained with its informative approximation mismatch.
    maps=[r for r in read(out/'sample_map.csv') if r['included']=='TRUE']
    samples=[r['sample'] for r in maps]
    # Independent source parse: do not rely on the primary map's treatment labels.
    import re
    blocks=(root/'research/results/discovery_mechanism_v1/intervention_metadata.txt').read_text().split('^SAMPLE = ')[1:]
    source_metadata={b.splitlines()[0].strip():b for b in blocks}
    for row in maps:
        block=source_metadata[row['gsm']]
        batch=re.search(r'!Sample_characteristics_ch1 = batch: (\S+)',block).group(1)
        treatment=re.search(r'!Sample_characteristics_ch1 = treatment: (.*)',block).group(1).strip()
        assert row['batch']==batch and row['treatment']==treatment
        normalize=lambda text:re.sub('[^a-zA-Z0-9+]','',text.replace('KH-103','KH103'))
        count_treatment,suffix=row['sample'].rsplit('_',1)
        assert normalize(count_treatment)==normalize(treatment) and suffix==batch[-1]
    import gzip,csv
    kept={r['gene']:r['kept']=='TRUE' for r in read(out/'expression_filter.csv')}
    totals=np.zeros(len(samples)); measured={}; all_values={}
    with gzip.open(root/'research/results/discovery_mechanism_v1/geneCounts.tab.gz','rt') as f:
        reader=csv.DictReader(f,delimiter='\t')
        assert set(reader.fieldnames[1:])=={r['sample'] for r in read(out/'sample_map.csv')}
        for r in reader:
            values=np.array([float(r[s]) for s in samples])
            all_values[r['Gene']]=values
            if kept[r['Gene']]: totals+=values
            if r['Gene'] in ['SPARCL1','FKBP5','TSC22D3','NR3C1']: measured[r['Gene']]=values
    raw={r['gene']:r for r in read(out/'candidate_raw_counts.csv')}
    for g,values in measured.items(): assert np.array_equal(values,[float(raw[g][s]) for s in samples])
    norm=read(out/'normalization.csv'); assert [r['sample'] for r in norm]==samples
    assert np.allclose(totals,[float(r['lib.size']) for r in norm])
    factors=np.array([float(r['norm.factors']) for r in norm]); assert np.isclose(factors.prod(),1)
    design=read(out/'design_matrix.csv'); names=[k for k in design[0] if k!='sample']
    assert [r['sample'] for r in design]==samples
    X=np.array([[float(r[k]) for k in names] for r in design])
    for i,r in enumerate(maps):
        for name in names:
            assert X[i,names.index(name)]==int(r['group']==name[5:] if name.startswith('group') else r['batch']==name[5:])
    assert np.linalg.matrix_rank(X)==X.shape[1]
    # Independently reconstruct default filterByExpr from unfiltered library sizes
    # and leverage-based minimum sample size; never relax the candidate filter.
    full_libraries=sum(all_values.values())
    leverage=np.einsum('ij,jk,ik->i',X,np.linalg.inv(X.T@X),X)
    minimum=1/leverage.max()
    if minimum>10: minimum=10+(minimum-10)*.7
    cutoff=10/np.median(full_libraries)*1e6
    for g,values in all_values.items():
        independently_kept=(sum(values/full_libraries*1e6>=cutoff)>=minimum-1e-14 and values.sum()>=15-1e-14)
        assert independently_kept==kept[g],g
    cr=read(out/'contrasts.csv'); contrasts={k:np.array([float(r[k]) for r in cr]) for k in cr[0] if k!='coefficient'}
    for drug in ['KH103','MIF','Cort113']:
        expected=np.zeros(len(names))
        for n,sign in [('grouppre_'+drug,1),('groupbaseline_'+drug,-1),('grouppre_DMSO',-1),('groupbaseline_DMSO',1)]: expected[names.index(n)]=sign
        assert np.array_equal(contrasts[drug],expected)
    corrrows=read(out/'contrast_correlation.csv'); corr=np.array([[float(r[k]) for k in names] for r in corrrows])
    common=np.linalg.inv(X.T@X); commoncorr=common/np.sqrt(np.outer(common.diagonal(),common.diagonal()))
    assert np.allclose(corr,commoncorr)
    unscaled={r['gene']:r for r in read(out/'coefficient_unscaled.csv')}; mod={r['gene']:r for r in read(out/'moderation.csv')}
    measurements=read(out/'voom_measurements.csv'); results=read(out/'model_results_complete.csv'); exact=[]
    for g,raw_values in measured.items():
        if not kept[g]:
            assert all(r['status']=='filtered_not_estimable' for r in results if r['gene']==g); continue
        rows=[r for r in measurements if r['gene']==g]; assert [r['sample'] for r in rows]==samples
        y=np.array([float(r['logCPM']) for r in rows]); w=np.array([float(r['weight']) for r in rows])
        assert np.allclose(y,np.log2((raw_values+.5)/(totals*factors+1)*1e6),atol=1e-10,rtol=1e-10)
        cov=np.linalg.inv(X.T@(w[:,None]*X)); beta=cov@X.T@(w*y)
        u=np.sqrt(cov.diagonal()); assert np.allclose(u,[float(unscaled[g][k]) for k in names])
        approximate_cov=np.outer(u,u)*corr
        for r in results:
            if r['gene']!=g: continue
            c=contrasts[r['contrast']]; effect=c@beta; variance=float(mod[g]['variance_post']); df=float(mod[g]['df_total'])
            se=np.sqrt(c@approximate_cov@c*variance)
            vals=[effect,se,df,effect-t.ppf(.975,df)*se,effect+t.ppf(.975,df)*se,2*t.sf(abs(effect/se),df)]
            assert np.allclose(vals,[float(r[k]) for k in ['log2_effect','se','df','lower','upper','p']],atol=1e-8,rtol=1e-6),(r,vals)
            exactse=np.sqrt(c@cov@c*variance)
            exact.append(dict(gene=g,contrast=r['contrast'],log2_effect=effect,exact_se=exactse,limma_approx_se=se,
                lower=effect-t.ppf(.975,df)*exactse,upper=effect+t.ppf(.975,df)*exactse,p=2*t.sf(abs(effect/exactse),df)))
    with (out/'exact_WLS_sensitivity.csv').open('w') as f:
        w=csv.DictWriter(f,fieldnames=list(exact[0]));w.writeheader();w.writerows(exact)
    result=dict(status='pass',samples=len(samples),published_count_measurements_checked=4*len(samples),
        WLS_contrasts_checked=len(exact),candidate_kept=kept['SPARCL1'],independent_counts_design_logCPM_WLS_CI_t=True,
        independent_GEO_treatment_batch_mapping=True,
        independent_full_gene_filter=True,genes_filter_checked=len(all_values),filter_CPM_cutoff=cutoff,filter_minimum_samples=minimum,
        Holm='not_estimable: all three candidate tests filtered',TMM_voom_eBayes_independently_reestimated=False,
        standard_error='limma contrasts.fit uses common coefficient correlation approximation; independently reconstructed; exact weighted covariance also exported',
        max_relative_SE_difference=max(abs(r['exact_se']/r['limma_approx_se']-1) for r in exact))
    (out/'audit.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
    amendment=dict(scope='Export repair only: unnamed limma s2.post indexed by gene position; frozen RDS unchanged, no refit',
        files=[dict(path=p.name,bytes=p.stat().st_size,sha256=hashlib.file_digest(p.open('rb'),'sha256').hexdigest()) for p in [out/'model.rds',out/'model_results_complete.csv',Path(__file__),Path(__file__).with_name('complete_mechanism_ci.R')]])
    (out/'export_amendment.json').write_text(json.dumps(amendment,indent=2)+'\n')


if __name__=='__main__': main()
