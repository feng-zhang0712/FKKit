# FKListKit

Diffable list infrastructure for FKUIKit: section/item models, table and collection view controllers, preset cells, swipe actions, and integration with **FKRefresh**, **FKEmptyState**, and **FKSkeleton**.

## Requirements

- iOS 15+
- Swift 6
- FKCoreKit (Pluggable cell protocols)
- FKUIKit: Refresh, EmptyState, Skeleton, Divider, ImageView

## Directory map

| Path | Responsibility |
|------|----------------|
| `Public/Core/` | `FKListItem`, `FKListSection`, `FKListSnapshot`, presentation state |
| `Public/Configuration/` | Layered `FKListConfiguration` and defaults |
| `Public/Presets/` | Built-in row models (`FKListPresetItem`, text/switch/disclosure, …) |
| `Public/Protocols/` | `FKListDataProviding`, `FKListDelegate` |
| `Public/Swipe/` | Swipe action models and handler registries |
| `Public/Table/` | `FKDiffableTableViewController` |
| `Public/Collection/` | `FKDiffableCollectionViewController`, layout presets |
| `Public/Cells/Table/` | `FKListPresetTableCell`, section header/footer views |
| `Public/Cells/Collection/` | `FKListPresetCollectionCell` |
| `Internal/` | Load coordinator, cell registry, snapshot applier, presentation coordinator |
| `Extension/` | Convenience builders for items and snapshots |

## Quick start (table)

```swift
final class FeedViewController: FKDiffableTableViewController, FKListDataProviding {
  init() {
    super.init(configuration: FKListDefaults.defaultConfiguration)
    dataProvider = self
  }

  func fetchInitial(page: Int) async throws -> FKListFetchResult {
    let dtos = try await api.fetch(page: page)
    let items = dtos.map { FKListItem.text(id: $0.id, title: $0.title) }
    return FKListFetchResult(snapshot: FKListSnapshot(items: items), hasMorePages: dtos.count >= 20)
  }

  func fetchNextPage(after pagination: FKRefreshPagination) async throws -> FKListFetchResult { /* … */ }
  func fetchRefresh(page: Int) async throws -> FKListFetchResult { /* … */ }
}
```

## Pagination convention

- Initial and refresh requests use `pagination.page` (starts at **1**).
- Call `pagination.advance()` **after** a successful load-more response.
- Pull-to-refresh calls `pagination.resetForNewRequest()`.

## Custom cells

```swift
register(MyCell.self, forPayloadType: MyModel.self)
setPayload(FKListItemPayload(myModel), for: itemID)
applySnapshot(FKListSnapshot(items: [.custom(id: itemID, cellTypeIdentifier: "MyCell")]))
```

## Examples

FKKitExamples hub: `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/ListKit/Hub/FKListKitExamplesHubViewController.swift`

The hub lists every runnable scenario (feed, refresh edge cases, skeleton policies, empty/error variants, collection layouts, delegate hooks, and more). Key entry points:

| Scenario | Demonstrates |
|----------|----------------|
| Feed · refresh & load more | `FKListDataProviding`, pagination, delegate |
| Refresh edge cases | `clearsSnapshotOnRefreshStart`, `refreshFailureKeepsContent` |
| Host-driven initial load | `loadInitialContent(handler:)` |
| Snapshot mutations | All `applyMutation` variants including `insertItems` and `replace` |
| Skeleton / empty / error | Presentation state machine; both skeleton policies |
| Settings · presets | All `FKListPresetItem` cases, asset leading, accessories, metadata |
| Swipe / selection / search | Interaction APIs; `FKListDelegate` selection callbacks |
| Row height / advanced hooks | `rowHeightProvider`, `configurePresetCell`, `makeEmptyStateConfiguration` |
| Collection layouts | `.list`, `.grid`, `.insetGroupedList`, layout hints, custom cells, delegate |

## Table vs collection

| Capability | Table | Collection |
|------------|-------|------------|
| Swipe actions | Yes | Not yet — registry is reserved |
| Section footer | Yes | Not yet — use headers or custom supplementary views |
| Row separators (`FKDivider`) | Yes | N/A (layout-driven spacing) |
| `configurePresetCell` / `rowHeightProvider` | Yes | Collection uses compositional estimated heights |

## Related

- Design: `docs/FKListKit_DESIGN.md`
- Pluggable: `Sources/FKCoreKit/Components/Pluggable/`
