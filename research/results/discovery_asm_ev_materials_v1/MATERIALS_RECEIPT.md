# 真实材料收到后的接收核对

当前：**尚未收到作者材料；材料请求未发送。** 这是接收要求与执行顺序，
不是已取得的数据、作者最终版本说明或候选分析 freeze。

## 下一实际动作

负责人填写现有请求草稿的真实姓名、单位及联系邮箱，向原文 lead contact
Pauline Esteves（`pauline.esteves@u-bordeaux.fr`）请求材料，抄送 PRIDE 提交者
Jean-William Dupuy（`jean-william.dupuy@u-bordeaux.fr`）。请求原稿在
`research/results/discovery_asm_ev_export_v1/AUTHOR_MATERIAL_REQUEST.md`。
已有作者回信、公开下载链接或本地原文件时，将这些真实材料提供给续接执行者。

## 先保存来源，再查看候选

1. 另建接收目录，保留原附件／公开链接、作者原说明、收到日期和 UTC、原文件名、
   字节数及 SHA-256。保留原件；任何解码或转换另存、绑定原 hash。
2. 核对 accession/原文 DOI/样本范围。全部 18 run 为
   `pe210308_01`–`pe210308_18`；逐 run 对应六患者与三重复，使用原映射
   `research/results/discovery_asm_ev_export_v1/sample_map_verified.csv`。
   排除或聚合必须明确说明；仅六患者均值不能还原逐 run 缺测和重复。
3. 表须覆盖全部最终 protein/master/group，而非显著蛋白、IPA/通路选择表。
   “未按差异预筛”允许明确的鉴定／QC 规则；需说明过滤前总组数、过滤规则和
   排除项。核对 accession/group 成员、master/decoy/contaminant、置信度/FDR、
   peptide/unique-peptide 数及所有 run 的原和归一化丰度。
4. 缺测、原零值和填补值须可区分。只有填补后的有限数值且不能恢复原缺测时，
   该缺口继续记录，不把填补值写成原检测信号。
5. 最终版本说明须明确实际 PD/Proline 版本、inferys、FASTA 版本／SHA、处理与
   consensus workflow、跨 run mapper/quantifier、分组/FDR/过滤/归一化/缺测
   设置，以及存档 18 个单 run PD3.1 结果与原发表 PD3.0 分析的对应关系。
   HAL version 1、项目公开时间、普通 README 不替代这一说明。
6. 核对同一最终版本的 peptide/PSM→protein/group、unique/shared、置信度／q 值
   及 run 映射；六患者年龄或成人确认、重复层级、QC／排除说明逐项核对。
7. 输出逐项验收结果与未解决冲突。合格材料到位后另冻结固定完整候选集合、
   输入／源码 hash 和身份检查规则，再读取候选结果行。缺件不记候选阴性。

身份检查区分唯一肽支持、组内歧义、未测量、EV 制备共分离和经典分泌身份。
病组比较没有 GC/vehicle 因子，不能确认候选 GC 响应；同患者重复不增加供体数。
