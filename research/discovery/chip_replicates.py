"""Describe reciprocal peak overlap across uninfected culture replicates, no differential test."""
import argparse
import csv
import json
from pathlib import Path


def main():
    ap=argparse.ArgumentParser();ap.add_argument('output',type=Path);out=ap.parse_args().output
    with (out/'peak_hits.csv').open() as f:hits=list(csv.DictReader(f))
    with (out/'peak_counts.csv').open() as f:counts=list(csv.DictReader(f))
    rows=[]
    for gene in ['SPARCL1','FKBP5','TSC22D3','KLF15']:
        for factor,window in [('GR','TSS_20000'),('RNAP2','TSS_5000')]:
            for treatment in ['EtOH','Dex']:
                key=lambda r:r['gene']==gene and r['factor']==factor and r['window']==window and r['primary']=='True' and r['title'].split()[1].split('_')[0]==treatment
                libs=sorted({r['gsm'] for r in counts if key(r)});assert len(libs)==2
                a=[r for r in hits if key(r) and r['gsm']==libs[0]];b=[r for r in hits if key(r) and r['gsm']==libs[1]]
                overlaps=[(x,y) for x in a for y in b if x['chrom']==y['chrom'] and int(x['start'])<int(y['end']) and int(x['end'])>int(y['start'])]
                rows.append(dict(gene=gene,factor=factor,window=window,treatment=treatment,replicate1=libs[0],replicate2=libs[1],
                    peaks1=len(a),peaks2=len(b),peaks1_with_overlap=len({x['peak_index'] for x,y in overlaps}),
                    peaks2_with_overlap=len({y['peak_index'] for x,y in overlaps}),overlap_pairs=len(overlaps)))
    with (out/'replicate_overlap.csv').open('w') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
    print(json.dumps(rows[:4],indent=2))


if __name__=='__main__':main()
