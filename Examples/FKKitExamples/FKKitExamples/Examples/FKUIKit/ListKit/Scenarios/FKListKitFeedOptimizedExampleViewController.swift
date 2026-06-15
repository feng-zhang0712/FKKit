import FKUIKit
import UIKit

/// Demonstrates ``FKListDefaults/feedConfiguration`` — prefetch on, no load-more animation.
final class FKListKitFeedOptimizedExampleViewController: FKDiffableTableViewController, FKListDataProviding {
  private var statusLabel: UILabel!

  init() {
    var config = FKListDefaults.feedConfiguration
    config.refresh.loadMorePreloadOffset = 120
    config.refresh.autohidesLoadMoreFooterWhenNotScrollable = false
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
    title = "Feed · Optimized"
    super.viewDidLoad()
  }

  func fetchInitial(page: Int) async throws -> FKListFetchResult {
    let result = try await FKListKitExampleFeedAPI.fetch(
      page: page,
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
      delay: 0.6,
      itemsPerPage: FKListKitExampleFeedAPI.paginationDemoPageSize
    )
    return FKListKitExampleFeedAPI.makeFetchResult(titles: result.titles, page: page, hasMorePages: result.hasMorePages)
  }
}

extension FKListKitFeedOptimizedExampleViewController: FKListDelegate {
  func list(_ list: FKDiffableTableViewController, presentationStateChanged state: FKListPresentationState) {
    FKListKitExampleStatusStrip.append("state → \(describe(state))", to: statusLabel)
  }

  func list(_ list: FKDiffableTableViewController, didLoadPage page: Int, result: FKListFetchResult) {
    FKListKitExampleStatusStrip.append(
      "didLoadPage \(page) · append without animation",
      to: statusLabel
    )
  }

  private func describe(_ state: FKListPresentationState) -> String {
    switch state {
    case .initialLoading: return "initialLoading"
    case .content: return "content"
    case .empty: return "empty"
    case .error: return "error"
    case .refreshing: return "refreshing"
    case .loadingNextPage: return "loadingNextPage"
    }
  }
}
