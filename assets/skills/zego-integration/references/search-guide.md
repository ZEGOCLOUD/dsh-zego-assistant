# 本地文档检索指南

在本地文档仓库（DOCS_ROOT）做检索。原则：**先缩小路径范围（产品+平台），再用精确关键词 grep，最后局部读取**。

工具优先 `rg`（ripgrep），无则用 `grep -r`。下文统一写 rg，grep 用户自行替换。

## 0. 先定位范围

查 `products-platforms.md` 拿到产品+平台的文档路径（如 `core_products/real-time-voice-video/zh/android-java`），后续检索全部限定在该路径下，避免全仓库噪音。用户没说产品/平台时先确认（错误码等有明显产品特征的除外）。

## 1. 错误码查询

```bash
rg -n "1230004" <DOCS_ROOT>/core_products/real-time-voice-video/zh/android-java/client-sdk/error-code.mdx
```

- 错误码表在 `client-sdk/error-code.mdx`，markdown 表格，`| 1230004 | 描述：...可能原因：...处理建议：... |` 一行即完整答案。
- 不知道产品时：`rg -l "1230004" <DOCS_ROOT> --glob 'error-code*'` 先找产品，再精读。
- **注意 import 包装**：部分平台的 error-code.mdx 只有几行、内容是 `import Content from '.../ios-oc/client-sdk/error-code.mdx'`——此时 grep 本文件无结果，要追被引用文件，或直接全产品范围 `--glob 'error-code*'` 检索。不同平台的错误码表内容一致，查到一份即可。

## 2. API 用法/参数

```bash
# 1) 在 API 参考目录定位方法（ParamField 的 name 属性）
rg -n 'name="loginRoom"' <DOCS_ROOT>/core_products/real-time-voice-video/zh/android-java/client-sdk/api-reference/

# 2) 用行号局部读取该方法上下文（±100 行左右），不要整文件读
```

- API 参考单文件可达数万行（如 class.mdx 约 2.2 万行），**必须先定位行号再局部读取**。
- 文档正文里的 `[loginRoom](@loginRoom)` 短链，用 `resolve_api_link.sh` 一步解析到文件+锚点。
- 服务端接口去 `server/api-reference/` 下找同名 `.yaml`（优先）或 `.mdx`。

## 3. 功能支持/配置项/关键词类问题

```bash
rg -n -i "screen sharing|屏幕共享" <产品平台路径>/
rg -n "分辨率" <产品平台路径>/ --glob '*.mdx' | head -20
```

- 命中文件多时，优先读 quick-start、功能指南类文件；`-l` 先列文件再挑。
- 中英文关键词都可以试（中文文档为主，但代码/参数名是英文）。
- 找「SDK 是否支持 X」类答案时，功能总览页（`client-sdk/api-reference/function-list` 或 introduction 下）往往一行就能回答。

## 4. 找文档入口（不知道文件在哪）

```bash
# 按文件名找
fd -e mdx "quick-start" <产品平台路径>/
find <产品平台路径> -name "*.mdx" | head -30
# 看 sidebars.json 了解该 instance 的文档组织
cat <产品平台路径>/sidebars.json
```

## 5. 读取优先级

1. quick-start / integration 类（集成流程）
2. 功能指南（目录名常为功能域，如 audio/、video/、room/）
3. API 参考（定位后局部读）
4. FAQ（最后参考，内容可能滞后）

## 6. 检索纪律

- 全仓库检索是最后手段（1.2 万文件），必须先限定产品路径。
- 每次只读命中点附近的内容；不确定再扩大范围。
- zh 查不到时换 en 路径再试（个别内容只有英文）。
- 本地确实查不到 → 在线兜底：WebFetch `https://doc-zh.zego.im/llms.txt` 定位页面 → 读 `<页面URL>.md`。
