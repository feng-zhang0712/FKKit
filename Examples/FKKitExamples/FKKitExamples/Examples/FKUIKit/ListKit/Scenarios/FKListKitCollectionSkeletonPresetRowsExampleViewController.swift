import FKUIKit
import UIKit

/// Demonstrates ``FKListSkeletonPolicy/presetRows(count:)`` on collection initial load.
final class FKListKitCollectionSkeletonPresetRowsExampleViewController: FKDiffableCollectionViewController, FKListDataProviding {
  init() {
    var config = FKListDefaults.defaultConfiguration
    config.loading.usesSkeletonForInitialLoad = true
    config.loading.skeletonPolicy = .presetRows(count: 6)
    config.refresh.isPullToRefreshEnabled = false
    config.refresh.isLoadMoreEnabled = false
    super.init(configuration: config, layoutPreset: .list)
    dataProvider = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    title = "Collection · Skeleton Rows"
    super.viewDidLoad()
  }

  func fetchInitial(page: Int) async throws -> FKListFetchResult {
    let result = try await FKListKitExampleFeedAPI.fetch(page: page, delay: 1.8, itemsPerPage: 12)
    return FKListKitExampleFeedAPI.makeFetchResult(titles: result.titles, page: page, hasMorePages: false)
  }

  func fetchNextPage(after pagination: FKRefreshPagination) async throws -> FKListFetchResult {
    FKListFetchResult(snapshot: FKListSnapshot(), hasMorePages: false)
  }

  func fetchRefresh(page: Int) async throws -> FKListFetchResult {
    try await fetchInitial(page: page)
  }
}
