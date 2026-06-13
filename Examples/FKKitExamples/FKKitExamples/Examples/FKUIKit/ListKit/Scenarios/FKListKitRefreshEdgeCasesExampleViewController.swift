import FKUIKit
import UIKit

/// Demonstrates refresh edge options: clear snapshot on refresh start and keep content on refresh failure.
final class FKListKitRefreshEdgeCasesExampleViewController: FKDiffableTableViewController, FKListDataProviding {
  private var shouldFailRefresh = true
  private var statusLabel: UILabel!

  init() {
    var config = FKListDefaults.defaultConfiguration
    config.refresh.clearsSnapshotOnRefreshStart = true
    config.refresh.refreshFailureKeepsContent = true
    config.refresh.isLoadMoreEnabled = false
    config.error.overridesTitle = "Refresh failed"
    config.error.overridesPrimaryActionTitle = "Retry"
    super.init(configuration: config)
    dataProvider = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    statusLabel = FKListKitExampleStatusStrip.install(on: self, above: tableView)
    title = "Refresh Edge Cases"
    super.viewDidLoad()
  }

  func fetchInitial(page: Int) async throws -> FKListFetchResult {
    let result = try await FKListKitExampleFeedAPI.fetch(page: 1, delay: 0.5)
    return FKListKitExampleFeedAPI.makeFetchResult(titles: result.titles, page: 1, hasMorePages: false)
  }

  func fetchNextPage(after pagination: FKRefreshPagination) async throws -> FKListFetchResult {
    FKListFetchResult(snapshot: FKListSnapshot(), hasMorePages: false)
  }

  func fetchRefresh(page: Int) async throws -> FKListFetchResult {
    FKListKitExampleStatusStrip.append("fetchRefresh started (snapshot cleared)", to: statusLabel)
    try await Task.sleep(nanoseconds: 700_000_000)
    if shouldFailRefresh {
      shouldFailRefresh = false
      throw NSError(domain: "FKListKitExample", code: 3, userInfo: [
        NSLocalizedDescriptionKey: "First refresh fails; prior rows return because refreshFailureKeepsContent is true.",
      ])
    }
    let result = try await FKListKitExampleFeedAPI.fetch(page: 1, delay: 0.3)
    FKListKitExampleStatusStrip.append("fetchRefresh succeeded", to: statusLabel)
    return FKListKitExampleFeedAPI.makeFetchResult(titles: result.titles, page: 1, hasMorePages: false)
  }
}
