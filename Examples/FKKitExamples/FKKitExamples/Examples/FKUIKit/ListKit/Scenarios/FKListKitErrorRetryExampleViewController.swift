import FKUIKit
import UIKit

/// Demonstrates error presentation and retry via ``reloadInitialContent()``.
final class FKListKitErrorRetryExampleViewController: FKDiffableTableViewController, FKListDataProviding {
  private var hasFailedOnce = true

  init() {
    var config = FKListDefaults.defaultConfiguration
    config.error.preservesContentOnError = false
    config.error.overridesTitle = "Unable to load"
    config.error.overridesPrimaryActionTitle = "Retry"
    config.refresh.isPullToRefreshEnabled = false
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
    title = "Error & Retry"
  }

  func fetchInitial(page: Int) async throws -> FKListFetchResult {
    try await Task.sleep(nanoseconds: 700_000_000)
    if hasFailedOnce {
      hasFailedOnce = false
      throw NSError(domain: "FKListKitExample", code: 1, userInfo: [
        NSLocalizedDescriptionKey: "Simulated network failure. Tap Retry on the overlay.",
      ])
    }
    let result = try await FKListKitExampleFeedAPI.fetch(page: 1, delay: 0.3)
    return FKListKitExampleFeedAPI.makeFetchResult(titles: result.titles, page: 1, hasMorePages: false)
  }

  func fetchNextPage(after pagination: FKRefreshPagination) async throws -> FKListFetchResult {
    FKListFetchResult(snapshot: FKListSnapshot(), hasMorePages: false)
  }

  func fetchRefresh(page: Int) async throws -> FKListFetchResult {
    try await fetchInitial(page: page)
  }
}
