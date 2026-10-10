"""Extract member-CRC-verified tables from complete saved packed blocks."""
import json
import sys
import zlib
from pathlib import Path
import py7zr
from set_protein_extract import LocalRanges
from validation_sources import record,utc,json_out

out=Path(sys.argv[1]).resolve();acc=sys.argv[2];directory=out/"protein_full_tables_small"/acc
manifests=sorted(directory.glob("parts_manifest*.json"),key=lambda p:p.stat().st_mtime)
logs=json.loads(manifests[-1].read_text())["parts"]
assert all(r["status"]=="pass" for r in logs),"Incomplete packedblock"
assert len({r["last_modified"] for r in logs})==1
segments=[]
for r in logs:
    p=directory/f'{r["start"]}-{r["end"]}.bin';assert record(p)==r["body"]
    segments.append((r["start"],r["end"],p))
old=out/"protein_archives"/acc;metadata=json.loads((old/"range_acquisition.json").read_text())
for r in metadata["range_records"]:
    p=old/f'{r["start"]}-{r["end"]}.bin';assert record(p)==r["body"];segments.append((r["start"],r["end"],p))
dest=directory/"extracted_verified";dest.mkdir(exist_ok=False)
with py7zr.SevenZipFile(LocalRanges(metadata["container_bytes"],segments),"r") as archive:
    targets=[a.filename for a in archive.list() if a.filename.endswith(("proteinGroups.txt","parameters.txt")) or "SampleNameEncription" in a.filename]
    crcs={a.filename:a.crc32 for a in archive.list() if a.filename in targets}
    archive.extract(path=dest,targets=targets)
outputs=[]
for target in targets:
    p=dest/target;assert p.is_file() and zlib.crc32(p.read_bytes())==crcs[target],target
    outputs.append(dict(**record(p),crc32=crcs[target],member=target))
json_out(directory/"extraction_verified.json",dict(status="pass",utc=utc(),script=record(Path(__file__)),outputs=outputs,
    partial_container=True,whole_archive_SHA1_verified=False,range_parts=len(logs),
    repair="BufferedIO.read may return shorter block at acquired boundary; no missing bytes synthesized. All requested member CRCs verified.",
    scope="Complete original unselectedMaxQuant proteinGroups, samplemapping andparameters; archivedcontainerpartial"))
print(acc,"all selected member CRCs passed")
