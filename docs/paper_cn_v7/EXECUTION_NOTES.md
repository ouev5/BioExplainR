# v0.13 实际执行、修订与范围

日期2026-10-10；主机UTC以freeze／audit／export原JSON为准。

## 实际完成

1. 阅读完整rgo、最新public_proteome及v0.12稿件／缺件状态；开始
   `python3 research/discovery/audit_public_proteome.py verify`通过。完整历史
   文件／ZIP层叠核验含原2,905保护文件。开始精确rgo字节保存于`evidence/`。
2. 按INTEGRATION_PROTOCOL另建v0.13。原表图逐字节复制；新增上清表4、16组
   S27–S42源表，图3重绘状态，其余后续图复用封存原PDF／PNG。原v0.12与
   各科学封存未修改。输入／初构建源码hash在integration_freeze中。
3. 导出Word、PDF、自包含HTML；4主图／6补图、4主表／5补充内嵌表、51对
   CSV-XLSX，主17页／补24页。正式PDF替换预览为原PDF图稿。
4. 新审计复核全部846 BH、112候选及224敏感性Holm；从保存逐日期效应重算
   4可估计候选t／SE／CI／P与方向，表4逐数值核对；四数组匹配计数、18
   EV版本、HBEC八主设计格各5样本通过。没有新候选效应输出或新模型拟合。
5. 对51组CSV-XLSX／Word表、19引用／正文链接、PDF文本边界与10原PDF图
   嵌入检查通过。原图1含一个栅格热图，其他9图无栅格。浏览器实际1440／390
   主补四页面无横溢出／JS错误，图片均自包含加载。

## 失败、修订与恢复

- 交接中的`/tmp/opencode/validation-report-venv`本机不存在。系统已有除
  PyMuPDF外的论文依赖；新建`paper-v013-venv`使用system-site-packages。
  首次安装PyMuPDF报`No space left on device`并留下不完整包，导入失败。
  执行pip缓存清理后无缓存force-reinstall PyMuPDF1.26.5成功；没有删除原
  研究／稿件／归档文件。浏览器另在`/tmp/opencode/paper-v013-browser`安装
  Playwright1.56.1，使用本机Chrome。
- 初构建脚本在freeze前出现字典推导式闭括号SyntaxError；修正语法后才
  首次执行研究依赖核验和稿件freeze，不将该失败算成功运行。
- 首版审计因正文范围`S27–S34`不含字面`S33`而停止；原引用覆盖完整范围。
  审计改为先展开明确的闭区间，再逐项核对，未删审计要求。
- 初稿表4遗漏PTX3 72h展示，已补齐全部四个可估计候选；正文新增明确分析
  阶段说明、修正继承的`GSE131688h`排版，最后纳入已有PTX3／咳嗽面板及
  保存原元数据参考文献。初稿正文、补充、export、browser及初构建源码均
  精确保存于`evidence/`，draft_amendment绑定hash。
- 第一次未封存refresh转换成功后，被json_out的拒绝覆盖原导出日志保护
  中止。改为每次导出另写attempt日志，只在未封存稿件更新生成资产索引。
  旧成功日志保留，最终源码另由manuscript_manifest绑定。
- Pandoc提示zh-CN翻译表和Abstract标签缺失；实际标题／正文为中文，四
  导出内容／图片和引用审计通过。没有据此声称翻译资源已修复。
- 本轮网页目录`browser`为初稿、`browser_final`为中间修订，最终发布阅读
  对应`browser_final_v2`。旧通过仅对应其原稿，最终JSON另核对最终文件hash。

## 封存与边界

旧public_proteome唯一根rgo依赖用hash匹配的开始快照；其checks核对新rgo
仍完整保留原历史段，其他科学原路径／hash、旧清单／ZIP继续层叠验证。
新manifest绑定本稿、代码、直接引用结果和更新根rgo，本地附件包不是新的
全项目软件验收。原大数组由旧封存索引，异地仅本附件不含所有历史依赖。

作者材料请求未发送、EV候选身份未启动、没有在线模型调用／湿实验／外部
上传；数字／文件／几何检查没有人工科学或图稿sign-off。具体真实材料
待办见ISSUES和原AUTHOR_MATERIAL_REQUEST／MATERIALS_RECEIPT。
