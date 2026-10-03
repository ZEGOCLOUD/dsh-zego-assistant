> 适用产品：实时互动 AI Agent（语音通话 / 数字人）
> 适用场景：Agent 创建与注册、客户端接入实时互动

## 文档入口

- `core_products/aiagent/zh/server`：Agent 的创建/配置/管理（服务端 API）。
- `core_products/aiagent/zh/{web,android,ios,flutter}`：客户端接入。
- 快速开始是主要依据（注意各平台 quick-start 大量互相 import，按 `../mdx-syntax.md` 追 import 链并按 platform 过滤）。

## 关键注意点

- **Agent 类型**：先确认 语音通话（Voice Call）还是 数字人（Digital Human）模式，两者的客户端流程与所需 SDK 不同。
- **SDK 获取**：需从下载页获取指定版本 SDK；部分 SDK 是压缩包形式，用本 skill 的 `downloader.py` 下载（自带 Referer 头）。
- **注册 Agent 配置**：注册时的配置项与 quick-start 示例代码片段保持一致；`LLM.ApiKey`、`TTS.Params.app.appid`、`TTS.Params.app.token` 等测试值使用 `zego_test`（由不同厂商决定），生产再替换为真实配置。
- **数字人**：Web 端 quick-start 直接 import Android 版内容并按 platform 过滤（`import Content from '.../android/quick-start-with-digital-human.mdx'`），阅读时注意区分。
- **最佳实践**：遵循 RTC 最佳实践（见 `rtc.md`），Agent 本质上运行在 RTC 通道之上。
