# FKListKit — Design Requirements

Implementation guide for FKKit **Diffable list infrastructure**: section/item models, table and collection view controllers, preset cells, swipe actions, and integration with **FKRefresh**, **FKEmptyState**, and **FKSkeleton**.

**Document type:** Design requirements (normative for implementers)  
**Status:** Draft  
**Roadmap reference:** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §1.2  
**中文版本:** [FKListKit_DESIGN.zh-CN.md](FKListKit_DESIGN.zh-CN.md)

---

## Table of Contents

- [1. Executive Summary](#1-executive-summary)
- [2. Goals, Non-Goals, and Success Criteria](#2-goals-non-goals-and-success-criteria)
- [3. Background & Problem Statement](#3-background--problem-statement)
- [4. Architectural Overview](#4-architectural-overview)
- [5. Module Boundaries](#5-module-boundaries)
- [6. Core Data Model](#6-core-data-model)
- [7. List Presentation State Machine](#7-list-presentation-state-machine)
- [8. FKDiffableTableViewController — Responsibilities](#8-fkdiffabletableviewcontroller--responsibilities)
- [9. FKDiffableTableViewController — Data & Snapshot API](#9-fkdiffabletableviewcontroller--data--snapshot-api)
- [10. FKDiffableTableViewController — Refresh & Pagination](#10-fkdiffabletableviewcontroller--refresh--pagination)
- [11. FKDiffableTableViewController — Empty, Error & Skeleton](#11-fkdiffabletableviewcontroller--empty-error--skeleton)
- [12. FKDiffableTableViewController — Selection & Interaction](#12-fkdiffabletableviewcontroller--selection--interaction)
- [13. FKDiffableTableViewController — Section Headers & Footers](#13-fkdiffabletableviewcontroller--section-headers--footers)
- [14. FKDiffableTableViewController — Swipe Actions](#14-fkdiffabletableviewcontroller--swipe-actions)
- [15. FKDiffableCollectionViewController](#15-fkdiffablecollectionviewcontroller)
- [16. FKListCell Presets](#16-fklistcell-presets)
- [17. Custom Cells & Pluggable Conformance](#17-custom-cells--pluggable-conformance)
- [18. Configuration Model](#18-configuration-model)
- [19. Delegate & Lifecycle Hooks](#19-delegate--lifecycle-hooks)
- [20. Search-Driven Lists](#20-search-driven-lists)
- [21. Prefetching & Performance](#21-prefetching--performance)
- [22. Accessibility](#22-accessibility)
- [23. SwiftUI Bridge (Phase 2)](#23-swiftui-bridge-phase-2)
- [24. Proposed Source Layout](#24-proposed-source-layout)
- [25. FKKitExamples Scenarios](#25-fkkitexamples-scenarios)
- [27. Open Questions](#27-open-questions)
- [28. Revision History](#28-revision-history)

---

## 1. Executive Summary

FKKit ships **cell registration protocols** (`FKListTableCellConfigurable`, `FKListCollectionCellConfigurable`) and powerful **Refresh / EmptyState / Skeleton** modules, but no **list view-controller infrastructure** that wires them together with `UITableViewDiffableDataSource` / `UICollectionViewDiffableDataSource`.

Teams repeatedly rebuild:

- Pull-to-refresh + infinite scroll + page index reset
- Initial skeleton → first snapshot → content
- Empty and error overlays with retry
- Standard settings-style rows (title, subtitle, switch, disclosure)
- Swipe actions with consistent styling

**FKListKit** (folder name: `List/` under `FKUIKit/Components/`) delivers:

| Deliverable | Role |
|-------------|------|
| **`FKListSection` / `FKListItem`** | Hashable diffable models |
| **`FKDiffableTableViewController`** | Table base VC + diffable DS + refresh/pagination/empty/skeleton |
| **`FKDiffableCollectionViewController`** | Collection base VC + compositional presets |
| **`FKListCell` presets** | Styled standard rows |
| **`FKListSwipeActionConfiguration`** | Swipe action wrapper (table) |

FKListKit is **not** a full app framework — it is a **thin, opinionated base** that composes existing FKKit modules.

---

## 2. Goals, Non-Goals, and Success Criteria

### 2.1 Goals

1. **Eliminate repeated list VC boilerplate** for the most common feed and settings patterns.
2. **First-class integration** with `FKRefresh`, `FKRefreshPagination`, `FKEmptyState`, `FKSkeleton`, `FKDivider`.
3. **Protocol-friendly custom cells** — honor Pluggable list cell contracts; presets are optional shortcuts.
4. **Correct pagination semantics** — refresh resets page; load-more advances; end-of-data disables footer.
5. **Safe async loading** — token/cancellation aware refresh handlers; no stale snapshot applies.
6. **FKKit consistency** — `@MainActor`, `Sendable` item types, layered configuration, English docs, Examples coverage.

### 2.2 Non-Goals

| Excluded | Reason |
|----------|--------|
| Full MVVM framework / reactive binding library | Host owns networking and mapping |
| Built-in networking or JSON parsing | Use `FKNetwork` in host layer |
| Drag-and-drop reorder UI (v1) | Defer to a later release if demanded |
| UITableView `UITableViewDataSource` legacy path | Diffable only in v1 |
| Nested diffable hierarchies / complex tree diff | Flat sections + items only v1 |
| Self-sizing complex form validation | Use `FKTextField` in custom cells |
| Replace `FKPagingController` | Orthogonal; lists inside child VCs |
| macOS / tvOS targets | iOS 15+ UIKit |

### 2.3 Success Criteria

- [ ] Table base VC implements §8–14; collection VC §15 by release.
- [ ] Example feed: pull-to-refresh, load-more, empty, error retry, skeleton first load — single demo without custom DS code.
- [ ] `FKRefreshPagination` resets on refresh and advances on successful load-more in integrated flow.
- [ ] Custom cell conforming to `FKListTableCellConfigurable` works without forking base VC.
- [ ] VoiceOver: section headers and swipe actions readable.
- [ ] Component README + root README index + CHANGELOG.

---

## 3. Background & Problem Statement

### 3.1 Current FKKit pieces

| Piece | Location | What it does today |
|-------|----------|-------------------|
| Cell protocols | `Pluggable/UIKit/FKCellReusable.swift` | Register/dequeue + `configure(with:)` |
| Table/CV extensions | `Extension/UIKit/UITableView.swift` | `fk_reloadDataWithoutAnimation()` only |
| Refresh | `FKRefresh` | Header/footer controls, async handlers, pagination footer states |
| Pagination model | `FKRefreshPagination` | `page`, `resetForNewRequest()`, `advance()` |
| Empty state | `FKEmptyState` | Overlay on `UIScrollView` / `UIView` |
| Skeleton | `FKSkeleton` | Overlay, visible-cell helpers on table/collection |
| Divider | `FKDivider` | Row separators |

**Missing glue:** a view controller that owns diffable data source lifecycle and coordinates the above.

### 3.2 Pain matrix

| Pain | Impact |
|------|--------|
| Duplicate refresh + pagination wiring in every feed VC | High maintenance |
| Empty overlay fights scroll view content inset | UX bugs |
| Skeleton left visible after first load | Visual glitch |
| Forgetting to reset page on refresh | Duplicate page-1 rows |
| Inconsistent settings row styling | Design drift |
| Swipe actions styled ad hoc | HIG inconsistency |

---

## 4. Architectural Overview

```text
┌──────────────────────────────────────────────────────────────────┐
│ Host feature module (owns API, mapping, business rules)          │
│   implements FKListDataProviding or calls apply(snapshot:)       │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│ FKDiffableTableViewController (@MainActor)                       │
│  ┌─────────────┐  ┌──────────────────┐  ┌─────────────────────┐ │
│  │ List state  │  │ Diffable DS      │  │ FKListLoadCoordinator│ │
│  │ machine     │  │ snapshot apply   │  │ refresh/pagination   │ │
│  └─────────────┘  └──────────────────┘  └─────────────────────┘ │
│         │                  │                      │              │
│         ▼                  ▼                      ▼              │
│   FKEmptyState      UITableView            FKRefreshControl      │
│   FKSkeleton        + preset/custom cells  + FKRefreshPagination │
└──────────────────────────────────────────────────────────────────┘
```

**Control flow (typical feed):**

1. VC appears → presentation state `.initialLoading` → skeleton on table.
2. Host fetches page 1 → builds `FKListSnapshot` → `applySnapshot`.
3. Coordinator transitions to `.content`; hides skeleton; shows table rows.
4. User pulls refresh → coordinator resets `FKRefreshPagination` → fetches page 1 → replaces snapshot items.
5. User scrolls near bottom → load-more → fetch page N → **append** items; `pagination.advance()`.
6. API returns no more data → footer `noMoreData`; coordinator emits `didReachEnd`.

---

## 5. Module Boundaries

| Concern | FKUIKit `List/` | FKCoreKit |
|---------|-----------------|-----------|
| UIViewController subclasses | Yes | No |
| Diffable data sources | Yes | No |
| `FKListItem` Hashable models | Yes | Optional pure Swift helpers only if UIKit-free |
| Preset cells (UIKit) | Yes | No |
| Refresh/Empty/Skeleton wiring | Yes (integrates) | No |

**Dependency:** `FKListKit` imports `FKCoreKit` (Pluggable, Async) and sibling `FKUIKit` components. No new third-party deps.

---

## 6. Core Data Model

### 6.1 Identity types

```swift
public struct FKListItemID: Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
}

public struct FKListSectionID: Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
}
```

- Stable string IDs required for diffable identity across updates.
- Convenience literals for static sections (`"main"`, `"settings"`).

### 6.2 Item envelope

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
  public var cellTypeIdentifier: String  // registered reuse id
  public var payload: FKListItemPayload  // type-erased Sendable box
}
```

**Design rules:**

- **`preset`** — FKListKit renders with built-in cell types (§16).
- **`custom`** — host registered cell + payload; base VC dispatches `configure(with:)` via registry.

`FKListItemPayload` — type-erased `Sendable` container (similar patterns elsewhere in FKKit) with typed subscript helpers documented in README.

### 6.3 Section model

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

### 6.4 Snapshot

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

Base VC exposes:

```swift
func applySnapshot(_ snapshot: FKListSnapshot, animatingDifferences: Bool, completion: (() -> Void)?)
func applyMutation(_ mutation: FKListSnapshotMutation, animatingDifferences: Bool, completion: (() -> Void)?)
```

---

## 7. List Presentation State Machine

### 7.1 States

```swift
public enum FKListPresentationState: Equatable, Sendable {
  case initialLoading      // Before first successful snapshot
  case content             // Normal list visible
  case empty(FKEmptyStateConfiguration?)  // Zero items, not an error
  case error(FKListErrorPresentation)     // Failed load, retry available
  case refreshing          // Pull-to-refresh in flight (content may stay visible)
  case loadingNextPage     // Load-more in flight
}
```

### 7.2 Transitions (normative)

| From | Event | To |
|------|-------|-----|
| initialLoading | first snapshot with items | content |
| initialLoading | first snapshot empty | empty |
| initialLoading | fetch failed | error |
| content | pull refresh start | refreshing (optional overlay policy) |
| refreshing | success with items | content |
| refreshing | success empty | empty |
| refreshing | failure | error (or stay content + toast — config) |
| content | load-more start | loadingNextPage |
| loadingNextPage | success append | content |
| loadingNextPage | failure | content (footer error state) |
| empty | retry success | content / empty |
| error | retry success | content / empty |

### 7.3 UI mapping

| State | Table visibility | Skeleton | Empty overlay | Refresh header |
|-------|------------------|----------|---------------|----------------|
| initialLoading | hidden or zero rows | **on** | hidden | idle |
| content | visible | off | hidden | idle |
| empty | hidden or visible per policy | off | **on** | idle |
| error | hidden or dimmed | off | **on** (error phase) | idle |
| refreshing | visible | off | hidden | loading |
| loadingNextPage | visible | off | hidden | footer loading |

**Empty overlay policy** (`FKListEmptyPresentationPolicy`):

| Policy | Behavior |
|--------|----------|
| `.overlayScrollView` | `tableView.fk_applyEmptyState` — recommended default |
| `.replaceContent` | Hide table, show empty on VC view |
| `.inlineZeroRows` | Keep table, zero sections, empty centered in background |

Document default: `.overlayScrollView`.

---

## 8. FKDiffableTableViewController — Responsibilities

### 8.1 Base class contract

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

**Must own:**

- `UITableView` layout (plain style default; grouped optional via config).
- `UITableViewDiffableDataSource<FKListSectionID, FKListItemID>` (section/item IDs).
- Cell registration map (presets + host registrations).
- `FKListLoadCoordinator` for refresh/load-more tokens.
- Optional `FKRefreshControl` header/footer references.

**Must not:**

- Perform URLSession calls internally (host provides closures).
- Force specific architecture (MVVM/MVC/Viper) — callbacks only.

### 8.2 Initialization

```swift
public init(
  configuration: FKListConfiguration = .init(),
  style: UITableView.Style = .plain
)
```

Loads table edge-to-edge in VC view with safe area; respects `configuration.layout.contentInsets`.

### 8.3 Subclassing hooks

`open` methods:

- `tableView(_:configurePresetCell:at:with:)` — customize preset binding
- `registerAdditionalCells(in:)` — host custom registrations
- `makeEmptyStateConfiguration(for:)` — empty/error copy overrides

---

## 9. FKDiffableTableViewController — Data & Snapshot API

### 9.1 Host-driven loading (primary pattern)

Host implements async fetch and calls apply:

```swift
listViewController.loadInitialContent { controller in
  let items = try await api.fetchFeed(page: 1)
  let snapshot = FKListSnapshot(sections: [.init(id: "main", items: items.map(...))])
  controller.applySnapshot(snapshot, animatingDifferences: false)
}
```

### 9.2 Provider protocol (optional ergonomic layer)

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

When `dataProvider` set, base VC wires refresh/load-more automatically.

### 9.3 Diffable behavior requirements

**Must:**

- Use item IDs as diffable identity; **never** reuse IDs for different semantic entities.
- Support `animatingDifferences: true/false` on apply.
- Batch rapid mutations via `performBatchUpdates` equivalent (Diffable API).
- `reloadItems` reconfigures visible cells without full reloadData.
- Preserve selection where possible across updates (configurable).

**Should:**

- Detect duplicate item IDs in debug builds and assert/log.

### 9.4 Separator handling

Configuration:

| Mode | Behavior |
|------|----------|
| `.system` | `UITableView` default separators |
| `.fkDivider(insets:)` | Custom separator via `FKDivider` in cell layout or `layoutMargins` |
| `.none` | No separators |

Preset cells use `FKDivider` hairline between rows when `.fkDivider` selected.

---

## 10. FKDiffableTableViewController — Refresh & Pagination

### 10.1 Refresh attachment

On `viewDidLoad`, when `configuration.refresh.isPullToRefreshEnabled`:

```swift
tableView.fk_addPullToRefresh(contextAsyncAction: { [weak self] context in
  await self?.coordinator.handlePullToRefresh(context: context)
})
```

**Must on pull-to-refresh:**

1. Call `pagination.resetForNewRequest()`.
2. Cancel in-flight load-more if any (configurable).
3. Invoke host refresh handler / `dataProvider.fetchRefresh(page: 1)`.
4. Replace snapshot items (not append) for primary feed section(s).
5. End refreshing via token-safe `endRefreshing(token:)`.
6. Set footer load-more back to idle; clear `noMoreData` if new data exists.

Align with `UIScrollView+FKRefresh` helper that resets footer on refresh start.

### 10.2 Load-more attachment

When `configuration.refresh.isLoadMoreEnabled`:

```swift
tableView.fk_addLoadMore(contextAsyncAction: { ... })
```

**Must on load-more:**

1. Guard: not already loading, `hasMorePages == true`, presentation state allows.
2. Fetch with current `pagination.page` (after advance policy — see below).
3. On success: **append** items; call `pagination.advance()` **after** successful response (document order: fetch uses current page, then advance).
4. On empty page: set footer `noMoreData`; fire `didReachEnd`.
5. On failure: footer error state or silent + log (config).

**Page index convention (normative):**

- Initial load uses page `1`.
- After first success with more data available, before next request `pagination.advance()` → next call uses page `2`.
- Document explicitly in README to match `FKRefreshPagination` semantics.

### 10.3 Coordinator token safety

`FKListLoadCoordinator` **must**:

- Issue monotonic load tokens per operation type (initial / refresh / loadMore).
- Ignore stale async results when token mismatch.
- Serialize refresh vs initial if both triggered (refresh wins, cancel initial).

### 10.4 Configuration fields (`FKListRefreshConfiguration`)

| Field | Default | Purpose |
|-------|---------|---------|
| `isPullToRefreshEnabled` | true | Header |
| `isLoadMoreEnabled` | true | Footer |
| `loadMoreTriggerMode` | from `FKRefreshSettings` | automatic/manual |
| `loadMorePreloadOffset` | 0 | |
| `automaticallyEndsRefreshingOnAsyncCompletion` | true | |
| `resetsPaginationOnRefresh` | true | |
| `clearsSnapshotOnRefreshStart` | false | optional flash hide |

---

## 11. FKDiffableTableViewController — Empty, Error & Skeleton

### 11.1 Initial skeleton

When `configuration.loading.usesSkeletonForInitialLoad == true` (default **true**):

1. Enter `initialLoading`.
2. Call `tableView.fk_showVisibleCellsSkeleton` or full-table overlay per `FKListSkeletonPolicy`:
   - `.visibleCells` — uses `FKSkeleton` visible-cell API
   - `.fullOverlay` — overlay on table
   - `.presetRows(count:)` — insert placeholder snapshot with skeleton cells (advanced)

3. On first successful `applySnapshot` with `presentationState` transition to `content`/`empty`, **must** hide skeleton synchronously on main actor.

### 11.2 Empty state

When snapshot item count == 0 and not error:

- Build `FKEmptyStateConfiguration` from `configuration.empty` template + scenario.
- Apply via `tableView.fk_applyEmptyState` or VC view per policy.
- Wire retry action to `reloadInitialContent()`.

**Must** set `FKEmptyState` phase `.empty` (not `.loading`) when list is intentionally empty.

### 11.3 Error state

On fetch failure:

- Transition to `.error` with `FKListErrorPresentation` (message, underlying error description debug-only).
- Show `FKEmptyState` phase `.error` with primary retry action.
- Optional: keep last good snapshot visible under overlay (config `preservesContentOnError`).

### 11.4 Short-content empty visibility

When using overlay policy, honor `FKEmptyState` scroll helpers — `fk_updateEmptyState` on content size change if table shorter than viewport.

---

## 12. FKDiffableTableViewController — Selection & Interaction

### 12.1 Selection modes

```swift
public enum FKListSelectionMode: Sendable, Equatable {
  case none
  case single(deselectOnSecondTap: Bool = false)
  case multiple
}
```

**Must:**

- Expose `didSelectItem`, `didDeselectItem` callbacks with `FKListItemID`.
- Support programmatic selection/deselection by ID.
- Optional haptic on select (off by default).

### 12.2 Row height

| Policy | Behavior |
|--------|----------|
| `.automatic` | Self-sizing preset cells |
| `.fixed(CGFloat)` | All rows |
| `.perItem((FKListItem) -> CGFloat)` | Host closure |

### 12.3 Highlight & disabled rows

Preset items carry `isEnabled`, `isSelectable` flags — disabled rows grayed, no selection.

---

## 13. FKDiffableTableViewController — Section Headers & Footers

**Must support:**

| Style | UITableView implementation |
|-------|---------------------------|
| `.title(String)` | `titleForHeaderInSection` or custom header view |
| `.subtitle(title:subtitle:)` | Custom header view with FK typography |
| `.custom(providerID:)` | Host registers provider closure map |

**Layout:**

- Header/footer fonts/colors from `FKListAppearanceConfiguration`.
- Estimated height support for self-sizing headers.

**Pinned section headers:** respect `configuration.layout.pinsSectionHeaders` (grouped style).

---

## 14. FKDiffableTableViewController — Swipe Actions

### 14.1 Configuration model

```swift
public struct FKListSwipeActionConfiguration: Sendable, Equatable {
  public var leading: [FKListSwipeAction]
  public var trailing: [FKListSwipeAction]
  public var permitsFullSwipe: Bool  // trailing destructive full swipe
}

public struct FKListSwipeAction: Sendable, Equatable, Identifiable {
  public var id: String
  public var title: String
  public var style: FKListSwipeActionStyle  // normal, destructive, cancel
  public var icon: FKListSwipeActionIcon?   // SF Symbol name
  public var handler: @MainActor @Sendable (FKListItemID) -> Void  // type-erased wrapper in public API
}
```

**Note:** Public API may use `FKListSwipeActionHandlerRegistry` keyed by action id to keep handlers out of `Equatable` struct — document pattern in README (same as other FKKit action configs).

### 14.2 Per-item actions

Items include optional `swipeActions: FKListSwipeActionConfiguration?`.

- If nil, no swipe for row.
- Base VC implements `trailingSwipeActionsConfigurationForRowAt` / leading equivalent.

### 14.3 Styling hooks

- Destructive actions use system red styling baseline; optional FK color overrides from appearance config.
- Icons from SF Symbols when specified.

### 14.4 Accessibility

- Actions expose `accessibilityLabel` from title.
- Full swipe destructive requires confirmation config option (default **false** v1).

---

## 15. FKDiffableCollectionViewController

### 15.1 Parity with table VC

Collection base VC **must** mirror table capabilities for:

- Snapshot apply/mutation
- Presentation state machine
- Refresh + pagination (scroll view extensions)
- Empty/error/skeleton
- Selection (single/multiple)
- Data provider protocol

### 15.2 Layout presets

```swift
public enum FKListCollectionLayoutPreset: Sendable, Equatable {
  case list                       // Full-width rows, optional separators
  case grid(columns: Int, spacing: CGFloat)
  case insetGroupedList           // iOS Settings-like inset groups
  case compositional((FKListCompositionalLayoutBuilder) -> UICollectionViewCompositionalLayout)
}
```

**Must ship presets:**

- `.list` — vertical list, one item per row
- `.grid(columns:spacing:)` — uniform grid
- `.insetGroupedList` — section background inset cards

### 15.3 Supplementary views

Section headers/footers via `UICollectionView.SupplementaryRegistration` — same `FKListSectionHeaderFooter` model.

### 15.4 Collection-specific cells

Reuse preset view models where possible; collection cells are distinct types (`FKListCollectionTextCell`, etc.) sharing view models with table presets.

---

## 16. FKListCell Presets

### 16.1 Preset item models

```swift
public enum FKListPresetItem: Hashable, Sendable {
  case text(FKListTextRow)
  case subtitle(FKListSubtitleRow)
  case icon(FKListIconRow)
  case switch(FKListSwitchRow)
  case checkbox(FKListCheckboxRow)
  case disclosure(FKListDisclosureRow)
  case customValue(FKListValueRow)   // title + trailing value label
}
```

### 16.2 Row capabilities matrix

| Preset | Leading | Title | Subtitle | Trailing | Interaction |
|--------|---------|-------|----------|----------|-------------|
| **text** | — | yes | — | — | select |
| **subtitle** | — | yes | yes | — | select |
| **icon** | image/SF Symbol | yes | optional | — | select |
| **switch** | optional icon | yes | optional | `UISwitch` | switch callback |
| **checkbox** | optional | yes | optional | checkmark | toggle callback |
| **disclosure** | optional | yes | optional | chevron | select → navigate |
| **customValue** | optional | yes | optional | value text | select |

### 16.3 Visual alignment with FKKit

- Typography from `FKListAppearanceConfiguration` (title/subtitle fonts, colors).
- Minimum row height **44pt** (HIG).
- Separator inset matches `FKDivider` list preset.
- Switch rows: use `FKToggle` when shipped; until then styled `UISwitch` with FK colors from config bridge (document migration).

### 16.4 Icon row + FKImageView

When `FKImageView` is available, icon row leading image **should** use `FKImageView` for remote URLs; static `UIImage` for local.

### 16.5 Accessory types

Support `FKListAccessory` enum: none, disclosureIndicator, checkmark, customView id.

---

## 17. Custom Cells & Pluggable Conformance

### 17.1 Registration API

```swift
func register<Cell: FKListTableCellConfigurable>(
  _ cellType: Cell.Type,
  forPayloadType payloadType: Cell.Item.Type
)
```

Registry maps `cellTypeIdentifier` in `FKListCustomItem` to dequeue + typed configure.

### 17.2 FKListTableCellConfigurable

Existing protocol — preset cells **should also conform** for unified code paths.

### 17.3 Host cell rules

- `configure(with:)` must be synchronous — no network in configure.
- Use `FKImageView` in custom cells for async images.
- Call `prepareForReuse` patterns in `configure` (reset images, cancel loads).

---

## 18. Configuration Model

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

### 18.1 Key layout fields

| Field | Purpose |
|-------|---------|
| `contentInsets` | Additional table insets |
| `separatorMode` | §9.4 |
| `rowHeightPolicy` | §12.2 |
| `sectionHeaderTopPadding` | Grouped style spacing |
| `pinsSectionHeaders` | Grouped |

### 18.2 Key appearance fields

| Field | Purpose |
|-------|---------|
| `titleTextStyle` / `subtitleTextStyle` | Dynamic Type friendly |
| `separatorColor` | FKDivider color |
| `selectedBackgroundColor` | |
| `sectionHeaderFont` | |

---

## 19. Delegate & Lifecycle Hooks

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

All methods optional via protocol extension defaults.

**Coordinator callbacks** fire on main actor only.

---

## 20. Search-Driven Lists

FKListKit does not ship `FKSearchBar` (parallel release) but **must** document integration:

```swift
// Host debounces search, builds filtered snapshot, applies:
listController.applySnapshot(filtered, animatingDifferences: true)
```

Optional `FKListSearchConfiguration`:

- `clearsSelectionOnSearch` 
- empty state scenario `.noSearchResult` when filter yields zero

When `FKSearchBar` ships, Example demonstrates embedding in `navigationItem.titleView`.

---

## 21. Prefetching & Performance

### 21.1 UITableViewDataSourcePrefetching

Base VC **should** conform forwarding protocol when `configuration.prefetch.isEnabled`:

- Host supplies `prefetchItems(at:)` / `cancelPrefetching(at:)` via delegate.
- Document pairing with `FKImageLoader.prefetch` for image rows.

### 21.2 Snapshot apply performance

- Avoid full snapshot replace on load-more — use `appendItems` mutation.
- Debounce non-critical applies (search) via host; FKListKit provides no debounce internally.
- Large snapshots (1000+ items): document `animatingDifferences: false` for batch imports.

### 21.3 Memory

- Diffable data source holds item IDs only in snapshot; payloads in parallel dictionary if needed — document **host responsibility** to avoid retaining heavy objects in cells.

---

## 22. Accessibility

**Must:**

- Preset cells set accessibility traits: switch → `.button`, static text → combined label from title+subtitle.
- Section headers: `accessibilityHeader` trait on header views.
- Swipe actions: system accessibility covers standard actions; custom titles required.
- Empty/error overlays: inherit `FKEmptyState` accessibility behavior.
- Announce refresh completion optionally (config, default false).

**Dynamic Type:** preset cells support scaling title/subtitle fonts from appearance config using `UIFontMetrics`.

---

## 23. SwiftUI Bridge (Phase 2)

Not required for v1. Plan for a later release:

- `FKListRepresentable` hosting table VC in SwiftUI.
- Or cell content builders for `List` — evaluate after UIKit MVP stable.

---

## 24. Proposed Source Layout

```text
Sources/FKUIKit/Components/List/
├── README.md
├── Public/
│   ├── Core/
│   │   ├── FKListSnapshot.swift
│   │   ├── FKListSection.swift
│   │   ├── FKListItem.swift
│   │   ├── FKListPresentationState.swift
│   │   └── FKListFetchResult.swift
│   ├── Table/
│   │   ├── FKDiffableTableViewController.swift
│   │   └── FKListTableViewController+PublicAPI.swift
│   ├── Collection/
│   │   └── FKDiffableCollectionViewController.swift
│   ├── Cells/
│   │   ├── Table/                     # preset cells
│   │   └── Collection/
│   ├── Configuration/
│   │   └── FKListConfiguration.swift (+ split files)
│   ├── Swipe/
│   │   └── FKListSwipeActionConfiguration.swift
│   ├── Protocols/
│   │   ├── FKListDataProviding.swift
│   │   └── FKListDelegate.swift
│   └── Bridge/                        # future SwiftUI
├── Internal/
│   ├── FKListLoadCoordinator.swift
│   ├── FKListDiffableDataSource.swift
│   ├── FKListCellRegistry.swift
│   ├── FKListSnapshotApplier.swift
│   └── FKListEmptyStateCoordinator.swift
└── Extension/
    └── FKListItem+Convenience.swift
```

Add `Components/List` to `Package.swift` `readmeExcludes`.

---

## 25. FKKitExamples Scenarios

Path: `Examples/.../FKUIKit/List/`

| # | Scenario | Validates |
|---|----------|-----------|
| 1 | `FeedRefreshLoadMore` | Pull refresh + infinite scroll + pagination |
| 2 | `SettingsMultisection` | Sections, headers, switch/disclosure presets |
| 3 | `EmptyState` | Zero results empty overlay |
| 4 | `ErrorRetry` | Failed initial load + retry |
| 5 | `SkeletonInitialLoad` | Skeleton until first snapshot |
| 6 | `SwipeActions` | Trailing destructive + leading pin |
| 7 | `CustomCell` | `FKListTableCellConfigurable` host cell |
| 8 | `CollectionGrid` | Grid preset |
| 9 | `SearchFilter` | Debounced filter snapshot (with FKSearchBar when available) |
| 10 | `IconRemoteRow` | Preset icon row + FKImageView |

---

## 27. Open Questions

| ID | Question | Proposed default |
|----|----------|------------------|
| Q1 | Single folder `List/` vs split `List/` + `ListCells/`? | Single `List/` with `Cells/` subfolder |
| Q2 | Store item payloads in snapshot vs side table? | Side dictionary keyed by `FKListItemID` to keep snapshot Hashable light |
| Q3 | Grouped vs plain default style? | `.plain` default; grouped via config |
| Q4 | Include `FKSkeletonTableViewCell` placeholder snapshot approach? | Prefer visible-cell skeleton overlay for v1 |
| Q5 | Collection VC same class hierarchy as table? | Separate classes sharing `FKListLoadCoordinator` |

---

## 28. Revision History

| Date | Change |
|------|--------|
| 2026-06-08 | Initial design requirements from COMPONENT_ROADMAP §1.2 |

---

## Related Documents

- [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) — program roadmap
- [FKImageLoader-FKImageView_DESIGN.md](FKImageLoader-FKImageView_DESIGN.md) — image row integration
- [Pluggable FKCellReusable](../Sources/FKCoreKit/Components/Pluggable/UIKit/FKCellReusable.swift)
- [FKRefresh README](../Sources/FKUIKit/Components/Refresh/README.md)
- [FKEmptyState README](../Sources/FKUIKit/Components/EmptyState/README.md)
- [FKSkeleton README](../Sources/FKUIKit/Components/Skeleton/README.md)
