# 正式实现补充（首次模型运行前）

- 恢复已保存 airway 全表与 pasilla 的火山图数值表；pasilla feature_id 按原发布计数表行序恢复，原脚本未重排行，因此逐行同源。无需重新拟合 DESeq2。
- ASCII feature_id 排序后，均匀索引使用 R `round(seq(1,N,length.out=n))`，包含两端；每数据集 50/200 行。
- 输出允许完整 JSON 对象或恰好一个 `json` fence；不提取散文中的子串。重复键、非对象、十进制/科学计数格式无效；缺键/非整数/负数不给该键分。`finish_reason=length` 全部不给分。
- base R 评分器独立计算真值；worker 保存解析值，Python 从原输出重新解析、原 CSV 重新计数。360 方法运行，每方法360目标，总1,800评分，正式模型调用216。
- 固定随机顺序与2,000任务bootstrap索引提前保存。调用从新chat开始，不传历史对话；ellmer_max_tries=1、ellmer_timeout_s=180。
- 同一个透明loopback转发器保存两客户端实际HTTP请求/响应字节，仅传输不修改body。其开销进入调用计时。模型服务串行，cache_prompt=false，服务cache-ram=0。
- 输入、实现、R包源码、model/runtime和设计文件哈希保存在正式启动前freeze。预热使用两行非研究fixture，不用于评分。外部API费为0；本地资源成本未测量。

## 入口修订

`common_performance_v1` 在预热与首个研究调用阶段中止：ellmer 0.5 的 `chat_openai()` 使用 Responses API 且忽略seed。实际HTTP已保存，不能混入符合方案的成绩。改为官方 `chat_openai_compatible()` Chat Completions入口，新目录v2重新冻结；任务与提示及评分规则未调优。

v2遇到前服务尚未退出的端口冲突，未推理。v3停止并保留：首个200行读表请求真实超时；静态入口检查随后发现BioExplainR config没有key_required参数以及ellmer把length映射为max_tokens，修正为openai_compatible预设/本地占位key和原响应finish_reason。v4重新冻结完整运行，仍保留180秒预算，未据模型答案修改任务/提示/评分规则；超时计入全分母。
