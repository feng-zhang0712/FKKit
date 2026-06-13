import FKUIKit
import UIKit

/// Demonstrates ``FKListCollectionDelegate`` lifecycle hooks on a collection feed.
final class FKListKitCollectionDelegateExampleViewController: FKDiffableCollectionViewController, FKListDataProviding {
  private var statusLabel: UILabel!

  init() {
    var config = FKListDefaults.defaultConfiguration
    config.refresh.loadMorePreloadOffset = 120
    config.refresh.autohidesLoadMoreFooterWhenNotScrollable = false
    super.init(configuration: config, layoutPreset: .list)
    dataProvider = self
    delegate = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    statusLabel = FKListKitExampleStatusStrip.install(on: self, above: collectionView)
    title = "Collection · Delegate"
    super.viewDidLoad()
  }

  func fetchInitial(page: Int) async throws -> FKListFetchResult {
    let result = try await FKListKitExampleFeedAPI.fetch(
      page: page,
      delay: 0.5,
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
      delay: 0.4,
      itemsPerPage: FKListKitExampleFeedAPI.paginationDemoPageSize
    )
    return FKListKitExampleFeedAPI.makeFetchResult(titles: result.titles, page: page, hasMorePages: result.hasMorePages)
  }
}

extension FKListKitCollectionDelegateExampleViewController: FKListCollectionDelegate {
  func list(_ list: FKDiffableCollectionViewController, presentationStateChanged state: FKListPresentationState) {
    FKListKitExampleStatusStrip.append("state → \(describe(state))", to: statusLabel)
  }

  func list(_ list: FKDiffableCollectionViewController, didRefresh success: Bool) {
    FKListKitExampleStatusStrip.append("didRefresh success=\(success)", to: statusLabel)
  }

  func list(_ list: FKDiffableCollectionViewController, willLoadPage page: Int) {
    FKListKitExampleStatusStrip.append("willLoadPage \(page)", to: statusLabel)
  }

  func list(_ list: FKDiffableCollectionViewController, didLoadPage page: Int, result: FKListFetchResult) {
    FKListKitExampleStatusStrip.append(
      "didLoadPage \(page) items=\(result.snapshot.totalItemCount)",
      to: statusLabel
    )
  }

  func list(_ list: FKDiffableCollectionViewController, didReachEnd: Void) {
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
