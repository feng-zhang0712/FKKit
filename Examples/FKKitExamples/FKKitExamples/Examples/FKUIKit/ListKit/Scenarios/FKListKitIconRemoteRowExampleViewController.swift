import FKUIKit
import UIKit

/// Demonstrates ``FKListIconRow`` with remote URLs (``FKImageView``) and prefetch delegate.
final class FKListKitIconRemoteRowExampleViewController: FKDiffableTableViewController {
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
          subtitle: "FKImageView in preset cell"
        )))
      )
    }
    return FKListSnapshot(items: items)
  }
}

extension FKListKitIconRemoteRowExampleViewController: FKListDelegate {
  func list(_ list: FKDiffableTableViewController, prefetchItems ids: [FKListItemID]) {
    FKListKitExampleStatusStrip.append("prefetch \(ids.map(\.rawValue).joined(separator: ", "))", to: statusLabel)
  }

  func list(_ list: FKDiffableTableViewController, cancelPrefetching ids: [FKListItemID]) {
    FKListKitExampleStatusStrip.append("cancel prefetch \(ids.count)", to: statusLabel)
  }
}
