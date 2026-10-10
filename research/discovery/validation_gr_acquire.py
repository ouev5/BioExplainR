"""Freeze public U2OS GR rescue comparisons and acquire count/protein inputs."""
import argparse
import gzip
import json
import re
from pathlib import Path

from validation_sources import ROOT, HERE, utc, record, csv_out, json_out, fetch


def acquire(url, path):
    return {"status": "retrieved", "url": url, "reuse_saved": True, **record(path)} if path.exists() else fetch(url, path, 45)


def run(out, action):
    dest = out / "gr_public"
    protein = out / "protein_public"
    protein.mkdir(exist_ok=True)
    if action == "protein":
        logs = []
        for name, url in [
            ("pride_project.json", "https://www.ebi.ac.uk/pride/ws/archive/v2/projects/PXD081613"),
            ("pride_files.json", "https://www.ebi.ac.uk/pride/ws/archive/v2/projects/PXD081613/files?pageSize=100"),
            ("lab_schemeTMT.csv", "https://ftp.pride.ebi.ac.uk/pride/data/archive/2026/09/PXD081613/lab_schemeTMT.csv"),
            ("protein_study_information.txt", "https://ftp.pride.ebi.ac.uk/pride/data/archive/2026/09/PXD081613/1898311467_Anna_TMT_TP_StudyInformation.txt"),
            ("biorxiv_metadata.json", "https://api.biorxiv.org/details/biorxiv/10.64898/2026.08.12.743743"),
        ]:
            rec = acquire(url, protein / name)
            logs.append(rec)
            print(name, rec["status"], rec.get("bytes"), flush=True)
        json_out(protein / "metadata_acquisition.json", {"utc": utc(), "records": logs})
        return
    if action == "freeze":
        samples = []
        for study in ["GSE342887", "GSE342771"]:
            text = (dest / "sources" / (study + "_metadata.txt")).read_text()
            for chunk in text.split("^SAMPLE = ")[1:]:
                gsm = chunk.splitlines()[0]
                title = re.search(r"!Sample_title = (.+)", chunk)[1]
                genotype = "alpha" if "GR alpha," in title else "AF2" if "E755R" in title else "IDR398"
                drug = "CORT" if ", CORT," in title else "DMSO"
                replicate = int(re.search(r"replicate (\d)", title)[1])
                url = re.search(r"!Sample_supplementary_file_1 = (.+)", chunk)[1].replace("ftp://", "https://")
                samples.append({"study": study, "sample": gsm, "title": title, "genotype": genotype,
                                "drug": drug, "replicate": replicate, "url": url,
                                "filename": url.rsplit("/", 1)[1]})
        csv_out(dest / "sample_map.csv", samples)
        json_out(dest / "design_freeze.json", {
            "utc": utc(), "script": record(Path(__file__)), "sample_map": record(dest / "sample_map.csv"),
            "candidates": ["PER2", "PER3", "METTL7A", "MAOA", "ANGPTL2", "FSTL3"],
            "controls": ["PER1", "FKBP5", "TSC22D3", "DUSP1", "NR3C1"],
            "RNA_model": "Each assay separately TMM/voom/eBayes, ~0+genotype_drug; filterByExpr full design",
            "comparisons": ["CORT_alpha", "CORT_AF2", "CORT_IDR398", "CORT_x_AF2", "CORT_x_IDR398"],
            "family": "11 genes x 5 contrasts = 55 Holm per assay; missing/filtered P=1",
            "unit": "one U2OS cell line, culture replicates; no human-donor inference",
            "design_boundary": "All transcriptomic samples are GR KO rescued with a construct. No empty KO transcriptomic arm; cannot estimate WT rescue vs empty KO interaction.",
            "treatment": "100 nM corticosterone 90min; 4SU final30min; cultures temperature-entrained",
            "assay_dependence": "mRNA-seq and TT-seq parallel samples, not independent datasets of biological units",
            "publication_status": "2026-08 bioRxiv preprint, not peer-reviewed article",
            "timing": "Only design metadata read; candidate counts unexamined."})
        print("GR design frozen: 18 mRNA and 17 nascent libraries; rescue variants, no empty KO", flush=True)
        return
    if action == "counts":
        import csv
        samples = list(csv.DictReader((dest / "sample_map.csv").open()))
        logs = []
        for s in samples:
            path = dest / "sources" / s["filename"]
            rec = acquire(s["url"], path)
            if rec["status"] == "retrieved":
                lines = gzip.decompress(path.read_bytes()).decode("utf-8").splitlines()
                rec["gzip_crc_complete"] = True
                print(s["sample"], len(lines), lines[0], flush=True)
            logs.append(rec)
            # One record per file retained immediately.
            log = dest / "sources" / (s["sample"] + "_acquisition.json")
            if not log.exists():
                json_out(log, rec)
        json_out(dest / "input_manifest.json", {"utc": utc(), "records": logs})


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["freeze", "counts", "protein"])
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    run(args.output.resolve(), args.action)
