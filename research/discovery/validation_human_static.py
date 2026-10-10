"""Save the publisher's public static ZIP and verify every archived member."""
import sys
import zipfile
from pathlib import Path
from validation_sources import fetch,json_out,record,utc
dest=Path(sys.argv[1]).resolve()/"human_protein"
url="https://mdpi-res.com/d_attachment/cells/cells-11-03164/article_deploy/cells-11-03164-s001.zip"
path=dest/"publisher_verified_supplement.zip"
rec=fetch(url,path,60)
if rec["status"]=="retrieved":
    assert zipfile.is_zipfile(path)
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None
        members=[]
        for name in archive.namelist():
            assert Path(name).name==name,"Reject archive path traversal"
            target=dest/Path(name).name
            assert not target.exists()
            target.write_bytes(archive.read(name))
            members.append(record(target))
        rec["members"]=members
        print(archive.namelist(),flush=True)
json_out(dest/"publisher_static_acquisition.json",{"utc":utc(),"input":rec})
