# ZEGO 文档仓库（docs_all）结构与查阅要点

仓库为 Docuo（Docusaurus 体系）monorepo，约 1.2 万个 mdx + 数百个 yaml，中英双语文档分目录存放。本文说明如何在这个仓库里快速找到要读的东西。

## 顶层目录

| 目录 | 内容 |
|---|---|
| `core_products/` | 核心产品（大头）：real-time-voice-video（实时音视频）、real-time-voice（实时语音）、low-latency-live-streaming（低延迟直播）、zim（即时通讯）、aiagent（AI Agent）、digital-human（数字人） |
| `extended_services/` | 扩展服务：super_board（超级白板）、cloud_player（云端播放器）、ai-effects（AI 美颜）、cloud_recording（云端录制）、local_recording、analytics_dashboard（星图）、cloud-realtime-asr 等 |
| `uikit/` | UIKit 组件：callkit、live_streaming_kit、live_audio_room_kit、imkit |
| `solutions/` | 场景解决方案：语聊房、在线 KTV、小班课、视频会议等 |
| `general/` | 通用内容（FAQ、术语等） |
| `snippets/` | 跨产品共享片段（被各处 import 复用，无独立公网页面） |
| `cloud-market/` | 云市场相关 |
| `docuo.config.{zh,en,}.json` | 站点配置：instances 路由表（见 `url-mapping.md`） |

**语言版本**：每个产品下分 `zh/` 与 `en/` 两套完整目录（如 `core_products/real-time-voice-video/zh/ios-oc` 与 `.../en/ios-oc`）。中文更全更及时，英文缺失时以中文为准。

## instance（文档空间）概念

每个「产品 × 平台 × 语言」组合是一个 instance（独立文档空间），例如 `core_products/real-time-voice-video/zh/ios-oc` 对应路由 `real-time-video-ios-oc`。instance 目录内有自己的 `sidebars.json`（侧边栏结构）。产品与平台的完整清单见 `products-platforms.md`。

## instance 目录内常见结构

| 子目录/文件 | 内容 |
|---|---|
| `introduction/` | 产品概述、计费 |
| `quick-start.mdx` 或 `quick-start/` | 快速开始（完整集成流程，**集成任务首选**） |
| `integration`、`xxx-guide` 类 | 集成指南/功能实现指南 |
| `client-sdk/api-reference/` | 客户端 SDK API 参考（class.mdx/protocol.mdx/…，**单文件可达数万行**） |
| `client-sdk/error-code.mdx` | 错误码表（markdown 表格，grep 友好） |
| `server/` | 服务端 API（`api-reference/*.yaml` 优先读；`callback/` 为回调） |
| `faq.mdx` | FAQ（更新滞后，仅作参考） |
| `snippets`、产品内共享目录 | 被 import 复用的片段 |

注意：不同产品的目录命名不完全一致（如 ZIM 是 `docs_zim_android_zh` 这类 instance 目录），以 `products-platforms.md` 映射表为准。

## 按信息类型的查阅策略

| 我需要 | 查找方式 | 注意 |
|---|---|---|
| 如何引入 SDK | 文档路径下找 integration/集成 相关 mdx | 通常在路径根或一级子目录 |
| 最小可用示例 | 找 quick-start 相关 mdx | 含完整 初始化→鉴权→进房→推拉流 流程 |
| 具体接口说明 | `client-sdk/api-reference/` 下 grep 方法名定位行号后局部读取 | 禁止整文件读取 |
| 服务端接口 | `server/api-reference/` 下找 .yaml | yaml 优先于 mdx |
| Token 鉴权 | 文档路径下 grep `Token`；配合本 skill 的 `references/token/` | |
| 错误码 | `client-sdk/error-code.mdx` grep 错误码数字 | |
| 特定功能实现 | grep 关键词 + 平台路径限定 | 如 `grep -r "混流" core_products/real-time-voice-video/zh/android-java/` |

## 读取纪律

- **API 参考禁止整文件读取**：先用 grep 拿到目标方法/锚点的行号，再用局部读取（offset/limit），否则几万行文件会撑爆上下文。
- **多文件可并行读取**：集成指南 + API 参考组合查阅时并行读。
- **同平台多语言变体都读**：如 `android-java` 与 `android-kotlin` 内容高度相似，确认平台标识符后可互为补充。
- **追 import 链**：文件开头出现 `import Content from '/xxx.mdx'` 时，正文 `<Content />` 位置的实际内容在被引用文件里，必须追过去读（规则见 `mdx-syntax.md`）。
