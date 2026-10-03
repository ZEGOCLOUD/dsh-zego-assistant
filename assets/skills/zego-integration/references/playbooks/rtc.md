> 适用产品：RTC（实时音视频、实时语音、低延迟直播、Video Call、Voice Call、Live Streaming）
> 适用场景：客户端 SDK 集成（推拉流、进房、屏幕共享、美颜、混流等）

## 文档入口

- 产品×平台路径见 `../products-platforms.md`（如 `core_products/real-time-voice-video/zh/android-java`）。**实时语音、低延迟直播与实时音视频是同一套基础 SDK 的不同产品包装**：文档大量复用 RTC 内容（不少页面只有一行 import，正文即 RTC 对应页；服务端文档直接共用 `real-time-voice-video/zh/server`），各自 instance 文档查不到的内容到 RTC 同平台文档里找。SDK 包有裁剪差异——如 Android 实时语音用 `im.zego:express-audio`（无视频能力、包体积更小），API 以各自 instance 文档为准。
- 必读顺序：`introduction/overview` → `quick-start` → 目标功能所在目录（audio/、video/、room/、live-streaming/ 等）→ `best-practice/`（最佳实践，集成后必读）。

## 关键注意点

- **Web SDK**：npm 安装；推拉流接口基于 WebRTC，与其他平台实现不同，必须用 Web 专属接口。Next.js 等服务端渲染框架注意客户端 SDK 的初始化时机（仅在客户端侧初始化，避免 SSR 阶段报错）。
- **Token 鉴权**：进房需要 Token，服务端生成方案见本 skill `references/token/`；**loginRoom 的 userID 必须与生成 Token 时的 userID 一致**。权限 Token 细节见文档仓库共享片段 `core_products/real-time-voice-video/zh/snippets/privilege-token.mdx`。
- **事件回调**：先注册事件处理（onRoomStreamUpdate、onRoomStateChanged 等）再进房，否则会丢首帧事件。
- **包管理器优先**：Android→maven、iOS/macOS→CocoaPods 或 SPM、Web→npm、Flutter→pub；仅离线场景才手动下载包。
- **排障**：错误码查对应平台 `client-sdk/error-code.mdx`；接口细节用 `resolve_api_link.sh` 解析文档内 `@apiName` 短链。

## Web / React / Next.js 实战经验（2026-10 实测，SDK 3.12.0）

- **npm 包名是 `zego-express-engine-webrtc`**（旧资料里的 `zego-express-engine-websdk` 已过时，以 quick-start 文档为准）。3.4.0+ 支持从 `zego-express-engine-webrtc/esm` 按需引入混音/混流/CDN 等模块。
- **TS 类型入口只导出 `ZegoExpressEngine` 与 `WebRTCUtil`**；`ZegoLocalStream`、`ZegoStream` 等类型不能从包入口 import，用方法签名推导，例如 `type LocalStream = Awaited<ReturnType<ZegoExpressEngine['createZegoStream']>>`，或从内部路径 `zego-express-engine-webrtc/sdk/code/zh/ZegoLocalStream.web` 导入。
- **Next.js 集成模式**：客户端组件（`'use client'`）中在事件回调内 `await import('zego-express-engine-webrtc')` 动态引入并创建引擎，引擎实例存 `useRef`（勿入 state，避免响应式包装——文档对 Vue3 markRaw 的警告同理）。appID 由服务端组件读环境变量后作 props 传入；ServerSecret 只在服务端（Token 路由）使用。
- **核心 API 流程**（3.x）：`new ZegoExpressEngine(appID, '')`（server 可空串）→ `on(...)` 注册回调 → `loginRoom(roomID, token, {userID, userName}, {userUpdate:true})` → `createZegoStream()` → `localStream.playVideo(HTMLElement)` 预览 → `startPublishingStream(streamID, localStream)`；远端在 `roomStreamUpdate` ADD 里 `startPlayingStream(streamID)` → `createRemoteStreamView(stream).play(容器)`。挂断顺序：`stopPublishingStream` → `destroyStream` → `stopPlayingStream`（全部）→ `logoutRoom` → `destroyEngine`。
- **Next.js dev 模式首次点按会"卡住"**：dev server 按需编译 SDK 的 lazy chunk（600+ 模块）非常慢，页面可能数十秒无响应，易误判为集成 bug。**先用 `next build && next start` 在生产模式验证**，dev 模式等首编完成即可。
- **自动化验证方法**：无头/内嵌浏览器对 WebRTC 媒体渲染支持不完整（getUserMedia 可能无帧甚至挂起 webview）。验证集成是否成功以**回调状态**为准：`roomStateChanged` 收到 `LOGINED`、`publisherStateUpdate` 收到 `PUBLISHING`、双端互见 `roomStreamUpdate` ADD 且 `playerStateUpdate` 收到 `PLAYING`，即证明 AppID/Token/信令/推拉流全链路正确；画面像素级确认留给真实浏览器。
- **streamID 全局唯一**（同一 AppID 下），常用 `${userID}-${Date.now()}`；同一 streamID 后推者会失败。
