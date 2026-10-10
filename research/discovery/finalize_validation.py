"""Record actual new evidence scope, source mappings and completion state."""
import csv
import json
import sys
from pathlib import Path
from validation_sources import ROOT, fetch, csv_out, json_out, record, utc

out=Path(sys.argv[1]).resolve()
records=[]
for gene in ["ENSG00000179094","ENSG00000120129","ENSG00000113580"]:
    path=out/"sources"/(gene+"_lookup.json")
    rec=fetch("https://rest.ensembl.org/lookup/id/"+gene+"?content-type=application/json",path,30)
    records.append(rec)
    if rec["status"]=="retrieved":
        data=json.loads(path.read_text())
        expected={"ENSG00000179094":"PER1","ENSG00000120129":"DUSP1","ENSG00000113580":"NR3C1"}[gene]
        assert data["display_name"]==expected and data["species"]=="homo_sapiens"
        rec["gene_mapping_verified"]=True
json_out(out/"new_control_mapping_audit.json",{"utc":utc(),"records":records})
def rows(path):
    with path.open(newline="") as stream:return list(csv.DictReader(stream))
asm=rows(out/"expression_results.csv");early=rows(out/"asm_early/early_results.csv");gr=rows(out/"gr_public/gr_results.csv")
protein=rows(out/"human_protein/human_selected_results.csv")
genes=["PER2","PER3","METTL7A","MAOA","ANGPTL2","FSTL3"]
ledger={
    "status":"completed_public_data_continuation","utc":utc(),
    "user_constraint":"No new wet experiments; validation by public datasets and published evidence",
    "report":"docs/biology_validation_v2/README.md","online_model_calls":0,"fresh_wet_experiments":0,
    "research_freezes":[record(p) for p in [out/"search_freeze.json",out/"expression_design_freeze.json",out/"asm_early/design_freeze.json",
        out/"gr_public/design_freeze.json",out/"protein_public/protein_design_freeze.json",out/"human_protein/human_protein_freeze.json",
        out/"human_protein/selected_array_reanalysis_freeze.json"]],
    "new_statistics":{"paired_ASM_tests":len(asm),"early_ASM_tests":len(early),"GR_assay_tests":len(gr),
        "mouse_protein_tests_including_sensitivity":88,"human_selected_protein_response_tests":22,"human_selected_direct_tests":11},
    "PER2":{"adult_late_response":"supported by six adult donor directions and paired t/count model; exact sign-flip Holm not confirmed",
        "early_ASM_induction":"not confirmed","adult_time_interaction":"not estimable from retrieved published summary, raw Ct absent",
        "adult_pulse_same_time_Tukey":0.7831,"GR_rescue_variants":"not confirmed","adult_ASM_candidate_protein":"not obtained",
        "candidate_function":"not confirmed; available calcium/cAMP experiments target other clock factors or GR/GNAS"},
    "METTL7A":{"human_protein":"sixdonorsper24/72h, each6/6positive, donor tHolm22 .0437/.00261, exactHolm.6875; selectedarrayscross-tissueexploratory",
        "direct_72minus24":"five shared donors,4positive/1negative,Holm11.4122,notconfirmed"},
    "independent_units":{"new_GSE130715":6,"new_GSE13168_complete_pairs":3,"GSE135730":"3 cultures percondition,donoridentity/agenotverified",
        "GR_U2OS":"onecellline,18/17 parallelRNA libraries sharedsource","human_HTPC":"6donorsperassay,5sharedtime;3technicalrepeatsaveraged",
        "policy":"Do not add old13/16/4 and new6; exact IDs differ but undisclosed aliases unresolved."},
    "source_conflicts":["GSE135730 human/mm9 summary; stable human gene IDs used, nocoordinateinference",
        "PXD081613 PRIDEhuman vs Musmusculusdatabaseand7218mouseannotations; unresolved, nothumanproteinproof",
        "METTL7A currentofficialnameTMT1A; NCBIEntrez25840aliasverified"],
    "publication_and_selection":["GR2026bioRxivpreprintnotpeerreviewed; noemptyKOtranscriptomicarm",
        "HumanALLproteinliststotalintensityonly; per-libraryarraysavailableonlyselecteddifferentiallists; nozeroeffectclaimformissing",
        "Noallstageglobalconfirmatoryfamily; allfollowupbasedonknownv011results"],
    "verification":{"ASM_raw_R":"396 measurements,88pairedtests; originalTPM/SOFT",
        "early_R":"132originalRPKMmeasurements,33tests","GR_Python":"385originalcounts,550WLSnumbers",
        "ASM_exact_Python":"220WLSnumbers;voom/moderationretained","mouse_protein_R":"160originalmeasurements,40estimabletests",
        "human_protein_R":"144selectedarrays,24donoreffects,6estimabletests; XLSXfidelityauditedinPython",
        "workflow":"8actualBioExplainRcontexts,bilingualofflineHTML; noRpackagecodechange"},
    "unfulfilled_scientific_claims":["AdultASM PER2 trueearlylate drugtime interaction","AdultASM candidateGRgeneticcausality",
        "AdultASM PER2protein/phase/amplitude/function"],
    "completion_scope":"All acquired public datasets analyzed/audited or feasibility-excluded with explicitreason; unresolvedclaimsareevidencegaps, not wetlabuseractions",
}
json_out(out/"scientific_ledger.json",ledger)
print("Public validation ledger completed")
