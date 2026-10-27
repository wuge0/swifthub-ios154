# 功能对照：官方 GitHub iOS 1.282.0

以官方客户端为基准，逐项对照当前移植版的能力。结论分三档：**已有**、**近似**、**没有**。

## 一、主结构

| 官方 | 本期实现 | 状态 |
| --- | --- | --- |
| Home（关注动态流） | 关注对象的公开事件聚合，按时间倒序 | 近似 |
| Notifications（收件箱） | 原 Notifications 模块，全部/参与/仓库筛选 | 已有 |
| Explore（趋势 + 搜索 + 筛选） | 原 Search 模块：日/周/月趋势 + 仓库/用户搜索 | 已有 |
| Profile（我的） | 原 Settings 模块承载 | 近似 |

## 二、已有能力

| 模块 | 说明 |
| --- | --- |
| 仓库详情 | 描述、语言、大小、时间、主页、Issue/PR/Commit/Branch/Release/Contributor 入口、Star/Watch/Fork |
| 代码浏览 | 目录列表、文件内容、README 渲染、语法高亮 |
| Issue | 列表（open/closed/all）、详情、评论、标签、指派人、里程碑 |
| Pull Request | 列表、详情、评论、变更统计 |
| Commit | 列表、详情、文件变更 |
| Branch / Release | 列表与详情 |
| 搜索 | 仓库、用户、趋势榜（日/周/月） |
| 通知 | 列表、按仓库筛选、已读标记 |
| 用户 | 详情、仓库、Star、关注、粉丝、事件 |
| 其它 | 主题（浅色/深色 + 20 种强调色）、多语言、语言筛选、Star 历史（WebView） |

## 三、本期新增

### 1. Home 关注流（`EventsMode.following`）

官方 Home 是私有时间线，公开 API 没有对应端点。实现方式：

```
GET /users/{me}/following?per_page=30      → 取关注列表
  ↓ 前 12 人
GET /users/{login}/received_events/public  → 每人取最近事件（失败的人跳过）
  ↓
按 createdAt 倒序合并，取首屏
```

取舍：

- **12 人是上限**。再多首屏会明显变慢，也会吃掉限流额度（认证用户 5000 次/小时，一次刷新约 13 次请求）
- **不做分页**。聚合结果没有稳定游标，`isFooterRefreshEnabled = false`
- **只用公开事件**。私有仓库的动态不会出现，和官方"能看到私有动态"有差距
- 关注列表为空时返回空数组，页面显示占位图

代码位置：`SwiftHub/Modules/Events/EventsViewModel.swift` 的 `followingFeed()`。

### 2. 界面细节

| 项 | 实现 |
| --- | --- |
| 大标题 | 仅 4 个 Tab 根页面（`usesLargeTitle`），二级页面紧凑 |
| Issue 行 | 状态图标替代头像：open 绿点、closed 紫色对勾 |
| PR 行 | merged 紫色合并箭头、closed 红叉、open 绿色 PR 箭头 |
| 仓库头部 | 独立卡片（底色 + 圆角 + 描边），不再是整片灰底 |
| 列表标题 | 链接蓝，次要信息弱化灰 |

## 四、没有的能力

| 官方功能 | 为什么没有 | 工作量估计 |
| --- | --- | --- |
| Copilot / Agents | 走 `api.github.com/cmc_internal`，无公开 API | 不可做 |
| Discussion | 需新增 GraphQL 查询 + 列表/详情/回复三个页面 | 中（3 个页面） |
| 创建 Issue / 发表评论 | 需写操作与富文本编辑器 | 中 |
| PR Files changed | 需要 diff 渲染（行级高亮、折叠） | 大 |
| 代码在线编辑 + 提交 | 需要 CodeMirror 级编辑器与提交流程 | 大 |
| 搜索限定符 / 最近搜索 | 交互组件，实现不难但需要设计 | 小 |
| 推送通知 | TrollStore 无法伪造 `aps-environment` | 不可做 |
| 私有仓库动态 | 需要 GraphQL `viewer` 时间线，公开 API 无 | 不可做 |

## 五、与官方体验的已知差距

1. **首屏加载慢**：关注流是 13 个串行/并发请求，冷启动约 3–6 秒，官方是一次 GraphQL。
2. **列表不是分组卡片**：官方是 inset grouped（组内分隔线内缩、组间留白），当前是平铺 + 自绘卡片，视觉接近但不等同。
3. **没有下拉刷新的品牌动画**，仍是系统 UIRefreshControl。
4. **图标非官方素材**：用的是 SF Symbols 近似，官方有自绘的 issue/PR 图标。
