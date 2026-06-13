import FKCoreKit
import FKUIKit
import UIKit

/// Demonstrates ``FKListIconRow`` with remote URLs (``FKImageView``) and ``FKImageLoader`` prefetch.
final class FKListKitIconRemoteRowExampleViewController: FKDiffableTableViewController {
  /// Matches ``FKListPresetTableCell`` leading thumbnail size for cache key alignment.
  private static let leadingPrefetchTargetSize = CGSize(width: 28, height: 28)

  private var statusLabel: UILabel!

  init() {
    var config = FKListDefaults.defaultConfiguration
    config.prefetch.isEnabled = true
    config.refresh.isPullToRefreshEnabled = false
    config.refresh.isLoadMoreEnabled = false
    super.init(configuration: config)
    delegate = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    title = "Icon · Remote Row"
    statusLabel = FKListKitExampleStatusStrip.install(on: self, above: tableView)
    super.viewDidLoad()
    applySnapshot(buildSnapshot(), animatingDifferences: false)
  }

  private func buildSnapshot() -> FKListSnapshot {
    let ids = [10, 11, 12, 16, 17, 20, 21, 22, 23, 24]
    let items = ids.enumerated().map { index, photoID in
      FKListItem(
        id: FKListItemID("icon-\(index)"),
        kind: .preset(.icon(FKListIconRow(
          leading: .remoteURL(FKListKitExampleIcons.remoteURL(id: photoID)),
          title: "Photo \(photoID)",
          subtitle: "FKImageView · FKImageLoader prefetch"
        )))
      )
    }
    return FKListSnapshot(items: items)
  }

  private func remoteURL(for itemID: FKListItemID) -> URL? {
    guard let item = currentSnapshot.item(withID: itemID),
          case .preset(.icon(let row)) = item.kind,
          case .remoteURL(let url) = row.leading
    else { return nil }
    return url
  }

  private func prefetchRequest(for url: URL) -> FKImageLoadRequest {
    FKImageLoadRequest(url: url, targetSize: Self.leadingPrefetchTargetSize)
  }
}

extension FKListKitIconRemoteRowExampleViewController: FKListDelegate {
  func list(_ list: FKDiffableTableViewController, prefetchItems ids: [FKListItemID]) {
    let urls = ids.compactMap { remoteURL(for: $0) }
    guard !urls.isEmpty else { return }
    Task {
      await FKImageLoader.shared.prefetch(urls: urls, targetSize: Self.leadingPrefetchTargetSize)
    }
    FKListKitExampleStatusStrip.append(
      "prefetch \(urls.count) · \(ids.map(\.rawValue).joined(separator: ", "))",
      to: statusLabel
    )
  }

  func list(_ list: FKDiffableTableViewController, cancelPrefetching ids: [FKListItemID]) {
    for id in ids {
      guard let url = remoteURL(for: id) else { continue }
      FKImageLoader.shared.cancelPrefetch(for: prefetchRequest(for: url))
    }
    FKListKitExampleStatusStrip.append("cancel prefetch \(ids.count)", to: statusLabel)
  }
}
