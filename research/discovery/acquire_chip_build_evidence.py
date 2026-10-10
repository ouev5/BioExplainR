"""Save figure/build sources and UCSC reference annotations without inspecting SPARCL1 peaks."""
import argparse
import json
from pathlib import Path
from acquire_chip import fetch


def main():
    ap=argparse.ArgumentParser();ap.add_argument('output',type=Path);ap.add_argument('--resume',action='store_true');a=ap.parse_args();out=a.output
    sources=[('Sasse_2017_Figure3.jpg','https://cdn.ncbi.nlm.nih.gov/pmc/blobs/46cd/5576583/baf6a0bfe233/rcmb.2016-0357OC_f3.jpg'),
        ('Sasse_2017_OUP.html','https://academic.oup.com/ajrcmb/article/57/2/226/8467261'),
        ('Sasse_2017_OUP.pdf','https://academic.oup.com/ajrcmb/article-pdf/57/2/226/66805205/ajrcmb_57_2_226.pdf'),
        ('Sasse_2017_OUP_supplement.pdf','https://oup.silverchair-cdn.com/oup/backfile/Content_public/Journal/ajrcmb/57/2/10.1165_rcmb.2016-0357OC/1/rcmb.2016-0357oc_supplement.pdf')]
    # Download ncbiRefSeq *whole chromosomes* so all annotated TSS for fixed genes
    # are included. This is annotation retrieval, not candidate peak inspection.
    for chrom in ['chr3','chr4','chr6','chrX']:
        sources.append((f'hg19_ncbiRefSeq_{chrom}.json',f'https://api.genome.ucsc.edu/getData/track?genome=hg19;track=ncbiRefSeq;chrom={chrom}'))
    manifest=out/'build_evidence_acquisition.json'
    records=json.loads(manifest.read_text()) if a.resume and manifest.exists() else []
    for name,url in sources:
        if any(r.get('path')==name and r['status']=='downloaded' for r in records): continue
        p=out/name; r=fetch(url,p)
        if r['status']=='downloaded' and name.endswith('.pdf') and not p.read_bytes().startswith(b'%PDF'): r['status']='invalid_content_not_pdf'
        records.append(r); (out/'build_evidence_acquisition.json').write_text(json.dumps(records,indent=2)+'\n')
    print(json.dumps(records,indent=2))


if __name__=='__main__':main()
