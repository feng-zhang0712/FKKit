import FKUIKit
import UIKit

/// Demonstrates host-driven ``loadInitialContent(handler:)`` without ``FKListDataProviding``.
final class FKListKitHostDrivenLoadExampleViewController: FKDiffableTableViewController {
  init() {
    var config = FKListDefaults.defaultConfiguration
    config.refresh.isPullToRefreshEnabled = false
    config.refresh.isLoadMoreEnabled = false
    config.loading.usesSkeletonForInitialLoad = true
    super.init(configuration: config)
    hostReloadHandler = { controller in
      let result = try await FKListKitExampleFeedAPI.fetch(page: 1, delay: 1.0)
      let snapshot = FKListKitExampleFeedAPI.makeSnapshot(titles: result.titles, page: 1)
      controller.applySnapshot(snapshot, animatingDifferences: false)
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Host-Driven Load"
    if let hostReloadHandler {
      loadInitialContent(handler: hostReloadHandler)
    }
  }
}
