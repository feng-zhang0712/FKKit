# FKListKit — 设计需求文档

FKKit **Diffable 列表基础设施**的实现指导文档：Section/Item 模型、Table/Collection 视图控制器、预设 Cell、滑动操作，以及与 **FKRefresh**、**FKEmptyState**、**FKSkeleton** 的集成。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 已实现（v1，活文档 — 与 `Sources/FKUIKit/Components/ListKit/` 对齐）  
**路线图引用：** [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) §1.2  
**组件 README：** [ListKit README](../Sources/FKUIKit/Components/ListKit/README.md)

> **历史说明：** 旧版 **FKCompositeKit ListKit**（插件式 `FKListPlugin`）已移除；当前 FKUIKit **ListKit** 为继承式 Diffable 基类 VC，二者 API 不兼容。

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
- [24. 源码目录结构（已实现）](#24-源码目录结构已实现)
- [25. FKKitExamples 场景](#25-fkkitexamples-场景)
- [26. 已知限制与后续演进](#26-已知限制与后续演进)
- [27. 设计决策记录](#27-设计决策记录)
- [28. 修订历史](#28-修订历史)

---

## 1. 概述

FKKit 已提供 **Cell 注册协议**（`FKListTableCellConfigurable`、`FKListCollectionCellConfigurable`）以及成熟的 **Refresh / EmptyState / Skeleton** 模块。**FKListKit** 将它们与 `UITableViewDiffableDataSource` / `UICollectionViewDiffableDataSource` **串联**为列表 ViewController 基础设施。

团队在每个项目中重复实现：

- 下拉刷新 + 无限滚动 + 页码重置
- 首次骨架屏 → 首帧快照 → 内容
- 空态/错误叠加与重试
- 设置页风格行（标题、副标题、开关、箭头）
- 风格统一的左/右滑操作

**FKListKit**（`FKUIKit/Components/ListKit/`）交付：

| 交付物 | 职责 |
|--------|------|
| **`FKListSection` / `FKListItem`** | Hashable Diffable 模型 |
| **`FKDiffableTableViewController`** | Table 基类 VC + Diffable DS + 刷新/分页/空态/骨架 |
| **`FKDiffableCollectionViewController`** | Collection 基类 + Compositional 预设 |
| **`FKListPresetItem` 预设行** | 标准行样式（`FKListPresetTableCell` / `FKListPresetCollectionCell`） |
| **`FKListSwipeActionConfiguration`** | 滑动操作封装（Table，v1） |

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
| Collection 滑动操作（v1） | 仅 Table 接线 swipe UI |

### 2.3 成功标准（v1 验收）

- [x] Table 基类 VC 实现 §8–14；Collection VC §15 完成。
- [x] 示例信息流：下拉刷新、加载更多、空态、错误重试、首次骨架 — **无需手写 DS**。
- [x] 集成流中刷新重置 `FKRefreshPagination`，加载更多成功后 `advance()`。
- [x] 遵循 `FKListTableCellConfigurable` 的自定义 Cell 无需 fork 基类。
- [x] VoiceOver：Section 头与滑动操作可读。
- [x] 组件 README + FKKitExamples Hub 全覆盖。
- [ ] 根 README 索引与 CHANGELOG 发版条目（发版时补齐）。

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
| **ListKit** | `Components/ListKit/` | **已交付** — Diffable 基类 VC + 预设行 |

### 3.2 痛点矩阵（ListKit 解决项）

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
│                     + FKListItemStore（Payload 旁路）            │
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

| 关注点 | FKUIKit `ListKit/` | FKCoreKit |
|--------|-------------------|-----------|
| UIViewController 子类 | 是 | 否 |
| Diffable DataSource | 是（内联于 VC） | 否 |
| `FKListItem` Hashable 模型 | 是 | 仅当无 UIKit 依赖时可放纯 Swift 辅助 |
| 预设 Cell | 是（v1）；长期见 §5.2 | 否 |
| Refresh/Empty/Skeleton 接线 | 是（集成） | 否 |
| Payload 旁路存储 | 是（`FKListItemStore`） | 否 |

**依赖：** ListKit import `FKCoreKit`（Pluggable、Async）及 FKUIKit 邻域组件；无第三方依赖。

### 5.1 FKCoreKit 复用要求（强制）

实现或扩展 ListKit 前**必须先检索** `Sources/FKCoreKit`。**禁止**在 `ListKit/` 内重复实现 Core 已有或应上提的通用逻辑：

| 能力 | 必须使用（FKCoreKit） | 禁止 |
|------|----------------------|------|
| Cell 复用契约 | **`FKCellReusable`**（Pluggable） | 自写 prepareForReuse 约定 |
| 异步/防抖 | **`FKDebouncer`**、`CancellableWork` | 裸 Timer |
| 图片加载 | **`FKImageView`** + **`FKImageLoader`** | 列表内自建加载器 |
| 布局/集合 | Extension（`IndexPath`、`UICollectionView` 等） | 重复 diff 辅助 |
| 本地化 | **`FKI18n`** | 硬编码 |

详见 [COMPONENT_ROADMAP.zh-CN.md — 勿重复造轮子](COMPONENT_ROADMAP.zh-CN.md#勿重复造轮子--复用对照表)。

### 5.2 与 FKCellKit 的边界

| 维度 | FKCellKit | FKListKit |
|------|-----------|-----------|
| 职责 | 独立 `UITableViewCell` / `UICollectionViewCell` 视图 | Diffable VC、刷新/分页/空态/骨架 |
| 预设 | 具体 Cell 子类 + Row 模型 | `FKListPresetItem` 枚举 + 薄 Cell 包装 |
| 关系 | **被消费** | 映射到 CellKit Cell（Phase 6） |

**v1：** 预设行布局维护在 `ListKit/Public/Presets/` 与 `Public/Cells/`。  
**后续（FKCellKit Phase 6）：** `FKListPresetItem` 映射到 FKCellKit Cell；ListKit 层仅保留 Item → Cell 绑定，**禁止 duplicate Auto Layout**。详见 [FKCellKit_DESIGN.zh-CN.md](FKCellKit_DESIGN.zh-CN.md) §5。

---

## 6. 核心数据模型

### 6.1 身份类型

```swift
public struct FKListItemID: Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
  public let rawValue: String
}

public struct FKListSectionID: Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
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
  public var swipeActions: FKListSwipeActionConfiguration?
}

public enum FKListItemKind: Hashable, Sendable {
  case preset(FKListPresetItem)
  case custom(FKListCustomItem)
}

public struct FKListCustomItem: Hashable, Sendable {
  public var cellTypeIdentifier: String
}
```

- **`preset`** — FKListKit 内置 Cell 渲染（§16）。
- **`custom`** — 宿主注册 Cell；Payload **不**嵌入快照，经 `FKListItemStore` 旁路存储（§17）。
- **`metadata`** — 可选 `isEnabled` / `isSelectable`；预设 Row 模型内也可含同名字段，Cell 绑定层合并语义。

### 6.3 Payload（旁路存储）

```swift
public struct FKListItemPayload: @unchecked Sendable {
  public init<T: Sendable>(_ value: T)
  public func unwrap<T>(_ type: T.Type = T.self) -> T?
}
```

- Diffable 身份仅用 `FKListItemID`；重 Payload 不进 `Hashable` 快照。
- 自定义 Cell 流程：`setPayload(_:for:)` → `applySnapshot`（含 `.custom` item）。

### 6.4 Section 模型

```swift
public struct FKListSection: Hashable, Sendable {
  public var id: FKListSectionID
  public var items: [FKListItem]
  public var header: FKListSectionHeaderFooter?
  public var footer: FKListSectionHeaderFooter?
  public var layoutHints: FKListSectionLayoutHints?  // Collection compositional 间距/inset
}

public enum FKListSectionHeaderFooter: Hashable, Sendable {
  case title(String)
  case subtitle(title: String, subtitle: String?)
  case custom(viewProviderID: String)
}

public struct FKListSectionLayoutHints: Hashable, Sendable {
  public var interGroupSpacing: CGFloat?
  public var contentInsets: FKListDirectionalInsets?
}
```

### 6.5 快照与变更

```swift
public struct FKListSnapshot: Hashable, Sendable {
  public var sections: [FKListSection]
  public var totalItemCount: Int { get }
  public func item(withID: FKListItemID) -> FKListItem?
  public func itemIDsWithChangedContent(comparedTo: FKListSnapshot) -> [FKListItemID]
}

public enum FKListSnapshotMutation: Sendable {
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

**便利构造（Extension）：**

```swift
FKListItem.text(id:title:)
FKListItem.subtitle(id:title:subtitle:)
FKListItem.custom(id:cellTypeIdentifier:)
FKListSection.main(items:)
FKListSnapshot(items:sectionID:)
```

`applySnapshot` 在 Debug 检测重复 Item ID；对 `itemIDsWithChangedContent` 自动 `reloadItems`，用于 switch/checkbox 状态更新。

---

## 7. 列表呈现状态机

### 7.1 状态

```swift
public enum FKListPresentationState: Equatable, Sendable {
  case initialLoading
  case content
  case empty
  case error(FKListErrorPresentation)
  case refreshing
  case loadingNextPage
}

public struct FKListErrorPresentation: Equatable, Sendable {
  public var title: String
  public var message: String?
  public var debugDescription: String?
}
```

- **空态文案**不携带在 `empty` 关联值中，而来自 `FKListEmptyConfiguration` 或 `activeEmptyScenarioOverride`。
- **错误文案**由 `FKListErrorPresentation` + `FKListErrorConfiguration` 构建 `FKEmptyStateConfiguration`。

### 7.2 状态转移（规范）

| 自 | 事件 | 至 |
|----|------|-----|
| initialLoading | 首次快照有数据 | content |
| initialLoading | 首次快照为空 | empty |
| initialLoading | 拉取失败 | error |
| content | 开始下拉刷新 | refreshing |
| refreshing | 成功有数据 | content |
| refreshing | 成功为空 | empty |
| refreshing | 失败 | error，或保留 content（`refreshFailureKeepsContent == true`） |
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

**空态策略**（`FKListEmptyPresentationPolicy`，位于 `FKListLayoutConfiguration`）：

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

  public weak var delegate: FKListDelegate?
  public weak var dataProvider: FKListDataProviding?

  public let swipeActionHandlerRegistry: FKListSwipeActionHandlerRegistry
  public let switchHandlerRegistry: FKListSwitchHandlerRegistry
  public let checkboxHandlerRegistry: FKListCheckboxHandlerRegistry

  public var rowHeightProvider: ((FKListItem) -> CGFloat)?
  public var didSelectItem: ((FKListItemID) -> Void)?
  public var didDeselectItem: ((FKListItemID) -> Void)?
  public var activeEmptyScenarioOverride: FKEmptyStateScenario?
  public var hostReloadHandler: (@MainActor (FKDiffableTableViewController) async throws -> Void)?
}
```

**必须持有：**

- `UITableView`（默认 plain；grouped 可配置）。
- `UITableViewDiffableDataSource<FKListSectionID, FKListItemID>`（内联，无独立 public 类型）。
- Cell 注册表（`FKListTableCellRegistry`：预设 + 宿主）。
- `FKListLoadCoordinator`（刷新/分页 Token）。
- `FKListPresentationCoordinator`（空态/骨架/错误叠加）。
- `FKListItemStore`（Payload 旁路）。
- 可选 `FKRefreshControl` 头/脚引用。

**不得：**

- 内部发起 URLSession（由宿主闭包/Provider 提供）。
- 强制 MVVM/MVC 等架构 — 仅回调。

### 8.2 初始化

```swift
public init(
  configuration: FKListConfiguration = FKListDefaults.defaultConfiguration,
  style: UITableView.Style = .plain
)
```

Table 贴满 VC.view（Safe Area）；尊重 `configuration.layout.contentInsets`。

### 8.3 可重写钩子

- `configurePresetCell(_:at:with:)` — 预设 Cell 绑定扩展
- `registerAdditionalCells(in:)` — 宿主额外注册
- `makeEmptyStateConfiguration(for:)` — 空态/错误文案覆盖

---

## 9. FKDiffableTableViewController — 数据与快照 API

### 9.1 宿主驱动加载

```swift
listViewController.loadInitialContent { controller in
  let dto = try await api.fetchFeed(page: 1)
  let snapshot = FKListSnapshot(items: [...])
  controller.applySnapshot(snapshot, animatingDifferences: false)
}
```

- `reloadInitialContent()` — 从 `dataProvider` 或 `hostReloadHandler` 重新拉首屏；空态/错误重试按钮调用此方法。
- 设置 `dataProvider` 且 `viewDidLoad` 时，基类自动 `reloadInitialContent()`。

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

### 9.3 自定义 Cell 与 Payload

```swift
register(MyCell.self, forPayloadType: MyModel.self)
setPayload(FKListItemPayload(myModel), for: itemID)
applySnapshot(FKListSnapshot(items: [.custom(id: itemID, cellTypeIdentifier: "MyCell")]))
```

### 9.4 Diffable 行为要求

**必须：**

- Item ID 作为 Diffable 身份；**禁止**不同实体复用 ID。
- 支持 `animatingDifferences` 开关。
- 批量变更走 Diffable API。
- `reloadItems` 重配可见 Cell，禁止全表 `reloadData`。
- `configuration.selection.preservesSelectionOnUpdates` 控制更新后保留选中态。

**应当：**

- Debug 检测重复 Item ID 并 assert/日志（已实现 `assertDuplicateItemIDsIfNeeded`）。

### 9.5 分隔线

| 模式 | 行为 |
|------|------|
| `.system` | 系统分隔线 |
| `.fkDivider(leadingInset:)` | `FKDivider` 发丝线 + 边距 |
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

1. `pagination.resetForNewRequest()`（当 `resetsPaginationOnRefresh == true`）。
2. 取消进行中的 load-more（当 `cancelsLoadMoreOnRefresh == true`）。
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
2. 用当前 `pagination.page` 请求（**成功后**再 `advance()` — 顺序见组件 README）。
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
| `loadMoreTriggerMode` | `.automatic` | 自动/手动 |
| `loadMorePreloadOffset` | 0 | 预加载距离 |
| `automaticallyEndsRefreshingOnAsyncCompletion` | true | async 完成自动 endRefreshing |
| `resetsPaginationOnRefresh` | true | 下拉刷新重置页码 |
| `clearsSnapshotOnRefreshStart` | false | 刷新开始时是否清空快照 |
| `cancelsLoadMoreOnRefresh` | true | 刷新时取消进行中的 load-more |
| `refreshFailureKeepsContent` | true | 刷新失败保留当前 content |
| `autohidesLoadMoreFooterWhenNotScrollable` | false | 不可滚动时是否隐藏 Footer |

---

## 11. FKDiffableTableViewController — 空态、错误与骨架屏

### 11.1 首次骨架屏

`configuration.loading.usesSkeletonForInitialLoad == true`（默认 **true**）：

1. 进入 `initialLoading`。
2. 按 `FKListSkeletonPolicy`：
   - `.visibleCells` — `tableView.fk_showVisibleCellsSkeleton`（**默认**）
   - `.fullOverlay` — Table 叠加层
   - `.presetRows(count:)` — **v1 保留 API**；当前行为同 `fullOverlay`

3. 首次成功 `applySnapshot` 并进入 `content`/`empty` 时，**必须**在主线程同步隐藏 Skeleton。

### 11.2 空态

快照 Item 总数为 0 且非错误：

- 由 `configuration.empty`（`FKEmptyStateScenario` + 可选 title/message 覆盖）构建叠加。
- 按 `configuration.layout.emptyPresentationPolicy` 应用 `fk_applyEmptyState`。
- 重试动作 → `reloadInitialContent()`。
- 可用 `activeEmptyScenarioOverride` 临时覆盖 scenario（如搜索零结果）。

**必须**使用 phase `.empty`，非 `.loading`。

### 11.3 错误态

拉取失败：

- → `.error(FKListErrorPresentation)`。
- `FKEmptyState` phase `.error` + 主按钮重试。
- `configuration.error.preservesContentOnError`：保留上次成功快照于叠加层下。

### 11.4 短内容空态

Table 高度不足一屏时，配合 `fk_updateEmptyState` / `fk_refreshEmptyStateAutomatically` 显示空态。

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

- `didSelectItem` / `didDeselectItem` 闭包与 `FKListDelegate` 回调带 `FKListItemID`。
- `selectItem(withID:animated:scrollPosition:)` / `deselectItem(withID:animated:)` 编程式选中。
- `configuration.selection.playsHapticOnSelect` 默认 **false**。

### 12.2 行高

| 策略 | 行为 |
|------|------|
| `.automatic` | 预设 Cell 自适应（`estimatedRowHeight = 52`） |
| `.fixed(CGFloat)` | 固定高度 |

**Per-item 高度：** 设置 `rowHeightProvider: ((FKListItem) -> CGFloat)?`（Table delegate 转发）。

### 12.3 禁用行

预设 Row 与 `FKListItemMetadata` 均支持 `isEnabled`、`isSelectable` — 禁用行灰显且不可选（`disabledAlpha` 来自 appearance 配置）。

---

## 13. FKDiffableTableViewController — Section 头尾

**必须支持：**

| 样式 | 实现 |
|------|------|
| `.title(String)` | `FKListSectionHeaderView` / Footer |
| `.subtitle(title:subtitle:)` | 自定义 Header + FK 字阶 |
| `.custom(viewProviderID:)` | `registerSectionViewProvider(id:provider:)` |

- 字色字体来自 `FKListAppearanceConfiguration`。
- 支持 estimated height 自适应。
- `pinsSectionHeaders` + `sectionHeaderTopPadding` 控制 grouped 吸顶与间距。

---

## 14. FKDiffableTableViewController — 滑动操作

### 14.1 配置模型

```swift
public struct FKListSwipeActionConfiguration: Sendable, Equatable, Hashable {
  public var leading: [FKListSwipeAction]
  public var trailing: [FKListSwipeAction]
  public var permitsFullSwipe: Bool
}

public struct FKListSwipeAction: Sendable, Equatable, Hashable, Identifiable {
  public var id: String
  public var title: String
  public var style: FKListSwipeActionStyle  // .normal / .destructive / .cancel
  public var icon: FKListSwipeActionIcon?   // SF Symbol name
}
```

Handler 经 **`FKListSwipeActionHandlerRegistry`** 按 `action.id` 注册，保持配置结构体 `Equatable`：

```swift
swipeActionHandlerRegistry.register(id: "delete") { itemID in ... }
```

### 14.2 按 Item 配置

`FKListItem.swipeActions: FKListSwipeActionConfiguration?` — nil 表示不可滑。

### 14.3 Switch / Checkbox Handler

Switch 与 Checkbox 预设行使用 **`handlerID`** 字符串，分别在 **`FKListSwitchHandlerRegistry`** / **`FKListCheckboxHandlerRegistry`** 注册：

```swift
switchHandlerRegistry.register(id: "notifications") { itemID, isOn in ... }
```

### 14.4 样式与无障碍

- 破坏性操作默认系统红。
- 支持 SF Symbol 图标。
- 标题作为 `accessibilityLabel`。
- 全滑 destructive 二次确认 v1 默认 **false**。

---

## 15. FKDiffableCollectionViewController

### 15.1 与 Table 能力对齐

Collection 基类 **必须**对齐：

- 快照 apply/mutation、`setPayload`、`FKListItemStore`
- 呈现状态机、`FKListPresentationCoordinator`
- Refresh + 分页、`FKListLoadCoordinator`
- 空态/错误/骨架（三种 `FKListEmptyPresentationPolicy`）
- 单选/多选、编程式 select/deselect
- `FKListDataProviding`、`hostReloadHandler`、`loadInitialContent`
- Prefetch 转发、`FKListCollectionDelegate`

**v1 不对齐：** Table 滑动操作 UI（`swipeActionHandlerRegistry` 存在但未接线）。

### 15.2 布局预设

```swift
public enum FKListCollectionLayoutPreset: Sendable, Equatable {
  case list
  case grid(columns: Int, spacing: CGFloat)
  case insetGroupedList
  case compositional((FKListCompositionalLayoutBuilder) -> UICollectionViewCompositionalLayout)
}
```

**已交付：**

- `.list` — 全宽行
- `.grid(columns:spacing:)` — 均匀网格
- `.insetGroupedList` — 类似系统设置的内嵌卡片 Section

**补充：** `compositionalLayoutProvider: ((FKListSnapshot) -> UICollectionViewLayout)?` 可在 preset 不足时完全自定义 layout；`FKListSection.layoutHints` 影响 section content inset / inter-group spacing。

### 15.3 补充视图

Section 头尾经 `UICollectionView.SupplementaryRegistration`，复用 `FKListSectionHeaderFooter` 模型；自定义 provider 经 `registerSectionHeaderProvider`。

### 15.4 Collection Cell

预设 Row 模型与 Table **共享**（`FKListPresetItem`）；Cell 类型独立（`FKListPresetCollectionCell` 等）。

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

### 16.2 Leading 内容

```swift
public enum FKListLeadingContent: Hashable, Sendable {
  case asset(name: String)
  case symbol(name: String)
  case remoteURL(URL)  // FKImageView
}
```

### 16.3 能力矩阵

| 预设 | Leading | 标题 | 副标题 | Trailing | 交互 |
|------|---------|------|--------|----------|------|
| **text** | — | ✓ | — | — | 选中 |
| **subtitle** | — | ✓ | ✓ | — | 选中 |
| **icon** | asset/symbol/URL | ✓ | 可选 | — | 选中 |
| **switch** | 可选 | ✓ | 可选 | Switch | `handlerID` → registry |
| **checkbox** | 可选 | ✓ | 可选 | 勾选 | `handlerID` → registry |
| **disclosure** | 可选 | ✓ | 可选 | chevron | 选中导航 |
| **customValue** | 可选 | ✓ | 可选 | 值文本 | 选中 |

### 16.4 视觉规范

- 字阶来自 `FKListAppearanceConfiguration`（`titleFont` / `subtitleFont`）；支持 Dynamic Type。
- 最小行高 **44pt**。
- 分隔与 `FKDivider` list preset 一致。
- Switch 行：v1 使用 styled `UISwitch`；**FKToggle** 就绪后迁移（见 FKFormControls 设计）。

### 16.5 附件

`FKListAccessory`：none、disclosureIndicator、checkmark、customView(id)。

---

## 17. 自定义 Cell 与 Pluggable

### 17.1 注册 API

```swift
func register<Cell: FKListTableCellConfigurable>(
  _ cellType: Cell.Type,
  forPayloadType payloadType: Cell.Item.Type
)
```

Collection 等价方法在 `FKDiffableCollectionViewController` 上，约束 `FKListCollectionCellConfigurable`。

### 17.2 Payload 旁路（规范流程）

1. `register(MyCell.self, forPayloadType: MyModel.self)`
2. `setPayload(FKListItemPayload(model), for: itemID)` — 写入 `FKListItemStore`
3. `applySnapshot(...)` 含 `FKListItem.custom(id:cellTypeIdentifier:)`
4. DataSource 出队时从 store 取 Payload 调用 `configure(with:)`

快照 prune 时 store 同步 `prune(keeping:)`，移除不再存在的 item id。

### 17.3 协议与规则

- 预设 Cell 经 `FKListPresetTableCell` 统一路径；自定义 Cell 遵循 `FKListTableCellConfigurable`。
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
  public var prefetch: FKListPrefetchConfiguration
  public var search: FKListSearchConfiguration?
}

public enum FKListDefaults {
  public static var defaultConfiguration: FKListConfiguration
}
```

### 18.1 布局（`FKListLayoutConfiguration`）

| 字段 | 用途 |
|------|------|
| `contentInsets` | Table/Collection 额外 inset |
| `separatorMode` | §9.5 |
| `rowHeightPolicy` | §12.2 |
| `sectionHeaderTopPadding` | Grouped 间距 |
| `pinsSectionHeaders` | 吸顶 |
| `emptyPresentationPolicy` | §7.3 三种空态策略 |

### 18.2 外观（`FKListAppearanceConfiguration`）

| 字段 | 用途 |
|------|------|
| `titleFont` / `subtitleFont` | Dynamic Type |
| `titleColor` / `subtitleColor` | 标签色 |
| `separatorColor` | FKDivider |
| `selectedBackgroundColor` | 选中背景 |
| `sectionHeaderFont` / `sectionHeaderColor` | Section 头 |
| `disabledAlpha` | 禁用行透明度 |

### 18.3 加载 / 空态 / 错误 / 选择 / 预取 / 搜索

| 结构体 | 关键字段 |
|--------|----------|
| `FKListLoadingConfiguration` | `usesSkeletonForInitialLoad`、`skeletonPolicy` |
| `FKListEmptyConfiguration` | `scenario`、`overridesTitle/Message`、`animatesPresentation` |
| `FKListErrorConfiguration` | `preservesContentOnError`、`scenario`、覆盖文案、`animatesPresentation` |
| `FKListSelectionConfiguration` | `mode`、`preservesSelectionOnUpdates`、`playsHapticOnSelect` |
| `FKListAccessibilityConfiguration` | `announcesRefreshCompletion`（默认 false） |
| `FKListPrefetchConfiguration` | `isEnabled` |
| `FKListSearchConfiguration` | `clearsSelectionOnSearch`、`emptyScenario`（可选，§20） |

---

## 19. Delegate 与生命周期钩子

```swift
@MainActor
public protocol FKListDelegate: AnyObject {
  func list(_ list: FKDiffableTableViewController, willRefresh context: FKRefreshActionContext)
  func list(_ list: FKDiffableTableViewController, didRefresh success: Bool)
  func list(_ list: FKDiffableTableViewController, willLoadPage page: Int)
  func list(_ list: FKDiffableTableViewController, didLoadPage page: Int, result: FKListFetchResult)
  func list(_ list: FKDiffableTableViewController, didReachEnd: Void)
  func list(_ list: FKDiffableTableViewController, didSelect item: FKListItemID)
  func list(_ list: FKDiffableTableViewController, didDeselect item: FKListItemID)
  func list(_ list: FKDiffableTableViewController, presentationStateChanged state: FKListPresentationState)
  func list(_ list: FKDiffableTableViewController, prefetchItems ids: [FKListItemID])
  func list(_ list: FKDiffableTableViewController, cancelPrefetching ids: [FKListItemID])
}
```

Collection 侧镜像协议 **`FKListCollectionDelegate`**（参数类型为 `FKDiffableCollectionViewController`）。

协议 extension 提供默认空实现；**仅主线程**回调。

---

## 20. 搜索驱动列表

FKListKit 不内置 `FKSearchBar`，**必须**文档化集成：

```swift
// 宿主防抖搜索 → 构建 filteredSnapshot → apply
listController.applySnapshot(filtered, animatingDifferences: true)
```

可选 `configuration.search`（`FKListSearchConfiguration`）：

- `clearsSelectionOnSearch`（默认 true）
- `emptyScenario`（默认 `.noSearchResult`）

Example `FKListKitSearchFilterExampleViewController` 演示 `UISearchController` + 防抖筛选。`FKSearchBar` 就绪后可替换搜索 UI，快照 apply 模式不变。

---

## 21. 预取与性能

### 21.1 Prefetching

`configuration.prefetch.isEnabled == true` 时基类转发 `UITableViewDataSourcePrefetching` / `UICollectionViewDataSourcePrefetching` → `FKListDelegate.prefetchItems` / `cancelPrefetching`。

与 `FKImageLoader.prefetch` 配合见 `FKListKitIconRemoteRowExampleViewController`。

### 21.2 快照性能

- Load-more 用 `appendItems`，避免全量 replace。
- 搜索防抖由宿主负责（`FKDebouncer`）。
- 1000+ Item：建议 `animatingDifferences: false`。

### 21.3 内存

- 快照仅存轻量 `FKListItem`；重 Payload 存 `FKListItemStore` — 宿主避免在 Cell 长期持有大对象。

---

## 22. 无障碍

**必须：**

- Switch 行：`.button` trait + on/off value。
- 标题+副标题合并 `accessibilityLabel`。
- Section Header：`.header` trait。
- 滑动操作：系统可读 + 自定义 title。
- 空态/错误：继承 `FKEmptyState` a11y。
- 刷新完成可选播报（`announcesRefreshCompletion`，默认 false）。

**Dynamic Type：** 预设行通过 `UIFont.preferredFont(forTextStyle:)` / `UIFontMetrics` 缩放。

---

## 23. SwiftUI 桥接（第二阶段）

**v1 不要求**。计划后续版本：

- `FKListRepresentable` 托管 Table VC，或
- SwiftUI `List` Cell Builder — UIKit MVP 稳定后评估。

---

## 24. 源码目录结构（已实现）

> 以组件 [README](../Sources/FKUIKit/Components/ListKit/README.md) 为准；下列为当前 v1 布局。

```text
Sources/FKUIKit/Components/ListKit/
├── README.md
├── Public/
│   ├── Core/           # Identity, Item, Section, Snapshot, State, FetchResult
│   ├── Configuration/  # FKListConfiguration 分层
│   ├── Presets/        # FKListPresetItem, Row 模型, FKListLeadingContent
│   ├── Protocols/      # FKListDataProviding, FKListDelegate, FKListCollectionDelegate
│   ├── Swipe/          # Swipe + Switch/Checkbox handler registries
│   ├── Table/          # FKDiffableTableViewController
│   ├── Collection/     # FKDiffableCollectionViewController, layout presets
│   └── Cells/
│       ├── Table/      # FKListPresetTableCell, section header/footer
│       └── Collection/ # FKListPresetCollectionCell, section header
├── Internal/
│   ├── FKListLoadCoordinator.swift
│   ├── FKListCellRegistry.swift
│   ├── FKListSnapshotApplier.swift
│   ├── FKListPresentationCoordinator.swift
│   └── FKListItemStore.swift
└── Extension/          # FKListItem/FKListSnapshot 便利构造
```

`Package.swift` `exclude:` 含 `Components/ListKit`（README 不参与 Swift 编译）。

---

## 25. FKKitExamples 场景

路径：`Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/ListKit/`  
Hub：`FKListKitExamplesHubViewController`

| 分组 | 场景 | 验证点 |
|------|------|--------|
| Table · 数据 | Feed · refresh & load more | `FKListDataProviding`、分页、delegate |
| | Host-driven initial load | `loadInitialContent(handler:)` |
| | Snapshot mutations | `applyMutation` 全变体 |
| Table · 呈现 | Skeleton initial load | `FKListSkeletonPolicy` |
| | Empty state | 零 Item 快照 + 重试 |
| | Error & retry | 首载失败 + `preservesContentOnError` |
| | Empty policy · replace / inline | 三种 `FKListEmptyPresentationPolicy` |
| Table · 交互 | Settings · multi-section | 全部 preset + section 头 + switch/checkbox |
| | Swipe actions | leading/trailing + handler registry |
| | Selection modes | single/multiple + 编程式选中 |
| | Search filter | 防抖 + `applySnapshot` |
| | Icon · remote row | `FKListIconRow` + prefetch delegate |
| | Custom cell | `FKListTableCellConfigurable` + payload store |
| Collection | List / grid / inset grouped | 三种 layout preset |

---

## 26. 已知限制与后续演进

| 项 | v1 状态 | 计划 |
|----|---------|------|
| `FKListSkeletonPolicy.presetRows` | API 保留；行为同 `fullOverlay` | 占位快照 + skeleton cell |
| Collection swipe actions | Registry 存在，无 UI 接线 | 视 UIKit API 评估 |
| 预设 Cell 布局 | 在 ListKit 内维护 | FKCellKit Phase 6 迁移 |
| SwiftUI 桥接 | 未交付 | §23 |
| 拖拽排序 | 非目标 | 按需 v2+ |
| 单元测试 | FKKit 默认不要求 | 按需补充 |

---

## 27. 设计决策记录

| ID | 问题 | **已决（v1）** |
|----|------|----------------|
| Q1 | 单文件夹 vs 拆分？ | **`ListKit/`** 单组件；`Presets/` + `Cells/Table|Collection/` 子目录 |
| Q2 | Payload 放快照内还是旁路？ | **旁路 `FKListItemStore`** + `setPayload(_:for:)` |
| Q3 | 默认 plain 还是 grouped？ | **plain**；`init(style:)` 可 grouped |
| Q4 | Skeleton 占位快照 vs 叠加？ | 默认 **`.visibleCells`**；`.presetRows` 待实现 |
| Q5 | Table/Collection 类层次？ | **独立 VC 类** + 共享 Internal（Coordinator、Store、Applier） |
| Q6 | 插件式 vs 继承式基类？ | **继承式** `FKDiffable*ViewController`（旧 CompositeKit ListKit 已移除） |

---

## 28. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-08 | 初版，源自 COMPONENT_ROADMAP §1.2 |
| 2026-06-13 | v1 实现对照修订：路径 `ListKit/`、Payload 旁路、配置/Delegate/API 对齐代码、Examples/目录/CellKit 边界、成功标准勾选、设计决策落定 |

---

## 相关文档

- [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) — 项目路线图
- [FKCellKit_DESIGN.zh-CN.md](FKCellKit_DESIGN.zh-CN.md) — 预设 Cell 长期归属
- [FKImageLoader-FKImageView_DESIGN.zh-CN.md](FKImageLoader-FKImageView_DESIGN.zh-CN.md) — 图标行集成
- [FKSearchBar-FKSearchField_DESIGN.zh-CN.md](FKSearchBar-FKSearchField_DESIGN.zh-CN.md) — 搜索控件集成
- [Pluggable FKCellReusable](../Sources/FKCoreKit/Components/Pluggable/UIKit/FKCellReusable.swift)
- [ListKit README](../Sources/FKUIKit/Components/ListKit/README.md)
- [FKRefresh README](../Sources/FKUIKit/Components/Refresh/README.md)
- [FKEmptyState README](../Sources/FKUIKit/Components/EmptyState/README.md)
- [FKSkeleton README](../Sources/FKUIKit/Components/Skeleton/README.md)
