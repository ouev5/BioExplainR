# BioExplainR 代码与论文归档状态

更新时间：2026-10-09；版本0.4.0.9000，论文v0.10。

**GitHub 按负责人要求继续暂停。当前稿为 v0.10，入口 `docs/paper_cn_v4/README.md`，正式共同任务/机制/ChIP增补为`docs/research_followup_v1/`，本地交付r13。下述403为此前实际尝试记录；发布需负责人重新要求恢复后执行。新稿及研究增补均未上传外部服务，#45–47 仅对应历史 v0.8。**

## 已准备

- MIT 许可证：根目录 `LICENSE`、`LICENSE.md`；引用元数据 `CITATION.cff`，变更记录 `NEWS.md`。
- 源码构建与检查、最新主稿/补充、工具比较 CSV/XLSX、公开发现案例输入及重算结果、哈希清单和发布包。
- 当前可编辑主稿和独立补充：`docs/paper_cn_v4/README.md`。网页入口源：`docs/index.html`。
- 先前公开建仓、提交、推送和 release 授权已被后续暂停决定覆盖。作者/通讯邮箱仍采用原有占位，不推断真实身份。

## 实际外部状态

|事项|状态|可核实记录|
|---|---|---|
|GitHub 账号|`ouev5`，API 身份请求成功|仅保存公开账号；令牌不写文件|
|拟建仓库名|`BioExplainR`|用户指定按包名命名|
|创建仓库|**blocked：HTTP403**|`gh repo create` 和 `gh api user/repos` 均返回 Resource not accessible by personal access token|
|推送与公开 release|**尚未完成**|仓库创建权限不足，未获得远程仓库|
|正式仓库/文档网址|**尚未建立**|不将拟用地址写为已经发布|
|Zenodo/DOI|**尚未签发**|环境没有 Zenodo 归档凭据；GitHub 令牌不提供 DOI 权限|

## 负责人明确恢复发布后的一次性配置

1. 负责人在 `ouev5` 账号创建公开仓库 `BioExplainR` 并给执行环境 Contents 读写权限，或配置能够创建仓库并读写内容的凭据到 `GH_TOKEN`。不要将令牌写入源码或聊天。
2. 发布执行者用 `gh` 建仓库（已存在则核实为空或审查已有内容）、设置无凭据 remote、推送已检查的源码和文档，创建版本标签与 GitHub release，附带源码 tar、论文及可复现案例包；随后匿名回读核对。
3. DOI 通过 Zenodo 账号关联 GitHub 仓库并开启归档后签发；若首次 release 先于关联，可手动在 Zenodo 存档源码与版本元数据。需要真实作者信息及 Zenodo 登录/凭据。签发后将版本 DOI、归档 URL 和正式仓库 URL 写入论文、CITATION.cff、README、DESCRIPTION，再发布可追踪修订。

GitHub release 与 DOI 是两个不同发布动作。当前稿清楚写明待完成状态，无虚构标识。
