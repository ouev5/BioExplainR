# PXD055968 完整定量导出版本核实

2026-10-10。续接 `rgo.md` 最新入口。原候选及先前来源诊断已知；本轮先核实
文件、处理版本、样本层级与完整定量数组，不读取候选效应后调整入口。
新目录：`research/results/discovery_asm_ev_export_v1/`。

## 获取与版本门槛

1. 开始核验 provenance 及层叠旧封存、2,905 保护文件，并保存根 rgo 精确快照。
   原目录、原清单和原归档保留；新入口独立绑定本轮材料。
2. 保存当前 PRIDE 项目、完整文件 API、FTP 目录、上游 checksum、ProteomeCentral
   公告。核对项目 accession、原文 DOI、18 run / 6 患者映射及原文件大小。
3. 检查存档 `.pdResult` / 必要时 `.msf` 实际 SQLite 结构、软件版本、工作流、
   搜索库和样本范围。优先只读 HTTP Range；严格核对 206、Content-Range、
   总长度、Last-Modified / ETag，保留每个取得的块及 hash。
   部分读取不称整文件上游 SHA1 通过，不将本地重建库误称原完整数据库。
4. 合格完整导出需未按差异预筛的全部蛋白组、精确 accession / group 成员、
   master/decoy/contaminant 标记、鉴定置信度及 unique 肽信息、所有 18 run 的
   原 abundance / normalized abundance 和缺测标记；若跨 run 的原定量结果或
   处理版本无法对应，保留冲突，不拼接单 run 结果冒充发表跨 run 数组。
5. PRIDE PD2.5/Mascot/Proline2020 与原文 PD3.0/CHIMERYS2023 的冲突需实际
   文件证据核实。数据库内版本线索不自动证明原论文使用哪个最终跨 run 导出。
   原文 43 人总体年龄均值不赋给蛋白组六患者；原表同患者三重复不计独立供体。

## 候选身份检查门槛

正确版本的完整数组、供体映射和重复层级满足后，另存身份检查 freeze，再读取
固定完整候选集合（沿用已冻结集合及控制，记录原路径/hash）。明确 distinguish
unique 肽支持、protein-group 歧义、缺测、EV 制备共分离和经典分泌身份。
没有 GC / vehicle 因子，任何病组丰度或 EV 识别不升级为 GC 响应、分泌速率、
功能或候选因果；不因未取得数组把候选记为阴性。

## 阻塞与交付

若公开材料不能满足门槛，保存实际探查、失败和明确缺件清单，准备未发送的
作者材料请求（最终导出 / workflow / 18 run 映射 / 原缺测 / 六患者年龄及重复
定义）。本轮不自动发送联系或外部上传。中文结果和新 manifest 给出真实进度，
新核验仅将旧 provenance 的根 rgo 文档依赖映射到开始精确快照，其他旧科学
依赖仍原路径/hash。GitHub 和外部上传继续暂停。
