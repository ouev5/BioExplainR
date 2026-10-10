"""Read-only SQLite over verified, cached PRIDE HTTP ranges (metadata only)."""
import argparse
import hashlib
import json
import time
import urllib.request
from pathlib import Path

import apsw

from asm_ev_export import OUT, BASE
from validation_sources import utc, record, json_out


class RemoteFile:
    def __init__(self, name, offline=False, blocksize=65536):
        self.name = name
        self.offline = offline
        rows = json.loads((OUT / "sources/files_corrected.json").read_text())
        self.size = next(r["fileSizeBytes"] for r in rows if r["fileName"] == name)
        self.folder = OUT / "ranges" / name
        self.folder.mkdir(exist_ok=True)
        self.blocksize = blocksize
        self.identity = None
        self.blocks = {}
        self.used = set()

    def block(self, start):
        end = min(start + self.blocksize, self.size) - 1
        path = self.folder / f"{start}-{end}.bin"
        logpath = path.with_suffix(".json")
        if start not in self.blocks:
            if path.exists():
                log = json.loads(logpath.read_text())
                assert log["status"] == "retrieved" and record(path) == log["file"]
                blob = path.read_bytes()
            else:
                if self.offline:
                    raise ValueError(f"Offline uncached range {self.name}: {start}-{end}")
                log = dict(url=BASE + self.name, requested=[start, end], attempts=[])
                for attempt in range(3):
                    try:
                        req = urllib.request.Request(BASE + self.name, headers={
                            "Range": f"bytes={start}-{end}", "Accept-Encoding": "identity",
                            "User-Agent": "BioExplainR-ASM-EV-version/0.4"})
                        with urllib.request.urlopen(req, timeout=15) as res:
                            assert res.status == 206
                            assert res.headers["Content-Range"] == f"bytes {start}-{end}/{self.size}"
                            headers = dict(res.headers)
                            blob = res.read(end - start + 2)
                            assert len(blob) == end - start + 1
                        path.write_bytes(blob)
                        log.update(status="retrieved", utc=utc(), http_status=206, headers=headers, file=record(path))
                        json_out(logpath, log)
                        break
                    except Exception as exc:
                        log["attempts"].append(dict(utc=utc(), error=str(exc), attempt=attempt + 1))
                        time.sleep(attempt + 1)
                else:
                    json_out(logpath, dict(log, status="failed"))
                    raise IOError(f"Range failed {self.name}:{start}")
            identity = (log["headers"]["ETag"], log["headers"]["Last-Modified"])
            if self.identity is None:
                self.identity = identity
            assert self.identity == identity, "Remote file identity changed across blocks"
            self.blocks[start] = blob
        self.used.add(start)
        if len(self.used) * self.blocksize > 64 * 1024 * 1024:
            raise ValueError("Metadata acquisition exceeded fixed 64MiB per-file limit")
        return self.blocks[start]

    def xRead(self, amount, offset):
        if offset + amount > self.size:
            raise apsw.IOError("Read outside original file")
        result = bytearray()
        while amount:
            start = offset // self.blocksize * self.blocksize
            blob = self.block(start)
            take = min(amount, len(blob) - (offset - start))
            result += blob[offset - start:offset - start + take]
            offset += take
            amount -= take
        return bytes(result)

    def xFileSize(self):
        return self.size

    def xClose(self):
        pass

    def xLock(self, level):
        pass

    def xUnlock(self, level):
        pass

    def xCheckReservedLock(self):
        return False

    def xFileControl(self, op, ptr):
        return False

    def xSectorSize(self):
        return 4096

    def xDeviceCharacteristics(self):
        return apsw.SQLITE_IOCAP_IMMUTABLE


class RemoteVFS(apsw.VFS):
    def __init__(self, remote):
        super().__init__("asm_ev_remote", "")
        self.remote = remote

    def xOpen(self, name, flags):
        assert flags[0] & apsw.SQLITE_OPEN_READONLY
        flags[1] = apsw.SQLITE_OPEN_READONLY
        return self.remote

    def xAccess(self, pathname, flags):
        return False


def safe(value):
    if isinstance(value, bytes):
        return dict(bytes=len(value), sha256=hashlib.sha256(value).hexdigest())
    return value


def inspect(name, label, tables, offline=False, blocksize=65536):
    dest = OUT / (label + ".json")
    if dest.exists():
        raise ValueError(f"Refusing overwrite {dest}")
    remote = RemoteFile(name, offline, blocksize)
    vfs = RemoteVFS(remote)
    con = apsw.Connection(name, flags=apsw.SQLITE_OPEN_READONLY, vfs="asm_ev_remote")
    con.execute("PRAGMA query_only=ON")
    schema = list(con.execute("SELECT type,name,tbl_name,rootpage,sql FROM sqlite_master ORDER BY type,name"))
    results = []
    for table in tables:
        assert table in {r[1] for r in schema if r[0] == "table"}
        sql = 'SELECT * FROM "' + table.replace('"', '""') + '"'
        cur = con.execute(sql)
        columns = [r[0] for r in cur.get_description()]
        data = [[safe(v) for v in row] for row in cur]
        results.append(dict(table=table, columns=columns, rows=data, row_count=len(data)))
    con.close()
    vfs.unregister()
    value = dict(status="pass", utc=utc(), name=name, file_bytes=remote.size,
        schema=[dict(zip(["type", "name", "table", "rootpage", "sql"], r)) for r in schema],
        metadata=results, original_identity=remote.identity, cached_blocks=len(remote.used),
        cached_bytes=sum(len(remote.blocks[s]) for s in remote.used),
        used_ranges=[record(remote.folder / f"{s}-{min(s + remote.blocksize, remote.size) - 1}.bin") for s in sorted(remote.used)],
        apsw_version=apsw.apswversion(), sqlite_version=apsw.sqlitelibversion(),
        offline=offline, whole_file_sha1_verified=False,
        scope="Metadata/schema inspection; not full original database or full quantified export")
    json_out(dest, value)
    print(json.dumps(dict(name=name, cached_blocks=value["cached_blocks"],
        tables=len([r for r in schema if r[0] == "table"]),
        metadata=[dict(table=r["table"], rows=r["row_count"], columns=r["columns"]) for r in results]),
        ensure_ascii=False, indent=2))
    return value


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("name")
    p.add_argument("label")
    p.add_argument("--tables", nargs="*", default=[])
    p.add_argument("--offline", action="store_true")
    p.add_argument("--blocksize", type=int, default=65536)
    a = p.parse_args()
    inspect(a.name, a.label, a.tables, a.offline, a.blocksize)
