"""Source-driven candidate follow-up tables and vector four-panel figure."""
import csv
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

ROOT = Path(__file__).resolve().parents[2]


def rows(p):
    with p.open(newline="") as f: return list(csv.DictReader(f))


def make_assets(out, table):
    context = ROOT / "research/results/discovery_context_v1"
    donors = ROOT / "research/results/discovery_donors_v1"
    for n, p in [(11, context / "model_results.csv"), (12, donors / "results.csv"), (13, donors / "donor_effects.csv")]:
        r = rows(p); table(f"Table_S{n}", list(r[0]), [[v[k] for k in r[0]] for v in r],
            f"Public reanalysis: {p.relative_to(ROOT)}; fixed candidate; biological units and null outcomes retained")
    plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 9, "pdf.fonttype": 42,
        "axes.spines.top": False, "axes.spines.right": False})
    fig, axes = plt.subplots(2, 2, figsize=(11.5, 8))
    fig.subplots_adjust(left=.14, right=.97, bottom=.12, top=.91, wspace=.53, hspace=.55)
    green, blue, orange = "#247A6B", "#387FA7", "#C09442"
    m = [r for r in rows(donors / "gene_measurements.csv") if r["symbol"] == "SPARCL1"]
    ax = axes[0, 0]; ax.set_title("A  Verified within-donor pairs", loc="left", weight="bold", pad=14)
    for group, positions, color in [("non_asthma", (0, 1), blue), ("fatal_asthma", (2.8, 3.8), green)]:
        for donor in sorted({r["donor"] for r in m if r["disease"] == group}):
            pair = [r for r in m if r["donor"] == donor]
            y = [float(next(r for r in pair if r["treatment"] == t)["log2_tpm_plus_one"]) for t in ["vehicle", "BUD"]]
            ax.plot(positions, y, "o-", color=color, alpha=.6, markersize=3, linewidth=.8)
    ax.set_xticks([0, 1, 2.8, 3.8], ["Vehicle", "BUD", "Vehicle", "BUD"])
    ax.set_ylabel("log2(gene TPM + 1)"); ax.text(.5, -.24, "Non-asthma: 7/7 up     Fatal asthma: 9/9 up", transform=ax.transAxes, ha="center", fontsize=8)
    ax = axes[0, 1]; ax.set_title("B  Donor response and between-group test", loc="left", weight="bold", pad=14)
    rr = rows(donors / "results.csv")
    for i, r in enumerate(rr):
        effect, lo, hi = [float(r[k]) for k in ["effect", "ci_low", "ci_high"]]
        ax.errorbar(effect, i, xerr=[[effect-lo], [hi-effect]], fmt="o", color=[blue, green, orange][i], capsize=4)
        ax.text(5.05, i, f"Holm P\n{float(r['holm_three_tests']):.2g}", va="center", fontsize=8)
    ax.set_yticks(range(3), ["Non-asthma", "Fatal asthma", "Fatal - non"]); ax.invert_yaxis()
    ax.axvline(0, color="#888", ls="--", lw=1); ax.set(xlim=(-1.4, 6.2), xlabel="Difference in log2(TPM + 1); 95% CI")
    ax = axes[1, 0]; ax.set_title("C  BUD effects in factorial experiment", loc="left", weight="bold", pad=14)
    mm = {r["contrast"]: r for r in rows(context / "model_results.csv") if r["symbol"] == "SPARCL1"}
    for i, c in enumerate(["bud_NT_noTNF", "bud_NT_TNF", "bud_KD_noTNF", "bud_KD_TNF"]):
        r = mm[c]; effect, lo, hi = [float(r[k]) for k in ["log2FoldChange", "ci_low", "ci_high"]]
        ax.errorbar(effect, i, xerr=[[effect-lo], [hi-effect]], fmt="o", capsize=4, color=[blue, blue, green, green][i])
    ax.set_yticks(range(4), ["NT, no TNF", "NT, TNF", "KD, no TNF", "KD, TNF"]); ax.invert_yaxis()
    ax.axvline(0, color="#888", ls="--", lw=1); ax.set(xlim=(-1.8, 3.3), xlabel="Count-model log2FC; 95% Wald CI")
    ax = axes[1, 1]; ax.set_title("D  Predefined interaction tests", loc="left", weight="bold", pad=14)
    for i, c in enumerate(["bud_tnf_NT", "bud_kd_noTNF", "three_way"]):
        r = mm[c]; effect, lo, hi = [float(r[k]) for k in ["log2FoldChange", "ci_low", "ci_high"]]
        ax.errorbar(effect, i, xerr=[[effect-lo], [hi-effect]], fmt="o", capsize=4, color=orange)
        ax.text(2.7, i, f"Holm P\n{float(r['holm_candidate_interactions']):.3g}", va="center", fontsize=8)
    ax.set_yticks(range(3), ["BUD x TNF (NT)", "BUD x KD", "Three-way"]); ax.invert_yaxis()
    ax.axvline(0, color="#888", ls="--", lw=1); ax.set(xlim=(-3.3, 4), xlabel="Interaction log2FC; 95% Wald CI")
    fig.suptitle("SPARCL1: donor-level response preserved; specific mechanisms remain unconfirmed", fontsize=12)
    fig.savefig(out / "figures/Figure_3.pdf"); fig.savefig(out / "figures/Figure_3.png", dpi=190)
    plt.close(fig)
