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
| `Public/Core/` | `FKListItem`, `FKListSection`, `FKListSnapshot`, presentation state, prefetch helper |
| `Public/Configuration/` | Layered `FKListConfiguration`, animation/layout defaults |
| `Public/Presets/` | Built-in row models (`FKListPresetItem`, text/switch/disclosure, …) |
| `Public/Protocols/` | `FKListDataProviding`, `FKListDelegate` |
| `Public/Swipe/` | Swipe action models and handler registries |
| `Public/Table/` | `FKDiffableTableViewController` |
| `Public/Collection/` | `FKDiffableCollectionViewController`, layout presets |
| `Public/Cells/Table/` | `FKListPresetTableCell`, skeleton placeholder, section header/footer |
| `Public/Cells/Collection/` | `FKListPresetCollectionCell` |
| `Internal/` | Load coordinator, cell registry, snapshot applier, presentation coordinator |
| `Public/Bridge/` | SwiftUI `FKDiffable*ViewControllerRepresentable` |
| `Extension/` | Convenience builders, diffable apply helpers |

## Quick start (feed)

```swift
final class FeedViewController: FKDiffableTableViewController, FKListDataProviding {
  init() {
    super.init(configuration: FKListDefaults.feedConfiguration)
    dataProvider = self
    delegate = self
  }
  // …
}

extension FeedViewController: FKListDelegate {
  func list(_ list: FKDiffableTableViewController, prefetchItems ids: [FKListItemID]) {
    FKListImagePrefetchHelper.prefetchLeadingIcons(
      ids: ids,
      in: currentSnapshot,
      targetSize: CGSize(width: 44, height: 44)
    )
  }
}
```

## Quick start (data provider)

```swift
final class ProductListViewController: FKDiffableTableViewController, FKListDataProviding {
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

## Custom cells

```swift
register(MyCell.self, forPayloadType: MyModel.self)
setPayload(FKListItemPayload(myModel), for: itemID)
applySnapshot(FKListSnapshot(items: [
  .custom(id: itemID, cellTypeIdentifier: String(describing: MyCell.self))
]))
```

## Pagination convention

- Initial and refresh requests use `pagination.page` (starts at **1**).
- Call `pagination.advance()` **after** a successful load-more response.
- Pull-to-refresh calls `pagination.resetForNewRequest()`.

## v4 scale APIs

| API | Use |
|-----|-----|
| `FKListWindowingConfiguration` | Cap in-memory item count for long feeds |
| `FKDiffableTableViewControllerRepresentable` | SwiftUI embedding |
| `FKDiffableCollectionViewControllerRepresentable` | SwiftUI collection embedding |
| Collection swipe actions | Same `FKListSwipeActionConfiguration` as table |
| `fk_applyDiffableDataSourceSnapshot` | Explicit diffable apply on scroll views |

## v3 performance APIs

| API | Use |
|-----|-----|
| `FKListImagePrefetchProviding` | Custom payload prefetch contract |
| `FKListImagePrefetchHelper.prefetchImages` | Preset icons + custom payloads |
| `FKListHeightCache` | Width-keyed dynamic row height cache |
| `FKListVideoVisibilityCoordinator` | Optional video auto-play with scroll forwarding |
| `payload(for:)` | Read custom payloads for prefetch/mutations |
| `FKListSkeletonPolicy.presetRows` | Table **and** collection placeholder cells |

## v2 performance APIs

| API | Use |
|-----|-----|
| `FKListDefaults.feedConfiguration` | Prefetch on, no load-more animation, taller estimates |
| `FKListAnimationConfiguration` | `defaultRowAnimation`, `animatesLoadMoreDifferences` |
| `FKListSnapshotMutation.reconfigureItems` | Lightweight in-place cell refresh |
| `FKListDelegate` `willDisplay` / `didEndDisplaying` | Video pause, exposure, off-screen cancel |
| `FKListImagePrefetchHelper` | Icon-row prefetch with `FKImageLoader` |

## Examples

FKKitExamples hub: `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/ListKit/Hub/FKListKitExamplesHubViewController.swift`

The hub lists every runnable scenario (feed, refresh edge cases, skeleton policies, empty/error variants, collection layouts, delegate hooks, and more). Key entry points:

| Scenario | Demonstrates |
|----------|----------------|
| Windowing | `FKListWindowingExampleViewController` |
| SwiftUI bridge | `FKDiffableTableViewControllerRepresentable` |
| Collection · swipe actions | Collection `FKListSwipeActionConfiguration` |
| Feed · complex reference | Full v2+v3 integration path for production-like feeds |
| Collection · skeleton preset rows | Collection `presetRows` placeholder cells |
| Feed · optimized | `FKListDefaults.feedConfiguration`, load-more without animation |
| Cell visibility | `willDisplay` / `didEndDisplaying` delegate hooks |
| Reconfigure items | `reconfigureItems` mutation |
| Skeleton · preset rows | `FKListSkeletonPolicy.presetRows(count:)` |
| Feed · refresh & load more | `FKListDataProviding`, pagination, delegate |
| Refresh edge cases | `clearsSnapshotOnRefreshStart`, `refreshFailureKeepsContent` |
| Host-driven initial load | `loadInitialContent(handler:)` |
| Snapshot mutations | All `applyMutation` variants including `insertItems` and `replace` |
| Skeleton / empty / error | Presentation state machine; both skeleton policies |
| Settings · presets | All `FKListPresetItem` cases, asset leading, accessories, metadata |
| Swipe / selection / search | Interaction APIs; `FKListDelegate` selection callbacks |
| SearchViewController · integration | `FKSearchViewController` + remote icon rows + prefetch (recommended over raw `UISearchBar`) |
| Row height / advanced hooks | `rowHeightProvider`, `configurePresetCell`, `makeEmptyStateConfiguration` |
| Collection layouts | `.list`, `.grid`, `.insetGroupedList`, layout hints, custom cells, delegate |

## Table vs collection

| Capability | Table | Collection |
|------------|-------|------------|
| Swipe actions | Yes | Yes |
| Section footer | Yes | Not yet — use headers or custom supplementary views |
| Row separators (`FKDivider`) | Yes | N/A (layout-driven spacing) |
| `configurePresetCell` / `rowHeightProvider` | Yes | Collection uses compositional estimated heights |

## Related

- Search pages: `Sources/FKUIKit/Components/SearchViewController/` — embeds `FKDiffableTableViewController` via `makeListViewController()`
- Design: `docs/FKListKit_DESIGN.md`
- Roadmap: `docs/FKListKit_ROADMAP.md`
- Pluggable: `Sources/FKCoreKit/Components/Pluggable/`
