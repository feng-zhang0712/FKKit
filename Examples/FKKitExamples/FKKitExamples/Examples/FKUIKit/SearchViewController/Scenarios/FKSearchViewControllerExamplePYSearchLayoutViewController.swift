import FKUIKit
import UIKit

/// PYSearch-style demo: hot tags + history on the entry page; tabbed results pushed on a separate screen.
///
/// Illustrates host-handled navigation — the search VC owns input and idle chrome; the host pushes
/// a custom results page (``FKPagingController`` ``FKPagingTabBarPlacement/contentTop``).
final class FKSearchViewControllerExamplePYSearchLayoutViewController: FKSearchViewController {
  private let historyStore = FKSearchViewControllerExamplePYSearchHistoryStore()

  init() {
    var config = FKSearchViewControllerDefaults.localFilter(placement: .stickyHeader)
    config.presentation = .customIdleHostHandledResults
    config.behavior.focusesSearchOnAppear = true
    super.init(configuration: config, placeholder: "Search programming languages")
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func makeSearchContentViewController() -> UIViewController? {
    let idle = FKSearchViewControllerExamplePYSearchIdleViewController(historyStore: historyStore)
    idle.onSelectTerm = { [weak self] term in
      self?.searchBar.setText(term, options: .silent)
      self?.pushResults(for: term)
    }
    idle.onDeleteHistory = { [weak self] index in
      self?.historyStore.remove(at: index)
    }
    idle.onClearHistory = { [weak self] in
      self?.historyStore.removeAll()
    }
    return idle
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "PYSearch Layout"

    // Entry page stays on idle chrome; navigate only on Return / suggestion tap (not while typing).
    searchBar.callbacks.onSearchQueryChanged = { _ in }

    callbacks.onHostSearchRequested = { [weak self] query, _ in
      self?.pushResults(for: query)
    }
  }

  private func pushResults(for query: String) {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    if let top = navigationController?.topViewController
      as? FKSearchViewControllerExamplePYSearchPushedResultsViewController,
      top.query.caseInsensitiveCompare(trimmed) == .orderedSame {
      return
    }

    historyStore.record(trimmed)
    navigationController?.pushViewController(
      FKSearchViewControllerExamplePYSearchPushedResultsViewController(query: trimmed),
      animated: true
    )
  }
}
