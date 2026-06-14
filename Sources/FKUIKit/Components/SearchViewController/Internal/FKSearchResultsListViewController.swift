import UIKit

/// Internal list child that forwards empty/error retry to ``FKSearchViewController/retryCurrentSearch()``.
@MainActor
final class FKSearchResultsListViewController: FKDiffableTableViewController {
  weak var searchHost: FKSearchViewController?

  override func reloadInitialContent() {
    if let searchHost {
      searchHost.retryCurrentSearch()
    } else {
      super.reloadInitialContent()
    }
  }

  override func makeEmptyStateConfiguration(for state: FKListPresentationState) -> FKEmptyStateConfiguration? {
    searchHost?.emptyConfiguration(for: state) ?? super.makeEmptyStateConfiguration(for: state)
  }
}
