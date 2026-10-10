"""Expose published format/design information without candidate result inspection."""
import gzip
from pathlib import Path
import xml.etree.ElementTree as ET

OUT = Path("research/results/discovery_donors_v1")
tree = ET.parse(OUT / "PMC6604213.xml")
report = []
for el in tree.iter():
    text = " ".join(el.itertext())
    if el.tag == "p" and any(term in text.lower() for term in ["donor", "tpm", "quality control", "supplement"]):
        report.append(text)
    if el.tag == "supplementary-material":
        report.append(ET.tostring(el, encoding="unicode"))
with gzip.open(OUT / "tpm.txt.gz", "rt") as f:
    report += ["INPUT FORMAT (first 3 rows):", next(f), next(f), next(f), next(f)]
with gzip.open(OUT / "series_matrix.txt.gz", "rt") as f:
    report += [line for line in f if line.startswith("!Sample_data_processing")]
(OUT / "design_inspection.txt").write_text("\n\n".join(report)+"\n")
print("Published format/design inspection saved")
