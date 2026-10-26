# iOS 15.4 移植说明

把 [khoren93/SwiftHub](https://github.com/khoren93/SwiftHub) 从 iOS 17 基线降到 **iOS 15.4**，并补上 GitHub 趋势榜小组件。产物是未签名 IPA，供 TrollStore 安装。

## 为什么需要移植

上游 master 虽然界面代码看起来"老派"（UIKit + RxSwift），但实际已经用了两处 iOS 16+ 的编译期 API：

| API | 引入版本 | 上游用量 |
| --- | --- | --- |
| `String(localized: .key)` | iOS 16 | 129 处 |
| `UIImage(resource: .name)` | iOS 16 | 108 处 |

这两者都是**编译器展开的语法糖**，不是运行时可选特性，所以只改 deployment target 编不过。加上 SwiftUI 的 `NavigationStack`、`#Preview` 等根本没有出现，整体改造面比预想小。

## 改动清单

### 1. 部署目标

- `SwiftHub.xcodeproj/project.pbxproj` 4 处 `IPHONEOS_DEPLOYMENT_TARGET = 17.0` → `15.4`
- `Podfile` 的 `platform :ios, '17.0'` → `'15.4'`
- `Podfile` 的 `post_install` 原本是**删除** Pods 的部署目标，改成**显式写 15.4**（删掉会留下 `compiled for newer iOS` 链接告警）

### 2. 本地化

新增 `SwiftHub/Configs/LocalizedKeys.swift`：

```swift
struct LocalizedKey: Hashable { let raw: String }

extension LocalizedKey {
    static var repositories: LocalizedKey { LocalizedKey("Repositories") }
    // …共 130 个键，键名来自 Localizable.xcstrings
}

func L(_ key: LocalizedKey) -> String {
    NSLocalizedString(key.raw, tableName: nil, bundle: .main, value: key.raw, comment: "")
}
```

调用点由脚本批量替换：

```diff
- title = String(localized: .repositories)
+ title = L(.repositories)

- String(localized: .repositoryStarsFormat(stars))
+ String(format: L(.repositoryStarsFormat), stars)
```

带参数的调用走 `String(format:)`，格式串本身仍由 `Localizable.xcstrings` 提供。

### 3. 图片

```diff
- UIImage(resource: .iconBack)
+ UIImage(named: "icon_back")!
```

符号名到资源名的映射由脚本从 `Assets.xcassets` 的 `.imageset` 目录反查。`UIImage(named:)` 返回可选值，而 `UIImage(resource:)` 不是，所以在原先直接链式调用的位置补了强制解包（资源都在 bundle 内，缺失即编译期就可发现，运行时不会为 nil）。

### 4. Xcode / Swift 版本

上游 Pods 声明 `SWIFT_VERSION = 6.x`，Xcode 15 不认；Kingfisher 8 还用了 `@retroactive`（Swift 6 编译器属性）。因此 CI 用 **macOS 15 runner + 最新 Xcode**（Xcode 26），并在 workflow 里自动选择最新版本。

### 5. 新增 Widget 扩展

`SwiftHubWidget/`：

| 文件 | 作用 |
| --- | --- |
| `SwiftHubWidget.swift` | `@main` WidgetBundle、`StaticConfiguration`、尺寸分发 |
| `TrendingProvider.swift` | `TimelineProvider`，30 分钟刷新一次 |
| `TrendingService.swift` | 拉 `https://api.gitterapp.com/repositories?since=daily` |
| `TrendingModels.swift` | `TrendingRepo` / `TrendingEntry` |
| `TrendingViews.swift` | small / medium / large 三种布局 |

设计取舍：

- **不读登录态**。Widget 走公开接口即可，避免依赖 App Group / Keychain 共享——那两样在 TrollStore 环境下都不稳定。
- **不使用 iOS 16+ API**。背景用 `if #available(iOSApplicationExtension 17.0, *)` 走 `containerBackground`，低版本回退到 `background`。
- **点击只打开 App 首页**（`swifthub://`），因为上游没有实现 URL 路由分发。

工程侧由 `scripts/add_widget_target.rb`（xcodeproj gem）程序化添加，可重复执行：

- 新建 `com.apple.product-type.app-extension` target，Bundle ID `com.public.SwiftHub.widget`
- 加入 `Embed Foundation Extensions` 拷贝阶段（`dst_subfolder_spec = 13`）
- 建立 app → widget 的 target 依赖，并写进 `SwiftHub.xcscheme`

## 构建

### 方式 A：GitHub Actions（无需 Mac）

推送到 `master` 或在 Actions 页面手动触发 `Build unsigned IPA`，完成后在 Artifacts 下载 `SwiftHub-unsigned-ipa`。

流程：选最新 Xcode → `pod install` → `xcodebuild CODE_SIGNING_ALLOWED=NO` → 校验 widget 已嵌入 → `codesign -f -s -` 签 appex 与主程序 → 打包 IPA → 打印 minos。

### 方式 B：本地 Mac

```bash
pod install --repo-update
open SwiftHub.xcworkspace      # scheme 选 SwiftHub，真机 Run
```

或出未签名包：

```bash
./build-unsigned-ipa.sh        # → build/SwiftHub-unsigned.ipa
```

## 安装（TrollStore）

1. 把 IPA 传到设备（AirDrop / 文件 App / 本地 HTTP 服务均可）
2. TrollStore 里「Install IPA」选中它
3. 桌面添加小组件：长按空白 → 左上「+」→ 搜 SwiftHub → 选尺寸

TrollStore 走 CoreTrust 漏洞，安装的是未签名包：不需要证书、不需要 Apple ID、不会 7 天过期。iOS 14.0–15.4.1 在支持范围内。

## 已知限制

| 限制 | 说明 |
| --- | --- |
| OAuth 凭据 | 仍是上游的演示 key（`Configs.swift` 里的 `appId` / `apiKey`），随时可能失效并共享上游限流。**建议换成自己注册的 OAuth App** |
| 无推送 | APNs 需要真实证书的 `aps-environment`，TrollStore 伪造不了。通知列表（拉 `/notifications`）仍可用 |
| 无 Copilot / Agents | 官方客户端那套走 `api.github.com/cmc_internal`，无公开 API，客户端侧无法复刻 |
| Widget 只读趋势 | 不展示个人数据（Star 数、通知数），原因是 TrollStore 下 App Group 不可靠 |
| Widget 刷新 | 系统控制，最快约 15 分钟一次；代码里请求 30 分钟 |

## 排错

| 现象 | 原因 / 处理 |
| --- | --- |
| 登录后重启掉登录 | entitlements 缺 `keychain-access-groups`，`SecItemAdd` 返回 -34018。检查打包时是否带上 `ent.plist` |
| 小组件显示「无法加载」 | 检查 `PlugIns/SwiftHubWidget.appex` 是否在包内、是否已签名 |
| 启动即崩 | 不要给 entitlements 加 `get-task-allow` / `dynamic-signing`，iOS 15 的 A12+ 机型封了这几个权限 |
| `pod install` 报某 Pod 要求 16.0+ | 把 Firebase 系列从 `~> 12.0` 降到 `~> 11.0` 后 `pod update` |

## 许可证

上游为 MIT，本分支同样遵循。原版权声明见 `LICENSE`。
