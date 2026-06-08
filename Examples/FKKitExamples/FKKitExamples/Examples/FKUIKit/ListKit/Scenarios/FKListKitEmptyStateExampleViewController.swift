import FKUIKit
import UIKit

/// Demonstrates intentional empty list overlay via zero-item snapshot.
final class FKListKitEmptyStateExampleViewController: FKDiffableTableViewController, FKListDataProviding {
  init() {
    var config = FKListDefaults.defaultConfiguration
    config.empty.scenario = .noSearchResult
    config.empty.overridesTitle = "No posts yet"
    config.empty.overridesMessage = "Pull to refresh or tap Retry when content arrives."
    config.refresh.isLoadMoreEnabled = false
    super.init(configuration: config)
    dataProvider = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Empty State"
  }

  func fetchInitial(page: Int) async throws -> FKListFetchResult {
    try await Task.sleep(nanoseconds: 600_000_000)
    return FKListFetchResult(snapshot: FKListSnapshot(), hasMorePages: false)
  }

  func fetchNextPage(after pagination: FKRefreshPagination) async throws -> FKListFetchResult {
    FKListFetchResult(snapshot: FKListSnapshot(), hasMorePages: false)
  }

  func fetchRefresh(page: Int) async throws -> FKListFetchResult {
    let result = try await FKListKitExampleFeedAPI.fetch(page: 1, delay: 0.5)
    return FKListKitExampleFeedAPI.makeFetchResult(titles: result.titles, page: 1, hasMorePages: false)
  }
}
