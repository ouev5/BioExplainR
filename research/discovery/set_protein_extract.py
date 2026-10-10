"""Download only packed protein-table blocks, preserving HTTP ranges and CRCs."""
import concurrent.futures
import io
import json
import re
import subprocess
import sys
import traceback
import zlib
from pathlib import Path
import py7zr
from set_validation import rows
from validation_sources import record,utc,json_out


class LocalRanges(io.BufferedIOBase):
    def __init__(self,size,segments):self.size=size;self.segments=segments;self.position=0
    def seekable(self):return True
    def readable(self):return True
    def tell(self):return self.position
    def seek(self,offset,whence=0):
        self.position=offset if whence==0 else self.position+offset if whence==1 else self.size+offset
        return self.position
    def read(self,size=-1):
        if size<0:size=self.size-self.position
        size=min(size,self.size-self.position);answer=[]
        while size>0:
            matches=[(start,end,path) for start,end,path in self.segments if start<=self.position<=end]
            if not matches:
                if answer:break
                raise ValueError(f"Non-acquired archive byte requested at{self.position}")
            start,end,path=matches[0];n=min(size,end-self.position+1)
            with path.open("rb") as stream:stream.seek(self.position-start);part=stream.read(n)
            assert len(part)==n;answer.append(part);self.position+=n;size-=n
        return b"".join(answer)


def main(out):
    small="--small-parts" in sys.argv
    dest=out/("protein_full_tables_small" if small else "protein_full_tables");resume="--resume" in sys.argv
    dest.mkdir(exist_ok=resume)
    if not resume:
        json_out(dest/"extraction_amendment.json",dict(utc=utc(),script=record(Path(__file__)),
            reason="Header inspection confirmed published complete proteinGroups members inside solid blocks. Increase bounded transfer to necessary block2 only,282034015/503686729bytes; retain initial128MiB plan and failed inspection records.",
            method="96concurrent256KiB40sHTTPparts after slow8MiB timeout" if small else "6concurrent8MiB90sHTTPparts",
            checks="Exact range/length and identicalLast-Modified; member CRCs; no wholearchiveSHA1 assertion"))
    else:
        number=1
        while (dest/f"resume_amendment_{number}.json").exists():number+=1
        json_out(dest/f"resume_amendment_{number}.json",dict(utc=utc(),script=record(Path(__file__)),reason="Resume verified successful parts; new attempt filenames for failures; reduce concurrency24"))
    all_records=[]
    for acc in ["PXD033514","PXD033534"]:
        directory=dest/acc;directory.mkdir(exist_ok=resume)
        if (directory/"extraction_verified.json").exists():
            assert json.loads((directory/"extraction_verified.json").read_text())["status"]=="pass"
            continue
        if (directory/"extraction.json").exists():
            assert json.loads((directory/"extraction.json").read_text())["status"]=="pass"
            continue
        inspected=json.loads((out/"protein_archives_inspected"/acc/"range_acquisition.json").read_text())
        block=inspected["packed_blocks"][2];url=inspected["url"];size=inspected["container_bytes"]
        part_size=256*1024 if small else 8*1024*1024
        tasks=[(start,min(start+part_size-1,block["end"])) for start in range(block["start"],block["end"]+1,part_size)]
        def get(task):
            start,end=task;name=f"{start}-{end}";path=directory/(name+".bin");logpath=directory/(name+".json")
            if logpath.exists():
                log=json.loads(logpath.read_text());assert log["status"]=="pass" and record(path)==log["body"];return log
            attempts=[]
            attempt_start=len(list(directory.glob(name+".attempt*.headers.txt")))+1
            for attempt in range(attempt_start,attempt_start+3):
                header=directory/(name+f".attempt{attempt}.headers.txt")
                p=subprocess.run(["curl","--silent","--show-error","--location","--connect-timeout","10","--max-time","40" if small else "90","--range",name,"--dump-header",str(header),url],capture_output=True)
                matches=re.findall(r"[Cc]ontent-[Rr]ange:\s*bytes\s+(\d+)-(\d+)/(\d+)",header.read_text())
                ok=p.returncode==0 and matches and tuple(map(int,matches[-1]))==(start,end,size) and len(p.stdout)==end-start+1
                attempts.append(dict(utc=utc(),returncode=p.returncode,bytes=len(p.stdout),stderr=p.stderr.decode(errors="replace"),header=record(header)))
                if ok:
                    path.write_bytes(p.stdout);modified=re.findall(r"[Ll]ast-[Mm]odified:\s*([^\r\n]+)",header.read_text())
                    log=dict(status="pass",url=url,start=start,end=end,last_modified=modified[-1] if modified else "",body=record(path),attempts=attempts)
                    json_out(logpath,log);return log
                failed_body=directory/(name+f".attempt{attempt}.partial.bin");failed_body.write_bytes(p.stdout)
                attempts[-1]["failed_body"]=record(failed_body)
            fail=dict(status="failed",url=url,start=start,end=end,attempts=attempts)
            json_out(directory/(name+f".failed{attempt_start}.json"),fail);return fail
        print(acc,"start",len(tasks),"parts",flush=True)
        with concurrent.futures.ThreadPoolExecutor(max_workers=24 if small and resume else 96 if small else 6) as pool:logs=list(pool.map(get,tasks))
        json_out(directory/(f"parts_manifest_resume{number}.json" if resume else "parts_manifest.json"),dict(utc=utc(),parts=logs))
        print(acc,"completed",sum(r["status"]=="pass" for r in logs),"of",len(logs),flush=True)
        assert all(r["status"]=="pass" for r in logs),"Incomplete block download; resume after failure inspection"
        assert len({r["last_modified"] for r in logs})==1 and logs[0]["last_modified"]
        segments=[(r["start"],r["end"],directory/f'{r["start"]}-{r["end"]}.bin') for r in logs]
        old=out/"protein_archives"/acc
        for r in json.loads((old/"range_acquisition.json").read_text())["range_records"]:
            path=old/f'{r["start"]}-{r["end"]}.bin';assert record(path)==r["body"]
            segments.append((r["start"],r["end"],path))
        remote=LocalRanges(size,segments)
        try:
            extraction=directory/"extracted";extraction.mkdir()
            with py7zr.SevenZipFile(remote,"r") as archive:
                targets=[a.filename for a in archive.list() if a.filename.endswith(("proteinGroups.txt","parameters.txt")) or "SampleNameEncription" in a.filename]
                crcs={a.filename:a.crc32 for a in archive.list() if a.filename in targets}
                archive.extract(path=extraction,targets=targets)
            outputs=[]
            for target in targets:
                p=extraction/target;assert p.is_file()
                assert zlib.crc32(p.read_bytes())==crcs[target],target
                outputs.append(dict(**record(p),crc32=crcs[target],member=target))
            result=dict(status="pass",utc=utc(),outputs=outputs,partial_container=True,whole_archive_SHA1_verified=False,
                downloaded_block_bytes=block["packed_bytes"],range_parts=len(logs),scope="Complete unselected MaxQuant proteinGroups with per-member CRC, original mapping and processing parameters")
        except Exception as exc:
            result=dict(status="incomplete",error=repr(exc),traceback=traceback.format_exc())
        json_out(directory/"extraction.json",result);print(acc,result["status"],flush=True)


if __name__=="__main__":main(Path(sys.argv[1]).resolve())
