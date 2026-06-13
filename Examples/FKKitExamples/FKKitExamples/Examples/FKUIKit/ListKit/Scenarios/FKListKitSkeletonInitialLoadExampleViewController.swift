import FKUIKit
import UIKit

/// Demonstrates ``FKListLoadingConfiguration`` skeleton until the first snapshot applies.
final class FKListKitSkeletonInitialLoadExampleViewController: FKDiffableTableViewController, FKListDataProviding {
  private var didInstallCaptionHeader = false

  init() {
    var config = FKListDefaults.defaultConfiguration
    config.loading.usesSkeletonForInitialLoad = true
    config.loading.skeletonPolicy = .fullOverlay
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
    title = "Skeleton Initial Load"
    super.viewDidLoad()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    guard tableView.bounds.width > 0 else { return }
    if !didInstallCaptionHeader {
      didInstallCaptionHeader = true
      installCaptionHeader()
    } else {
      FKListKitExampleTableHeader.refreshIfWidthChanged(tableView)
    }
  }

  private func installCaptionHeader() {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = "Shimmer overlay (~2.5s) until the first page loads."
    label.translatesAutoresizingMaskIntoConstraints = false

    let container = UIView()
    container.backgroundColor = .systemBackground
    container.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
      label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
      label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
      label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
    ])

    FKListKitExampleTableHeader.apply(container, to: tableView)
  }

  func fetchInitial(page: Int) async throws -> FKListFetchResult {
    let result = try await FKListKitExampleFeedAPI.fetch(page: page, delay: 2.5)
    return FKListKitExampleFeedAPI.makeFetchResult(titles: result.titles, page: page, hasMorePages: false)
  }

  func fetchNextPage(after pagination: FKRefreshPagination) async throws -> FKListFetchResult {
    FKListFetchResult(snapshot: FKListSnapshot(), hasMorePages: false)
  }

  func fetchRefresh(page: Int) async throws -> FKListFetchResult {
    try await fetchInitial(page: page)
  }
}
