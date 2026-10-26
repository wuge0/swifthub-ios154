# SwiftHub 降到 iOS 15.4 适配清单

目标：把 `khoren93/SwiftHub`（MIT，3.1k★，UIKit + RxSwift，21 个功能模块）跑在 iOS 15.4.1 真机上。

**为什么可行**：全部 179 个 Swift 文件里，`NavigationStack`、`SwiftData`、`@Observable`、`TipKit`、`presentationDetents`、`Chart`、`Grid`、`#available(iOS 16/17)` 的出现次数**都是 0**。它的 `17.0` 只写在工程配置里，不影响代码本身。

---

## 一、已经改好的三处

| 文件 | 改动 |
| --- | --- |
| `SwiftHub.xcodeproj/project.pbxproj` | 4 处 `IPHONEOS_DEPLOYMENT_TARGET = 17.0` → `15.4`（Project 的 Debug/Release + Target 的 Debug/Release） |
| `Podfile` 第 2 行 | `platform :ios, '17.0'` → `'15.4'` |
| `Podfile` 的 `post_install` | 原来是把 Pods 的部署目标**删掉**（靠继承），改成**显式写 15.4**，避免 `compiled for newer iOS` 链接告警 |

配套文件：

- `swifthub-ios15.4/` —— 改好的完整工程，Xcode 直接打开
- `swifthub-ios15.4.patch` —— 纯补丁，可 `git apply` 到你自己 fork 的上游

---

## 二、编译步骤（需要 macOS）

```bash
cd swifthub-ios15.4
pod install --repo-update          # CocoaPods ≥ 1.16（Podfile.lock 记录的版本）
open SwiftHub.xcworkspace          # 注意是 xcworkspace，不是 xcodeproj
```

然后在 Xcode 里：

1. **Signing**：如果设备在 TrollStore 支持范围内（iOS 15.4.1 正好在列），**这一步可以完全跳过**，走第七节的免签路线；否则把 `DEVELOPMENT_TEAM`（现在是作者团队 `7EVAXJV277`）改成你自己的 Team。
2. **Bundle ID**：`com.public.SwiftHub` 大概率冲突，改成 `com.你的名字.SwiftHub`。
3. Scheme 选 `SwiftHub`，目标选你的 15.4.1 真机，Run。

### 必须先换掉的 OAuth 凭据

`SwiftHub/Configs/Configs.swift` 里是**作者的演示凭据**，直接跑会受限甚至失效：

```swift
enum Keys {
    case github
    var apiKey: String { ... "5a39979251c0452a9476bd45c82a14d8e98c3fb3" }  // ← 换成你的
    var appId:  String { ... "00cbdbffb01ec72e280a" }                     // ← 换成你的
}
```

到 GitHub → Settings → Developer settings → OAuth Apps 新建一个，回调地址随便填（App 用 device/web 流程取 token），拿到 Client ID / Secret 填进去。`githubScope` 默认是 `user+repo+notifications+read:org`，按需调整。

---

## 三、可能卡住的点

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| `pod install` 报 `Unable to find a specification` | 本地 spec 仓库过期 / 网络 | `pod install --repo-update`；国内可换镜像源，或 `pod repo update` |
| 某个 Pod 报「requires iOS 16.0+」 | `Podfile.lock` 锁的是 Firebase 12.19、Kingfisher 8.14 这类新版本 | 把该 Pod 的上限调低（如 `pod 'FirebaseAnalytics', '~> 11.0'`、`pod 'FirebaseCrashlytics', '~> 11.0'`），再 `pod update` |
| Xcode 提示「deployment target 15.4 not supported」 | 新版 Xcode 抬高了最低支持目标 | 改用 Xcode 15.x / 16.x 编译，工程本身不用改 |
| 运行即崩，日志有 `dyld: Symbol not found` | 某个 Pod 的二进制 minos 高于 15.4 | 用下面第四节的 `vtool` 全量扫一遍，把超标的 Pod 降版 |
| 登录后空白 / 401 | OAuth App 没配对，或 scope 不够 | 核对 `Configs.swift` 的 appId/apiKey/scope |
| 「Trending」页面报错 | `api.gitterapp.com` 是第三方服务，可能已停 | 该功能非核心，可删掉对应模块或换数据源 |

---

## 四、静态验收（不用真机也能查）

```bash
# 1) 主程序最低版本
vtool -show-build SwiftHub.app/SwiftHub | grep -E "minos|sdk"

# 2) 全量扫：列出所有 minos 高于 15.4 的 Mach-O（Pods 里的 framework 也会被扫到）
find SwiftHub.app -type f -perm -111 | while read f; do
  v=$(vtool -show-build "$f" 2>/dev/null | awk '/minos/{print $2; exit}')
  [ -n "$v" ] && [ "$(printf '%s\n15.4\n' "$v" | sort -V | head -1)" != "15.4" ] && echo "$v  $f"
done

# 3) 强链接的系统库清单，逐个确认 15.4 上存在
otool -L SwiftHub.app/SwiftHub | sort
```

第 2 步输出为空，才说明包里没有任何组件要求高于 15.4。

---

## 五、拿到手就没有的功能

| 能力 | 说明 |
| --- | --- |
| Copilot 聊天 / 代码评审 | 官方走 `api.github.com/cmc_internal/api/agents` 内部端点，无公开 API，复刻不了 |
| Agents / AHP 会话 | 同上，服务端能力不在客户端 |
| 桌面小组件 | SwiftHub 没有；WidgetKit（iOS 14+）可以自己加 |
| 实时活动 | 需要 ActivityKit（16.1+），15.4 无法实现，只能用本地通知替代 |
| 新版官方 UI | 官方用自研 Primer 设计系统，视觉差异明显 |

---

## 六、合规

- **MIT**：保留 `LICENSE` 和版权声明，改动处注明来源即可，可商用。
- **商标**：别用 GitHub 的名字、Logo、官方截图做图标和商店素材；应用名换成你自己的。
- **OAuth**：必须用自己注册的 App，否则随时被作者吊销，且所有用户共享他的 rate limit。

---

---

## 七、免签路线（TrollStore，推荐）

TrollStore 走 CoreTrust 漏洞，安装的是**未签名** IPA：不需要证书、不需要 Apple ID、不会 7 天过期。iOS 14.0–15.4.1 都在支持范围，15.4.1 正好命中。

### 方式 A：本地 Mac（最快）

工程里已附 `build-unsigned-ipa.sh`：

```bash
cd swifthub-ios15.4
./build-unsigned-ipa.sh          # 产出 build/SwiftHub-unsigned.ipa
```

它做四件事：`pod install` → `xcodebuild CODE_SIGNING_ALLOWED=NO` → `ldid -S` 打 entitlements → 打包 `Payload/` 成 ipa。

### 方式 B：GitHub Actions（没有 Mac 也能出包）

工程里已附 `.github/workflows/build-ipa.yml`。把仓库推到 GitHub，然后在 Actions 页面手动触发（或 push 自动跑），跑完在 Artifacts 里下载 `SwiftHub-unsigned-ipa`。

- runner 用 `macos-14`（Xcode 15.x，支持 15.4 部署目标）
- 流程同样是：`pod install` → 免签 `xcodebuild` → `ldid` 打 entitlements → 打包 → `vtool` 打印 minos
- 私有仓库的 artifact 需要登录 GitHub 才能下载；公开仓库无所谓
- 首次跑之前把 `env.BUNDLE_ID` 改成你自己的

### 方式 C：直接改配置后自己签

如果设备不在 TrollStore 支持范围内，就得回到 Xcode 正常签名：改 `DEVELOPMENT_TEAM` + bundle id，选真机 Run（免费 Apple ID 也行，但 7 天要重签）。

### 必须打的 entitlements

未签名二进制默认没有任何权限，SwiftHub 用 KeychainAccess 存 token，缺权限会直接失败（`SecItemAdd` 返回 **-34018**）。所以至少要：

```xml
<key>application-identifier</key>
<string>com.yourname.swifthub</string>
<key>keychain-access-groups</key>
<array><string>com.yourname.swifthub</string></array>
```

脚本已按变量自动生成，改 `BUNDLE_ID` 即可。

### 两个坑

| 坑 | 说明 |
| --- | --- |
| 不要加 `get-task-allow` / `dynamic-codesigning` | iOS 15 的 A12+ 机型封了这几个权限，带上会**启动即崩** |
| 推送用不了 | APNs 需要真实证书的 `aps-environment`，TrollStore 伪造不了（SwiftHub 本身也没推送服务） |

### 装上仍然跑不起来的那类情况

TrollStore 只解决“装”，不解决“系统里没有这个框架”。像官方 GitHub 1.282.0 这种强链接 `ActivityKit` / `TipKit` / `libswift_StringProcessing` 的包，TrollStore 能装进去，但启动时 dyld 找不到符号，照样崩在 `main` 之前。所以：**TrollStore 不是降级工具，它只是免签安装器。**

---

## 八、工作量参考

| 阶段 | 预计 |
| --- | --- |
| 改配置 + `pod install` + 首次跑通 | 半天 |
| 修 Pod 版本冲突 / 符号缺失 | 1–3 天（取决于 Pod 版本要求） |
| 换 OAuth、改 bundle id、去品牌化 | 半天 |
| 补小组件、调 UI | 按需，1–2 周 |

对比从零写一个等价客户端（2–4 人月），这个底座能省掉绝大部分 UI 和数据层工作。

---

## 九、附加功能：Trending 小组件（本次补齐）

工程内新增 `SwiftHubWidget` 扩展，桌面直接看 GitHub 每日趋势榜。

| 项 | 值 |
| --- | --- |
| Bundle ID | `com.public.SwiftHub.widget` |
| 部署目标 | 15.4（`minos=15.4.0`，与主 App 一致） |
| 尺寸 | small / medium / large（small 展示 1 个，medium 3 个，large 8 个） |
| 数据源 | `https://api.gitterapp.com/repositories?since=daily`（公开接口，不需要登录） |
| 刷新 | 请求 30 分钟一次，实际由系统调度 |
| 点击 | 打开 SwiftHub（`swifthub://`） |

设计上有意**不读登录态**：App Group / Keychain 共享在 TrollStore 环境下不稳定，趋势榜走公开接口即可，反而更可靠。

工程接入由 `scripts/add_widget_target.rb` 完成（xcodeproj gem，可重复执行）：创建 app-extension target、加入 `Embed Foundation Extensions`（`dst_subfolder_spec=13`）、建立 target 依赖并写进 scheme。

### 一个必须记住的坑

加完扩展后 Xcode 报：

```
error: Cycle inside SwiftHub; building could produce unreliable results.
→ copy SwiftHubWidget.appex → script phase "Crashlytics" → process Info.plist → copy SwiftHubWidget.appex
```

原因是 Crashlytics 的 Run Script 排在 `Embed Extensions` 之前，而它又依赖 Info.plist 处理（Xcode 会从嵌入的 appex 提取 App Shortcuts 元数据）。解法是把 **Embed Foundation Extensions 挪到 Crashlytics 之前**，让脚本阶段保持在最后。

### 签名

CI 里先签 appex、再签主程序：

```bash
codesign -f -s - --entitlements ent-widget.plist "$APP/PlugIns/SwiftHubWidget.appex"
codesign -f -s - --entitlements ent.plist "$APP/SwiftHub"
```

实测产物：appex 308 KB，签名块 21,008 字节，`_CodeSignature` 完整，entitlements 含 `application-identifier=com.public.SwiftHub.widget`。
