import FKUIKit
import UIKit

/// Demonstrates ``FKListWindowingConfiguration`` trimming oldest items during load-more.
final class FKListKitWindowingExampleViewController: FKDiffableTableViewController, FKListDataProviding {
  private var statusLabel: UILabel!

  init() {
    var config = FKListDefaults.feedConfiguration
    config.windowing = FKListWindowingConfiguration(isEnabled: true, maxItemCount: 24)
    config.refresh.loadMorePreloadOffset = 120
    super.init(configuration: config)
    dataProvider = self
    delegate = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    statusLabel = FKListKitExampleStatusStrip.install(on: self, above: tableView)
    title = "Windowing"
    super.viewDidLoad()
  }

  func fetchInitial(page: Int) async throws -> FKListFetchResult {
    let result = try await FKListKitExampleFeedAPI.fetch(page: page, itemsPerPage: 12)
    return FKListKitExampleFeedAPI.makeFetchResult(titles: result.titles, page: page, hasMorePages: result.hasMorePages)
  }

  func fetchNextPage(after pagination: FKRefreshPagination) async throws -> FKListFetchResult {
    let result = try await FKListKitExampleFeedAPI.fetch(page: pagination.nextPage, itemsPerPage: 12)
    return FKListKitExampleFeedAPI.makeFetchResult(
      titles: result.titles,
      page: pagination.nextPage,
      hasMorePages: result.hasMorePages
    )
  }

  func fetchRefresh(page: Int) async throws -> FKListFetchResult {
    try await fetchInitial(page: page)
  }
}

extension FKListKitWindowingExampleViewController: FKListDelegate {
  func list(_ list: FKDiffableTableViewController, didLoadPage page: Int, result: FKListFetchResult) {
    FKListKitExampleStatusStrip.append(
      "page \(page) · in-memory=\(currentSnapshot.totalItemCount) (cap \(configuration.windowing.maxItemCount))",
      to: statusLabel
    )
  }
}
