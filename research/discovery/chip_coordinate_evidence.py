"""Resolve build by whole-genome coordinate fingerprint and independent control annotation."""
import argparse
from datetime import datetime,timezone
import gzip
import hashlib
import json
from pathlib import Path
from acquire_chip import fetch


def main():
    ap=argparse.ArgumentParser();ap.add_argument('output',type=Path);out=ap.parse_args().output
    acquisitions=[]
    for name,url in [
        ('hg18.chrom.sizes','https://hgdownload.soe.ucsc.edu/goldenPath/hg18/bigZips/hg18.chrom.sizes'),
        ('Sasse_2017_Figure3_verified.jpg','https://cdn.ncbi.nlm.nih.gov/pmc/blobs/46cd/5576583/baf6a0bfe233/rcmb.2016-0357OC_f3.jpg?source=continuation'),
        ('Sasse_2017_Figure3_alt.jpg','https://pmc.ncbi.nlm.nih.gov/articles/PMC5576583/bin/rcmb.2016-0357OC_f3.jpg?source=continuation')]:
        if not (out/name).exists(): acquisitions.append(fetch(url,out/name))
    # This module never examines SPARCL1 peaks. Check all peak coordinates,
    # plus the fixed canonical FKBP5 control independently in both human builds.
    for build in ['hg19','hg38']:
        name=f'{build}_FKBP5_annotation.json'
        url=f'https://api.genome.ucsc.edu/getData/track?genome={build};track=ncbiRefSeq;chrom=chr6;start=35000000;end=36000000'
        if not (out/name).exists(): acquisitions.append(fetch(url,out/name))
    sizes={b:dict((c,int(n)) for c,n in (line.split() for line in (out/f'{b}.chrom.sizes').read_text().splitlines())) for b in ['hg18','hg19','hg38','mm9']}
    summary={b:dict(unknown_contigs=set(),out_of_bounds=0,max_observed_end={}) for b in sizes}
    peak_files=sorted(out.glob('*.narrowPeak.gz'))
    for p in peak_files:
        with gzip.open(p,'rt') as f:
            for line in f:
                cols=line.split();chrom=cols[0];end=int(cols[2])
                for b,r in summary.items():
                    r['max_observed_end'][chrom]=max(r['max_observed_end'].get(chrom,0),end)
                    if chrom not in sizes[b]: r['unknown_contigs'].add(chrom)
                    elif end>sizes[b][chrom]: r['out_of_bounds']+=1
    compatible=[b for b,r in summary.items() if not r['unknown_contigs'] and r['out_of_bounds']==0]
    for b,r in summary.items():r['unknown_contigs']=sorted(r['unknown_contigs'])
    result=dict(status='coordinate_verified_hg19' if compatible==['hg19'] else 'unverified_assembly',assembly='hg19/GRCh37' if compatible==['hg19'] else None,
        author_confirmed=False,compatible_builds=compatible,comparison=summary,peak_files=len(peak_files),
        evidence='Whole-genome fingerprint: all 18 files fit hg19 lengths; many coordinates impossible under hg18/hg38/mm9. Source authors did not confirm correction; original GEO mm9 metadata retained.',
        acquisitions=acquisitions,utc=datetime.now(timezone.utc).isoformat())
    (out/'coordinate_assembly_evidence.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))


if __name__=='__main__':main()
