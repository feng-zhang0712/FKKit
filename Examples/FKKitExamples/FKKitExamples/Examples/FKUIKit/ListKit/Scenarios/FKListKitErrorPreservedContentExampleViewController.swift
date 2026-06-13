import FKUIKit
import UIKit

/// Demonstrates ``FKListErrorConfiguration/preservesContentOnError`` keeping list rows under the error overlay.
final class FKListKitErrorPreservedContentExampleViewController: FKDiffableTableViewController, FKListDataProviding {
  private var shouldFailRefresh = true

  init() {
    var config = FKListDefaults.defaultConfiguration
    config.error.preservesContentOnError = true
    config.error.overridesTitle = "Refresh failed"
    config.error.overridesPrimaryActionTitle = "Retry"
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
    title = "Error · Preserved Content"
  }

  func fetchInitial(page: Int) async throws -> FKListFetchResult {
    let result = try await FKListKitExampleFeedAPI.fetch(page: 1, delay: 0.4)
    return FKListKitExampleFeedAPI.makeFetchResult(titles: result.titles, page: 1, hasMorePages: false)
  }

  func fetchNextPage(after pagination: FKRefreshPagination) async throws -> FKListFetchResult {
    FKListFetchResult(snapshot: FKListSnapshot(), hasMorePages: false)
  }

  func fetchRefresh(page: Int) async throws -> FKListFetchResult {
    try await Task.sleep(nanoseconds: 500_000_000)
    if shouldFailRefresh {
      shouldFailRefresh = false
      throw NSError(domain: "FKListKitExample", code: 2, userInfo: [
        NSLocalizedDescriptionKey: "Pull to refresh again to succeed. Existing rows stay visible underneath.",
      ])
    }
    let result = try await FKListKitExampleFeedAPI.fetch(page: 1, delay: 0.3)
    return FKListKitExampleFeedAPI.makeFetchResult(titles: result.titles, page: 1, hasMorePages: false)
  }
}
