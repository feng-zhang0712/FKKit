import FKUIKit
import UIKit

/// Demonstrates ``FKDiffableCollectionViewController`` with ``FKListCollectionLayoutPreset/list``.
final class FKListKitCollectionListExampleViewController: FKDiffableCollectionViewController, FKListDataProviding {
  init() {
    var config = FKListDefaults.defaultConfiguration
    config.refresh.loadMorePreloadOffset = 120
    config.refresh.autohidesLoadMoreFooterWhenNotScrollable = false
    super.init(configuration: config, layoutPreset: .list)
    dataProvider = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Collection · List"
  }

  func fetchInitial(page: Int) async throws -> FKListFetchResult {
    let result = try await FKListKitExampleFeedAPI.fetch(
      page: page,
      delay: 0.4,
      itemsPerPage: FKListKitExampleFeedAPI.paginationDemoPageSize
    )
    return FKListKitExampleFeedAPI.makeFetchResult(titles: result.titles, page: page, hasMorePages: result.hasMorePages)
  }

  func fetchNextPage(after pagination: FKRefreshPagination) async throws -> FKListFetchResult {
    let result = try await FKListKitExampleFeedAPI.fetch(
      page: pagination.nextPage,
      itemsPerPage: FKListKitExampleFeedAPI.paginationDemoPageSize
    )
    return FKListKitExampleFeedAPI.makeFetchResult(
      titles: result.titles,
      page: pagination.nextPage,
      hasMorePages: result.hasMorePages
    )
  }

  func fetchRefresh(page: Int) async throws -> FKListFetchResult {
    let result = try await FKListKitExampleFeedAPI.fetch(
      page: page,
      delay: 0.5,
      itemsPerPage: FKListKitExampleFeedAPI.paginationDemoPageSize
    )
    return FKListKitExampleFeedAPI.makeFetchResult(titles: result.titles, page: page, hasMorePages: result.hasMorePages)
  }
}
