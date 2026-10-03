# SDK Download URLs

This document contains the download URLs for ZEGO Server Assistant SDKs for all supported languages.

## Official SDK URLs

All SDKs are hosted on GitHub at: `https://github.com/zegoim/zego_server_assistant`

### Go

```bash
https://raw.githubusercontent.com/zegoim/zego_server_assistant/refs/heads/release/github/token/go/src/token04/token04.go
```

**File name**: `token04.go`

**Recommended directories** (in priority order):
1. `pkg/zego/token/`
2. `internal/zego/token/`
3. `zego/token/`
4. `utils/zego/token/`
5. `lib/zego/token/`

### C++

```bash
https://raw.githubusercontent.com/zegoim/zego_server_assistant/refs/heads/release/github/token/c%2B%2B/token04/kernel/impl/ZegoServerAssistantImpl.cpp
```

**File name**: `ZegoServerAssistantImpl.cpp`

**Recommended directories** (in priority order):
1. `zego/token/`
2. `utils/zego/token/`
3. `lib/zego/token/`
4. `src/zego/token/`

**Note**: C++ SDK may require additional header files. Check the full repository for dependencies.

### Java

```bash
https://raw.githubusercontent.com/zegoim/zego_server_assistant/refs/heads/release/github/token/java/token04/src/im/zego/serverassistant/utils/TokenServerAssistant.java
```

**File name**: `TokenServerAssistant.java`
**Package**: `im.zego.serverassistant.utils`

**Recommended directories** (in priority order):
1. `src/main/java/im/zego/serverassistant/utils/`
2. `im/zego/serverassistant/utils/`
3. `zego/token/`
4. `utils/zego/token/`

### Python

```bash
https://raw.githubusercontent.com/zegoim/zego_server_assistant/refs/heads/release/github/token/python/token04/src/token04.py
```

**File name**: `token04.py`

**Recommended directories** (in priority order):
1. `zego/token/`
2. `utils/zego/token/`
3. `lib/zego/token/`
4. `services/zego/token/`

**Dependencies**: Requires standard library only (no external pip packages)

### Node.js / TypeScript

```bash
https://raw.githubusercontent.com/zegoim/zego_server_assistant/refs/heads/release/github/token/nodejs/token04/server/zegoServerAssistant.ts
```

**File name**: `zegoServerAssistant.ts`

**Recommended directories** (in priority order):
1. `zego/token/`
2. `utils/zego/token/`
3. `lib/zego/token/`
4. `services/zego/token/`
5. `src/zego/token/`

**Note**: This is TypeScript. Can be used directly in TS projects or compiled to JS.

### PHP

```bash
https://raw.githubusercontent.com/zegoim/zego_server_assistant/refs/heads/release/github/token/php/token04/src/ZEGO/ZegoServerAssistant.php
```

**File name**: `ZegoServerAssistant.php`
**Namespace**: `ZEGO\ZegoServerAssistant`

**Recommended directories** (in priority order):
1. `ZEGO/Token/`
2. `zego/token/`
3. `utils/zego/token/`
4. `lib/zego/token/`

### C#

```bash
https://raw.githubusercontent.com/zegoim/zego_server_assistant/refs/heads/release/github/token/.net/token04/src/ZegoServerAssistant/GenerateToken.cs
```

**File name**: `GenerateToken.cs`
**Namespace**: `ZegoServerAssistant`

**Recommended directories** (in priority order):
1. `ZegoServerAssistant/`
2. `Services/ZegoServerAssistant/`
3. `Utils/ZegoServerAssistant/`
4. `zego/token/`

## Language Identifiers

When using the download script, use these exact identifiers:

| Language  | Identifier |
|-----------|------------|
| Go        | GO         |
| C++       | CPP        |
| Java      | JAVA       |
| Python    | PYTHON     |
| Node.js   | NODEJS     |
| PHP       | PHP        |
| C#        | CSHARP     |

## 建议存放位置（由你按项目结构决定）

脚本默认把源文件下载到**当前目录**，用 `--output` 指定其他位置：

```bash
python scripts/download_sdk.py --language PYTHON --output src/zego/token/token04.py
```

放入项目时参考下表（各语言特色路径，项目已有 `zego/` 目录时优先放 `<该目录>/token`）：

| 语言 | 建议路径 |
|---|---|
| Go | `pkg/zego/token`、`internal/zego/token` |
| Python | `utils/zego/token`、`services/zego/token` |
| Node.js | `src/zego/token`、`utils/zego/token` |
| Java | `src/main/java/im/zego/serverassistant/utils`（须与文件内 package 声明一致，放别处要同步改 package 行） |
| PHP | `ZEGO/Token` |
| C# | `ZegoServerAssistant/`、`Services/ZegoServerAssistant` |
| C++ | `utils/zego/token`、`src/zego/token` |

## Fallback Language

If the target language is not supported, use **NODEJS** as the reference implementation. The Node.js/TypeScript SDK is well-structured and can be easily translated to other languages.

## Direct Repository Access

For browsing the full source code or finding additional files:

```bash
https://github.com/zegoim/zego_server_assistant/tree/release/github/token
```

## Version Information

- All SDK URLs point to the `release` branch
- Token version: `token04` (current version for ZEGO services)
- Always use the `token04` version for new integrations

## 网络不通时的镜像下载（github 直连失败）

上面所有 `raw.githubusercontent.com` / `github.com` URL 在无法直连 GitHub 的网络下会失败。两种解决办法：

1. **推荐：用 `scripts/download_sdk.py`**——已内置自动回退，直连失败时改走 `https://gh-proxy.com/<原URL>` 镜像。
2. 手动下载时，在原 URL 前加镜像前缀：

   ```bash
   curl -LO "https://gh-proxy.com/https://raw.githubusercontent.com/zegoim/zego_server_assistant/refs/heads/release/github/token/nodejs/token04/server/zegoServerAssistant.ts"
   ```
