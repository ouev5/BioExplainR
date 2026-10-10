"""Inspect published MaxQuant archives through validated, cached HTTP byte ranges."""
import io
import json
import re
import subprocess
import sys
import traceback
from pathlib import Path

import py7zr

from set_validation import rows
from validation_sources import record,utc,json_out,csv_out


class Remote(io.BufferedIOBase):
    def __init__(self,url,size,dest,budget=128*1024*1024,reuse=None):
        self.url=url;self.size=size;self.dest=dest;self.position=0;self.block=256*1024;self.cache={};self.logs=[];self.bytes=0;self.budget=budget
        self.reuse=reuse
    def seekable(self):return True
    def readable(self):return True
    def tell(self):return self.position
    def seek(self,offset,whence=0):
        self.position=offset if whence==0 else self.position+offset if whence==1 else self.size+offset
        if self.position<0:raise ValueError("Negative seek")
        return self.position
    def read(self,size=-1):
        if size<0:size=self.size-self.position
        size=min(size,self.size-self.position);answer=[]
        while size>0:
            number=self.position//self.block;start=number*self.block;end=min(start+self.block,self.size)-1
            if number not in self.cache:
                if self.reuse:
                    prior=self.reuse/(f"{start}-{end}.bin")
                    if prior.exists():
                        log=json.loads((self.reuse/"range_acquisition.json").read_text())
                        rec=next(r for r in log["range_records"] if r["start"]==start and r["end"]==end)
                        assert record(prior)==rec["body"]
                        self.cache[number]=prior.read_bytes();continue
                if self.bytes+end-start+1>self.budget:raise ValueError("Selective extraction exceeded frozen128MiB budget; no full-array success claim")
                name=f"{start}-{end}";body=self.dest/(name+".bin");header=self.dest/(name+".headers.txt")
                p=subprocess.run(["curl","--silent","--show-error","--location","--connect-timeout","10","--max-time","45","--range",f"{start}-{end}","--dump-header",str(header),self.url],capture_output=True)
                body.write_bytes(p.stdout);self.bytes+=len(p.stdout)
                hdr=header.read_text();matches=re.findall(r"[Cc]ontent-[Rr]ange:\s*bytes\s+(\d+)-(\d+)/(\d+)",hdr)
                entry=dict(utc=utc(),url=self.url,start=start,end=end,returncode=p.returncode,stderr=p.stderr.decode(errors="replace"),body=record(body),headers=record(header))
                self.logs.append(entry)
                assert p.returncode==0 and matches and tuple(map(int,matches[-1]))==(start,end,self.size),entry
                assert len(p.stdout)==end-start+1,entry
                self.cache[number]=p.stdout
            data=self.cache[number];offset=self.position-start;n=min(size,len(data)-offset)
            answer.append(data[offset:offset+n]);self.position+=n;size-=n
        return b"".join(answer)


def main(out):
    retry=len(sys.argv)>2 and sys.argv[2]=="--inspect-retry"
    public=out/"public_sources";dest=out/("protein_archives_inspected" if retry else "protein_archives");dest.mkdir(exist_ok=False)
    candidates=[r for r in rows(public/"protein_file_inventory.csv") if r["project"] in ["PXD033514","PXD033534"] and r["category"]=="SEARCH"]
    json_out(dest/"archive_freeze.json",dict(utc=utc(),script=record(Path(__file__)),projects=candidates,
        method="Range206, exact Content-Range/size, cached256KiB,128MiB/project maximum; list then extract proteinGroups.txt only if within budget",
        interpretation="Remote container is partially acquired; extracted member CRC verified by py7zr, whole-archive upstream SHA1 not verified unless full download"))
    for r in candidates:
        acc=r["project"];directory=dest/acc;directory.mkdir();url=r["ftp_url"].replace("ftp://ftp.pride.ebi.ac.uk/","https://ftp.pride.ebi.ac.uk/")
        remote=Remote(url,int(r["bytes"]),directory,reuse=out/"protein_archives"/acc if retry else None)
        result=dict(project=acc,url=url,utc=utc(),container_bytes=int(r["bytes"]))
        try:
            with py7zr.SevenZipFile(remote,mode="r") as archive:
                listing=[dict(filename=a.filename,uncompressed=a.uncompressed,compressed=a.compressed,is_directory=a.is_directory) for a in archive.list()]
                csv_out(directory/"members.csv",listing)
                solid=archive._is_solid();blocks=len(archive.header.main_streams.unpackinfo.folders)
                result.update(solid=solid,blocks=blocks,uncompressed_total=sum(a.uncompressed for a in archive.list()))
                targets=[r["filename"] for r in listing if r["filename"].endswith("proteinGroups.txt")]
                result["targets"]=targets
                print(acc,"solid",solid,"blocks",blocks,"targets",targets,flush=True)
                pack=archive.header.main_streams.packinfo;offset=archive.afterheader+pack.packpos
                packed=[]
                for i,size in enumerate(pack.packsizes):
                    packed.append(dict(block=i,start=offset,end=offset+size-1,packed_bytes=size));offset+=size
                result["packed_blocks"]=packed
                folders=archive.header.main_streams.unpackinfo.folders
                csv_out(directory/"member_blocks.csv",[dict(filename=a.filename,folder=next((i for i,f in enumerate(folders) if a.folder is f),-1),uncompressed=a.uncompressed) for a in archive.files])
                if targets and not retry:
                    extraction=directory/"extracted";extraction.mkdir()
                    archive.extract(path=extraction,targets=targets)
                    result.update(status="proteinGroups_extracted_crc_checked",extracted=[record(p) for p in extraction.rglob("*") if p.is_file()])
                else:result["status"]="members_and_packed_blocks_inspected" if targets else "no_proteinGroups_member"
        except Exception as exc:
            result.update(status="incomplete",error=repr(exc),traceback=traceback.format_exc())
        result.update(transferred_bytes=remote.bytes,range_records=remote.logs,whole_archive_hash_verified=False)
        json_out(directory/"range_acquisition.json",result)
        print(json.dumps({k:v for k,v in result.items() if k!="range_records"},ensure_ascii=False,indent=2),flush=True)


if __name__=="__main__":main(Path(sys.argv[1]).resolve())
