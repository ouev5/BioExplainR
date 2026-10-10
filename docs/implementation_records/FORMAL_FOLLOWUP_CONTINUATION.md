# 共同任务正式运行、GR模型与ChIP核实续接

日期：2026-10-09。当前主稿v0.10；新研究增补入口`docs/research_followup_v1/README.md`。

## 已完成

1. 固定airway/pasilla源表、50/200均匀选行、24阈值任务、360运行顺序、2,000任务bootstrap及scripts/model/runtime SHA-256后运行。正式`common_performance_v4`完成216模型尝试+1预热；五方法各360目标，离线/base R/两facts各360正确，读表8正确、175覆盖、37超时；Python独立原CSV/原HTTP/原输出/评分/时间/tokens/配对区间通过。
2. 恢复ellmer0.5.0和固定Qwen/llama.cpp，完整取得SCassist/GPTCelltype/GeneAgent固定源码，iSEE2.14.0源码保存；六工具原生适用性核查完成，四专属工具not_applicable不计错、不作全面排名。
3. GSE229084元数据、51处理映射、47分析文库，TMM/voom-limma模型完成；SPARCL1计数0–4未通过固定filterByExpr，三交互不可估计。FKBP5等控制有可测响应。Python独立核对35,942过滤、188测量、39WLS效应/CI/t与准确/近似协方差。作者SE处理对象51样本映射及705,534共享计数另行一致，102不可映射标识保留。
4. 获取18 ChIP峰、原文HTML及RefSeq/长度快照；全基因组坐标支持hg19，GEO mm9冲突及未获作者确认保留。8主样本SPARCL1 GR ±20kb为vehicle4/2、DEX8/8；RNAPII±5kb为0/0、1/1。R原峰/原注释独立重算288计数、2,505命中、summit/距离、16重复比较通过。
5. 增补Word/PDF/HTML导出4页4表；表与结果、PDF文字边界、桌面/移动浏览器通过。当前软件R源码未改动，历史主稿/图表保留。

## 失败／修订保留

- runtime恢复早期终端超时/中断，v3独立进程最终完成真实manifest；不把空txt标完成。
- common v1：ellmer默认Responses API忽略seed，中止；v2：前服务端口冲突，未推理；v3：config不存在key_required与ellmer length映射问题，中止。正式v4使用正确官方compatible入口；任务/提示/评分未按输出调优。
- mechanism fit v1/v2/v3在freeze路径、处理空白、TRUE类型映射阶段失败。v4完整拟合；CI因s2.post无名字初次导出缺值，冻结RDS未变，只修复另文件导出；精确SE与limma共同相关近似相差最多2.19%，复核同时记录。
- ChIP首个article/pdf请求返回challenge HTML，旧acquisition只记录传输状态，不将其当原文；后续有效212,463bytes原文HTML另保存。XML500、出版社403、图OCR不清楚保留。
- R ChIP初次窗口100000格式成1e+05失败；包装器只固定scipen后完整审计通过。
- 作者处理对象串行503/超时后59个HTTP Range完成30,570,232bytes（SHA-256 dc405de62f9bb9ec822f94b66c6b228b53b6871cf62325857979b85314448d67）。源为双层gzip，两层CRC验证后回读；失败/半包及无法映射基因ID保留。
- scorer提前静态发现bootstrap list需转换数值，包装器修复类型，不改评分规则；两项严格JSON/超时全分母反例通过。

## 解释与未完成边界

共同任务已知开发数据/小本地模型/单机180秒预算；200行直接读表全部超时，不能据此概括所有模型或六工具能力。目标已显式存在于facts提示，传递正确不证明通用推理。失败tokens及本地总成本未知。

A549低表达不可估计不支持或否定GR依赖。ASM单细胞系峰重叠不表示差异占据、直接靶点、增强子连接或功能因果；assembly是坐标证据核实，非作者更正。TMM/voom/eBayes未独立重估；独立代码实现复核不是第三方人员科学sign-off。新供体/湿实验/rescue/位点reporter/CRISPR/SPARCL1蛋白基质功能临床终点未做。

原2,905保护文件与r1–r12保留。r13/当前baseline-11审计接入新目录与增补，最终以实际`current_audit.json`、`historical_audit.json`及交付完整性为准。GitHub/外部上传继续暂停，#45–47仅为v0.8。
