"""Retrieve alternative primary article sources; reject challenge pages as evidence."""
import argparse
import json
from pathlib import Path
from acquire_chip import fetch


def main():
    ap=argparse.ArgumentParser();ap.add_argument('output',type=Path);out=ap.parse_args().output
    records=[]
    for name,url in [
        ('PMC5576583_front.xml','https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pmc&id=5576583'),
        ('PMC5576583_article.html','https://pmc.ncbi.nlm.nih.gov/articles/PMC5576583/?report=xml'),
        ('PMC5576583_article_alt.html','https://pmc.ncbi.nlm.nih.gov/articles/PMC5576583/?pdf=1'),
        ('article_crossref.json','https://api.crossref.org/works/10.1165/rcmb.2016-0357OC'),
        ('publisher_supplement.pdf','https://www.atsjournals.org/doi/suppl/10.1165/rcmb.2016-0357OC/suppl_file/rcmb.2016-0357oc_supplement.pdf')]:
        r=fetch(url,out/name)
        if r['status']=='downloaded':
            raw=(out/name).read_bytes()
            if name.endswith('.pdf') and not raw.startswith(b'%PDF'): r['status']='invalid_content_not_pdf'
            if name.endswith('.html') and (b'recaptcha' in raw.lower() or b'Glucocorticoid Receptor ChIP-Seq' not in raw): r['status']='invalid_content_not_article'
        records.append(r)
        (out/'alternative_sources.json').write_text(json.dumps(records,indent=2)+'\n')
    print(json.dumps(records,indent=2))


if __name__=='__main__':main()
