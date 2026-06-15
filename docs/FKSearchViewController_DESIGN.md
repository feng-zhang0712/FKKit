# FKSearchViewController — 模块设计需求文档

FKKit **`FKSearchViewController`** 的实现指导文档：可复用的**搜索页/搜索驱动列表**组合 ViewController，编排 **`FKSearchBar`**、**`FKListKit`**、**`FKEmptyState`**、**`FKSkeleton`** 与可选 **`FKNetwork`** 远程查询；消除各 App 重复实现防抖、取消、加载态、零结果与列表快照更新。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 已定稿（v1.1 含 Presentation 自定义扩展）  
**路线图引用：** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) Tier 2 — FKSearchViewController  
**缺口分析引用：** [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md) §8.5  
**控件层（已交付）：** [FKSearchBar-FKSearchField_DESIGN.md](FKSearchBar-FKSearchField_DESIGN.md)  
**列表基类（已交付）：** [FKListKit_DESIGN.md](FKListKit_DESIGN.md)  

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 架构总览](#4-架构总览)
- [5. 模块边界与选型树](#5-模块边界与选型树)
- [6. 搜索模式](#6-搜索模式)
- [7. 呈现状态机](#7-呈现状态机)
- [8. Search Bar 布局与放置](#8-search-bar-布局与放置)
- [9. 结果列表集成（ListKit）](#9-结果列表集成listkit)
- [9.1 Presentation 模式（v1.1）](#91-presentation-模式v11)
- [10. 数据提供者与取消语义](#10-数据提供者与取消语义)
- [11. 空态、错误与骨架屏](#11-空态错误与骨架屏)
- [12. 公开 API 索引](#12-公开-api-索引)
- [13. 配置模型](#13-配置模型)
- [13.1 初始化与 Provider 接线](#131-初始化与-provider-接线)
- [13.2 子类扩展点](#132-子类扩展点)
- [13.3 生命周期与布局顺序](#133-生命周期与布局顺序)
- [14. Delegate 与回调](#14-delegate-与回调)
- [15. 并发与 Swift 6](#15-并发与-swift-6)
- [16. 无障碍与 HIG](#16-无障碍与-hig)
- [17. SwiftUI 桥接（v1.1）](#17-swiftui-桥接v11)
- [18. FKUIKit 复用要求](#18-fkuikit-复用要求)
- [19. 建议源码目录结构](#19-建议源码目录结构)
- [20. FKKitExamples 场景](#20-fkkitexamples-场景)
- [21. 分阶段交付计划](#21-分阶段交付计划)
- [22. v2 能力展望](#22-v2-能力展望)
- [23. 待决问题](#23-待决问题)
- [24. 修订历史](#24-修订历史)
- [25. 相关文档](#25-相关文档)

---

## 1. 概述

电商、社交、工具类 App 大量存在「**搜索框 + 结果列表**」页面：导航栏或顶栏搜索、防抖查询、加载指示、无结果空态、取消清空。FKKit 已交付 **`FKSearchBar`**（控件）与 **`FKListKit`**（Diffable 列表基类），但 **Examples 仍手写** `UISearchBar` + `tableHeaderView` + 自管 `Task` 取消（见 `FKListKitSearchFilterExampleViewController`）。

**`FKSearchViewController`**（建议路径 `Sources/FKUIKit/Components/SearchViewController/`）提供：

| 交付物 | 职责 |
|--------|------|
| **`FKSearchViewController`** | 组合根 VC：Search Bar 放置 + 子列表 VC + 状态机 |
| **`FKSearchViewControllerConfiguration`** | 模式、布局、空态/加载策略 |
| **`FKSearchResultsProviding`** | 远程/本地统一查询协议（async） |
| **`FKSearchLocalFilterProviding`** | 本地内存筛选协议 |
| **`FKSearchPresentationState`** | idle / loading / results / empty / error |
| **`FKSearchViewControllerDelegate`** | 生命周期与状态变更（可选） |
| **`FKSearchViewControllerCallbacks`** | 闭包优先 API（对齐 SearchBar / ListKit） |

**关键约束：** 本模块 **编排** 已有组件；**不**重新实现防抖（用 `FKSearchBar` + `FKDebouncer`）、**不**复制 List Diffable 逻辑（用 `FKDiffableTableViewController` 子 VC）。

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **一页式搜索体验** — 集成方子类或配置即可得到生产可用搜索列表页。
2. **双模式** — **本地筛选**（内存数据集）与 **远程搜索**（async provider + 取消）。
3. **Search Bar 放置** — 导航栏（`titleView`）、粘性顶栏、列表 `tableHeaderView`（documented 三种）。
4. **正确取消** — 新查询 / 取消 / VC dismiss 时取消 in-flight `Task`；过期结果丢弃。
5. **状态驱动 UI** — loading 走 `FKSearchBar.setLoading` + 可选 `FKSkeleton`；空/错走 `FKEmptyState`。
6. **ListKit 一等集成** — 内嵌 `FKDiffableTableViewController`；`applySnapshot` 由 Search VC 编排。
7. **可 subclass** — `open` 钩子：`makeListViewController()`、`configureSearchBar(_:)`、`emptyConfiguration(for:)`。
8. **Swift 6** — `@MainActor`；配置 `Sendable`；provider 闭包 `@Sendable` where needed。
9. **Examples 全覆盖** — 替换 ListKit 示例中 `UISearchBar` 为 FKKit 路径。

### 2.2 非目标（v1）

| 排除 | 说明 |
|------|------|
| 重新实现 `FKSearchBar` / `FKSearchField` | 控件层已交付 |
| `UISearchController` 薄封装 | 保持 FK 样式与行为一致 |
| 搜索建议 / Autocomplete 下拉 | v2 或宿主 |
| 最近搜索持久化 | v2 |
| Scope 条（`FKSegmentedControl`） | v1.1；依赖 FormControls |
| 语音搜索 | 不在范围 |
| 内建 JSON/Network 客户端 | provider 由宿主注入；文档示例可用 `FKNetwork` |
| Collection 专属搜索布局（网格商品） | v1 Table 为主；v1.1 Collection 子类 |
| **PYSearch 式热门/历史预设 UI** | **FKBusinessKit** 业务层封装；FKKit 仅提供 hook |
| macOS | iOS 15+ |

### 2.3 成功标准

- [ ] 本地模式：输入防抖后列表快照更新；零结果展示 `.noSearchResult`。
- [ ] 远程模式：loading → 结果/空/错；快速输入仅最新 query 落盘。
- [ ] Cancel：清空 query、取消 Task、恢复初始快照（可配置）。
- [ ] 导航栏 / 粘性顶栏 / header 三种 placement 均有 Example。
- [ ] 子类可 override `makeListViewController()` 使用自定义 Cell，无需 fork Search 逻辑。
- [ ] README 选型树：何时用 SearchBar alone vs SearchViewController vs 手写 ListKit §20。
- [ ] `xcodebuild` `SWIFT_STRICT_CONCURRENCY=complete` 通过。

---

## 3. 背景与问题陈述

### 3.1 FKKit 现状

| 领域 | 状态 |
|------|------|
| `FKSearchBar` / `FKSearchField` | **已交付** — 防抖、取消、loading |
| `FKListKit` + `FKListSearchConfiguration` | **已交付** — 仅**约定**；无内置 Search UI |
| `FKListKitSearchFilterExampleViewController` | 使用 **`UISearchBar`** + 手写 header frame |
| `FKSearchExampleLoadingSearchViewController` | 远程 mock，**无**列表结果区 |
| **`FKSearchViewController`** | **无** |

### 3.2 重复集成痛点

| 痛点 | 影响 |
|------|------|
| Search UI 与 List 生命周期分离 | dismiss 后 Task 仍写 UI |
| `tableHeaderView` + Auto Layout 冲突 | 示例用 frame 手搓 |
| 空结果 vs 初始空列表未区分 | 错误 Empty scenario |
| 导航搜索与内容搜索两套代码 | 样式不一致 |
| 未复用 `FKSearchBar.setLoading` | 重复 spinner 逻辑 |

---

## 4. 架构总览

```text
┌─────────────────────────────────────────────────────────────────┐
│                    FKSearchViewController                        │
│  ┌──────────────── FKSearchBar ─────────────────────────────┐   │
│  │ FKDebouncer (internal via SearchBar)                      │   │
│  └───────────────────────────┬──────────────────────────────┘   │
│  ┌─ optional scopeHost (v1.1) ──────────────────────────────┐   │
│  │ FKChipGroup / FKSegmentedControl slot                     │   │
│  └───────────────────────────┬──────────────────────────────┘   │
│  FKSearchSessionCoordinator (internal)                           │
│    query token · Task cancel · state machine                     │
│  ┌─ child VC ──────────────────────────────────────────────┐   │
│  │ FKDiffableTableViewController (default)                     │   │
│  │  FKEmptyState · FKSkeleton · applySnapshot                  │   │
│  └────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
         ▲                              ▲
         │                              │
  FKSearchLocalFilterProviding   FKSearchResultsProviding
  (memory filter)                (async remote)
```

**数据流（远程）：**

```text
onSearchQueryChanged(query)
  → coordinator.beginSearch(query) // increment token
  → searchBar.setLoading(true)
  → await provider.search(query)
  → token still current?
       yes → applySnapshot / empty / error
       no  → discard
  → searchBar.setLoading(false)
```

---

## 5. 模块边界与选型树

### 5.1 选型树

| 需求 | 推荐 |
|------|------|
| 列表内嵌一行紧凑筛选 | **`FKSearchField`** + 宿主 `applySnapshot` |
| 单页搜索 + 结果列表（标准搜索页） | **`FKSearchViewController`** |
| 仅导航栏搜索框，结果在另一 VC | **`FKSearchBar`** + `FKSearchBarNavigationHosting` |
| 设置页 Section 内搜索行 | **`FKFormCellSearchCell`**（CellKit）+ `FKSearchField` |
| 系统 `UISearchController` 样式 / large title 自动折叠 | **非目标** — 用 placement 配置近似 |
| 底部 Sheet 内搜索 | **`FKSearchField`** in Sheet；完整页用 Search VC |

### 5.2 与 FKSearchBar

| 层级 | 职责 |
|------|------|
| **FKSearchBar** | 输入、防抖事件、清除/取消、loading chrome |
| **FKSearchViewController** | 放置 SearchBar、驱动列表状态、编排 provider |

Search VC **必须** 嵌入 **`FKSearchBar`**（默认 `FKSearchBarDefaults.navigationBar()` 或 `inlineCard()`），**禁止** 内嵌 `UISearchBar`。

### 5.3 与 FKListKit

- Search VC **拥有** 子 `FKDiffableTableViewController`（Container 模式）；
- 默认关闭 pull-to-refresh / load-more（`configuration.list.refresh`）；
- 读取 `FKListSearchConfiguration`：`clearsSelectionOnSearch`、`emptyScenario`；
- **不** 修改 ListKit 基类源码 — 通过 composition。

### 5.4 与 FKEmptyState / FKSkeleton

| 状态 | 组件 |
|------|------|
| 无匹配结果 | `FKEmptyStateConfiguration.scenario(.noSearchResult)` |
| 远程失败 | `.loadFailed` + 重试 → 重发当前 query |
| 首次远程加载（可选） | `FKSkeleton` on list（`configuration.loading.useSkeleton`） |

### 5.5 与 FKNetwork

- v1 **不** hard-depend Network target；
- README / Examples 演示 `FKSearchResultsProviding` 内调用 `FKNetworkClient`；
- 错误映射为 `FKSearchError` → Empty error UI。

---

## 6. 搜索模式

```swift
public enum FKSearchMode: Sendable, Equatable {
  /// Filter in-memory snapshot via ``FKSearchLocalFilterProviding``.
  case localFilter
  /// Async search via ``FKSearchResultsProviding`` (network or database).
  case remote
}
```

| 模式 | Provider | 初始 UI | Query 空串 |
|------|----------|---------|------------|
| **localFilter** | `FKSearchLocalFilterProviding` | 展示全量 `baselineSnapshot` | 恢复 baseline |
| **remote** | `FKSearchResultsProviding` | 空列表或 placeholder（可配置） | 空列表 / idle 文案 |

```swift
public protocol FKSearchLocalFilterProviding: AnyObject {
  /// Full dataset before filtering.
  var baselineSnapshot: FKListSnapshot { get }
  /// Returns filtered snapshot; query is normalized (trimmed).
  func filteredSnapshot(for query: String) -> FKListSnapshot
}

public protocol FKSearchResultsProviding: AnyObject {
  func search(query: String) async throws -> FKSearchResultsResponse
}

public struct FKSearchResultsResponse: Sendable {
  public var snapshot: FKListSnapshot
  public var emptyScenario: FKEmptyStateScenario?
}
```

---

## 7. 呈现状态机

```swift
public enum FKSearchPresentationState: Sendable, Equatable {
  case idle
  case editing
  case loading(query: String)
  case results(query: String, itemCount: Int)
  case empty(query: String, scenario: FKEmptyStateScenario)
  case error(query: String, error: FKSearchError)
}
```

**转移（摘要）：**

```text
idle → editing (begin editing)
editing → loading (debounced query, remote/local work starts)
loading → results | empty | error
any → idle (cancel policy clears query)
```

- 每次转移可选通知 `delegate` / `onPresentationStateChanged`；
- **Stale guard：** `FKSearchSessionCoordinator` 单调递增 `searchGeneration`，provider 返回后比对。

---

## 8. Search Bar 布局与放置

```swift
public enum FKSearchBarPlacement: Sendable, Equatable {
  /// ``FKSearchBarNavigationHosting`` on navigationItem.
  case navigationBar
  /// Pinned below navigation bar / safe area (scrolls with content optional).
  case stickyHeader
  /// ``UITableView.tableHeaderView`` (frame-managed helper).
  case tableHeader
}
```

| Placement | 典型场景 | 备注 |
|-----------|----------|------|
| `navigationBar` | 全局搜索 Tab | 大标题时自行处理 scroll |
| `stickyHeader` | 搜索始终可见 | 默认推荐 |
| `tableHeader` | 与 ListKit 旧示例兼容 | 内部复用 frame helper，避免 AL 冲突 |

**Cancel 行为：** 委托给 `FKSearchBar` 的 `FKSearchCancelPolicy`；Search VC 在 `onCancel` 时：

1. 取消 in-flight Task；
2. 恢复 baseline / 清空 remote 结果（可配置 `cancelRestoresBaseline`）；
3. `popViewController` **不**自动发生 — 由宿主决定（文档示例两种）。

---

## 9. 结果列表集成（ListKit）

### 9.1 Child View Controller

```swift
@MainActor
open class FKSearchViewController: UIViewController {
  public private(set) var searchBar: FKSearchBar
  public private(set) var listViewController: FKDiffableTableViewController

  /// Override to customize list configuration or cell registration.
  open func makeListViewController() -> FKDiffableTableViewController
}
```

- Container embed：`addChild` + pin `listViewController.view` below search chrome；
- Search bar 区域由 **`FKSearchChromeContainerView`**（internal）布局。

### 9.2 快照更新规则

| 事件 | 行为 |
|------|------|
| 本地 filter | `filteredSnapshot` → `applySnapshot(..., animatingDifferences: config.animatesSnapshotChanges)` |
| 远程 success | provider snapshot → apply |
| 远程 empty | apply empty snapshot + Empty overlay |
| Query 清空 | baseline 或 empty idle |
| Selection | 若 `clearsSelectionOnSearch` → deselect all |

### 9.3 与 ListKit §20 关系

ListKit **继续** 文档化「宿主自管 Search」路径；Search VC 为 **推荐** 封装。ListKit 示例 **迁移** 至 Search VC Example（保留一个「低级集成」示例可选）。

### 9.1 Presentation 模式（v1.1）

**原则：** 默认 **Unified**（v1 行为不变）；深度自定义通过 **opt-in 配置 + open 钩子** 实现；**不** 内建 PYSearch 热门/历史样式（归属 [FKBusinessKit](file:///Users/frank/Desktop/Workspace/FKBusinessKit)）。

#### 9.1.1 双区域模型

```text
FKSearchViewController
├── Search Chrome（FKSearchBar + optional accessoryView）
├── Search Content（idle / 发现页 — 可选自定义 VC）
└── Results Content（结果页 — 内嵌 List 或自定义 VC 或宿主导航）
```

| 区域 | 默认（Unified） | 自定义 |
|------|----------------|--------|
| Search Chrome | `FKSearchBar` + placement | `configureSearchBar` · `makeSearchAccessoryView()` |
| Search Content | 无独立区域；idle 用 List snapshot | `makeSearchContentViewController()` |
| Results Content | `makeListViewController()` | `makeResultsViewController()` · `hostHandled` |

#### 9.1.2 配置

```swift
public enum FKSearchResultsPresentationMode: Sendable, Equatable {
  /// Default — ``makeListViewController()``; idle + results share embedded list.
  case embeddedList
  /// ``makeResultsViewController()`` child; may conform to ``FKSearchResultsDisplaying``.
  case customViewController
  /// Built-in results UI suppressed; host navigates via callback/delegate.
  case hostHandled
}

public enum FKSearchIdleContentPresentation: Sendable, Equatable {
  /// Idle via baseline / remoteIdleSnapshot on results surface (default).
  case listSnapshot
  /// Show ``makeSearchContentViewController()`` when query is empty.
  case customViewController
  /// No idle body below search chrome.
  case none
}

public struct FKSearchPresentationConfiguration: Sendable, Equatable {
  public var resultsMode: FKSearchResultsPresentationMode
  public var idleContent: FKSearchIdleContentPresentation
}
```

**默认：** `resultsMode: .embeddedList`，`idleContent: .listSnapshot` — 与 v1 完全一致。

#### 9.1.3 子类钩子（v1.1 新增）

| 方法 | 用途 |
|------|------|
| `makeSearchContentViewController()` | 自定义搜索页 body（idle/发现）；`nil` = 无 |
| `makeResultsViewController()` | 自定义结果页 VC；默认转发 `makeListViewController()` |
| `makeSearchAccessoryView()` | SearchBar 下方 accessory（筛选条、说明条） |
| `makeListViewController()` | 保留；embeddedList 默认结果 |

#### 9.1.4 结果更新协议

非 List 自定义结果 VC 实现 ``FKSearchResultsDisplaying`` 接收 loading / snapshot / empty / error：

```swift
public enum FKSearchResultsPresentationUpdate: Sendable, Equatable { ... }

@MainActor
public protocol FKSearchResultsDisplaying: AnyObject {
  func applySearchResultsUpdate(_ update: FKSearchResultsPresentationUpdate, from searchViewController: FKSearchViewController)
}
```

`FKDiffableTableViewController` 子类仍走 `applySnapshot` 捷径，无需实现协议。

#### 9.1.5 宿主导航（微信 / PYSearch push 式）

`resultsMode: .hostHandled` 时：

- Search VC **不** 调用 provider / **不** 更新内嵌结果；
- 每次有效 query 触发 `onSearchQueryDispatch` / delegate → `.handledByHost`；
- 宿主在回调内 `push`/`present` 任意结果 VC；
- Cancel / dismiss 仍由 Search VC session coordinator 管理。

#### 9.1.6 与 FKBusinessKit 边界

| 层级 | 职责 |
|------|------|
| **FKSearchViewController** | 编排、状态机、hook、ListKit 集成 |
| **FKBusinessKit**（未来） | PYSearch 式热门 Tag、历史 Cell/Tag、持久化、预设样式 |

FKBusinessKit 通过 `makeSearchContentViewController()` 注入发现页，通过 `hostHandled` 或自定义 Results VC 注入结果页 — **不** 反向依赖 FKBusinessKit。

---

## 10. 数据提供者与取消语义

### 10.1 Session Coordinator（internal）

```swift
// Internal — behavior spec
final class FKSearchSessionCoordinator {
  func performSearch(query: String, generation: UInt64) async
  func cancelAll()
}
```

| 触发 | 动作 |
|------|------|
| 新 debounced query | `cancel` 旧 Task；generation++ |
| `searchBar` cancel | cancel + 恢复 UI |
| `viewDidDisappear` | cancel（可配置 `cancelsOnDisappear`） |
| deinit | cancel |

### 10.2 最小 query 长度

- 尊重 `FKSearchBar.configuration.debounce.minimumQueryLengthForSearchCallback`；
- 低于阈值 → 视为空 query（不调用 remote provider；本地模式恢复 baseline）。

### 10.3 远程 debounce

- **禁止** Search VC 再套一层 Debouncer — 仅监听 `onSearchQueryChanged`；
- Submit on Return：`onSubmit` → 立即搜索（flush debounce，SearchBar 已支持）。

---

## 11. 空态、错误与骨架屏

| 条件 | UI |
|------|-----|
| `localFilter` + 无匹配 | `.noSearchResult` |
| `remote` + 空 snapshot | `.noSearchResult` 或 provider 指定 scenario |
| 网络/解码错误 | `.loadFailed`；CTA 重试当前 query |
| 首次加载 | optional skeleton rows（`configuration.loading.skeletonRowCount`） |

```swift
public enum FKSearchError: Error, Sendable, Equatable {
  case providerFailed(String)
  case cancelled
}
```

**初始空列表 vs 搜索无结果：** remote 模式 idle 时 **不** 显示 `.noSearchResult`（可配置 idle 文案或隐藏 empty）。

---

## 12. 公开 API 索引

| 类型 | 说明 |
|------|------|
| `FKSearchViewController` | 组合 VC |
| `FKSearchViewControllerConfiguration` | 根配置 |
| `FKSearchMode` | local / remote |
| `FKSearchBarPlacement` | 三种放置 |
| `FKSearchPresentationState` | 状态机 |
| `FKSearchLocalFilterProviding` | 本地筛选 |
| `FKSearchResultsProviding` | 远程搜索 |
| `FKSearchResultsResponse` | 远程响应 |
| `FKSearchViewControllerCallbacks` | 闭包 API |
| `FKSearchViewControllerDelegate` | 可选 delegate |
| `FKSearchError` | 错误 |
| `FKSearchViewControllerDefaults` | 预设配置工厂（local / remote） |
| `FKSearchEmptyConfiguration` | 空态/idle 策略 |
| `FKSearchBehaviorConfiguration` | 取消、动画、idle 行为 |
| `FKSearchViewControllerLoadingConfiguration` | 骨架屏与 SearchBar loading |
| `FKSearchPresentationConfiguration` | 结果/idle 呈现模式 |
| `FKSearchResultsPresentationMode` | embeddedList / customViewController / hostHandled |
| `FKSearchIdleContentPresentation` | listSnapshot / customViewController / none |
| `FKSearchResultsDisplaying` | 非 List 结果 VC 更新协议 |
| `FKSearchResultsPresentationUpdate` | 结果面 unified update enum |
| `FKSearchQueryDispatch` | performBuiltIn / handledByHost |

---

## 13. 配置模型

```swift
public struct FKSearchViewControllerConfiguration: Sendable, Equatable {
  public var mode: FKSearchMode
  public var placement: FKSearchBarPlacement
  public var searchBar: FKSearchBarConfiguration
  public var list: FKListConfiguration
  public var loading: FKSearchViewControllerLoadingConfiguration
  public var empty: FKSearchEmptyConfiguration
  public var behavior: FKSearchBehaviorConfiguration
  public var presentation: FKSearchPresentationConfiguration
}

public struct FKSearchBehaviorConfiguration: Sendable, Equatable {
  /// When cancel clears query, restore local baseline or remote idle snapshot.
  public var cancelRestoresBaseline: Bool
  /// Cancel in-flight search when the view controller disappears.
  public var cancelsOnDisappear: Bool
  public var animatesSnapshotChanges: Bool
  /// When `true`, remote mode shows baseline/placeholder snapshot for empty query instead of clearing.
  public var showsResultsOnEmptyQuery: Bool
  /// Auto-focus search field on first appearance (default `false`).
  public var focusesSearchOnAppear: Bool
}

public struct FKSearchViewControllerLoadingConfiguration: Sendable, Equatable {
  public var useSkeleton: Bool
  public var skeletonRowCount: Int
  /// Drives ``FKSearchBar/setLoading(_:animated:)`` during remote queries.
  public var searchBarLoading: Bool
}

/// Empty-state semantics distinct from ``FKListEmptyConfiguration`` (list-level defaults).
public struct FKSearchEmptyConfiguration: Sendable, Equatable {
  /// Scenario when a non-empty query yields zero rows (local or remote).
  public var searchNoResultsScenario: FKEmptyStateScenario
  /// Optional idle copy when remote query is empty; `nil` hides empty overlay (recommended).
  public var remoteIdleScenario: FKEmptyStateScenario?
  public var overridesTitle: String?
  public var overridesMessage: String?
}

/// Preset factories mirroring ListKit / SearchBar defaults style.
public enum FKSearchViewControllerDefaults {
  public static func localFilter(
    placement: FKSearchBarPlacement = .stickyHeader
  ) -> FKSearchViewControllerConfiguration

  public static func remote(
    placement: FKSearchBarPlacement = .stickyHeader
  ) -> FKSearchViewControllerConfiguration
}
```

**默认：**

- `mode: .localFilter`
- `placement: .stickyHeader`
- `searchBar: FKSearchBarDefaults.inlineCard()`
- `list.refresh.isPullToRefreshEnabled: false`
- `list.refresh.isLoadMoreEnabled: false`
- `list.search: FKListSearchConfiguration(emptyScenario: .noSearchResult)`
- `list.loading.usesSkeletonForInitialLoad: false`（Search VC 自管 loading 骨架）
- `behavior.cancelRestoresBaseline: true`
- `behavior.cancelsOnDisappear: true`
- `behavior.animatesSnapshotChanges: true`
- `behavior.showsResultsOnEmptyQuery: false`
- `behavior.focusesSearchOnAppear: false`
- `empty.searchNoResultsScenario: .noSearchResult`
- `empty.remoteIdleScenario: nil`（idle 不展示 `.noSearchResult`）
- `loading.useSkeleton: false`（local）；`FKSearchViewControllerDefaults.remote()` 为 `true`
- `loading.searchBarLoading: true`（remote）

### 13.1 初始化与 Provider 接线

```swift
@MainActor
open class FKSearchViewController: UIViewController {
  public init(
    configuration: FKSearchViewControllerConfiguration = FKSearchViewControllerDefaults.localFilter(),
    placeholder: String? = nil
  )

  /// Required for ``FKSearchMode/localFilter``; ignored in remote mode.
  public weak var localFilterProvider: FKSearchLocalFilterProviding?

  /// Required for ``FKSearchMode/remote``; ignored in local mode.
  public weak var resultsProvider: FKSearchResultsProviding?

  /// Re-runs the current debounced query (e.g. after network recovery).
  public func retryCurrentSearch()

  /// Programmatic query update; respects SearchBar normalization and debounce options.
  public func setQuery(_ query: String, options: FKSearchTextUpdateOptions = .withSearchQuery)
}
```

| 模式 | 必须设置 | 首次 `viewDidAppear` 行为 |
|------|----------|---------------------------|
| `localFilter` | `localFilterProvider` | `applySnapshot(baselineSnapshot)` |
| `remote` | `resultsProvider` | 空 snapshot 或 idle placeholder（见 `showsResultsOnEmptyQuery`） |

Provider 为 `AnyObject` 弱引用；宿主通常在 `viewDidLoad` 或 push 前赋值。缺 provider 时 Search VC **断言（debug）/ 静默 no-op（release）** 并在 README 说明。

### 13.2 子类扩展点

| 方法 | 用途 |
|------|------|
| `makeListViewController() -> FKDiffableTableViewController` | 自定义 Cell 注册、list 配置 |
| `configureSearchBar(_:)` | 额外 placeholder、accessibility、callbacks 叠加 |
| `emptyConfiguration(for: FKListPresentationState) -> FKEmptyStateConfiguration?` | 覆盖空/错 copy；默认映射 `configuration.empty` |
| `willPerformSearch(query:)` | 可选 hook（日志、埋点）；默认 no-op |
| `didUpdatePresentationState(_:)` | 子类状态扩展；默认转发 delegate/callbacks |
| `makeSearchContentViewController()` | v1.1 — 自定义搜索页 body |
| `makeResultsViewController()` | v1.1 — 自定义结果页（默认 `makeListViewController()`） |
| `makeSearchAccessoryView()` | v1.1 — SearchBar 下 accessory |

内部列表子类 `FKSearchResultsListViewController` 将 `reloadInitialContent()` 转发为 ``retryCurrentSearch()``，使 Empty/Error CTA 重试当前 query 而非 ListKit 初始加载。

### 13.3 生命周期与布局顺序

```text
init → viewDidLoad:
  makeListViewController()
  configureSearchBar(_:)
  embed list child VC
  install search placement (navigation / sticky / tableHeader)
  wire SearchBar callbacks → session coordinator
viewWillAppear → navigationBar placement re-fit titleView width
viewDidAppear → optional focusSearchOnAppear
viewWillDisappear → cancelsOnDisappear ? cancelAll()
deinit → cancelAll()
```

**Sticky header 布局：** `FKSearchChromeContainerView` 固定于 safe area 顶；list child `view` 顶边约束到 chrome 底。  
**Table header：** `FKSearchTableHeaderInstaller` frame 管理；`viewDidLayoutSubviews` 刷新宽度（与 ListKit 示例同源策略，库内化）。

---

## 14. Delegate 与回调

```swift
public struct FKSearchViewControllerCallbacks {
  public var onPresentationStateChanged: (@MainActor (FKSearchPresentationState) -> Void)?
  public var onResultSelected: (@MainActor (FKListItemID) -> Void)?
  /// When set, can return `.handledByHost` to suppress built-in results (push flow).
  public var onSearchQueryDispatch: (@MainActor (String, FKSearchViewController) -> FKSearchQueryDispatch)?
  /// Fired when dispatch is `.handledByHost` or `resultsMode == .hostHandled`.
  public var onHostSearchRequested: (@MainActor (String, FKSearchViewController) -> Void)?
}

@MainActor
public protocol FKSearchViewControllerDelegate: AnyObject {
  func searchViewController(_ vc: FKSearchViewController, stateChanged state: FKSearchPresentationState)
  func searchViewController(_ vc: FKSearchViewController, didSelect item: FKListItemID)
  func searchViewController(_ vc: FKSearchViewController, searchQueryDispatchFor query: String) -> FKSearchQueryDispatch
  func searchViewController(_ vc: FKSearchViewController, hostSearchRequested query: String)
}
```

- 列表选择转发子 VC `FKListDelegate` / 闭包；
- **Callbacks 优先**（对齐 SearchBar）。

---

## 15. 并发与 Swift 6

| 规则 | 说明 |
|------|------|
| `FKSearchViewController` | `@MainActor` |
| Provider | `async throws`；MainActor 回调 UI |
| `FKSearchResultsProviding` | class protocol；实现方保证线程安全 |
| Task 取消 | 协作式；provider 应检查 `Task.isCancelled` |
| 配置 | `Sendable` |

---

## 16. 无障碍与 HIG

- Search field：SearchBar 已提供 accessibility；VC 设置 `navigationItem` title 为页面名；
- 加载：announce optional（默认 false，对齐 ListKit）；
- 空态：继承 `FKEmptyState` VoiceOver；
- 触控目标：SearchBar ≥ 44pt（控件层保证）；
- Dynamic Type：SearchBar + List preset 支持；
- RTL：SearchBar layout engine 已处理；列表同 ListKit。

---

## 17. SwiftUI 桥接（v1.1）

- `FKSearchViewControllerRepresentable` 包装 UIKit VC；
- 或 `FKSearchScreen` SwiftUI 组合（SearchBarRepresentable + List 需 ListKit bridge 成熟后）；
- **v1 不阻塞** UIKit 交付。

---

## 18. FKUIKit 复用要求

| 需求 | 使用 |
|------|------|
| 搜索输入 | **`FKSearchBar`** / **`FKSearchBarNavigationHosting`** |
| 防抖 | **SearchBar 内置 `FKDebouncer`** — 禁止 duplicate |
| 列表 | **`FKDiffableTableViewController`** |
| 空/错 | **`FKEmptyStateConfiguration.scenario`** |
| 骨架 | **`FKSkeleton`**（optional） |
| 字符串 trim | **`FKSearchTextNormalization`** via SearchBar |
| 示例数据 | FKKitExamples `FKSearchExampleSupport` patterns |

**禁止：** 复制 ListKit Diffable 逻辑；复制 SearchBar coordinator。

---

## 19. 建议源码目录结构

```text
Sources/FKUIKit/Components/SearchViewController/
├── README.md
├── Public/
│   ├── FKSearchViewController.swift
│   ├── FKSearchViewControllerConfiguration.swift
│   ├── FKSearchMode.swift
│   ├── FKSearchBarPlacement.swift
│   ├── FKSearchPresentationState.swift
│   ├── FKSearchResultsProviding.swift
│   ├── FKSearchLocalFilterProviding.swift
│   ├── FKSearchViewControllerCallbacks.swift
│   ├── FKSearchViewControllerDelegate.swift
│   ├── FKSearchError.swift
│   ├── FKSearchPresentationConfiguration.swift
│   ├── FKSearchResultsPresentationMode.swift
│   ├── FKSearchIdleContentPresentation.swift
│   ├── FKSearchResultsDisplaying.swift
│   ├── FKSearchResultsPresentationUpdate.swift
│   └── FKSearchQueryDispatch.swift
├── Internal/
│   ├── FKSearchSessionCoordinator.swift
│   ├── FKSearchChromeContainerView.swift
│   ├── FKSearchTableHeaderInstaller.swift
│   ├── FKSearchContentContainer.swift
│   └── FKSearchResultsListViewController.swift
└── Extension/
    └── FKSearchViewController+ListDelegate.swift
```

`Package.swift` — `fkUIKitComponentDocDirectories` 增加 `Components/SearchViewController`。

---

## 20. FKKitExamples 场景

路径：`Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/SearchViewController/`

### 20.1 Hub

| # | 场景 | 验证点 |
|---|------|--------|
| H0 | `FKSearchViewControllerHubViewController` | 子场景索引 |

### 20.2 基线（v1）

| # | 场景 | 验证点 |
|---|------|--------|
| B1 | `LocalFilterSticky` | 本地 filter + sticky header |
| B2 | `LocalFilterTableHeader` | tableHeader placement |
| B3 | `NavigationBarSearch` | titleView + push 搜索页 |
| B4 | `RemoteLoading` | mock 1.2s API + cancel |
| B5 | `EmptyNoResults` | `.noSearchResult` |
| B6 | `ErrorRetry` | failed → retry |
| B7 | `CancelRestoresBaseline` | cancel 策略 |
| B8 | `CustomListCells` | override `makeListViewController()` |

### 20.3 Presentation 自定义（v1.1）

| # | 场景 | 验证点 |
|---|------|--------|
| P1 | `CustomSearchContent` | `FKSearchPresentationConfiguration.customIdleEmbeddedResults` · `makeSearchContentViewController()` |
| P2 | `CustomResultsDisplay` | `FKSearchResultsDisplaying` · `makeResultsViewController()` · remote 状态更新 |
| P3 | `HostHandledPush` | `resultsMode: .hostHandled` · `onHostSearchRequested` · 宿主 push 独立结果页 |
| P4 | `PYSearchLayout` | 热门标签 + 历史 idle · `hostHandled` push · `FKPagingController` `contentTop` 独立结果页 |

**说明：** PYSearch 式热门/历史 UI **不在 FKKit**；由 FKBusinessKit 通过 P1/P3 钩子注入。

### 20.4 后续增强（v1.2+）

| # | 场景 | 验证点 |
|---|------|--------|
| E1 | `ScopeChips` | FKChipGroup 行 · `makeSearchAccessoryView()` |
| E2 | `SwiftUIRepresentable` | 宿主 SwiftUI |
| E3 | `CollectionGridResults` | Collection 子类 |

**迁移：** `FKListKitSearchFilterExampleViewController` 注明推荐 B1；可选保留为「低级 API」示例。

---

## 21. 分阶段交付计划

| 阶段 | 交付物 | 主题 |
|------|--------|------|
| **SV0** | Configuration + SessionCoordinator + local mode | 本地筛选 |
| **SV1** | Remote provider + loading + error | 异步搜索 |
| **SV2** | 三种 placement + chrome layout | 布局 |
| **SV3** | Delegate/callbacks + README 选型树 | API 完整 |
| **SV4** | Examples B1–B8 + Hub | 演示 |
| **SV5** | Gap/Roadmap 更新；ListKit 示例交叉链接 | 文档 |

每阶段：`xcodebuild` → CHANGELOG。

---

## 22. v2 能力展望

| 能力 | 说明 |
|------|------|
| 搜索建议 / Autocomplete | 下拉 `FKCallout` 或 inline table section |
| 最近搜索 | `FKStorage` 持久化 + section header |
| `FKDiffableCollectionViewController` 子类 | 网格搜索结果 |
| 多 scope | `FKSegmentedControl` + query 参数 |
| 与 `FKBusinessKit.track` 搜索埋点 | opt-in hook |
| 键盘快捷键（iPad） | focus on `/` |

---

## 23. 待决问题

| ID | 问题 | **决议（v1）** |
|----|------|----------------|
| Q1 | 目录名 `SearchViewController/` vs `Search/`？ | **`SearchViewController/`** — 与 ListKit 平级 |
| Q2 | 默认 child 仅 Table？ | v1 **Table**；Collection 子类 v1.1 |
| Q3 | remote idle 展示 placeholder 还是空？ | **`showsResultsOnEmptyQuery == false`** 时空列表且 **不** 显示 `.noSearchResult`；`true` 时展示 provider/宿主注入的 idle snapshot |
| Q4 | 是否内置 Network 适配器？ | v1 **仅 Examples** |
| Q5 | Cancel 是否默认 pop VC？ | **否** — 仅 clear；文档展示 pop 模式 |
| Q6 | `open class` vs composition protocol？ | **`open class FKSearchViewController`** |
| Q7 | skeleton 默认开？ | remote **`true`**，local **`false`** |
| Q8 | Error 重试走 ListKit `reloadInitialContent`？ | **是** — 内部 list 子类转发为 `retryCurrentSearch()` |

---

## 24. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-14 | 初版：Tier 2 组合搜索页设计 |
| 2026-06-14 | v1.1：Presentation 自定义（idle/results 分离、hostHandled、FKSearchResultsDisplaying）；明确 PYSearch 样式归属 FKBusinessKit |

---

## 25. 相关文档

| 文档 | 内容 |
|------|------|
| [FKSearchBar-FKSearchField_DESIGN.md](FKSearchBar-FKSearchField_DESIGN.md) | 控件层 |
| [FKListKit_DESIGN.md](FKListKit_DESIGN.md) | §20 搜索驱动列表 |
| [FKCellKit_DESIGN.md](FKCellKit_DESIGN.md) | 行内搜索 Cell |
| [EmptyState README](../Sources/FKUIKit/Components/EmptyState/README.md) | `.noSearchResult` |
| [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md) | §8.5 |
| [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) | Tier 2 |
