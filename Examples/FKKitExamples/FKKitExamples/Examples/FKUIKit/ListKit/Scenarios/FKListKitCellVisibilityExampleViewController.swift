import FKUIKit
import UIKit

/// Demonstrates ``FKListDelegate`` visibility hooks for off-screen work cancellation.
final class FKListKitCellVisibilityExampleViewController: FKDiffableTableViewController {
  private var statusLabel: UILabel!
  private var visibleIDs = Set<FKListItemID>()
  private var lastEvent = "—"

  init() {
    var config = FKListDefaults.defaultConfiguration
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
    title = "Cell Visibility"
    statusLabel = FKListKitExampleStatusStrip.install(on: self, above: tableView)
    statusLabel.text = "visible=0 · last: —"
    super.viewDidLoad()
    applySnapshot(buildSnapshot(), animatingDifferences: false)
  }

  private func buildSnapshot() -> FKListSnapshot {
    let items = (1 ... 30).map { index in
      FKListItem.subtitle(
        id: FKListItemID("row-\(index)"),
        title: "Post \(index)",
        subtitle: "Scroll to see willDisplay / didEndDisplaying"
      )
    }
    return FKListSnapshot(items: items)
  }

  private func refreshStatus() {
    statusLabel.text = "visible=\(visibleIDs.count) · last: \(lastEvent)"
  }
}

extension FKListKitCellVisibilityExampleViewController: FKListDelegate {
  func list(_ list: FKDiffableTableViewController, willDisplay item: FKListItemID, at indexPath: IndexPath) {
    visibleIDs.insert(item)
    lastEvent = "willDisplay \(item.rawValue)"
    refreshStatus()
  }

  func list(_ list: FKDiffableTableViewController, didEndDisplaying item: FKListItemID, at indexPath: IndexPath) {
    visibleIDs.remove(item)
    lastEvent = "didEndDisplay \(item.rawValue)"
    refreshStatus()
  }
}
