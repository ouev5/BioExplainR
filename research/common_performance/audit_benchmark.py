"""Independent JSON parsing, source counting, scoring, wire and bootstrap audit."""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import re
import numpy as np

FIELDS=['n_features','n_significant','n_up','n_down','n_na_padj']


def pairs(items):
    d={}
    for k,v in items:
        if k in d: raise ValueError('duplicate JSON key')
        d[k]=v
    return d


def parse(text,truncated):
    if truncated: return {}
    text=text.strip()
    if text.startswith('```json') and text.endswith('```'): text=text[7:-3].strip()
    try: x=json.loads(text,object_pairs_hook=pairs)
    except (ValueError,TypeError): return {}
    if not isinstance(x,dict) or re.search(r'[0-9][.eE]',text): return {}
    return {k:v for k,v in x.items() if k in FIELDS and type(v) is int and v>=0}


def main():
    ap=argparse.ArgumentParser(); ap.add_argument('directory',type=Path); a=ap.parse_args(); out=a.directory
    load=lambda name: json.loads((out/name).read_text())
    frozen=load('freeze.json')
    root=Path(__file__).resolve().parents[2]
    for r in frozen['inputs']+frozen['scripts']+frozen['design']:
        p=Path(r['path']); p=p if p.is_absolute() else root/p
        assert p.stat().st_size==r['bytes'] and hashlib.file_digest(p.open('rb'),'sha256').hexdigest()==r['sha256'],p
    tasks=load('tasks.json'); schedule=load('schedule.json'); all_scores=[]; run_data=[]
    wires=[(load(f'wire/{i:03d}_request.json'),load(f'wire/{i:03d}_response.json')) for i in range(1,218)]
    assert len(tasks)==24 and len(schedule)==360
    wire_index=1; prompt_pairs={}; tokens={}
    for s in schedule:
        t=tasks[s['task_index']]; z=load(f"runs/{s['order']:03d}.json")
        assert all(z[k]==v for k,v in s.items())
        with (out/'inputs'/t['input']).open() as f: table=list(csv.DictReader(f))
        sig=[r for r in table if r['padj']!='NA' and float(r['padj'])<t['alpha'] and r['log2FoldChange']!='NA' and abs(float(r['log2FoldChange']))>t['lfc']]
        ref=[len(table),len(sig),sum(float(r['log2FoldChange'])>0 for r in sig),sum(float(r['log2FoldChange'])<0 for r in sig),sum(r['padj']=='NA' for r in table)]
        parsed=parse(z['text'],z.get('finish')=='length')
        correct=[parsed.get(k)==v for k,v in zip(FIELDS,ref)]
        all_scores.append((s,ref,parsed,correct)); run_data.append(z)
        if s['method'] not in ['base_r','bio_offline']:
            req,res=wires[wire_index]; wire_index+=1
            assert req['temperature']==0 and req['seed']==42 and req['cache_prompt'] is False
            assert req.get('max_tokens',req.get('max_completion_tokens'))==256
            messages=req['messages']; assert len(messages)==2
            for message,text in zip(messages,[z.get('system'),z.get('user')]):
                content=message['content']
                if isinstance(content,list): content=''.join(v['text'] for v in content)
                assert content==text
            if 'choices' in res:
                assert res['choices'][0]['message']['content']==z['text']
                assert res['choices'][0]['finish_reason']==z['finish']
                usage=res['usage']; tokens.setdefault(s['method'],[]).append(usage)
            else:
                assert z['status']=='error' and not parsed and 'error' in res
            if s['method'] in ['ellmer_facts','bio_client_facts']:
                key=(s['task_index'],s['repeat']); prompt_pairs.setdefault(key,[]).append(z['user'])
    assert wire_index==217 and all(len(v)==2 and v[0]==v[1] for v in prompt_pairs.values())
    with (out/'scores.csv').open() as f: primary=list(csv.DictReader(f))
    assert len(primary)==1800
    for (s,ref,parsed,correct),chunk in zip(all_scores,[primary[i:i+5] for i in range(0,len(primary),5)]):
        for row,k,v,c in zip(chunk,FIELDS,ref,correct):
            assert int(row['order'])==s['order'] and row['fact']==k and int(row['expected'])==v
            assert (row['correct']=='TRUE')==c and (row['covered']=='TRUE')==(k in parsed)
    with (out/'summary.csv').open() as f: summary=list(csv.DictReader(f))
    for row in summary:
        selected=[(scores,z) for scores,z in zip(all_scores,run_data) if scores[0]['method']==row['method']]
        corr=sum(sum(s[3]) for s,z in selected); covered=sum(len(s[2]) for s,z in selected)
        assert corr==int(row['correct']) and covered==int(row['covered']) and len(selected)==72
        assert sum(all(s[3]) for s,z in selected)==int(row['all_correct'])
        assert np.isclose(np.median([z['elapsed_sec'] for s,z in selected]),float(row['median_sec']))
        assert np.isclose(np.quantile([z['elapsed_sec'] for s,z in selected],.95),float(row['p95_sec']))
    indices=np.array(load('bootstrap_indices.json'))
    metric=lambda m: np.array([np.mean([v for s,ref,ans,corr in all_scores if s['method']==m and s['task_index']==i for v in corr]) for i in range(24)])
    with (out/'paired_bootstrap.csv').open() as f:
        for row in csv.DictReader(f):
            m=row['comparison'].split()[0]; delta=metric(m)-metric('ellmer_table'); boot=delta[indices].mean(axis=1)
            assert np.allclose([float(row[k]) for k in ['estimate','lower','upper']],[delta.mean(),*np.quantile(boot,[.025,.975])])
    token_summary={m:dict(prompt_tokens=sum(x['prompt_tokens'] for x in v),completion_tokens=sum(x['completion_tokens'] for x in v),
        median_prompt_tokens=float(np.median([x['prompt_tokens'] for x in v])),median_completion_tokens=float(np.median([x['completion_tokens'] for x in v]))) for m,v in tokens.items()}
    result=dict(status='pass',runs=360,target_scores=1800,formal_model_calls=216,warmup_calls=1,prompt_pairs_identical=72,
                independent_reference=True,independent_parser=True,bootstrap_recomputed=True,tokens=token_summary,
                failed_requests=sum(z['status']=='error' for z in run_data),token_scope='Only completed responses; timeout tokens unknown')
    (out/'audit.json').write_text(json.dumps(result,indent=2)+'\n'); print(json.dumps(result,indent=2))


if __name__=='__main__': main()
