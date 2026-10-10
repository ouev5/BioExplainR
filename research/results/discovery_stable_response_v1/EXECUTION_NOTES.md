# 本轮执行与修订记录

分析和报告实际运行于主机UTC 2026-10-09；各freeze、文献acquisition与export分别保存实际UTC。此说明不是回填每命令精确起止时间的运行日志。

- `discovery_genome_v1`在完整交互筛查后，因0候选的留一供体赋值停止；空候选本身是真实科学结果。脚本仅修复零行赋值，重新冻结运行`discovery_genome_v2`，三交互均0显著。
- 启动稳定响应筛查的第一次命令误传未存在的`discovery_response_v1`来源，normalizePath即停止；尚未建立输出。改用实际`discovery_genome_v2`后完成`discovery_stable_response_v1`。
- 外部读取遇第3候选ENSG00000235770缺注释，原脚本停止；修订为固定12候选缺测P=1，重新提取原TPM，仍保留48检验分母，无替换候选。见external_execution_amendment.json。
- 原TPM独立R审计首次以all.equal相对1e-9比较遇CI差约5.0e-10；记录为−0.471686288430094 vs −0.471686288932591。显式容差改为abs差≤1e-10+1e-8×abs(reference)，随后全部通过；不改变结果或P。源于跨库浮点逆分布精度，不改写原TPM或效应。
- v1报告使用非合同字段uncertainties、direct_time仅声明ASM；v2改用uncertainty并显式混合scope/不合并单位，v1RDS/HTML保留。见report_amendment.json。
- 中文报告构建第一次相对source路径relative_to绝对ROOT失败，未保存稿件；v1目录仅保留错误JSON。路径resolve后在v2目录完成Word/PDF/HTML，文稿仍称结果报告v1。
- PMC8294620/PMC2701960全文XML实际500，失败保留focused_fulltext_acquisition.json；其已保存Europe PMC题名/摘要仅按该范围使用。
- 尝试读取PNG时模型环境不支持图像输入；未做视觉检查。数字/CSV、PDF文本边界与矢量路径、HTML实际加载/1440和390宽度均完成。
- 全仓git diff --check遇此前已修改的baseline CSV CRLF尾空白，未改旧manifest；本轮文件另作语法／尾空白及封存hash检查。

正式运行命令见报告README。独立Python审计增补了24项marginal微阵列结果／精确置换后复核通过；已保存的其他数值无变化。
