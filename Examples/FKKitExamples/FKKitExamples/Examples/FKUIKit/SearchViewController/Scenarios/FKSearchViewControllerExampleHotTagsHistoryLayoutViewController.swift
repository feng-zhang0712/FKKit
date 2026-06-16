import FKUIKit
import UIKit

/// Hot tags + history on the entry page; tabbed results pushed on a separate screen.
///
/// Illustrates host-handled navigation — the search VC owns input and idle chrome; the host pushes
/// a custom results page (``FKPagingController`` ``FKPagingTabBarPlacement/contentTop``).
final class FKSearchViewControllerExampleHotTagsHistoryLayoutViewController: FKSearchViewController {
  private let historyStore = FKSearchViewControllerExampleSearchHistoryStore()

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
    let idle = FKSearchViewControllerExampleHotTagsIdleViewController(historyStore: historyStore)
    idle.onSelectTerm = { [weak self] term in
      self?.setQuery(term, options: .withSearchQuery)
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
    title = "Hot Tags + History"

    callbacks.onHostSearchRequested = { [weak self] query, _ in
      self?.pushResults(for: query)
    }
  }

  private func pushResults(for query: String) {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    if let top = navigationController?.topViewController
      as? FKSearchViewControllerExampleHostPushedTabbedResultsViewController,
      top.query.caseInsensitiveCompare(trimmed) == .orderedSame {
      return
    }

    historyStore.record(trimmed)
    navigationController?.pushViewController(
      FKSearchViewControllerExampleHostPushedTabbedResultsViewController(query: trimmed),
      animated: true
    )
  }
}
