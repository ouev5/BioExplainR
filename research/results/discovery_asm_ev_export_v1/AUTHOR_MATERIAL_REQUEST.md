# PXD055968 材料请求草稿（未发送）

状态：**草稿，未联络作者、未发送、未外部上传**。以下联系信息来自原文 lead
contact 与 PRIDE 提交者；发件人真实姓名/单位/用途需负责人填写，不能冒充作者。

To: Pauline Esteves <pauline.esteves@u-bordeaux.fr>

Cc: Jean-William Dupuy <jean-william.dupuy@u-bordeaux.fr>

Subject: Request for the complete paper-version quantitative export for PXD055968

Dear Dr Esteves and Dr Dupuy,

We are conducting a computational examination of protein identification in primary
human bronchial smooth-muscle extracellular-vesicle preparations, referring to your
iScience article, DOI 10.1016/j.isci.2025.112546, and dataset PXD055968. We would be
grateful for the complete, unfiltered protein quantitative export corresponding to
the analysis reported in the article, rather than only the selected IPA/pathway or
differential-protein tables.

We inspected the archived processing/consensus metadata for all 18 `.pdResult`
files, using read-only byte ranges. They report Proteome Discoverer **3.1.0.638**,
CHIMERYS **inferys_3.0.0_fragmentation**, and
`RP_UP000005640_Homo_sapiens_2024_01_22.fasta`. Each consensus workflow is `CWF_ID`
and contains one raw file, with no final protein abundance columns or joint
feature-mapper/precursor-quantifier node. These differ from the article methods
(PD3.0, inferys_2.1, September2023 database) and PRIDE project processing description
(PD2.5, Mascot/Proline, September2020 database). We do not assume which version is
the final analysis used for the publication.

Could you please provide, or point us to a public location for:

1. The complete final protein/master-protein/protein-group table, including
   accessions, group members, master/decoy/contaminant flags, confidence/FDR,
   peptide and unique-peptide counts, and abundances for every mapped sample/run.
   Both original and normalized abundances, plus missing/zero/imputed-value flags,
   would allow identification evidence to be distinguished from imputation.
2. The final joint quantification result/workflow or Proline export, with actual
   software/model/database versions, processing and consensus workflows,
   normalization, protein grouping, filtering, and missing-value settings.
   Please clarify whether the archived single-file searches belong to the final
   article analysis or an alternative/reprocessed version.
3. The accompanying peptide/PSM-to-protein mapping and unique/shared-peptide
   information for the same final version, if available.
4. A minimal deidentified mapping for patients 595, 614, 615, BA184, BA185 and BA186:
   age or confirmation of adult status, and whether the three repeats per patient
   represent separate cultures, EV preparations, digestions, or LC-MS injections.
   Any sample exclusions or QC decisions would also be helpful.

We will treat the six patient labels as six independent units. The disease-group
comparison has no controlled glucocorticoid/vehicle factor; EV protein identification
will not be interpreted as glucocorticoid response, per-cell secretion rate, or
candidate-specific functional causality.

Thank you for your help.

[Responsible person's real name]

[Institution and contact email]

## 材料收到后的入口

- 另建输入目录，保留邮件/公开链接、收到日期、原文件、字节数、SHA-256。
- 先核实版本、未按差异预筛、18 run 与六患者映射、原缺测和肽证据字段。
- 按 `ASM_EV_EXPORT_PROTOCOL.md` 另冻结完整候选身份检查；缺件仍明确保留。
- 不沿用本轮 `blocked_missing_final_export` 当成候选阴性或已完成数组分析。
