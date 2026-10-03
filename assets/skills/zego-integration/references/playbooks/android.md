> 适用产品：RTC（实时音视频）Android 客户端集成
> 适用场景：Java/Kotlin 集成 Express Android SDK、Gradle 工程、Android 模拟器自动化验证、与 Web 端互通联调

## 文档入口

- 文档路径见 `../products-platforms.md`：`core_products/real-time-voice-video/zh/android-java`（Java 版）与 `android-kotlin`（Kotlin 版）。
- 必读：quick-start/integrating-sdk（maven 坐标）+ quick-start/implementing-video-call（完整可运行的 MainActivity 示例，直接抄 API 流程）。
- Android 实现文档基本不套 import 外壳，示例代码完整可直接用。

## 集成要点（2026-10 实测，SDK 3.25.0）

- **Maven 坐标**：`maven { url 'https://maven.zego.im' }`（ZEGO 自有 CDN，国内直连可达）+ `implementation 'im.zego:express-video:3.25.0'`。**注意**：老资料里的 `com.github.zegolibrary:express-video`（jitpack）已废弃（release-notes r2084 有迁移说明）。
- **Token 鉴权模式**：`profile.appSign = ""`（空串）+ `roomConfig.token = <token04>`；`config.isUserStatusNotify = true` 才能收 onRoomUserUpdate。`profile.appID` 是 **long**（1234567890L）。
- **kotlin-stdlib 冲突（高频坑）**：appcompat 传递依赖 kotlin-stdlib 1.8.22 与 ZEGO SDK 带的 kotlin-stdlib-jdk8:1.6.21 产生 Duplicate class。用 `constraints { implementation('org.jetbrains.kotlin:kotlin-stdlib:1.8.22') ... }` 统一。
- 核心 API 流程：`ZegoEngineProfile{appID, appSign:"", scenario, application}` → `ZegoExpressEngine.createEngine(profile, eventHandler)` → `loginRoom(roomID, user, config, callback)` → `startPreview(new ZegoCanvas(textureView))` + `startPublishingStream(streamID)`；`onRoomStreamUpdate(ADD)` → `startPlayingStream(streamID, canvas)`。挂断：`logoutRoom` + `ZegoExpressEngine.destroyEngine(callback)`。
- AndroidManifest：CAMERA/RECORD_AUDIO/INTERNET + `android:usesCleartextTraffic="true"`（本地 http Token 端点需要）。
