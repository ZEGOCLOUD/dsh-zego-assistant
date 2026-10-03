---
name: zego-integration
description: Use this skill when integrating ZEGO/ZEGOCLOUD products (RTC video call, voice call, live streaming, ZIM in-app chat, AI Agent, digital human, whiteboard, UIKit), implementing Token authentication, calling server APIs with signature, looking up error codes / API parameters / platform compatibility, finding or reading ZEGO docs (URL to local mdx), or downloading ZEGO SDKs and demos. 触发词：zego、即构、ZEGOCLOUD、Express SDK、实时音视频、直播、即时通讯、AI Agent、数字人、白板、错误码、token 生成、鉴权、服务端 API、签名、查文档、找文档、integrate zego、video call、live streaming、in-app chat、digital human、error code、token authentication、server api、signature。
---

# ZEGO 产品集成与文档查阅

本 skill 把 ZEGO 官方文档仓库（ZEGOCLOUD/docs_all，约 1.2 万个 mdx/yaml）下载到本地，通过「查映射表 + grep 检索 + 读源文件」离线完成产品集成、问题排查、错误码查询、Token/签名实现等任务。

## 目录

```
本skill/
├── references/
│   ├── products-platforms.md   # 产品 × 平台 × 文档路径映射表（定位文档入口，最常用）
│   ├── docs-repo-structure.md  # 文档仓库结构与查阅要点
│   ├── url-mapping.md          # 公网 URL ↔ 本地 mdx 互推规则
│   ├── mdx-syntax.md           # MDX 语法（import 复用、条件渲染、组件含义）
│   ├── search-guide.md         # 本地检索策略（错误码/API/关键词）
│   ├── token/                  # 服务端 Token 生成（说明 + SDK 地址 + API 规范）
│   ├── server-api/             # 服务端 API 签名与请求结构
│   └── playbooks/              # 场景最佳实践指引（按产品/场景分文件）
├── scripts/                    # update_docs.sh / find_mdx.py / mdx_to_url.py / resolve_api_link.sh / download_sdk.py / downloader.py
└── examples/                   # token/ 与 signature/ 多语言示例代码
```

## 第一步：初始化（每次会话首次使用本 skill 时）

先运行更新脚本，确保本地文档是最新快照（脚本自带 10 分钟节流，重复调用无开销）：

```bash
bash <本skill目录>/scripts/update_docs.sh
```

输出末尾的 `DOCS_ROOT=...` 即文档仓库路径（默认 `~/.cache/zego-integration/docs_all`，可用 `ZEGO_DOCS_ROOT` 覆盖）。后续所有查阅都基于该路径。

- `STATUS=ready/updated/cached`：正常，直接干活。
- `STATUS=offline`：网络不可用，降级使用本地现有快照，不要因此中断任务。
- exit 1（本地无副本且无法下载）：先解决网络（脚本已内置 gh-proxy.com 镜像回退），再重试。

## 任务路由

| 用户任务 | 做法 |
|---|---|
| 集成 ZEGO 产品/功能 | 走下方「集成工作流」；先查 `references/playbooks/` 有无对应场景指引 |
| 查错误码含义 | `search-guide.md` → 错误码小节（grep error-code.mdx） |
| 查某 API 用法/参数 | `search-guide.md` → API 小节（grep 定位锚点，局部读取） |
| 查平台/功能支持情况 | `references/products-platforms.md` 映射表 + grep 验证 |
| 给了文档 URL 要找内容 | `python3 scripts/find_mdx.py <DOCS_ROOT> <url>` → 直接读本地 mdx |
| 需要给出文档公网链接 | `python3 scripts/mdx_to_url.py <DOCS_ROOT> <mdx路径>` |
| 文档里的 `[xxx](@apiName)` 短链 | `bash scripts/resolve_api_link.sh <apiName> <当前mdx路径> [DOCS_ROOT]` |
| 服务端生成 Token | `references/token/` + `examples/token/` + `scripts/download_sdk.py` |
| 调用服务端 API | `references/server-api/` + `examples/signature/` |
| 下载 SDK / Demo / 仓库 | `python3 scripts/downloader.py <url> [下载目录]`（目录缺省为 `当前目录/.tmp`） |

## 集成工作流

1. **确定范围**：根据项目与用户需求确定产品、功能、平台（客户端：iOS/Android/Web/Flutter…；服务端语言：Go/Java/Python/Node/PHP/C#）。不清楚时向用户确认。先查 `references/playbooks/` 是否有该场景的最佳实践指引。
2. **定位文档**：查 `references/products-platforms.md` 找到 产品+平台 对应的文档路径（如 `core_products/real-time-voice-video/zh/ios-oc`），按 `docs-repo-structure.md` 的目录约定找到 quick-start / integration 类文档。
3. **读完整文档再写码**：完整读取快速开始与集成指南（涉及 import 复用的文件，按 `mdx-syntax.md` 的规则追读被引用文件，并按 platform 条件过滤内容）。**必须使用目标平台专属文档**——各平台实现细节不同，用错平台文档会导致集成失败。
4. **服务端配套**：客户端需要 Token 鉴权时，按 `references/token/` 在服务端实现；需要调服务端 API 时，按 `references/server-api/` 实现签名。
5. **实现与验证**：实现过程中遇到具体 API 疑问，按 `search-guide.md` 查 API 参考；集成后按文档的验证步骤测试。

## 场景最佳实践（playbooks）

`references/playbooks/` 下每个 md 文件是一个场景/产品的最佳实践指引，目录内 `README.md` 有完整索引。**处理集成任务前先看该目录是否有匹配的指引文件**（文件名即产品/场景名）。

## 在线兜底（本地检索不足时）

- 中文站全量索引：`https://doc-zh.zego.im/llms.txt`（全部文档页的 MD 列表，含 .md 直链），海外/英文站为 `https://www.zegocloud.com/docs/llms.txt`，均可用 WebFetch 获取后定位页面。
- 任意文档页 URL 追加 `.md` 后缀即可拿到该页 Markdown 源（如 `https://doc-zh.zego.im/real-time-video-ios-oc/introduction/overview.md`），用 WebFetch 读取。
- 英文站为 `https://www.zegocloud.com/docs/...`（同样支持 `.md` 后缀）。

## 通用最佳实践

- **先读文档再写码**：任何 ZEGO 集成/排障任务，禁止不查文档直接动手。
- **API 参考大文件禁止整读**：单文件可达数万行，先 grep 定位行号再局部读取（详见 `search-guide.md`）。
- **服务端 API 优先读 yaml**：`server/api-reference/*.yaml` 结构化程度高，信息密度大于 mdx。
- **zh/en 两个语言版本**：中文文档更全更及时；英文缺失时以中文为准。
- **SDK 集成方式**：客户端同时提供包管理器与离线包时，默认用包管理器装最新版（Android→maven，iOS/macOS→CocoaPods/SPM，Web→npm 等）。
- **密钥管理**：AppID/ServerSecret 等统一放 .env 或配置文件并注释用途与获取方式；ServerSecret 绝不暴露到客户端、不提交版本控制。
- **下载 ZEGO 资源**（SDK 压缩包、示例、图片等）需带 `Referer: https://doc-zh.zego.im/` 头（downloader.py 已内置）。
- **测试 id 命名**：尽量简短，数字+字母驼峰式。
- 文档中给出 GitHub 示例/压缩包，而纯文档不足以完成集成时，应下载参考。

## 避免做什么

- 避免用搜索引擎搜 ZEGO 问题——先本地文档仓库，再官方在线兜底。
- 避免只读文档片段就开工集成——快速开始/集成指南必须完整读。
- 避免任务完成后生成一堆说明性 md 文件。
- 避免把 FAQ 内容当作权威（FAQ 更新滞后，冲突时以指南和 API 参考为准）。
