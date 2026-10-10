# HBEC全成员身份修订与最终交付

2026-10-10，首轮结果及独立R数值复核完成后发现身份层级问题：HBEC行781
`Protein.IDs=NX_P21397-2;NX_P21397-1;NX_P27338-2;NX_P27338-1`，
`Majority.protein.IDs`与FASTA片段仅MAOA成员，完整Protein.IDs仍含其他成员。
首轮Python/R共同遵循“所有可解析FASTA片段同一基因”不够证明全部组成员同一基因。
首轮结果、freeze和代码保留原字节，最终结果新建`complete/`。

对全部HBEC行统一强化：从原表全部有效NX FASTA片段建立精确accession→基因集合，
并保留canonical accession（去isoform数字后缀）的基因集合。每个Protein.IDs成员
必须NX_开头，其精确映射（没有才canonical）必须唯一；所有成员均映射到同一基因，
且与该行原FASTA片段单基因一致，否则排除。禁止把仅majority成员的基因用于归属
其他成员；无映射明确unresolved，不在线猜注释，不取最显著蛋白行。

同时逐行公开完整IDs、majority IDs、原header基因、全部成员解析基因、未解析IDs及
最终QC，新名单位置/方向、样本、尺度、有效n、统计与校正方案均保持。改动是首次
看到结果后的身份纠正，不能宣称为事前盲法；改动前后数字差异可直接追溯。

独立R实现从原表自行建立精确／canonical映射，在原冻结审计的hqc步骤后重做
完整ID核对，再执行其全部统计/原测量/family/敏感性审计。只纠正CSV空gene→NA
的问题。新resume源码写入freeze，原审计脚本不改。

首轮交付检查发现R包默认报告中长scope_limitations事实会截短；最终双语HTML
追加完整研究范围和效应尺度说明（包括HBEC并非确认log2倍数），并绑定实际结果。
原离线报告和首次检查失败保留。最终check仍要求完整范围字符串可回读。

最终数值、说明、工作簿、R包结果及清单/ZIP都在`complete/`；首轮目录仅为
保留的superseded研究过程。本轮封存同时绑定首轮文件以保存失败／纠正依据。
