import FKUIKit
import UIKit

/// Demonstrates ``FKListSnapshotMutation/reconfigureItems`` for lightweight in-place updates.
final class FKListKitReconfigureItemsExampleViewController: FKDiffableTableViewController {
  private var likeCounts: [FKListItemID: Int] = [:]

  init() {
    var config = FKListDefaults.defaultConfiguration
    config.refresh.isPullToRefreshEnabled = false
    config.refresh.isLoadMoreEnabled = false
    super.init(configuration: config)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Reconfigure Items"
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Like all",
      primaryAction: UIAction { [weak self] _ in self?.likeAll() }
    )
    applySnapshot(buildSnapshot(), animatingDifferences: false)
  }

  override func configurePresetCell(
    _ cell: FKListPresetTableCell,
    at indexPath: IndexPath,
    with item: FKListItem
  ) {
    guard let count = likeCounts[item.id] else { return }
    cell.accessoryType = .none
    cell.accessoryView = accessoryLabel(count: count)
  }

  private func buildSnapshot() -> FKListSnapshot {
    let items = (1 ... 6).map { index -> FKListItem in
      let id = FKListItemID("post-\(index)")
      likeCounts[id] = 0
      return FKListItem.subtitle(id: id, title: "Post \(index)", subtitle: "Tap Like all to reconfigure")
    }
    return FKListSnapshot(items: items)
  }

  private func likeAll() {
    for id in likeCounts.keys {
      likeCounts[id, default: 0] += 1
    }
    let ids = Array(likeCounts.keys)
    applyMutation(.reconfigureItems(ids), animatingDifferences: false)
  }

  private func accessoryLabel(count: Int) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .systemPink
    label.text = "♥ \(count)"
    label.sizeToFit()
    return label
  }
}
