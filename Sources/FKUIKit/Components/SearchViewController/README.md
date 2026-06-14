# FKSearchViewController

Composable search page for FKUIKit: orchestrates **FKSearchBar**, **FKListKit**, **FKEmptyState**, and optional **FKSkeleton** for local filter or remote async search flows.

## Requirements

- iOS 15+
- Swift 6
- FKCoreKit
- FKUIKit: SearchBar, ListKit, EmptyState, Skeleton

## Directory map

| Path | Responsibility |
|------|----------------|
| `Public/FKSearchViewController.swift` | Root view controller; placement, state machine, provider wiring |
| `Public/FKSearchViewControllerConfiguration.swift` | Layered configuration and `FKSearchViewControllerDefaults` |
| `Public/FKSearchMode.swift` | Local filter vs remote search |
| `Public/FKSearchBarPlacement.swift` | Navigation bar, sticky header, table header |
| `Public/FKSearchPresentationState.swift` | idle / editing / loading / results / empty / error |
| `Public/FKSearchLocalFilterProviding.swift` | In-memory filter protocol |
| `Public/FKSearchResultsProviding.swift` | Async remote search protocol |
| `Public/FKSearchViewControllerCallbacks.swift` | Closure-first API |
| `Public/FKSearchViewControllerDelegate.swift` | Optional delegate |
| `Public/FKSearchError.swift` | Provider and cancellation errors |
| `Internal/FKSearchSessionCoordinator.swift` | Task cancel and stale-result guard |
| `Internal/FKSearchChromeContainerView.swift` | Sticky header chrome layout |
| `Internal/FKSearchTableHeaderInstaller.swift` | Frame-managed `tableHeaderView` helper |
| `Internal/FKSearchResultsListViewController.swift` | List child forwarding retry to search VC |
| `Extension/FKSearchViewController+ListDelegate.swift` | Selection forwarding |

## When to use

| Need | Use |
|------|-----|
| Compact filter row inside a form/list row | `FKSearchField` + host-driven `applySnapshot` |
| Full search page with results list | **`FKSearchViewController`** |
| Search in navigation bar, results elsewhere | `FKSearchBar` + `FKSearchBarNavigationHosting` |
| System `UISearchController` large-title behavior | Not provided — use placement configuration |

## Quick start (local filter)

```swift
final class ProductSearchViewController: FKSearchViewController, FKSearchLocalFilterProviding {
  private let baseline: FKListSnapshot

  init(items: [FKListItem]) {
    baseline = FKListSnapshot(items: items)
    super.init(configuration: .localFilter(), placeholder: "Search products")
    localFilterProvider = self
  }

  var baselineSnapshot: FKListSnapshot { baseline }

  func filteredSnapshot(for query: String) -> FKListSnapshot {
    let filtered = baseline.sections.flatMap(\.items).filter { item in
      guard case .preset(.subtitle(let row)) = item.kind else { return false }
      return row.title.localizedCaseInsensitiveContains(query)
    }
    return FKListSnapshot(items: filtered)
  }
}
```

## Quick start (remote)

```swift
final class RemoteSearchViewController: FKSearchViewController {
  init() {
    super.init(configuration: FKSearchViewControllerDefaults.remote(), placeholder: "Search")
    resultsProvider = self
  }
}

extension RemoteSearchViewController: FKSearchResultsProviding {
  func search(query: String) async throws -> FKSearchResultsResponse {
    let dtos = try await api.search(query)
    let items = dtos.map { FKListItem.text(id: $0.id, title: $0.title) }
    return FKSearchResultsResponse(snapshot: FKListSnapshot(items: items))
  }
}
```

## Subclass hooks

- `makeListViewController()` — custom cells and list configuration
- `configureSearchBar(_:)` — extra setup after default wiring
- `emptyConfiguration(for:)` — override empty/error copy
- `willPerformSearch(query:)` — logging or analytics
- `retryCurrentSearch()` — re-run current query (error CTA)

## Navigation bar notes

- The controller sets `navigationItem.largeTitleDisplayMode = .never` to avoid layout conflicts with search chrome.
- Avoid `navigationItem.prompt` on iOS 18+ when using sticky or table-header placement — it can corrupt the navigation bar (black trailing artifact). Use in-content captions or the Examples hub subtitles instead.

## Examples

FKKitExamples hub: `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/SearchViewController/Hub/FKSearchViewControllerExamplesHubViewController.swift`

| Scenario | Demonstrates |
|----------|----------------|
| Local · sticky / table header / navigation bar | `FKSearchMode`, `FKSearchBarPlacement`, `FKSearchLocalFilterProviding` |
| Remote · loading & cancel | `FKSearchResultsProviding`, loading skeleton, stale-result guard |
| Remote · error & retry | `FKSearchError`, `retryCurrentSearch()` |
| Remote · idle placeholder | `showsResultsOnEmptyQuery`, `remoteIdleSnapshot` |
| Empty · no results | `FKEmptyStateScenario.noSearchResult` |
| Cancel policies | `cancelRestoresBaseline` true/false |
| Focus / minimum query length | `focusesSearchOnAppear`, `minimumQueryLengthForSearchCallback` |
| Custom list cells | `makeListViewController()`, cell registration |
| Custom empty copy | `emptyConfiguration(for:)` |
| Callbacks / delegate | `FKSearchViewControllerCallbacks`, `FKSearchViewControllerDelegate`, `setQuery` |

## Design reference

See `docs/FKSearchViewController_DESIGN.md` for the full state machine, placement notes, and roadmap.
