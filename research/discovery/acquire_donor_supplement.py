"""Preserve original sample-to-donor mapping before any candidate statistics."""
from pathlib import Path
import fitz
import zipfile
from prepare_context import fetch, record, write_json

out = Path("research/results/discovery_donors_v1")
url = "https://pmc.ncbi.nlm.nih.gov/articles/instance/6604213/bin/rcmb.2018-0385OC_kan_data_supplement.pdf"
path = out / "original_supplement_verified.pdf"
archive = out / "supplementaryFiles.zip"
archive_url = "https://www.ebi.ac.uk/europepmc/webservices/rest/PMC6604213/supplementaryFiles?format=zip"
item = ({**record(archive), "url": archive_url, "transport": "curl GET after urllib/HEAD timeouts"}
        if archive.exists() else fetch(archive_url, archive))
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    name = "rcmb.2018-0385OC_kan_data_supplement.pdf"
    path.write_bytes(z.read(name))
with fitz.open(path) as pdf:
    assert len(pdf) > 1 and "Preparing to download" not in pdf[0].get_text()
    (out / "supplement_text.txt").write_text("\n\n".join(f"PAGE {i+1}\n"+p.get_text() for i, p in enumerate(pdf)))
write_json(out / "supplement_input.json", item)
print(item)
