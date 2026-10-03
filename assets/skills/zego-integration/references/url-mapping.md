# 公网 URL ↔ 本地 mdx 互推规则

ZEGO 文档站的每个页面都对应仓库里一个 mdx 文件，双向可推。优先用脚本，规则用于理解和兜底。

## 脚本（推荐）

```bash
# URL → 本地 mdx（支持完整 URL、带 /docs 前缀的英文站 URL、纯路径）
python3 <skill>/scripts/find_mdx.py <DOCS_ROOT> "https://doc-zh.zego.im/real-time-video-ios-oc/introduction/overview"
# → <DOCS_ROOT>/core_products/real-time-voice-video/zh/ios-oc/introduction/overview.mdx

# 本地 mdx → 公网 URL（zh/en 各输出一行；snippets 共享片段无公网页面，会报错说明）
python3 <skill>/scripts/mdx_to_url.py <DOCS_ROOT> <DOCS_ROOT>/core_products/.../overview.mdx
# → zh  https://doc-zh.zego.im/real-time-video-ios-oc/introduction/overview
# → en  https://www.zegocloud.com/docs/real-time-video-ios-oc/introduction/overview

# 文档内 [text](@apiName) 短链 → API 参考 mdx + 锚点
bash <skill>/scripts/resolve_api_link.sh startPublishingStream core_products/real-time-voice-video/zh/web/quick-start.mdx <DOCS_ROOT>
```

## 域名与配置文件对应关系

| 域名 | 语言 | 配置文件 | URL 前缀 |
|---|---|---|---|
| `doc-zh.zego.im` | 中文 | `docuo.config.zh.json` | 无 |
| `www.zegocloud.com/docs` | 英文 | `docuo.config.en.json` | `/docs`（推本地时剥掉） |
| 仅路径 `/xxx` | 默认中文 | `docuo.config.zh.json` | 无 |

配置里的 `instances[]` 定义路由表（zh 152 个 / en 110 个），每项形如：

```json
{ "id": "real_time_video_ios_oc_zh",
  "routeBasePath": "real-time-video-ios-oc",
  "path": "core_products/real-time-voice-video/zh/ios-oc",
  "clientApiPath": "client-sdk/api-reference" }
```

- `routeBasePath`：URL 里紧随域名的一段。
- `path`：对应的本地目录（相对仓库根）。
- `clientApiPath`：该 instance 的客户端 API 参考目录（@ 短链解析用）。

## URL 拼装/还原规则

```
URL = 域名 [+ /docs] + / + routeBasePath + / + fileId
本地文件 = <仓库根>/<instance.path>/<fileId 还原成的实际文件>
```

**fileId 规则**（文件相对 instance 目录的路径变换）：

1. 去掉扩展名（.mdx/.md）
2. 全部小写
3. 空格 → 连字符
4. 去掉 `01-`、`02-` 之类数字前缀
5. 结尾的 `/index` 去掉

示例（instance `real-time-video-android-java`）：

| 本地文件 | fileId | 完整 URL 路径 |
|---|---|---|
| `introduction/overview.mdx` | `introduction/overview` | `/real-time-video-android-java/introduction/overview` |
| `01-Intro/02-Overview.mdx` | `intro/overview` | `/real-time-video-android-java/intro/overview` |
| `Quick Start/Setup Guide.mdx` | `quick-start/setup-guide` | `/real-time-video-android-java/quick-start/setup-guide` |

**匹配实例时用最长前缀优先**（greedy match）：URL 第一段先与所有 routeBasePath 匹配，命中后剩余部分即 fileId；反向时找包含该文件的最长 `path` 前缀的 instance。

## sidebars.json

每个 instance 目录内有 `sidebars.json`，描述侧边栏（也可用于了解文档组织）：

- `{"type": "doc", "id": "introduction/overview", "label": "概述"}` —— id 就是上文的 fileId。
- `{"type": "category", "items": [...]}` —— 分组。
- `{"type": "link", "href": "/real-time-video-ios-oc/..."}` —— 站内锚点链接（如 API class 内的某类）。

## 注意事项

- 部分旧 URL 走 `docuo.config.*.json` 里的 `redirects`（约 31 条，多为 API 目录迁移），本地还原时若直接命中失败，查一下 redirects 是否有 source→destination 映射。
- `snippets/`、各产品 `snippets/` 目录下的文件是被 import 的共享片段，**没有**独立公网 URL。
- 页面 URL 加 `.md` 后缀可直接获取该页 Markdown（在线兜底用）：`https://doc-zh.zego.im/<路径>.md`。
- `https://doc-zh.zego.im/llms.txt` 是全部文档页的 .md 直链总表（约 640KB），WebFetch 可读。
