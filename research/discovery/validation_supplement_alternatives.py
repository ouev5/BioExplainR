"""Use public OA package/attachment interfaces; reject HTML download placeholders."""
import json
import sys
import tarfile
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path
from validation_sources import fetch, json_out, record, utc

dest = Path(sys.argv[1]).resolve() / "human_protein"
logs = []
url = "https://pmc.ncbi.nlm.nih.gov/utils/oa/oa.fcgi?id=PMC9562650"
path = dest / "oa_package.xml"
rec = fetch(url, path, 30); logs.append(rec)
if rec["status"] == "retrieved":
    links = [e.get("href") for e in ET.parse(path).getroot().iter("link") if e.get("format") == "tgz"]
    for link in links:
        package = dest / "PMC9562650.tar.gz"
        rec = fetch(link.replace("ftp://", "https://"), package, 60); logs.append(rec)
        if rec["status"] == "retrieved":
            with tarfile.open(package) as archive:
                selected = [m for m in archive.getmembers() if m.name.endswith("cells-11-03164-s001.zip")]
                assert len(selected) == 1
                data = archive.extractfile(selected[0]).read()
                target = dest / "verified_supplement.zip"
                target.write_bytes(data)
                assert zipfile.is_zipfile(target)
                rec["verified_supplement"] = record(target)
if not (dest / "verified_supplement.zip").exists():
    for i, url in enumerate([
        "https://pmc.ncbi.nlm.nih.gov/articles/instance/9562650/bin/cells-11-03164-s001.zip?download=1",
        "https://www.mdpi.com/2073-4409/11/19/3164/s1?version=1665329229",
        "https://europepmc.org/articles/PMC9562650/bin/cells-11-03164-s001.zip",
        "https://www.ebi.ac.uk/europepmc/webservices/rest/PMC9562650/supplementaryFiles",
    ], 1):
        target = dest / f"supplement_alternative_{i}.bin"
        rec = fetch(url, target, 30); logs.append(rec)
        if rec["status"] == "retrieved":
            rec["valid_zip"] = zipfile.is_zipfile(target)
            if rec["valid_zip"]:
                (dest / "verified_supplement.zip").write_bytes(target.read_bytes())
                break
json_out(dest / "supplement_alternative_acquisition.json", {"utc": utc(), "records": logs})
if (dest / "verified_supplement.zip").exists():
    with zipfile.ZipFile(dest / "verified_supplement.zip") as archive:
        print("Verified supplement members", archive.namelist(), flush=True)
else:
    print("Supplement unavailable via tested interfaces; failures retained", flush=True)
