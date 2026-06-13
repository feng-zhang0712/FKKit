import FKUIKit
import UIKit

/// Demonstrates default ``FKListSkeletonPolicy/visibleCells`` until the first snapshot applies.
final class FKListKitSkeletonVisibleCellsExampleViewController: FKDiffableTableViewController, FKListDataProviding {
  init() {
    var config = FKListDefaults.defaultConfiguration
    config.loading.usesSkeletonForInitialLoad = true
    config.loading.skeletonPolicy = .visibleCells
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
    title = "Skeleton · Visible Cells"
    super.viewDidLoad()
  }

  func fetchInitial(page: Int) async throws -> FKListFetchResult {
    let result = try await FKListKitExampleFeedAPI.fetch(page: page, delay: 1.2)
    return FKListKitExampleFeedAPI.makeFetchResult(titles: result.titles, page: page, hasMorePages: false)
  }

  func fetchNextPage(after pagination: FKRefreshPagination) async throws -> FKListFetchResult {
    FKListFetchResult(snapshot: FKListSnapshot(), hasMorePages: false)
  }

  func fetchRefresh(page: Int) async throws -> FKListFetchResult {
    try await fetchInitial(page: page)
  }
}
