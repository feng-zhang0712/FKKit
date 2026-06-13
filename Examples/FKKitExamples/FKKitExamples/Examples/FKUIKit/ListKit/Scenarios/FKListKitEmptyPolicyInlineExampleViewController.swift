import FKUIKit
import UIKit

/// Demonstrates ``FKListEmptyPresentationPolicy/inlineZeroRows``.
final class FKListKitEmptyPolicyInlineExampleViewController: FKDiffableTableViewController, FKListDataProviding {
  init() {
    var config = FKListDefaults.defaultConfiguration
    config.layout.emptyPresentationPolicy = .inlineZeroRows
    config.empty.scenario = .noOrders
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
    title = "Empty · Inline Zero Rows"
  }

  func fetchInitial(page: Int) async throws -> FKListFetchResult {
    try await Task.sleep(nanoseconds: 350_000_000)
    return FKListFetchResult(snapshot: FKListSnapshot(), hasMorePages: false)
  }

  func fetchNextPage(after pagination: FKRefreshPagination) async throws -> FKListFetchResult {
    FKListFetchResult(snapshot: FKListSnapshot(), hasMorePages: false)
  }

  func fetchRefresh(page: Int) async throws -> FKListFetchResult {
    try await fetchInitial(page: page)
  }
}
