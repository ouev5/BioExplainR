"""Seal transparent scientific interpretation and hashes after independent audits."""
from datetime import datetime,timezone
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]


def main():
    mechanism=ROOT/'research/results/discovery_mechanism_fit_v4'
    chip=ROOT/'research/results/discovery_chip_analysis_v1'
    assert json.loads((mechanism/'audit.json').read_text())['status']=='pass'
    assert json.loads((chip/'r_audit.json').read_text())['status']=='pass'
    assert json.loads((chip/'r_replicate_audit.json').read_text())['status']=='pass'
    ledger=dict(status='analyses_completed',utc=datetime.now(timezone.utc).isoformat(),
        receptor=dict(dataset='GSE229084',unit='A549 cancer epithelial cell-line cultures, not ASM/patients',
            libraries=47,batches=4,features=35942,filter_retained=15437,
            candidate='SPARCL1',candidate_count_range=[0,4],candidate_primary_interactions='all three not_estimable after fixed filter',
            conclusion='This dataset cannot establish or reject SPARCL1 GR dependence. Control response cannot substitute for candidate.',
            control_FKBP5=dict(DEX_log2_effect=2.59388903839693,KH103_interaction=-2.51520232773266,MIF_interaction=-2.49773488491858,Cort113_interaction=-2.12061078993093),
            mapping='DMSO titles rep2/rep3 conflict with batch set3/set4; suffix linked to public batch and exact count header; no invented missing DMSO set2',
            published_object_mapping='Authors SE.processed.rds colData independently confirms all 51 GEO/MG IDs, treatments/batches; MG_15 absent; downloaded nested gzip CRC verified',
            published_counts_crosscheck='13,834 matching gene IDs x 51 columns = 705,534 measurements agree (max difference 4.66e-10); 102 blank/description IDs unmappable, listed; SPARCL1 absent from authors filtered object',
            independent_audit='All 35,942 gene filters; 188 original candidate/control measurements; 39 estimable WLS contrasts; TMM/voom/eBayes not independently reestimated',
            amendments='CI export indexed unnamed s2.post correctly; frozen fit/RDS unchanged; exact vs contrasts.fit common-correlation SE sensitivity max relative difference 2.19%'),
        chromatin=dict(dataset='GSE95632',unit='One HASM2 donor cell line, two cultures per primary condition/factor; not independent donors',
            assembly='coordinate_verified_hg19 among hg18/hg19/hg38/mm9',author_confirmed=False,
            original_metadata='Human sample with mm9 label retained as conflict',primary_libraries=8,all_peak_libraries=18,
            all_peaks=1347409,q_qualified=1346792,SPARCL1_GR_TSS20kb_vehicle=[4,2],SPARCL1_GR_TSS20kb_DEX=[8,8],
            SPARCL1_RNAPII_TSS5kb_vehicle=[0,0],SPARCL1_RNAPII_TSS5kb_DEX=[1,1],DEX_GR_replicated_overlap_pairs=8,DEX_RNAPII_replicated_overlap_pairs=1,
            conclusion='Published q-qualified peaks overlap candidate windows reproducibly in DEX. Not differential occupancy statistics, enhancer linkage, direct regulation or functional proof.',
            independent_audit='R GenomicRanges recomputed all RefSeq windows, 288 counts, 2,505 hits, summit distances and 16 replicate comparisons',
            source='Saved PMC primary HTML, all peaks, four RefSeq chromosome snapshots, chromosome sizes; XML unavailable and publisher supplement HTTP403; OCR inconclusive'),
        not_done=['New donor/wet-lab experiments','GR rescue, site reporter/CRISPR','SPARCL1 protein/matrix/functional endpoints','Third-party human scientific/code sign-off'])
    for directory in [mechanism,chip]:
        (directory/'scientific_ledger.json').write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+'\n')
        files=[dict(path=p.name,bytes=p.stat().st_size,sha256=hashlib.file_digest(p.open('rb'),'sha256').hexdigest()) for p in sorted(directory.iterdir()) if p.is_file() and p.name!='files_manifest.json' and not p.name.endswith('.incomplete')]
        (directory/'files_manifest.json').write_text(json.dumps(dict(files=files),indent=2)+'\n')
    print(json.dumps(ledger,ensure_ascii=False,indent=2))


if __name__=='__main__':main()
