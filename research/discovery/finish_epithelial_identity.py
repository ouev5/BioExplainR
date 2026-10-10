"""Deliver and verify corrected epithelial results, including superseded evidence."""
import argparse
import json

import epithelial_protein as analysis
import finish_epithelial_protein as finish
from epithelial_identity import INITIAL, FINAL, NEW_CODE
from validation_sources import record, json_out

analysis.OUT = FINAL
finish.OUT = FINAL
finish.CODE = analysis.CODE + NEW_CODE


def build():
    finish.build()


def verify():
    data = json.loads((FINAL / "analysis_freeze.json").read_text())
    for r in data["superseded_files"]:
        assert record(analysis.ROOT/r["path"]) == r, r["path"]
    finish.verify()


def seal():
    finish.seal()
    verify()


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action",choices=["build","seal","verify"])
    globals()[p.parse_args().action]()
