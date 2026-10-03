# dsh-zego-assistant

ZEGO 官方集成 Skill（[zego-integration](https://github.com/ZEGOCLOUD/zego-integration)）的 [DeepSeek Harness (DSH)](https://github.com/deepseek-ai/deepseek-harness) 插件包。安装后，agent 的技能目录中会出现 `zego-integration` 技能，AI 处理 ZEGO 相关任务时自动加载产品领域知识、官方文档索引与标准集成工作流程。

## 提供的能力

安装的是完整的 zego-integration Skill，能力包括：

| 能力 | 用途 |
|---|---|
| 产品集成 | 引导 ZEGO 产品选型、平台选择与集成实施（RTC/ZIM/AI Agent/数字人/白板等） |
| 文档查阅 | 官方文档全量本地缓存，支持错误码、接口参数、平台兼容性查询 |
| 服务端 Token 生成 | token04 生成规范与多语言服务端示例 |
| 服务端 API 调用 | 签名机制说明与多语言调用示例 |
| 资源下载 | 下载 SDK、示例项目与代码（内置国内镜像回退） |
| 场景最佳实践 | Web/iOS/Android 等场景实战指引，持续扩充 |

## Skill 同步与发布

`assets/skills/zego-integration/` 内容来自 [ZEGOCLOUD/zego-integration](https://github.com/ZEGOCLOUD/zego-integration)。日常发布只需在 main 分支运行：

```bash
./publish.sh          # 或 ./publish.sh minor / major
```

脚本会自动检查上游更新并同步；有变化时提交同步、自动递增版本号并执行 `npm publish`（2FA 账号按提示在终端输入 OTP），随后推送 git。上游无变化则不做任何事；网络受限时自动走镜像克隆上游。

## 安装

前置条件：已安装并运行 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)。

从 npm 安装（预构建制品，推荐）：

```bash
dsh plugin --profile web add dsh-zego-assistant
```

从 GitHub 安装（拉取源码）：

```bash
dsh plugin --profile web add github:ZEGOCLOUD/dsh-zego-assistant
```

pnpm ≥ 8.15 时如报 `ERR_PNPM_ADDING_TO_ROOT`，加 `-w`：

```bash
dsh plugin --profile web add -w dsh-zego-assistant
```

安装后重启该 profile，说一句 "帮我用 ZEGO 实现 1v1 视频通话" 即可验证技能被激活。首次使用时 Skill 会自动下载文档快照到本地缓存（`~/.cache/zego-integration/`）。

## 许可证

MIT
