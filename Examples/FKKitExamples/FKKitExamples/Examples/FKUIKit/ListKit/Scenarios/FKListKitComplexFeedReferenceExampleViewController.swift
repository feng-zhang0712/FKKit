import FKUIKit
import UIKit

/// Reference feed integrating v2+v3 ListKit APIs: custom cell, prefetch, visibility, reconfigure, height cache, load-more.
final class FKListKitComplexFeedReferenceExampleViewController: FKDiffableTableViewController, FKListDataProviding {
  static let cellTypeIdentifier = FKListKitExampleFeedPost.cellTypeIdentifier

  private let heightCache = FKListHeightCache()
  private var statusLabel: UILabel!
  private var lastMeasuredTableWidth: CGFloat = 0

  init() {
    var config = FKListDefaults.feedConfiguration
    config.refresh.loadMorePreloadOffset = 160
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
    title = "Feed · Complex Reference"
    register(FKListKitExampleFeedPostCell.self, forPayloadType: FKListKitExampleFeedPost.self)
    rowHeightProvider = { [weak self] item in
      guard let self else { return 120 }
      guard let post = self.payload(for: item.id)?.unwrap(FKListKitExampleFeedPost.self) else { return 120 }
      let width = self.tableView.bounds.width > 0 ? self.tableView.bounds.width : UIScreen.main.bounds.width
      return FKListKitExampleComplexFeedAPI.estimatedRowHeight(for: post, width: width, cache: self.heightCache)
    }
    tableView.estimatedRowHeight = 280
    super.viewDidLoad()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let width = tableView.bounds.width
    guard width > 0, abs(width - lastMeasuredTableWidth) > 0.5 else { return }
    lastMeasuredTableWidth = width
    heightCache.invalidateAll()
    guard tableView.numberOfSections > 0 else { return }
    tableView.reloadData()
  }

  override func configureCustomCell(_ cell: UITableViewCell, at indexPath: IndexPath, with item: FKListItem) {
    guard let feedCell = cell as? FKListKitExampleFeedPostCell else { return }
    feedCell.onLikeTapped = { [weak self] id in self?.likePost(id: id) }
  }

  func fetchInitial(page: Int) async throws -> FKListFetchResult {
    let result = try await FKListKitExampleComplexFeedAPI.fetch(page: page)
    storePayloads(result.posts)
    return FKListKitExampleComplexFeedAPI.makeFetchResult(posts: result.posts, hasMorePages: result.hasMorePages)
  }

  func fetchNextPage(after pagination: FKRefreshPagination) async throws -> FKListFetchResult {
    let result = try await FKListKitExampleComplexFeedAPI.fetch(page: pagination.nextPage)
    storePayloads(result.posts)
    return FKListKitExampleComplexFeedAPI.makeFetchResult(posts: result.posts, hasMorePages: result.hasMorePages)
  }

  func fetchRefresh(page: Int) async throws -> FKListFetchResult {
    heightCache.invalidateAll()
    let result = try await FKListKitExampleComplexFeedAPI.fetch(page: page, delay: 0.5)
    storePayloads(result.posts)
    return FKListKitExampleComplexFeedAPI.makeFetchResult(posts: result.posts, hasMorePages: result.hasMorePages)
  }

  private func storePayloads(_ posts: [FKListKitExampleFeedPost]) {
    for post in posts {
      setPayload(FKListItemPayload(post), for: post.id)
    }
  }

  private func likePost(id: FKListItemID) {
    guard var post = payload(for: id)?.unwrap(FKListKitExampleFeedPost.self) else { return }
    post.likeCount += 1
    setPayload(FKListItemPayload(post), for: id)
    applyMutation(.reconfigureItems([id]), animatingDifferences: false)
    FKListKitExampleStatusStrip.append("reconfigure \(id.rawValue) → ♥ \(post.likeCount)", to: statusLabel)
  }
}

extension FKListKitComplexFeedReferenceExampleViewController: FKListDelegate {
  func list(_ list: FKDiffableTableViewController, prefetchItems ids: [FKListItemID]) {
    FKListImagePrefetchHelper.prefetchImages(
      for: ids,
      in: currentSnapshot,
      payloadProvider: { [weak self] id in self?.payload(for: id) },
      presetIconTargetSize: FKListKitExampleFeedPost.avatarSize
    )
  }

  func list(_ list: FKDiffableTableViewController, cancelPrefetching ids: [FKListItemID]) {
    FKListImagePrefetchHelper.cancelPrefetchImages(
      for: ids,
      in: currentSnapshot,
      payloadProvider: { [weak self] id in self?.payload(for: id) },
      presetIconTargetSize: FKListKitExampleFeedPost.avatarSize
    )
  }

  func list(_ list: FKDiffableTableViewController, didLoadPage page: Int, result: FKListFetchResult) {
    FKListKitExampleStatusStrip.append(
      "didLoadPage \(page) · items=\(result.snapshot.totalItemCount)",
      to: statusLabel
    )
  }
}
