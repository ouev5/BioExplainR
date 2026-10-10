"""Recover pairing from original Table E1; GEO's donor field is a library ID."""
from pathlib import Path
import re


def supplement_mapping(out):
    text = (out / "supplement_text.txt").read_text()
    matches = re.findall(r"(?m)^(287\d\d)\n((?:AS|N)\d{6})\n(asthma|non-asthma)\n(control|budesonide)\n", text)
    assert len(matches) == 34 and len({r[0] for r in matches}) == 34
    return {s: {"donor": d, "disease": "fatal_asthma" if g == "asthma" else "non_asthma",
                "treatment": "BUD" if t == "budesonide" else "vehicle"} for s, d, g, t in matches}


def parse_design(out, titles, samples, characteristics, observed):
    field = lambda prefix: next([x[len(prefix):] for x in row] for row in characteristics if all(x.startswith(prefix) for x in row))
    disease, treatment, geo_donor = field("disease state: "), field("treatment: "), field("donor: ")
    assert geo_donor == titles  # diagnosed metadata mismatch, not true biological donor IDs
    mapping = supplement_mapping(out)
    md = []; unresolved = []
    for title, accession, g, t in zip(titles, samples, disease, treatment):
        col = f"{g}_{'BUD' if t == 'budesonide' else 'control'}_{title}"
        if title not in mapping:
            unresolved.append(title)
            continue
        if col not in observed: continue
        actual = mapping[title]
        assert actual["disease"] == ("fatal_asthma" if g == "asthma" else "non_asthma")
        assert actual["treatment"] == ("BUD" if t == "budesonide" else "vehicle")
        md.append({"sample": accession, "title": title, "tpm_column": col, **actual, "geo_donor_field": title})
    assert set(unresolved) == {"28793", "28796"}
    excluded = {s for s in observed if s.rsplit("_", 1)[-1] in unresolved}
    assert excluded == {"non_asthma_BUD_28793", "non_asthma_control_28796"}
    assert {r["tpm_column"] for r in md} == observed-excluded
    assert len(md) == 32 and len({r["donor"] for r in md}) == 16
    assert {r["title"] for r in md} == set(titles)-{"28793", "28796"}
    return md
