import FKUIKit
import UIKit

/// Host-handled results: Search VC orchestrates input; host pushes a separate results screen.
final class FKSearchViewControllerExampleHostHandledPushViewController: FKSearchViewController {
  init() {
    var config = FKSearchViewControllerDefaults.localFilter(placement: .stickyHeader)
    config.presentation = .customIdleHostHandledResults
    super.init(configuration: config, placeholder: "Search then push results")
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func makeSearchContentViewController() -> UIViewController? {
    FKSearchViewControllerExampleDiscoveryViewController(
      titleText: "Tap a suggestion or type to search",
      items: ["Swift", "Python", "Ruby"]
    ) { [weak self] term in
      self?.setQuery(term, options: .withSearchQuery)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Host-Handled Push"
    callbacks.onHostSearchRequested = { [weak self] query, _ in
      self?.navigationController?.pushViewController(
        FKSearchViewControllerExamplePushedResultsViewController(query: query),
        animated: true
      )
    }
  }
}

/// Standalone results page pushed by the host (WeChat-style separation).
final class FKSearchViewControllerExamplePushedResultsViewController: FKDiffableTableViewController {
  private let query: String

  init(query: String) {
    self.query = query
    let config = FKSearchViewControllerDefaults.makeListConfiguration()
    super.init(configuration: config)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Results"
    let snapshot = FKSearchViewControllerExampleSupport.filteredFruitSnapshot(for: query)
    applySnapshot(snapshot, animatingDifferences: false)
  }
}
