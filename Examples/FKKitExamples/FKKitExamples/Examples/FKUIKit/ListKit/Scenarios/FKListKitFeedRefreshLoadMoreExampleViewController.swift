import FKUIKit
import UIKit

/// Demonstrates ``FKListDataProviding``, pull-to-refresh, load-more, and ``FKListDelegate``.
final class FKListKitFeedRefreshLoadMoreExampleViewController: FKDiffableTableViewController, FKListDataProviding {
  private var statusLabel: UILabel!

  init() {
    var config = FKListDefaults.defaultConfiguration
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
    title = "Feed · Refresh & Load More"
    super.viewDidLoad()
  }

  func fetchInitial(page: Int) async throws -> FKListFetchResult {
    let result = try await FKListKitExampleFeedAPI.fetch(page: page)
    return FKListKitExampleFeedAPI.makeFetchResult(titles: result.titles, page: page, hasMorePages: result.hasMorePages)
  }

  func fetchNextPage(after pagination: FKRefreshPagination) async throws -> FKListFetchResult {
    let result = try await FKListKitExampleFeedAPI.fetch(page: pagination.nextPage)
    return FKListKitExampleFeedAPI.makeFetchResult(
      titles: result.titles,
      page: pagination.nextPage,
      hasMorePages: result.hasMorePages
    )
  }

  func fetchRefresh(page: Int) async throws -> FKListFetchResult {
    let result = try await FKListKitExampleFeedAPI.fetch(page: page, delay: 0.6)
    return FKListKitExampleFeedAPI.makeFetchResult(titles: result.titles, page: page, hasMorePages: result.hasMorePages)
  }
}

extension FKListKitFeedRefreshLoadMoreExampleViewController: FKListDelegate {
  func list(_ list: FKDiffableTableViewController, presentationStateChanged state: FKListPresentationState) {
    FKListKitExampleStatusStrip.append("state → \(describe(state))", to: statusLabel)
  }

  func list(_ list: FKDiffableTableViewController, didRefresh success: Bool) {
    FKListKitExampleStatusStrip.append("didRefresh success=\(success) page=\(pagination.page)", to: statusLabel)
  }

  func list(_ list: FKDiffableTableViewController, willLoadPage page: Int) {
    FKListKitExampleStatusStrip.append("willLoadPage \(page)", to: statusLabel)
  }

  func list(_ list: FKDiffableTableViewController, didLoadPage page: Int, result: FKListFetchResult) {
    FKListKitExampleStatusStrip.append(
      "didLoadPage \(page) items=\(result.snapshot.totalItemCount) hasMore=\(result.hasMorePages)",
      to: statusLabel
    )
  }

  func list(_ list: FKDiffableTableViewController, didReachEnd: Void) {
    FKListKitExampleStatusStrip.append("didReachEnd", to: statusLabel)
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
