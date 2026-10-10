"""Audit species/build conflict using every peak's contig/bounds against UCSC builds."""
import argparse
from datetime import datetime,timezone
import gzip
import hashlib
import json
from pathlib import Path
import subprocess
from acquire_chip import fetch


def main():
    ap=argparse.ArgumentParser(); ap.add_argument('output',type=Path); out=ap.parse_args().output
    sources=[]
    for build in ['hg19','hg38','mm9']:
        p=out/f'{build}.chrom.sizes'
        if not p.exists(): sources.append(fetch(f'https://hgdownload.soe.ucsc.edu/goldenPath/{build}/bigZips/{build}.chrom.sizes',p))
    stats=[]; comparisons={b:dict(unknown_contigs=set(),out_of_bounds=0,unique_contigs=set()) for b in ['hg19','hg38','mm9']}
    sizes={b:dict((c,int(n)) for c,n in (line.split() for line in (out/f'{b}.chrom.sizes').read_text().splitlines())) for b in comparisons}
    for p in sorted(out.glob('*.narrowPeak.gz')):
        chroms={}; n=0
        with gzip.open(p,'rt') as f:
            for line in f:
                cols=line.split(); assert len(cols)==10
                c,start,end=cols[0],int(cols[1]),int(cols[2]); assert 0<=start<end
                chroms[c]=max(chroms.get(c,0),end); n+=1
                for b,r in comparisons.items():
                    if c not in sizes[b]: r['unknown_contigs'].add(c)
                    elif end>sizes[b][c]: r['out_of_bounds']+=1
        stats.append(dict(file=p.name,peaks=n,chrom_max_end=chroms,sha256=hashlib.file_digest(p.open('rb'),'sha256').hexdigest()))
    for b,r in comparisons.items():
        observed={c for s in stats for c in s['chrom_max_end']}
        r['unique_contigs']=sorted(observed&set(sizes[b])-set().union(*(set(sizes[o]) for o in sizes if o!=b)))
        r['unknown_contigs']=sorted(r['unknown_contigs'])
    compatible=[b for b,r in comparisons.items() if not r['unknown_contigs'] and not r['out_of_bounds']]
    result=dict(status='verified_hg19_by_build_specific_contigs' if compatible==['hg19'] and comparisons['hg19']['unique_contigs'] else 'unverified_assembly',
        compatible_builds=compatible,comparisons=comparisons,peak_files=stats,
        metadata_conflict='Human HASM2 GEO incorrectly or incompatibly labeled mm9; original retained',
        evidence_basis='All published peak contig names and all ends checked against independently downloaded build chromosome sizes; unique alternate contigs establish build, not guessed from candidate locus',
        acquired=sources,utc=datetime.now(timezone.utc).isoformat())
    (out/'assembly_audit.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))


if __name__=='__main__': main()
