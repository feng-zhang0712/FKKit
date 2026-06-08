# FKListKit — 设计需求文档

FKKit **Diffable 列表基础设施**的实现指导文档：Section/Item 模型、Table/Collection 视图控制器、预设 Cell、滑动操作，以及与 **FKRefresh**、**FKEmptyState**、**FKSkeleton** 的集成。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) §1.2  
**English version:** [FKListKit_DESIGN.md](FKListKit_DESIGN.md)

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 架构总览](#4-架构总览)
- [5. 模块边界](#5-模块边界)
- [6. 核心数据模型](#6-核心数据模型)
- [7. 列表呈现状态机](#7-列表呈现状态机)
- [8. FKDiffableTableViewController — 职责](#8-fkdiffabletableviewcontroller--职责)
- [9. FKDiffableTableViewController — 数据与快照 API](#9-fkdiffabletableviewcontroller--数据与快照-api)
- [10. FKDiffableTableViewController — 刷新与分页](#10-fkdiffabletableviewcontroller--刷新与分页)
- [11. FKDiffableTableViewController — 空态、错误与骨架屏](#11-fkdiffabletableviewcontroller--空态错误与骨架屏)
- [12. FKDiffableTableViewController — 选择与交互](#12-fkdiffabletableviewcontroller--选择与交互)
- [13. FKDiffableTableViewController — Section 头尾](#13-fkdiffabletableviewcontroller--section-头尾)
- [14. FKDiffableTableViewController — 滑动操作](#14-fkdiffabletableviewcontroller--滑动操作)
- [15. FKDiffableCollectionViewController](#15-fkdiffablecollectionviewcontroller)
- [16. FKListCell 预设](#16-fklistcell-预设)
- [17. 自定义 Cell 与 Pluggable](#17-自定义-cell-与-pluggable)
- [18. 配置模型](#18-配置模型)
- [19. Delegate 与生命周期钩子](#19-delegate-与生命周期钩子)
- [20. 搜索驱动列表](#20-搜索驱动列表)
- [21. 预取与性能](#21-预取与性能)
- [22. 无障碍](#22-无障碍)
- [23. SwiftUI 桥接（第二阶段）](#23-swiftui-桥接第二阶段)
- [24. 建议源码目录结构](#24-建议源码目录结构)
- [25. FKKitExamples 场景](#25-fkkitexamples-场景)
- [27. 待决问题](#27-待决问题)
- [28. 修订历史](#28-修订历史)

---

## 1. 概述

FKKit 已提供 **Cell 注册协议**（`FKListTableCellConfigurable`、`FKListCollectionCellConfigurable`）以及成熟的 **Refresh / EmptyState / Skeleton** 模块，但缺少将它们与 `UITableViewDiffableDataSource` / `UICollectionViewDiffableDataSource` **串联**的列表 ViewController 基础设施。

团队在每个项目中重复实现：

- 下拉刷新 + 无限滚动 + 页码重置
- 首次骨架屏 → 首帧快照 → 内容
- 空态/错误叠加与重试
- 设置页风格行（标题、副标题、开关、箭头）
- 风格统一的左/右滑操作

**FKListKit**（`FKUIKit/Components/List/`）交付：

| 交付物 | 职责 |
|--------|------|
| **`FKListSection` / `FKListItem`** | Hashable Diffable 模型 |
| **`FKDiffableTableViewController`** | Table 基类 VC + Diffable DS + 刷新/分页/空态/骨架 |
| **`FKDiffableCollectionViewController`** | Collection 基类 + Compositional 预设 |
| **`FKListCell` 预设** | 标准行样式 |
| **`FKListSwipeActionConfiguration`** | 滑动操作封装（Table） |

FKListKit **不是**完整 App 框架 — 而是**薄层、有主张的基类**，组合现有 FKKit 模块。

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **消除列表 VC 样板代码** — 覆盖最常见信息流与设置页模式。
2. **一等公民集成** `FKRefresh`、`FKRefreshPagination`、`FKEmptyState`、`FKSkeleton`、`FKDivider`。
3. **协议友好** — 尊重 Pluggable Cell 契约；预设仅为快捷方式。
4. **分页语义正确** — 刷新重置页码；加载更多递增；无更多数据时禁用 Footer。
5. **异步加载安全** — Token/取消感知；禁止过期快照写入。
6. **FKKit 一致性** — `@MainActor`、`Sendable` Item、分层配置、英文文档、Examples 全覆盖。

### 2.2 非目标

| 排除项 | 原因 |
|--------|------|
| 完整 MVVM / 响应式绑定框架 | 宿主自行负责网络与映射 |
| 内置网络或 JSON 解析 | 宿主层使用 `FKNetwork` |
| 拖拽排序 UI（v1） | 视需求延后 |
| 传统 `UITableViewDataSource` 路径 | v1 仅 Diffable |
| 复杂树形 Diff | v1 仅扁平 Section + Item |
| 复杂表单校验 | 自定义 Cell 内用 `FKTextField` |
| 替代 `FKPagingController` | 正交；列表在子 VC 内 |
| macOS / tvOS | 仅 iOS 15+ UIKit |

### 2.3 成功标准

- [ ] Table 基类 VC 实现 §8–14；Collection VC §15 完成。
- [ ] 示例信息流：下拉刷新、加载更多、空态、错误重试、首次骨架 — **无需手写 DS**。
- [ ] 集成流中刷新重置 `FKRefreshPagination`，加载更多成功后 `advance()`。
- [ ] 遵循 `FKListTableCellConfigurable` 的自定义 Cell 无需 fork 基类。
- [ ] VoiceOver：Section 头与滑动操作可读。
- [ ] 组件 README + 根 README + CHANGELOG。

---

## 3. 背景与问题陈述

### 3.1 现有 FKKit 能力

| 模块 | 位置 | 现状 |
|------|------|------|
| Cell 协议 | `Pluggable/UIKit/FKCellReusable.swift` | 注册/出队 + `configure(with:)` |
| Table/CV 扩展 | `Extension/UIKit/UITableView.swift` | 仅 `fk_reloadDataWithoutAnimation()` |
| Refresh | `FKRefresh` | 头/脚控件、async 回调、Footer 分页态 |
| 分页模型 | `FKRefreshPagination` | `page`、`resetForNewRequest()`、`advance()` |
| 空态 | `FKEmptyState` | `UIScrollView` / `UIView` 叠加 |
| 骨架屏 | `FKSkeleton` | 叠加层、Table/Collection 可见 Cell 辅助 |
| 分隔线 | `FKDivider` | 行分隔 |

**缺失：** 拥有 Diffable 生命周期并协调上述模块的 ViewController。

### 3.2 痛点矩阵

| 痛点 | 影响 |
|------|------|
| 每个 feed VC 重复接 Refresh + 分页 | 维护成本高 |
| 空态与 contentInset 冲突 | UX Bug |
| 首载后 Skeleton 未隐藏 | 视觉故障 |
| 刷新未重置页码 | 重复第 1 页数据 |
| 设置行样式不统一 | 设计漂移 |
| 滑动操作各自实现 | 不符合 HIG |

---

## 4. 架构总览

```text
┌──────────────────────────────────────────────────────────────────┐
│ 宿主特性模块（API、映射、业务规则）                                │
│   实现 FKListDataProviding 或调用 apply(snapshot:)               │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│ FKDiffableTableViewController（@MainActor）                      │
│  ┌─────────────┐  ┌──────────────────┐  ┌─────────────────────┐ │
│  │ 呈现状态机  │  │ Diffable DS      │  │ FKListLoadCoordinator│ │
│  │             │  │ 快照 apply       │  │ 刷新/分页            │ │
│  └─────────────┘  └──────────────────┘  └─────────────────────┘ │
│         │                  │                      │              │
│         ▼                  ▼                      ▼              │
│   FKEmptyState      UITableView            FKRefreshControl      │
│   FKSkeleton        + 预设/自定义 Cell     + FKRefreshPagination │
└──────────────────────────────────────────────────────────────────┘
```

**典型信息流控制流：**

1. VC 出现 → `initialLoading` → Table 骨架屏。
2. 宿主拉取第 1 页 → 构建 `FKListSnapshot` → `applySnapshot`。
3. 协调器 → `content`；隐藏 Skeleton；显示行。
4. 下拉刷新 → 重置分页 → 拉第 1 页 → **替换** Item（非 append）。
5. 滚到底 → 加载更多 → 拉第 N 页 → **append**；`pagination.advance()`。
6. 无更多数据 → Footer `noMoreData`；触发 `didReachEnd`。

---

## 5. 模块边界

| 关注点 | FKUIKit `List/` | FKCoreKit |
|--------|-----------------|-----------|
| UIViewController 子类 | 是 | 否 |
| Diffable DataSource | 是 | 否 |
| `FKListItem` Hashable 模型 | 是 | 仅当无 UIKit 依赖时可放纯 Swift 辅助 |
| 预设 Cell | 是 | 否 |
| Refresh/Empty/Skeleton 接线 | 是（集成） | 否 |

**依赖：** `FKListKit` import `FKCoreKit`（Pluggable、Async）及 FKUIKit 邻域组件；无第三方依赖。

---

## 6. 核心数据模型

### 6.1 身份类型

```swift
public struct FKListItemID: Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
}

public struct FKListSectionID: Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
}
```

- Diffable 身份跨更新必须稳定。
- 支持字符串字面量（`"main"`、`"settings"`）。

### 6.2 Item 信封

```swift
public struct FKListItem: Hashable, Sendable {
  public var id: FKListItemID
  public var kind: FKListItemKind
  public var metadata: FKListItemMetadata?
}

public enum FKListItemKind: Hashable, Sendable {
  case preset(FKListPresetItem)
  case custom(FKListCustomItem)
}

public struct FKListCustomItem: Hashable, Sendable {
  public var cellTypeIdentifier: String
  public var payload: FKListItemPayload
}
```

- **`preset`** — FKListKit 内置 Cell 渲染（§16）。
- **`custom`** — 宿主注册 Cell + Payload；基类经注册表 dispatch `configure(with:)`。

`FKListItemPayload` — 类型擦除的 `Sendable` 容器，README 文档化 typed 访问辅助。

### 6.3 Section 模型

```swift
public struct FKListSection: Hashable, Sendable {
  public var id: FKListSectionID
  public var items: [FKListItem]
  public var header: FKListSectionHeaderFooter?
  public var footer: FKListSectionHeaderFooter?
  public var layoutHints: FKListSectionLayoutHints?
}

public enum FKListSectionHeaderFooter: Hashable, Sendable {
  case title(String)
  case subtitle(title: String, subtitle: String?)
  case custom(viewProviderID: String)
}
```

### 6.4 快照与变更

```swift
public struct FKListSnapshot: Hashable, Sendable {
  public var sections: [FKListSection]
}

public enum FKListSnapshotMutation {
  case replace(FKListSnapshot)
  case appendItems([FKListItem], toSection: FKListSectionID)
  case insertItems([(FKListItem, after: FKListItemID?)], inSection: FKListSectionID)
  case deleteItems([FKListItemID])
  case reloadItems([FKListItemID])
  case reloadSections([FKListSectionID])
}
```

公开 API：

```swift
func applySnapshot(_ snapshot: FKListSnapshot, animatingDifferences: Bool, completion: (() -> Void)?)
func applyMutation(_ mutation: FKListSnapshotMutation, animatingDifferences: Bool, completion: (() -> Void)?)
```

---

## 7. 列表呈现状态机

### 7.1 状态

```swift
public enum FKListPresentationState: Equatable, Sendable {
  case initialLoading
  case content
  case empty(FKEmptyStateConfiguration?)
  case error(FKListErrorPresentation)
  case refreshing
  case loadingNextPage
}
```

### 7.2 状态转移（规范）

| 自 | 事件 | 至 |
|----|------|-----|
| initialLoading | 首次快照有数据 | content |
| initialLoading | 首次快照为空 | empty |
| initialLoading | 拉取失败 | error |
| content | 开始下拉刷新 | refreshing |
| refreshing | 成功有数据 | content |
| refreshing | 成功为空 | empty |
| refreshing | 失败 | error（或保留 content + Toast — 可配置） |
| content | 开始加载更多 | loadingNextPage |
| loadingNextPage | 成功 append | content |
| loadingNextPage | 失败 | content（Footer 错误态） |
| empty | 重试成功 | content / empty |
| error | 重试成功 | content / empty |

### 7.3 UI 映射

| 状态 | Table 可见性 | Skeleton | 空态叠加 | 刷新头 |
|------|--------------|----------|----------|--------|
| initialLoading | 隐藏或零行 | **开** | 隐藏 | idle |
| content | 可见 | 关 | 隐藏 | idle |
| empty | 视策略 | 关 | **开** | idle |
| error | 隐藏或 dim | 关 | **开**（error） | idle |
| refreshing | 可见 | 关 | 隐藏 | loading |
| loadingNextPage | 可见 | 关 | 隐藏 | footer loading |

**空态策略**（`FKListEmptyPresentationPolicy`）：

| 策略 | 行为 |
|------|------|
| `.overlayScrollView` | `tableView.fk_applyEmptyState` — **默认推荐** |
| `.replaceContent` | 隐藏 Table，空态在 VC.view |
| `.inlineZeroRows` | 保留 Table，零 Section，背景居中空态 |

---

## 8. FKDiffableTableViewController — 职责

### 8.1 基类契约

```swift
@MainActor
open class FKDiffableTableViewController: UIViewController {
  public let tableView: UITableView
  public var configuration: FKListConfiguration
  public var pagination: FKRefreshPagination
  public private(set) var presentationState: FKListPresentationState
  public private(set) var currentSnapshot: FKListSnapshot
}
```

**必须持有：**

- `UITableView`（默认 plain；grouped 可配置）。
- `UITableViewDiffableDataSource<FKListSectionID, FKListItemID>`。
- Cell 注册表（预设 + 宿主）。
- `FKListLoadCoordinator`（刷新/分页 Token）。
- 可选 `FKRefreshControl` 头/脚引用。

**不得：**

- 内部发起 URLSession（由宿主闭包/Provider 提供）。
- 强制 MVVM/MVC 等架构 — 仅回调。

### 8.2 初始化

```swift
public init(
  configuration: FKListConfiguration = .init(),
  style: UITableView.Style = .plain
)
```

Table 贴满 VC.view（Safe Area）；尊重 `configuration.layout.contentInsets`。

### 8.3 可重写钩子

- `tableView(_:configurePresetCell:at:with:)` — 预设 Cell 绑定扩展
- `registerAdditionalCells(in:)` — 宿主额外注册
- `makeEmptyStateConfiguration(for:)` — 空态/错误文案覆盖

---

## 9. FKDiffableTableViewController — 数据与快照 API

### 9.1 宿主驱动加载（主路径）

```swift
listViewController.loadInitialContent { controller in
  let dto = try await api.fetchFeed(page: 1)
  let snapshot = FKListSnapshot(sections: [...])
  controller.applySnapshot(snapshot, animatingDifferences: false)
}
```

### 9.2 Provider 协议（可选便利层）

```swift
@MainActor
public protocol FKListDataProviding: AnyObject {
  func fetchInitial(page: Int) async throws -> FKListFetchResult
  func fetchNextPage(after pagination: FKRefreshPagination) async throws -> FKListFetchResult
  func fetchRefresh(page: Int) async throws -> FKListFetchResult
}

public struct FKListFetchResult: Sendable {
  public var snapshot: FKListSnapshot
  public var hasMorePages: Bool
}
```

设置 `dataProvider` 后，基类自动接 Refresh / Load-more。

### 9.3 Diffable 行为要求

**必须：**

- Item ID 作为 Diffable 身份；**禁止**不同实体复用 ID。
- 支持 `animatingDifferences` 开关。
- 批量变更走 Diffable API。
- `reloadItems` 重配可见 Cell，禁止全表 `reloadData`。
- 可配置更新后保留选中态。

**应当：**

- Debug 检测重复 Item ID 并 assert/日志。

### 9.4 分隔线

| 模式 | 行为 |
|------|------|
| `.system` | 系统分隔线 |
| `.fkDivider(insets:)` | `FKDivider` 发丝线 + 边距 |
| `.none` | 无分隔 |

预设 Cell 在 `.fkDivider` 模式下使用 FKDivider 行间距 preset。

---

## 10. FKDiffableTableViewController — 刷新与分页

### 10.1 下拉刷新

`configuration.refresh.isPullToRefreshEnabled == true` 时：

```swift
tableView.fk_addPullToRefresh(contextAsyncAction: { ... })
```

**下拉刷新必须：**

1. `pagination.resetForNewRequest()`。
2. 取消进行中的 load-more（可配置）。
3. 调用宿主 refresh / `fetchRefresh(page: 1)`。
4. **替换**主 Section Item（非 append）。
5. Token 安全 `endRefreshing(token:)`。
6. Footer 回 idle；有新数据则清除 `noMoreData`。

与 `UIScrollView+FKRefresh`「刷新开始时重置 Footer」行为对齐。

### 10.2 加载更多

```swift
tableView.fk_addLoadMore(contextAsyncAction: { ... })
```

**加载更多必须：**

1. 守卫：非重复加载、`hasMorePages`、状态允许。
2. 用当前 `pagination.page` 请求（**成功后**再 `advance()` — 顺序须在 README 写清）。
3. 成功：**append** Item；`pagination.advance()`。
4. 空页：Footer `noMoreData`；`didReachEnd`。
5. 失败：Footer 错误或静默（可配置）。

**页码约定：**

- 首载 page = 1。
- 每次成功且仍有下一页 → `advance()` → 下次请求 page 2、3…

### 10.3 协调器 Token 安全

`FKListLoadCoordinator` **必须**：

- 为 initial / refresh / loadMore 分配单调递增 Token。
- Token 不匹配则丢弃异步结果。
- refresh 与 initial 并发时以 refresh 为准，取消 initial。

### 10.4 刷新配置字段

| 字段 | 默认 | 用途 |
|------|------|------|
| `isPullToRefreshEnabled` | true | 头部 |
| `isLoadMoreEnabled` | true | 脚部 |
| `loadMoreTriggerMode` | 来自 `FKRefreshSettings` | 自动/手动 |
| `loadMorePreloadOffset` | 0 | 预加载距离 |
| `automaticallyEndsRefreshingOnAsyncCompletion` | true | |
| `resetsPaginationOnRefresh` | true | |
| `clearsSnapshotOnRefreshStart` | false | 刷新开始时是否清空 |

---

## 11. FKDiffableTableViewController — 空态、错误与骨架屏

### 11.1 首次骨架屏

`configuration.loading.usesSkeletonForInitialLoad == true`（默认 **true**）：

1. 进入 `initialLoading`。
2. 按 `FKListSkeletonPolicy`：
   - `.visibleCells` — `tableView.fk_showVisibleCellsSkeleton`
   - `.fullOverlay` — Table 叠加层
   - `.presetRows(count:)` — 占位快照 + Skeleton Cell（高级）

3. 首次成功 `applySnapshot` 并进入 `content`/`empty` 时，**必须**在主线程同步隐藏 Skeleton。

### 11.2 空态

快照 Item 总数为 0 且非错误：

- 由 `configuration.empty` 模板构建 `FKEmptyStateConfiguration`。
- 按策略 `fk_applyEmptyState`。
- 重试动作 → `reloadInitialContent()`。

**必须**使用 phase `.empty`，非 `.loading`。

### 11.3 错误态

拉取失败：

- → `.error` + `FKListErrorPresentation`。
- `FKEmptyState` phase `.error` + 主按钮重试。
- 可选 `preservesContentOnError`：保留上次成功快照于叠加层下。

### 11.4 短内容空态

Table 高度不足一屏时，配合 `fk_updateEmptyState` 显示空态。

---

## 12. FKDiffableTableViewController — 选择与交互

### 12.1 选择模式

```swift
public enum FKListSelectionMode: Sendable, Equatable {
  case none
  case single(deselectOnSecondTap: Bool = false)
  case multiple
}
```

**必须：**

- `didSelectItem` / `didDeselectItem` 回调带 `FKListItemID`。
- 支持按 ID 编程式选中/取消。
- 选中触觉默认关闭。

### 12.2 行高

| 策略 | 行为 |
|------|------|
| `.automatic` | 预设 Cell 自适应 |
| `.fixed(CGFloat)` | 固定 |
| `.perItem((FKListItem) -> CGFloat)` | 宿主闭包 |

### 12.3 禁用行

预设 Item 含 `isEnabled`、`isSelectable` — 禁用行灰显且不可选。

---

## 13. FKDiffableTableViewController — Section 头尾

**必须支持：**

| 样式 | 实现 |
|------|------|
| `.title(String)` | `titleForHeaderInSection` 或自定义 Header |
| `.subtitle(title:subtitle:)` | 自定义 Header + FK 字阶 |
| `.custom(providerID:)` | 宿主注册 Provider 映射 |

- 字色字体来自 `FKListAppearanceConfiguration`。
- 支持 estimated height 自适应。
- `pinsSectionHeaders` 控制 grouped 吸顶。

---

## 14. FKDiffableTableViewController — 滑动操作

### 14.1 配置模型

```swift
public struct FKListSwipeActionConfiguration: Sendable, Equatable {
  public var leading: [FKListSwipeAction]
  public var trailing: [FKListSwipeAction]
  public var permitsFullSwipe: Bool
}

public struct FKListSwipeAction: Sendable, Equatable, Identifiable {
  public var id: String
  public var title: String
  public var style: FKListSwipeActionStyle
  public var icon: FKListSwipeActionIcon?
  // handler 经 FKListSwipeActionHandlerRegistry 注册，保持 Equatable 结构体纯净
}
```

### 14.2 按 Item 配置

Item 可选 `swipeActions: FKListSwipeActionConfiguration?` — nil 表示不可滑。

### 14.3 样式

- 破坏性操作默认系统红；外观配置可覆盖。
- 支持 SF Symbol 图标。

### 14.4 无障碍

- 标题作为 `accessibilityLabel`。
- 全滑 destructive 可选二次确认（v1 默认 **false**）。

---

## 15. FKDiffableCollectionViewController

### 15.1 与 Table 能力对齐

Collection 基类 **必须**对齐：

- 快照 apply/mutation
- 呈现状态机
- Refresh + 分页
- 空态/错误/骨架
- 单选/多选
- `FKListDataProviding`

### 15.2 布局预设

```swift
public enum FKListCollectionLayoutPreset: Sendable, Equatable {
  case list
  case grid(columns: Int, spacing: CGFloat)
  case insetGroupedList
  case compositional((FKListCompositionalLayoutBuilder) -> UICollectionViewCompositionalLayout)
}
```

**必须交付：**

- `.list` — 全宽行
- `.grid(columns:spacing:)` — 均匀网格
- `.insetGroupedList` — 类似系统设置的内嵌卡片 Section

### 15.3 补充视图

Section 头尾经 `UICollectionView.SupplementaryRegistration`，复用 `FKListSectionHeaderFooter` 模型。

### 15.4 Collection Cell

预设 **ViewModel 复用**；Cell 类型独立（`FKListCollectionTextCell` 等）。

---

## 16. FKListCell 预设

### 16.1 预设 Item 枚举

```swift
public enum FKListPresetItem: Hashable, Sendable {
  case text(FKListTextRow)
  case subtitle(FKListSubtitleRow)
  case icon(FKListIconRow)
  case switch(FKListSwitchRow)
  case checkbox(FKListCheckboxRow)
  case disclosure(FKListDisclosureRow)
  case customValue(FKListValueRow)
}
```

### 16.2 能力矩阵

| 预设 | Leading | 标题 | 副标题 | Trailing | 交互 |
|------|---------|------|--------|----------|------|
| **text** | — | ✓ | — | — | 选中 |
| **subtitle** | — | ✓ | ✓ | — | 选中 |
| **icon** | 图/SF Symbol | ✓ | 可选 | — | 选中 |
| **switch** | 可选图标 | ✓ | 可选 | Switch | 开关回调 |
| **checkbox** | 可选 | ✓ | 可选 | 勾选 | 切换回调 |
| **disclosure** | 可选 | ✓ | 可选 | chevron | 选中导航 |
| **customValue** | 可选 | ✓ | 可选 | 值文本 | 选中 |

### 16.3 视觉规范

- 字阶来自 `FKListAppearanceConfiguration`；支持 Dynamic Type。
- 最小行高 **44pt**。
- 分隔与 `FKDivider` list preset 一致。
- Switch 行：`FKToggle` 就绪后迁移；此前 styled `UISwitch` + FK 色（文档说明）。

### 16.4 图标行 + FKImageView

`FKImageView` 可用时，远程 URL **应当**用 `FKImageView`；本地用 `UIImage`。

### 16.5 附件

`FKListAccessory`：none、disclosureIndicator、checkmark、customView id。

---

## 17. 自定义 Cell 与 Pluggable

### 17.1 注册 API

```swift
func register<Cell: FKListTableCellConfigurable>(
  _ cellType: Cell.Type,
  forPayloadType payloadType: Cell.Item.Type
)
```

### 17.2 协议

预设 Cell **也应**遵循 `FKListTableCellConfigurable`，统一代码路径。

### 17.3 宿主 Cell 规则

- `configure(with:)` **同步**，禁止网络。
- 异步图用 `FKImageView`。
- `configure` 内重置复用态（取消图片加载等）。

---

## 18. 配置模型

```swift
public struct FKListConfiguration: Sendable, Equatable {
  public var layout: FKListLayoutConfiguration
  public var appearance: FKListAppearanceConfiguration
  public var refresh: FKListRefreshConfiguration
  public var loading: FKListLoadingConfiguration
  public var empty: FKListEmptyConfiguration
  public var error: FKListErrorConfiguration
  public var selection: FKListSelectionConfiguration
  public var accessibility: FKListAccessibilityConfiguration
}

public enum FKListDefaults {
  public static var defaultConfiguration: FKListConfiguration
}
```

### 18.1 布局字段

| 字段 | 用途 |
|------|------|
| `contentInsets` | Table 额外 inset |
| `separatorMode` | §9.4 |
| `rowHeightPolicy` | §12.2 |
| `sectionHeaderTopPadding` | Grouped 间距 |
| `pinsSectionHeaders` | 吸顶 |

### 18.2 外观字段

| 字段 | 用途 |
|------|------|
| `titleTextStyle` / `subtitleTextStyle` | Dynamic Type |
| `separatorColor` | FKDivider |
| `selectedBackgroundColor` | 选中背景 |
| `sectionHeaderFont` | Section 头 |

---

## 19. Delegate 与生命周期钩子

```swift
@MainActor
public protocol FKListDelegate: AnyObject {
  func list(_ list: FKDiffableTableViewController, willRefresh: FKRefreshActionContext)
  func list(_ list: FKDiffableTableViewController, didRefresh success: Bool)
  func list(_ list: FKDiffableTableViewController, willLoadPage page: Int)
  func list(_ list: FKDiffableTableViewController, didLoadPage page: Int, result: FKListFetchResult)
  func list(_ list: FKDiffableTableViewController, didReachEnd: Void)
  func list(_ list: FKDiffableTableViewController, didSelect item: FKListItemID)
  func list(_ list: FKDiffableTableViewController, presentationStateChanged: FKListPresentationState)
}
```

协议扩展提供默认空实现；**仅主线程**回调。

---

## 20. 搜索驱动列表

FKListKit 不内置 `FKSearchBar`（并行发布），**必须**文档化集成：

```swift
// 宿主防抖搜索 → 构建 filteredSnapshot → apply
listController.applySnapshot(filtered, animatingDifferences: true)
```

可选 `FKListSearchConfiguration`：

- `clearsSelectionOnSearch`
- 零结果用 `.noSearchResult` 空态场景

`FKSearchBar` 就绪后 Example 演示 `navigationItem.titleView` 嵌入。

---

## 21. 预取与性能

### 21.1 Prefetching

`configuration.prefetch.isEnabled` 时基类 **应当**转发 `UITableViewDataSourcePrefetching`：

- 宿主实现 prefetch / cancelPrefetch。
- 文档说明与 `FKImageLoader.prefetch` 配合。

### 21.2 快照性能

- Load-more 用 `appendItems`，避免全量 replace。
- 搜索防抖由宿主负责。
- 1000+ Item：文档建议 `animatingDifferences: false`。

### 21.3 内存

- 快照宜仅存 ID；Payload 可存并行字典 — **宿主**避免在 Cell 长期持有大对象。

---

## 22. 无障碍

**必须：**

- Switch 行：`.button` trait + on/off value。
- 标题+副标题合并 `accessibilityLabel`。
- Section Header：`.header` trait。
- 滑动操作：系统可读 + 自定义 title。
- 空态/错误：继承 `FKEmptyState` a11y。
- 刷新完成可选播报（默认 false）。

**Dynamic Type：** 预设行通过 `UIFontMetrics` 缩放。

---

## 23. SwiftUI 桥接（第二阶段）

**v1 不要求**。计划后续版本：

- `FKListRepresentable` 托管 Table VC，或
- SwiftUI `List` Cell Builder — UIKit MVP 稳定后评估。

---

## 24. 建议源码目录结构

```text
Sources/FKUIKit/Components/List/
├── README.md
├── Public/
│   ├── Core/           # Snapshot, Section, Item, State
│   ├── Table/          # FKDiffableTableViewController
│   ├── Collection/
│   ├── Cells/
│   ├── Configuration/
│   ├── Swipe/
│   ├── Protocols/
│   └── Bridge/
├── Internal/
│   ├── FKListLoadCoordinator.swift
│   ├── FKListDiffableDataSource.swift
│   ├── FKListCellRegistry.swift
│   ├── FKListSnapshotApplier.swift
│   └── FKListEmptyStateCoordinator.swift
└── Extension/
```

`Package.swift` `readmeExcludes` 增加 `Components/List`。

---

## 25. FKKitExamples 场景

路径：`Examples/.../FKUIKit/List/`

| # | 场景 | 验证点 |
|---|------|--------|
| 1 | `FeedRefreshLoadMore` | 下拉 + 无限滚动 + 分页 |
| 2 | `SettingsMultisection` | 多 Section、头、开关/箭头预设 |
| 3 | `EmptyState` | 零结果空态 |
| 4 | `ErrorRetry` | 首载失败 + 重试 |
| 5 | `SkeletonInitialLoad` | 首载骨架 |
| 6 | `SwipeActions` | 左滑/右滑 destructive |
| 7 | `CustomCell` | 宿主自定义 Cell |
| 8 | `CollectionGrid` | 网格 |
| 9 | `SearchFilter` | 防抖筛选快照 |
| 10 | `IconRemoteRow` | 图标行 + FKImageView |

---

## 27. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | 单文件夹 `List/` vs 拆分？ | `List/` + `Cells/` 子目录 |
| Q2 | Payload 放快照内还是旁路字典？ | 旁路 `FKListItemID` 字典，快照更轻 |
| Q3 | 默认 plain 还是 grouped？ | plain；grouped 可配置 |
| Q4 | 占位 Skeleton 快照 vs 叠加？ | v1 优先 visible-cell 叠加 |
| Q5 | Table/Collection 类层次？ | 独立类 + 共享 `FKListLoadCoordinator` |

---

## 28. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-08 | 初版，源自 COMPONENT_ROADMAP §1.2 |

---

## 相关文档

- [FKListKit_DESIGN.md](FKListKit_DESIGN.md) — 英文版
- [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) — 项目路线图
- [FKImageLoader-FKImageView_DESIGN.zh-CN.md](FKImageLoader-FKImageView_DESIGN.zh-CN.md) — 图标行集成
- [Pluggable FKCellReusable](../Sources/FKCoreKit/Components/Pluggable/UIKit/FKCellReusable.swift)
- [FKRefresh README](../Sources/FKUIKit/Components/Refresh/README.md)
- [FKEmptyState README](../Sources/FKUIKit/Components/EmptyState/README.md)
- [FKSkeleton README](../Sources/FKUIKit/Components/Skeleton/README.md)
