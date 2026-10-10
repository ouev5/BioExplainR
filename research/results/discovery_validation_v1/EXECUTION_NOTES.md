# 中止记录

`python3 research/discovery/validation_sources.py search research/results/discovery_validation_v1`
首次运行在下载记录的 relative/absolute 路径处理处停止（ValueError）。目录仅有
检索前 freeze 与根交接快照，不是完整检索结果或 pass。修复路径 resolve 后，
新运行另用 `discovery_validation_v2/`，此目录保留。
