import FKUIKit
import UIKit

/// Demonstrates ``FKListEmptyPresentationPolicy/replaceContent``.
final class FKListKitEmptyPolicyReplaceExampleViewController: FKDiffableTableViewController, FKListDataProviding {
  init() {
    var config = FKListDefaults.defaultConfiguration
    config.layout.emptyPresentationPolicy = .replaceContent
    config.empty.scenario = .noFavorites
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
    title = "Empty · Replace Content"
  }

  func fetchInitial(page: Int) async throws -> FKListFetchResult {
    try await Task.sleep(nanoseconds: 400_000_000)
    return FKListFetchResult(snapshot: FKListSnapshot(), hasMorePages: false)
  }

  func fetchNextPage(after pagination: FKRefreshPagination) async throws -> FKListFetchResult {
    FKListFetchResult(snapshot: FKListSnapshot(), hasMorePages: false)
  }

  func fetchRefresh(page: Int) async throws -> FKListFetchResult {
    try await fetchInitial(page: page)
  }
}
