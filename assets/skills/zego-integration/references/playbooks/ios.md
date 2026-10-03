> 适用产品：RTC（实时音视频）iOS 客户端集成
> 适用场景：SwiftUI/UIKit 集成 Express iOS SDK、模拟器自动化验证、与 Web 端互通联调

## 文档入口

- 文档路径见 `../products-platforms.md`：`core_products/real-time-voice-video/zh/ios-swift`（Swift 版）与 `zh/ios-oc`（OC 版）。
- **注意 import 复用**：ios-swift 的 integrating-sdk.mdx 常常只是 `import Content from '.../ios-oc/...'` 的包装，SPM 地址、CocoaPods 配置等实际内容在 ios-oc 原文里（按 `../mdx-syntax.md` 追链）。
- 必读：quick-start/integrating-sdk（集成方式）+ quick-start/implementing-video-call（API 流程）。

## 集成方式（2026-10 实测，SDK 3.25.0）

- **SPM（推荐）**：包地址 `https://github.com/zegolibrary/express-video-ios`（在 ios-oc 集成文档中），product 名 `ZegoExpressEngine`。
- **网络要点**：该 SPM 仓库的 **xcframework 二进制托管在 ZEGO 自有 CDN**（artifact-node.zego.cloud，国内直连可达），**只有 git clone 需要访问 github**。github 不通时用临时 git 改写，不要动全局配置：

  ```bash
  printf '[url "https://gh-proxy.com/https://github.com/"]\n\tinsteadOf = https://github.com/\n' > /tmp/spm_gitconfig
  export GIT_CONFIG_GLOBAL=/tmp/spm_gitconfig
  xcodebuild -resolvePackageDependencies -project X.xcodeproj
  ```

- **CocoaPods**：`pod 'ZegoExpressEngine'`（需 CocoaPods ≥1.10，XCFramework）。

## 核心 API 流程（与 Web 差异较大）

```
ZegoEngineProfile(appID:, appSign:"", scenario:) → ZegoExpressEngine.createEngine(with:eventHandler:)
→ loginRoom(roomID, user: ZegoUser(userID:), config: ZegoRoomConfig{token, isUserStatusNotify=true})
→ startPreview(ZegoCanvas(view:)) + startPublishingStream(streamID)
→ onRoomStreamUpdate(.add) → startPlayingStream(streamID, canvas: ZegoCanvas(view:))
挂断: stopPreview → stopPublishingStream → stopPlayingStream → logoutRoom → ZegoExpressEngine.destroy
```

- iOS **没有** Web 端的 `createZegoStream`/`createRemoteStreamView`，直接用 `ZegoCanvas(view:)` 绑定 UIView 渲染（SwiftUI 用 `UIViewRepresentable` 包一个容器 view 注入）。
- **Token 鉴权模式坑**：`profile.appSign` 是**非可选 String**，传 `""`（空串）即 Token 模式；此时 `loginRoom` 的 `ZegoRoomConfig.token` 必填。quick-start 示例对此描述含糊，SDK 头文件注释（ZegoExpressDefines.h 2262 行附近）才是权威。
- `userID` 必须与生成 Token 的 userID 一致（同 Web）。

## 构建与模拟器（自动化验证要点）

- **xcode-select 指向 CommandLineTools 时**，不必 sudo 切换：所有命令前加 `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`。
- **新版 Xcode 的 iOS runtime 需单独下载**（Xcode 不再内置）：`xcodebuild -downloadPlatform iOS`（约 8GB，Apple CDN 国内可达，耗时 30~90 分钟，期间 `simctl list runtimes` 为空）。
- **无 runtime 时 `-destination 'generic/platform=iOS Simulator'` 会报 "iOS is not installed"**——改用 `-target <name> -sdk iphonesimulator` 绕过 destination 解析：

  ```bash
  xcodebuild -project X.xcodeproj -target <target> -sdk iphonesimulator -configuration Debug build
  ```

- 创建/启动/安装：`simctl create "test" <devicetype> <runtime>` → `boot` → `install <app>` → `launch <bundleid>`。
- **权限预授权，避免系统弹窗阻塞自动化**：`xcrun simctl privacy <UDID> grant microphone <bundle>`（camera 同理）。
- **自动化验证不依赖 UI 点击**：`xcrun simctl launch <UDID> <bundle> -autojoin room1` 传参 + App 侧 `ProcessInfo.processInfo.arguments` 解析自动进房；验证状态用 `simctl io <UDID> screenshot` + 读图。
- **模拟器无摄像头**：推流仍会成功（音频来自宿主 Mac 麦克风），本地预览黑屏、远端收到的视频无帧属**预期行为**；判断成功以回调为准（loginRoom errorCode==0、onPublisherStateUpdate publishing、onRoomStreamUpdate add、onPlayerStateUpdate playing）。
- **模拟器与宿主共享网络**：`http://localhost:<port>` 直达宿主服务，可复用 Web 端的 Token 端点；App 的 Info.plist 需加 `NSAppTransportSecurity.NSAllowsLocalNetworking=true` 放行本地 http。
- SwiftUI 集成模式：引擎回调里更新状态统一 `DispatchQueue.main.async`；渲染容器用 `UIViewRepresentable` 的 `makeUIView` 回调注入 manager，容器晚于进房创建时在 attach 里补 `startPreview`/`startPlayingStream`。
- 手写 project.pbxproj 集成 SPM 需要三段：`XCRemoteSwiftPackageReference`（挂 PBXProject.packageReferences）+ `XCSwiftPackageProductDependency`（挂 target.packageProductDependencies）+ 对应 `PBXBuildFile { productRef }`（挂 Frameworks phase）。CI 签名可用 `CODE_SIGNING_ALLOWED=NO`（模拟器运行无需签名）。