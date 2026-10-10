"""Use the original v0.8 date line for HEAD's pre-existing narrative comparison."""
from pathlib import Path

p=Path('research/common_performance/check_handoff.py')
source=p.read_text()
source=source.replace("assert old.split(marker,1)[1]==current.split(marker,1)[1]",
    "marker='日期：2026-10-08；软件0.4.0.9000'; assert old.split(marker,1)[1]==current.split(marker,1)[1]")
exec(compile(source,str(p),'exec'))
