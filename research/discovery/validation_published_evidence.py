"""Extract the actual adult-ASM temporal statistical table and function evidence."""
import csv
import json
import sys
from pathlib import Path

from validation_sources import csv_out, json_out, record, utc

out = Path(sys.argv[1]).resolve()
table = json.loads((out / "PMC8294620_tables.json").read_text())["T2"]
assert table[0] == ["Comparison 1", "Comparison 2", "PER1", "ARNTL", "PER2"]
data = []
for row in table[2:]:
    assert len(row) == 8
    for gene, idx in [("PER1", 2), ("ARNTL", 4), ("PER2", 6)]:
        data.append({"study": "Bartman2021_PMC8294620_adult", "comparison1": row[0], "comparison2": row[1],
                     "symbol": gene, "published_significance": row[idx], "published_Tukey_pvalue_text": row[idx + 1],
                     "source": "Table2, original HTML", "same_time_drug_comparison": row[0][:3] == row[1][:3] and row[0][-3:] != row[1][-3:],
                     "raw_p_or_effect_available": False})
csv_out(out / "published_adult_ASM_time_tests.csv", data)
assert next(r for r in data if r["symbol"] == "PER2" and r["comparison1"] == "t24 Veh")["published_Tukey_pvalue_text"] == "0.7831"
assert next(r for r in data if r["symbol"] == "PER2" and r["comparison1"] == "t12 Dex" and r["comparison2"] == "t24 Dex")["published_Tukey_pvalue_text"] == "0.0498"
evidence = [
    {"source": "PMC8294620", "endpoint": "adult ASM time-course RNA", "gene": "PER2", "tissue": "adult human ASM, 33-77y, 3F/3M source pool",
     "intervention": "100nM DEX/vehicle 30min pulse; washed;12/16/20/24h", "measurement": "qPCR,S16 reference,n4-6 per condition",
     "result": "t24DEX vs t24Veh Tukey=.7831; t24DEX vs t12DEX=.0498", "support": "published adult time design; not matched-drug confirmation",
     "limit": "No individual donor Ct/missingness/covariance publicly supplied in retrieved article; Table2 selected comparisons only; no phase/amplitude inference"},
    {"source": "PMC8294620", "endpoint": "clock protein/calcium perturbation", "gene": "PER1/ARNTL, not PER2", "tissue": "fetal human ASM",
     "intervention": "PER1/ARNTL siRNA and overexpression, hyperoxia", "measurement": "BMAL1protein,Fura2 Ca2+/SOCE",
     "result": "clock factor perturbation changes calcium; PER1/ARNTL overexpression attenuates hyperoxia responses", "support": "functional clock precedent",
     "limit": "Neither adult PER2 nor NR3C1 genetic perturbation; not candidate function validation"},
    {"source": "PMC7052668", "endpoint": "GRalpha genetic/protein/cAMP", "gene": "NR3C1/GRalpha", "tissue": "primary nonasthma human ASM",
     "intervention": "GRalpha siRNA72h vs scrambled, Bud1uM±formoterol", "measurement": "GRalpha immunoblot ~94kDa;live cADDis cAMP,n4-5lines",
     "result": "GRalpha protein nearly depleted; rapid cAMP response little changed", "support": "Real ASM receptor genetic experiment and protein verification",
     "limit": "No PER2 measurement/rescue; rapid endpoint differs from24hRNA; residualGR possibility explicitly discussed; not GR-equivalence proof"},
    {"source": "PMC7027561/GSE130715", "endpoint": "GNASprotein/cAMP", "gene": "GNAS", "tissue": "human primary ASM, RNA six adults19-54y",
     "intervention": "GNASsiRNA vs scrambled;GC rapidcAMP and24hBUDRNA", "measurement": "GalphaS immunoblot n3donor cells,livecAMP n4-5",
     "result": "GalphaS depletion reduces rapidGCcAMP", "support": "Orthogonal perturbation and function precedents; newRNA contrasts separately tested",
     "limit": "GNASnotGR; published unique-signature lists are not direct interaction tests; noPER2protein/Ca2+causal link"},
    {"source": "GSE342887/GSE342771", "endpoint": "GRrescue RNA", "gene": "PER2/PER1", "tissue": "humanU2OSosteosarcoma",
     "intervention": "GRKO rescuedalpha/AF2E755R/IDR398,100nMCORT90min", "measurement": "mRNA18/TT17libraries,new55Holmperassay",
     "result": "PER2drug/variantinteractionsnotconfirmed;PER1alpha/AF2interactionsupported", "support": "Actualpublicreceptorgeneticcross-contextcheck",
     "limit": "NoemptyKOarm;cultureunits;preprint;parallelassayssharesamples"},
    {"source": "PXD081613", "endpoint": "proteinabundance", "gene": "sixcandidates plus fivecontrols", "tissue": "mouseannotatedtable;PRIDEhumanconflict",
     "intervention": "CORT/DMSO1/3h,phase31/43,TMT2plex", "measurement": "processednormalizedprotein;32channels",
     "result": "PER2notdetectedunderfixedrule;MAOA/TMT1AnotHolmsignificant;GRproteinphase31_3hdecreases", "support": "Exploratorynonhumanorthologcomparison",
     "limit": "NohumanASMproteinconfirmation;species/celloriginnotauthorverified;noMSre-search;durationconfoundedwithplex"},
]
csv_out(out / "public_validation_evidence.csv", evidence)
json_out(out / "published_evidence_run.json", {"status": "completed", "utc": utc(), "adult_time_published_tests": len(data),
         "source_table": record(out / "PMC8294620_tables.json"), "scope": "Published adjusted statistics extraction and explicit evidence classification; not recomputation from unavailable raw donor Ct"})
print("Adult ASM original Table2", len(data), "published comparisons extracted")
