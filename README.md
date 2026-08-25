# dsh-zego-assistant

ZEGO 官方集成助手（zego-assistant）的 [DeepSeek Harness (DSH)](https://github.com/deepseek-ai/deepseek-harness) 插件包。安装后，agent 的技能目录中会出现 5 个 ZEGO 技能，同时桥接 ZEGO doc-ai MCP 服务器的工具。

技能内容逐字取自 [ZEGOCLOUD/zego-claude-code-plugins](https://github.com/ZEGOCLOUD/zego-claude-code-plugins) 的 `plugins/zego-assistant/skills`，版本号与源插件保持同步。

## 提供的技能

| 技能 | 用途 |
|---|---|
| `integrate-zego-product` | 集成 ZEGO 产品 SDK（Express/ZIM/AI Agent/数字人/白板），按流程引导产品、平台选择与文档查阅 |
| `implement-zego-token-on-server` | 服务端实现 ZEGO Token 生成，附 6 种语言示例（Go/Java/Node/Python/PHP/C#） |
| `integrate-zego-server-api` | 调用 ZEGO 服务端 API（房间管理、混流、踢人等），含签名机制与多语言签名示例 |
| `resource-downloader` | 下载 ZEGO SDK、示例项目与 GitHub 仓库 |
| `search-zego-doc-fragments` | 基于 RAG 的文档片段检索：错误码、API 参数、平台兼容性排查 |

## MCP 桥接

本包通过 [`@deepseek-ai/dsh-mcp-client`](https://www.npmjs.com/package/@deepseek-ai/dsh-mcp-client) 连接 `https://doc-ai.zego.im/mcp/`，`serverName` 为 `ZEGO`，因此模型看到的工具名形如 `mcp__ZEGO__get_doc_links` —— 与 Claude Code 的 `mcp__<server>__<tool>` 命名完全一致，SKILL.md 中对 MCP 工具的引用无需任何改动。

MCP 工具断线自动重连、`tools/list_changed` 重同步、每调用 60s 超时均由 dsh-mcp-client 内置处理。

## 安装

前置条件：已安装并运行 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)。

```bash
dsh plugin --profile web add dsh-zego-assistant
```

pnpm ≥ 8.15 时如报 `ERR_PNPM_ADDING_TO_ROOT`，加 `-w`：

```bash
dsh plugin --profile web add -w dsh-zego-assistant
```

安装后重启该 profile，说一句 "integrate ZEGO RTC video call" 即可验证技能被激活。

从 GitHub 安装（拉取源码，本地开发也用这种方式）：

```bash
dsh plugin --profile web add github:ZEGOCLOUD/doc-dsh-plugin
dsh plugin --profile web --dump-config          # 应能看到 dsh-zego-assistant 层
```

## 与源仓库同步

技能目录 `assets/skills/` 从源仓库 vendor 而来（未做任何改写）。更新方式：

```bash
git clone --depth 1 https://github.com/ZEGOCLOUD/zego-claude-code-plugins /tmp/zego-cc
rm -rf assets/skills && mkdir -p assets/skills
cp -R /tmp/zego-cc/plugins/zego-assistant/skills/. assets/skills/
```

同步后把 `package.json` 的 `version` 对齐源插件版本（源 `plugins/zego-assistant/.claude-plugin/plugin.json` / marketplace.json）再发布。

注意：`zego-doc-writer` 插件（文档团队内部工具）未包含在本包内；其 commands/agents 形态需要按 DSH 的 `ctx.commands` / `ctx.subagents` API 重写后才能迁移。

## 许可证

MIT
