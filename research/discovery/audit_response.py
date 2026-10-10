"""Independent numerical audit of genome FDR, original counts, WLS and time effects."""
import csv
import gzip
import io
import itertools
import json
import sys
from pathlib import Path

import numpy as np
from scipy import stats


ROOT = Path(__file__).resolve().parents[2]


def rows(p):
    with Path(p).open(newline="") as stream:
        return list(csv.DictReader(stream))


def num(r, field):
    return float(r[field]) if r[field] else np.nan


def eq(a, b):
    assert np.allclose(a, b, rtol=1e-8, atol=1e-10, equal_nan=True), (a, b)


def bh(p):
    p = np.asarray(p); order = np.argsort(p); n = len(p)
    val = np.minimum(1, np.minimum.accumulate((p[order]*n/np.arange(1, n+1))[::-1])[::-1])
    result = np.empty(n); result[order] = val; return result


def holm(p):
    p = np.asarray(p); order = np.argsort(p); n = len(p)
    val = np.minimum(1, np.maximum.accumulate(p[order]*np.arange(n, 0, -1)))
    result = np.empty(n); result[order] = val; return result


def run(out, genome=None):
    genome = Path(genome) if genome is not None else ROOT / "research/results/discovery_genome_v2"
    de = rows(genome / "deseq2_all_contrasts.csv")
    ii = [r for r in de if r["contrast"] in ["bud_tnf_NT", "bud_kd_noTNF", "three_way"]]
    p = np.array([num(r, "pvalue") for r in ii]); p[~np.isfinite(p)] = 1
    eq([num(r, "pooled_BH") for r in ii], bh(p)); assert sum(bh(p) < .05) == 0
    response = rows(out / "response_full_results.csv")
    p = np.array([num(r, "pvalue") for r in response]); p[~np.isfinite(p)] = 1
    eq([num(r, "response_pooled_BH") for r in response], bh(p))
    for r in response:
        if np.isfinite(num(r, "pvalue")):
            eq(num(r, "pvalue"), 2*stats.norm.sf(abs(num(r, "stat"))))
            eq(num(r, "ci_low"), num(r, "log2FoldChange")-stats.norm.ppf(.975)*num(r, "lfcSE"))
            eq(num(r, "ci_high"), num(r, "log2FoldChange")+stats.norm.ppf(.975)*num(r, "lfcSE"))
    vr = [r for r in rows(genome / "voom_all_contrasts.csv") if r["contrast"].startswith(("bud_NT", "bud_KD"))]
    vb = bh([num(r, "pvalue") for r in vr]); lookup = {(r["feature_id"], r["contrast"]): v for r, v in zip(vr, vb)}
    for r in response:
        eq(num(r, "voom_response_pooled_BH"), lookup.get((r["feature_id"], r["contrast"]), np.nan))
    selected = rows(out / "frozen_candidates.csv"); ids = {r["feature_id"] for r in selected}
    sf = {r["sample"]: num(r, "size_factor") for r in rows(ROOT / "research/results/discovery_context_v1/size_factors.csv")}
    md = rows(ROOT / "research/results/discovery_context_v1/samples.csv")
    discovery_ids = {r["feature_id"] for r in response}
    raw = {}
    with gzip.open(ROOT / "research/results/discovery_context_v1/counts.txt.gz", "rt") as stream:
        for r in csv.DictReader(stream, delimiter="\t"):
            feature = r[next(iter(r))].split(".")[0]
            if feature in discovery_ids:
                raw[feature] = {s["sample"]: float(r[s["count_column"]]) for s in md}
    assert set(raw) == discovery_ids
    direction_counts = {}
    for g, values in raw.items():
        for contrast in ["bud_NT_noTNF", "bud_NT_TNF", "bud_KD_noTNF", "bud_KD_TNF"]:
            kd = "NT" if "NT" in contrast else "KD"; tnf = "yes" if contrast.endswith("_TNF") else "no"
            x = []
            for donor_id in sorted({s["donor"] for s in md}):
                use = [s for s in md if s["donor"] == donor_id and s["kd"] == kd and s["tnf"] == tnf]
                if len(use) != 2:
                    continue
                a = next(s for s in use if s["bud"] == "yes")["sample"]
                b = next(s for s in use if s["bud"] == "no")["sample"]
                x.append(np.log2(values[a]/sf[a]+1)-np.log2(values[b]/sf[b]+1))
            direction_counts[(g, contrast)] = (len(x), sum(v > 0 for v in x), sum(v < 0 for v in x))
    by_gene = {}
    for r in response:
        g = r["feature_id"]; n, pos, neg = direction_counts[(g, r["contrast"])]
        assert (int(r["n_donors"]), int(r["positive_donors"]), int(r["negative_donors"])) == (n, pos, neg)
        effect = num(r, "log2FoldChange"); ve = num(r, "voom_log2_effect"); vq = num(r, "voom_response_pooled_BH")
        passed = (num(r, "baseMean") >= 10 and abs(effect) >= .5 and num(r, "response_pooled_BH") < .05
                  and np.isfinite(vq) and vq < .05 and np.sign(effect) == np.sign(ve) and n >= 3
                  and (pos == n if effect > 0 else neg == n))
        assert passed == (r["pass"] == "TRUE")
        by_gene.setdefault(g, []).append((passed, np.sign(effect), abs(num(r, "stat"))))
    before_loo = {g: min(v[2] for v in values) for g, values in by_gene.items()
                  if len(values) == 4 and all(v[0] for v in values) and len({v[1] for v in values}) == 1}
    assert len(before_loo) == 54
    loo = rows(out / "all_priority_leave_one_donor_out.csv")
    loo_groups = {}
    for r in loo:
        loo_groups.setdefault(r["feature_id"], []).append(num(r, "log2_effect"))
    after_loo = {g: score for g, score in before_loo.items() if len(loo_groups[g]) == 16
                 and all(np.isfinite(v) and np.sign(v) == by_gene[g][0][1] for v in loo_groups[g])}
    ranked = sorted(after_loo, key=lambda g: (-after_loo[g], g))
    assert len(ranked) == 54 and ranked[:12] == [r["feature_id"] for r in selected]
    donor = rows(out / "candidate_context_donor_effects.csv")
    for r in donor:
        g, d = r["feature_id"], r["donor"]
        kd = "NT" if "NT" in r["contrast"] else "KD"; tnf = "yes" if r["contrast"].endswith("_TNF") else "no"
        use = [s for s in md if s["donor"] == d and s["kd"] == kd and s["tnf"] == tnf]
        if len(use) != 2:
            assert not r["effect"]; continue
        a = next(s for s in use if s["bud"] == "yes")["sample"]
        b = next(s for s in use if s["bud"] == "no")["sample"]
        eq(num(r, "effect"), np.log2(raw[g][a]/sf[a]+1)-np.log2(raw[g][b]/sf[b]+1))
    screen = rows(out / "stable_response_screen.csv")
    all_pass = [r for r in screen if r["priority_pass"] == "TRUE"]
    assert len(all_pass) == 54 and [r["feature_id"] for r in all_pass[:12]] == [r["feature_id"] for r in selected]
    # Weighted least-squares covariance and coefficients, independently from exported measurements.
    design_rows = rows(out / "gr_design_matrix.csv"); names = list(design_rows[0])[1:]
    X = np.array([[num(r, c) for c in names] for r in design_rows])
    sample_order = [r["sample"] for r in design_rows]
    crows = rows(out / "gr_contrasts.csv")
    cs = {k: np.array([num(r, k) for r in crows]) for k in ["DEX", "KH103", "MIF", "Cort113"]}
    late = np.zeros(len(names)); late[names.index("grouppost_DMSO")] = 1; late[names.index("groupbaseline_DMSO")] = -1
    direct = np.zeros(len(names)); direct[names.index("grouppost_DMSO")] = 1; direct[names.index("grouppre_DMSO")] = -1
    measurements = rows(out / "gr_candidate_measurements.csv"); beta = {}; inv = {}
    for g in {r["feature_id"] for r in measurements}:
        by_sample = {r["sample"]: r for r in measurements if r["feature_id"] == g}
        y = np.array([num(by_sample[s], "logCPM") for s in sample_order])
        w = np.array([num(by_sample[s], "weight") for s in sample_order])
        inv[g] = np.linalg.inv(X.T @ (w[:, None]*X)); beta[g] = np.linalg.solve(X.T @ (w[:, None]*X), X.T @ (w*y))
    gr_checks = 0
    for filename, adjustfield in [("gr_candidate_results.csv", "holm_all_tests"), ("gr_late_results.csv", "holm_12_tests")]:
        rr = rows(out / filename); ps = []
        for r in rr:
            if r["status"] != "estimable":
                ps.append(1); continue
            g = r["feature_id"]; c = cs[r["contrast"]] if filename.startswith("gr_candidate") else late
            effect = c @ beta[g]; var = c @ inv[g] @ c; se = np.sqrt(var*num(r, "variance_post")); df = num(r, "df")
            eq(num(r, "log2_effect"), effect); eq(num(r, "unscaled_var"), var); eq(num(r, "se"), se)
            pvalue = 2*stats.t.sf(abs(effect/se), df); eq(num(r, "pvalue"), pvalue)
            eq(num(r, "ci_low"), effect-stats.t.ppf(.975, df)*se); eq(num(r, "ci_high"), effect+stats.t.ppf(.975, df)*se)
            ps.append(pvalue); gr_checks += 6
        eq([num(r, adjustfield) for r in rr], holm(ps))
    # Original processed arrays, exact-symbol probe selection and median measurements.
    src = ROOT / "research/results/discovery_sparcl1_v1"
    with gzip.open(src / "GPL6480.annot.gz", "rt") as stream:
        annotation = list(csv.DictReader([l for l in stream if l.strip() and not l.startswith(("#", "!", "^"))], delimiter="\t"))
    with gzip.open(src / "GSE34313_series_matrix.txt.gz", "rt") as stream:
        text = stream.read()
    start = text.index("!series_matrix_table_begin\n")+len("!series_matrix_table_begin\n"); end = text.index("!series_matrix_table_end", start)
    matrix = {r["ID_REF"]: r for r in csv.DictReader(io.StringIO(text[start:end]), delimiter="\t")}
    am = rows(out / "asm_time_measurements.csv")
    for r in am:
        probes = [a["ID"] for a in annotation if a["Gene symbol"] == r["symbol"]]
        eq(num(r, "value"), np.median([float(matrix[p][r["sample"]]) for p in probes]))
    marginal = rows(out / "asm_time_results.csv")
    for r in marginal:
        if r["status"] != "estimable":
            continue
        a = np.array([num(v, "value") for v in am if v["feature_id"] == r["feature_id"] and v["group"] == r["contrast"]])
        b = np.array([num(v, "value") for v in am if v["feature_id"] == r["feature_id"] and v["group"] == "untreated"])
        va, vb = a.var(ddof=1)/len(a), b.var(ddof=1)/len(b)
        effect = a.mean()-b.mean(); se = np.sqrt(va+vb); df = (va+vb)**2/(va**2/(len(a)-1)+vb**2/(len(b)-1))
        eq(num(r, "effect"), effect); eq(num(r, "pvalue"), 2*stats.t.sf(abs(effect/se), df))
        eq(num(r, "ci_low"), effect-stats.t.ppf(.975, df)*se); eq(num(r, "ci_high"), effect+stats.t.ppf(.975, df)*se)
        pool = np.r_[a, b]; permutation = []
        for ix in itertools.combinations(range(len(pool)), len(a)):
            mask = np.zeros(len(pool), bool); mask[list(ix)] = True
            permutation.append(pool[mask].mean()-pool[~mask].mean())
        eq(num(r, "permutation_p"), np.mean(np.abs(permutation) >= abs(effect)-1e-12))
    eq([num(r, "holm_24_tests") for r in marginal], holm([num(r, "pvalue") for r in marginal]))
    temporal = rows(out / "direct_temporal_results.csv")
    gr_base = {r["feature_id"]: r for r in rows(out / "gr_late_results.csv")}
    for r in temporal:
        if r["status"] != "estimable":
            continue
        g = r["feature_id"]
        if r["study"] == "A549":
            effect = direct @ beta[g]; se = np.sqrt(direct @ inv[g] @ direct * num(gr_base[g], "variance_post")); df = num(gr_base[g], "df")
        else:
            a = np.array([num(v, "value") for v in am if v["feature_id"] == g and v["group"] == "dex24h"])
            b = np.array([num(v, "value") for v in am if v["feature_id"] == g and v["group"] == "dex4h"])
            va, vb = a.var(ddof=1)/len(a), b.var(ddof=1)/len(b)
            effect = a.mean()-b.mean(); se = np.sqrt(va+vb); df = (va+vb)**2/(va**2/(len(a)-1)+vb**2/(len(b)-1))
        eq(num(r, "effect"), effect); eq(num(r, "se"), se); eq(num(r, "df"), df)
        eq(num(r, "pvalue"), 2*stats.t.sf(abs(effect/se), df))
    eq([num(r, "holm_24_tests") for r in temporal], holm([num(r, "pvalue") for r in temporal]))
    report = {"status": "pass", "pooled_interaction_tests": len(ii), "pooled_response_tests": len(response),
              "retained_signature_genes": 54, "selected_genes": 12, "raw_count_donor_checks": len(donor),
              "all_genome_donor_sign_checks": len(response), "fixed_ranking_independently_verified": True,
              "exact_GR_WLS_numeric_checks": gr_checks, "raw_array_measurement_checks": len(am),
              "direct_time_tests": len(temporal), "marginal_array_tests": len(marginal),
              "scope": "Independent Python arithmetic, original count/array inputs, weighted fits and pooled multiplicity; DESeq2 dispersions and limma moderation not independently refitted."}
    (out / "numeric_audit.json").write_text(json.dumps(report, indent=2)+"\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    run(Path(sys.argv[1]), Path(sys.argv[2]) if len(sys.argv) > 2 else None)
