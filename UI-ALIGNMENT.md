# 界面参考：GitHub iOS 1.282.0

这份文档记录"把 SwiftHub 的界面往官方客户端靠"的具体依据、改了哪些、以及没做什么。

## 一、参考对象与提取方式

参考包：`GitHub-1.282.0.ipa`（`com.github.stormbreaker.prod`，1.282.0 / 208302809，`MinimumOSVersion = 17.0`）。

官方客户端是 **SwiftUI 全代码构建**，这点直接影响能提取到什么：

| 想提取的 | 可行性 | 原因 |
| --- | --- | --- |
| 界面布局 XML | ✗ | `Base.lproj` 里只有 `LaunchScreen.storyboardc`，没有任何页面 storyboard 或 xib |
| Tab 标题文案 | ✗ | SwiftUI 的 `Text` 走 String Catalog，编译进 `Assets.car` 的字符串表，未能在二进制里定位到 `Home` / `Explore` 这类短串 |
| 界面资源图 | △ | `Assets.car` 6.6 MB，是 BOMStore 容器，名称表为 UTF-8 混在哈希键里，未做完整解析 |
| **模块结构** | ✓ | Swift 符号表里有完整的 `*ViewControllerClient` / `*Delegate` 协议名 |
| **图标体系** | ✓ | 二进制里能读到 SF Symbols 名 |

所以下面的结论全部来自**类名 + 符号名**这两类硬证据，不靠截图臆测。

## 二、从符号表读出的信息架构

主入口（一级页面）：

```
HomeViewControllerClient
InboxFilterViewControllerFactoryType        // 收件箱 = 通知
ExploreTrendingViewControllerClientType     // 探索：趋势
ExploreFilterViewControllerFactoryType      // 探索：筛选
GlobalSearchViewControllerClient            // 全站搜索
SettingsViewControllerClient                // 设置（承载"我的"）
TabNavRootViewControllerType                // Tab 导航根
```

二级模块（说明详情页覆盖范围）：

```
RepositoryDirectoryViewControllerType / RepositoryCodeBlobViewControllerClientType
IssueViewModelControllerClientType / NewIssueViewControllerClient
PullRequestFilesOverviewViewControllerClientType / MergeQueueViewControllerClient
DiscussionsViewControllerClient / NewDiscussionViewControllerClient
CommitViewControllerClient / CommitDetailsViewControllerClient
DeploymentReviewViewControllerClient / DeploymentApprovalViewControllerClient
RecentSearchesViewControllerDelegate / SearchQualifiersAccessoryViewControllerDelegate
```

由此可以确定一级结构是 **Home / Notifications(Inbox) / Explore（趋势+搜索+筛选）/ Profile(Settings)**，趋势和搜索被合并进 Explore，设置不占独立 Tab 而是承载"我的"。这正是 SwiftHub 原来的 4 个 Tab（Events / Search / Notifications / Settings）需要调整顺序与命名的原因。

图标方面，官方用系统符号而非自绘图：

```
chevron.up.chevron.down   // 筛选/切换
checkmark.circle.fill     // 选中态
person.crop.circle        // 头像/我的
copilot.visibility        // Copilot 入口
```

## 三、改了什么

### 1. Tab 结构

| | 改前 | 改后 |
| --- | --- | --- |
| 顺序 | Events · Search · Notifications · Settings | **Home · Notifications · Explore · Profile** |
| 文案 | Events / Search / Activities / Settings | Home / Notifications / Explore / Profile |
| 图标 | 自绘 PNG（`icon_tabbar_*`） | SF Symbols：`house` / `bell` / `magnifyingglass` / `person.crop.circle`，选中态用 `.fill` |
| 未登录 | Search · Login · Settings | Explore · Sign in · Profile |

新增 4 个本地化键（`Home.TabBar.Home/Explore/Profile/SignIn.Title`），中英文都补齐；原来叫 `Activities` 的键统一改成 `Notifications`。

### 2. 色板

新增 `SwiftHub/Extensions/UIColor/UIColor+GitHub.swift`，按 Primer 语义命名（canvas / fg / border / accent）：

| 用途 | 浅色 | 深色 |
| --- | --- | --- |
| 页面底色 `primary` / `background` | `#FFFFFF` | `#0D1117` |
| 次级底色（TabBar、分组） `primaryDark` | `#F6F8FA` | `#0D1117` |
| 卡片/导航 `primary`（深色） | — | `#161B22` |
| 描边 `separator` | `#D0D7DE` | `#30363D` |
| 正文 `text` | `#1F2328` | `#E6EDF3` |
| 次要 `textGray` | `#656D76` | `#8B949E` |
| 链接/强调 `secondary` | `#0969DA` | `#2F81F7` |
| 成功 | `#1F883D` | `#3FB950` |

`LightTheme` / `DarkTheme` 全部换成这套值，原来用的是 Material 色（浅色灰 `grey200` 当导航底、红色 `red` 当强调色）。`ColorTheme` 增加 `github` 选项并置为默认。

> 注意：`github` 加在枚举**末尾**，不是开头。放到开头会让已有 case 的 `rawValue` 整体后移，老用户存的配色会错位。

### 3. 导航栏与 TabBar

- 导航栏：主题底色 + `shadowColor` 细线 + 标题用正文色，替代系统默认的半透明模糊
- TabBar：底色由 `#F6F8FA` 改为白（深色 `#161B22`），选中蓝、未选中 `#656D76`
- 右侧箭头：自绘 `icon_cell_disclosure` → `chevron.right`（13pt semibold）
- 列表标题色：正文黑 → 链接蓝（官方的仓库名/用户名都是链接色）

## 四、没做的（以及为什么）

| 项 | 状态 | 原因 |
| --- | --- | --- |
| 列表卡片化 | 未做 | 官方是分组卡片（圆角 6pt、组内分隔线内缩、组间留白），SwiftHub 的 cell 布局写在 xib 里，要改约束得逐个子类适配，且我这边没有 Xcode 预览环境，盲改风险高 |
| 大标题导航 | 未做 | `prefersLargeTitles` 会影响所有页面，SwiftHub 多数详情页自带 header，开大标题容易叠字 |
| Home feed 卡片 | 未做 | 官方 feed 是「头像 + 事件描述 + 仓库卡 + 代码块」的复合卡片，需要新的 cell 类型与 GraphQL 字段，工作量超过界面配色范畴 |
| Copilot 入口 | 不可做 | 服务端走 `cmc_internal` 内部接口，无公开 API |

## 五、验证

CI 构建通过后解包核对：

| 项 | 结果 |
| --- | --- |
| 主程序 minos / sdk | 15.4.0 / 26.2.0 |
| Widget | 存在，minos 15.4.0 |
| 本地化条数 | 127（中英各 127） |
| `Home.TabBar.Home.Title` | en=`Home`，zh-Hans=`首页` |
| `Home.TabBar.Explore.Title` | en=`Explore`，zh-Hans=`浏览` |
| `Home.TabBar.Profile.Title` | en=`Profile`，zh-Hans=`我的` |
| `person.crop.circle`（SF Symbol 字面量） | 在 `__cstring` 中命中 |

短符号名（`house`、`bell`）在二进制里搜不到是正常的：Swift 对 ≤15 字节的字符串做小字符串优化，直接编码进指令立即数，不落到字符串表。`person.crop.circle`（18 字节）和 `Home.TabBar.*`（23 字节）能被搜到，说明符号调用确实编进去了。
