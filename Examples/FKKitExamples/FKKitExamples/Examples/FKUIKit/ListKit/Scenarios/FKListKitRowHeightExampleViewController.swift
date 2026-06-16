import FKUIKit
import UIKit

/// Demonstrates ``FKListRowHeightPolicy`` and ``FKDiffableTableViewController/rowHeightProvider``.
final class FKListKitRowHeightExampleViewController: FKDiffableTableViewController {
  init() {
    var config = FKListDefaults.defaultConfiguration
    config.layout.rowHeightPolicy = .fixed(56)
    config.refresh.isPullToRefreshEnabled = false
    config.refresh.isLoadMoreEnabled = false
    super.init(configuration: config)
    rowHeightProvider = { item in
      guard case .preset(.subtitle(let row)) = item.kind else { return 56 }
      return row.subtitle?.contains("Tall") == true ? 96 : 56
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Row Height"
    applySnapshot(buildSnapshot(), animatingDifferences: false)
  }

  private func buildSnapshot() -> FKListSnapshot {
    let items: [FKListItem] = [
      FKListItem.subtitle(id: "compact-1", title: "Compact row", subtitle: "Fixed 56pt via policy"),
      FKListItem.subtitle(id: "compact-2", title: "Compact row", subtitle: "Standard height"),
      FKListItem.subtitle(id: "tall-1", title: "Tall row", subtitle: "Tall subtitle uses rowHeightProvider (96pt)"),
      FKListItem.subtitle(id: "compact-3", title: "Compact row", subtitle: "Back to 56pt"),
    ]
    return FKListSnapshot(items: items)
  }
}
