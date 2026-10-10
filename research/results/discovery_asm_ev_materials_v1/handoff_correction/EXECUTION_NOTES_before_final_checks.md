# 本轮执行记录与受阻项

- 开始执行 `python3 research/discovery/seal_asm_ev_export.py verify`，pass：
  986 本轮证据文件、16 源码、1,007 原归档成员及层叠旧封存；原 2,905 保护
  文件核对通过。开始精确根 rgo 快照随后保存。
- `asm_ev_materials.py acquire`：13 请求并行获取；原计划、UTC、响应 headers、
  URL、原字节和 hash 保存。OpenAIRE read timeout、Figshare403 的真实失败保留。
- `follow --plan hal_followup_plan.json`：6 请求，5取得，OpenAIRE XML 超时。
  HAL全字段与实际页面核对为同一 DOI 论文，文件下载项只有一 PDF。
- `follow --plan hal_pdf_plan.json`：外层45,000ms中断；没有 response 文件和
  完成 JSON，不当作 pass。`hal_pdf_resume_plan.json` 另文件名重试，外层
  180,000ms仍中断，同样无响应文件／完成 JSON。原计划保留。
- 两次 urllib 使用的是 socket timeout 25s，不是下载总时限；持续少量传输
  可超过该时限。本次通过独立 curl plan 设置明确总时限，原源码/freeze 不改。
- `asm_ev_materials_review.py pdf`：curl `--max-time 60`，exit28；取得
  3,564,070字节，stderr报告总13,089,865字节。部分PDF原字节保存 `.bin`，
  未执行全文提取／方法核对，未宣称完整PDF校验通过。
- `asm_ev_materials_review.py review`：核对HTTP内容而非只看200；HAL原API与
  页面下载链接一致。PRIDE三个文件API的 `total_records` 与56/48/38条实际
  行一致，原项目文件name/size/accession与前轮完整56项一致；原JSON和表保存。
- `review_freeze.json` 是来源获取后的说明审读输入记录，**不是候选分析冻结**。
  未获得完整蛋白数组、未提取候选测量、未发送联系、未外部上传。
- 新封存与审计入口为 `seal_asm_ev_materials.py`；旧export的根rgo依赖只用
  `rgo_before_materials.md`精确快照，其他旧科学文件原路径/hash。
