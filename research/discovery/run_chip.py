"""Freeze and count all published q<=.05 peaks against all fixed-gene TSS/windows."""
import argparse
import csv
from datetime import datetime,timezone
import gzip
import hashlib
import json
import math
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
GENES=['SPARCL1','FKBP5','TSC22D3','KLF15']


def write_csv(p,rows,fields):
    with p.open('w') as f:
        w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows(rows)


def main():
    ap=argparse.ArgumentParser();ap.add_argument('source',type=Path);ap.add_argument('output',type=Path);a=ap.parse_args();source=a.source.resolve();out=a.output.resolve();out.mkdir()
    build=json.loads((source/'coordinate_assembly_evidence.json').read_text());assert build['status']=='coordinate_verified_hg19'
    annotation=[]
    for p in sorted(source.glob('hg19_ncbiRefSeq_chr*.json')):
        x=json.loads(p.read_text());assert x['genome']=='hg19' and x['itemsReturned']==len(x['ncbiRefSeq']) and not x.get('maxItemsLimit')
        annotation.extend(r for r in x['ncbiRefSeq'] if r['name2'] in GENES)
    assert set(r['name2'] for r in annotation)==set(GENES)
    samples=json.loads((source/'peak_samples.json').read_text());assert len(samples)==18
    windows=[]
    for gene in GENES:
        rows=[r for r in annotation if r['name2']==gene];assert len({r['chrom'] for r in rows})==1
        chrom=rows[0]['chrom'];tss=sorted({r['txStart'] if r['strand']=='+' else r['txEnd']-1 for r in rows})
        for width in [5000,20000,100000]:
            for pos in tss: windows.append(dict(gene=gene,window=f'TSS_{width}',chrom=chrom,start=max(0,pos-width),end=pos+width+1,tss=pos))
        windows.append(dict(gene=gene,window='gene_body',chrom=chrom,start=min(r['txStart'] for r in rows),end=max(r['txEnd'] for r in rows),tss=''))
    fields=['gene','window','chrom','start','end','tss'];write_csv(out/'windows.csv',windows,fields)
    (out/'annotation.json').write_text(json.dumps(annotation,indent=2)+'\n')
    inputs=[source/'coordinate_assembly_evidence.json',source/'peak_samples.json',ROOT/'research/results/discovery_mechanism_v1/chip_metadata.txt',ROOT/'research/discovery/MECHANISM_PROTOCOL.md',Path(__file__).resolve(),Path(__file__).with_name('audit_chip.R')]+list(source.glob('*.narrowPeak.gz'))+list(source.glob('hg19_ncbiRefSeq_chr*.json'))+list(source.glob('*.chrom.sizes'))+[out/'windows.csv',out/'annotation.json']
    frozen=dict(frozen_utc=datetime.now(timezone.utc).isoformat(),candidate_peaks_read=False,assembly='coordinate-verified hg19 among hg18/hg19/hg38/mm9; not author-confirmed',
        coordinates='BED zero-based half-open, TSS on minus strand=txEnd-1; symmetric +/-width includes central nucleotide',
        primary='uninfected EtOH/Dex; GR TSS+/-20kb and RNAP2 TSS+/-5kb; transduction libraries secondary descriptions',
        inputs=[dict(path=str(p.relative_to(ROOT)),bytes=p.stat().st_size,sha256=hashlib.file_digest(p.open('rb'),'sha256').hexdigest()) for p in sorted(inputs)])
    (out/'analysis_freeze.json').write_text(json.dumps(frozen,indent=2)+'\n')
    hits=[];counts=[]; quality=[]
    for s in samples:
        title=s['title'];primary=('+' not in title and 'KLF15' not in title);factor='GR' if title.startswith('GR ') else 'RNAP2'
        passed={};total=0;qualified=0;missingq=0
        for w in windows: passed.setdefault((w['gene'],w['window']),set())
        with gzip.open(source/s['file'],'rt') as f:
            for index,line in enumerate(f,1):
                x=line.rstrip().split('\t');assert len(x)==10
                chrom,start,end=x[0],int(x[1]),int(x[2]);q=float(x[8]);total+=1
                if q<0:missingq+=1
                if q<math.log10(20):continue
                qualified+=1
                matches={}
                for w in windows:
                    if chrom==w['chrom'] and start<w['end'] and end>w['start']:
                        key=(w['gene'],w['window']);passed[key].add(index);matches.setdefault(key,[]).append(w)
                for (gene,window),ww in matches.items():
                    tss=[w['tss'] for w in ww if w['tss']!=''];summit=start+int(x[9]) if int(x[9])>=0 else (start+end-1)/2
                    distance=min((abs(summit-t) for t in tss),default='')
                    hits.append(dict(gsm=s['gsm'],title=title,primary=primary,factor=factor,gene=gene,window=window,peak_index=index,
                        chrom=chrom,start=start,end=end,peak_name=x[3],signalValue=float(x[6]),log10p=float(x[7]),log10q=q,summit=summit,nearest_TSS_distance=distance))
        for (g,w),indices in passed.items():
            counts.append(dict(gsm=s['gsm'],title=title,primary=primary,factor=factor,gene=g,window=w,count=len(indices)))
        quality.append(dict(gsm=s['gsm'],title=title,all_peaks=total,q_qualified=qualified,missing_q=missingq))
    hit_fields=['gsm','title','primary','factor','gene','window','peak_index','chrom','start','end','peak_name','signalValue','log10p','log10q','summit','nearest_TSS_distance']
    write_csv(out/'peak_hits.csv',hits,hit_fields)
    write_csv(out/'peak_counts.csv',counts,['gsm','title','primary','factor','gene','window','count'])
    write_csv(out/'peak_quality.csv',quality,['gsm','title','all_peaks','q_qualified','missing_q'])
    result=dict(status='completed',assembly=build['status'],author_confirmed=False,samples=18,primary_samples=sum('+' not in s['title'] and 'KLF15' not in s['title'] for s in samples),
        genes=GENES,all_peaks=sum(r['all_peaks'] for r in quality),qualified_peaks=sum(r['q_qualified'] for r in quality),
        interpretation='Published q-qualified peak-window overlaps, not differential occupancy statistics or direct regulatory/functional proof')
    (out/'summary.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
    print(json.dumps([r for r in counts if r['gene']=='SPARCL1' and r['primary'] and r['window']==('TSS_20000' if r['factor']=='GR' else 'TSS_5000')],indent=2))


if __name__=='__main__':main()
