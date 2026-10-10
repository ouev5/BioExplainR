# v0.12 导出与续接记录

本版来自新完整54基因统计和未预筛人蛋白原LFQ数组重算，统计方案为结果后探索。
原v0.11／验证报告原路径保留；具体科学数值及下载/解析原错误见
`research/results/discovery_set_validation_v1/EXECUTION_NOTES.md`。

- 首次主稿导出长图标题在PDF折行，旧renderer文字全字符串匹配图页失败；
  新版本导出器规范化空白匹配图标题后直接嵌入原PDF，不改旧renderer源文件。
- 首次正文链接审计发现S13b/S20只在范围引用，补齐估计目标、逐表/逐图解释。
- 完整蛋白来源说明新增Markdown内嵌表，未配置第5native table时补充渲染
  停止；新增S26 CSV/XLSX及native spec后5表逐格核对。
- Pandoc缺zh翻译／LOjavaldx警告真实输出保留；最终13/19页、原图嵌入、
  字体文本边界／图片加载／网页1440/390检查通过。自动几何不作人工视觉审阅。
- 草稿来源清单文件数37误写在封存前据原CSV改43；各原数据/旧family不改。
- 原七标签/发表六供体、处理版本、两个原LFQ0/发表有限值冲突保留。旧rgo、
  README、index文档依赖精确快照另存，新清单显式绑定当前文档。

本目录未封存阶段的`--refresh`重新导出仅覆盖本目录工作稿；封存后构建拒绝。
最终数值及交付范围由audit/browser_final_v2/manuscript_manifest绑定。
