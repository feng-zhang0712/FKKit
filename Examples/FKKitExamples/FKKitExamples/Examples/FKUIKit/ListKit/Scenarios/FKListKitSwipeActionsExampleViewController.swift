import FKUIKit
import UIKit

/// Demonstrates per-item swipe actions and ``FKListSwipeActionHandlerRegistry``.
final class FKListKitSwipeActionsExampleViewController: FKDiffableTableViewController {
  private var statusLabel: UILabel!

  init() {
    var config = FKListDefaults.defaultConfiguration
    config.layout.separatorMode = .system
    config.refresh.isPullToRefreshEnabled = false
    config.refresh.isLoadMoreEnabled = false
    super.init(configuration: config)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    title = "Swipe Actions"
    super.viewDidLoad()
    registerSwipeHandlers()
    applySnapshot(buildSnapshot(), animatingDifferences: false)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if statusLabel == nil, tableView.bounds.width > 0 {
      statusLabel = FKListKitExampleStatusStrip.installInTableHeader(
        tableView,
        placeholder: "Swipe a row left or right. Latest action:"
      )
    } else {
      FKListKitExampleTableHeader.refreshIfWidthChanged(tableView)
    }
  }

  private func registerSwipeHandlers() {
    swipeActionHandlerRegistry.register(id: "pin") { [weak self] itemID in
      guard let self else { return }
      FKListKitExampleStatusStrip.append("Pinned \(itemID.rawValue)", to: statusLabel, resizingTableHeader: tableView)
    }
    swipeActionHandlerRegistry.register(id: "archive") { [weak self] itemID in
      guard let self else { return }
      FKListKitExampleStatusStrip.append("Archived \(itemID.rawValue)", to: statusLabel, resizingTableHeader: tableView)
    }
    swipeActionHandlerRegistry.register(id: "delete") { [weak self] itemID in
      guard let self else { return }
      FKListKitExampleStatusStrip.append("Deleted \(itemID.rawValue)", to: statusLabel, resizingTableHeader: tableView)
      applyMutation(.deleteItems([itemID]), animatingDifferences: true)
    }
  }

  private func buildSnapshot() -> FKListSnapshot {
    let swipe = FKListSwipeActionConfiguration(
      leading: [
        FKListSwipeAction(id: "pin", title: "Pin", style: .normal, icon: FKListSwipeActionIcon(symbolName: "pin")),
      ],
      trailing: [
        FKListSwipeAction(id: "archive", title: "Archive", style: .normal),
        FKListSwipeAction(id: "delete", title: "Delete", style: .destructive, icon: FKListSwipeActionIcon(symbolName: "trash")),
      ],
      permitsFullSwipe: false
    )
    let items = (1 ... 6).map { index in
      FKListItem(
        id: FKListItemID("mail-\(index)"),
        kind: .preset(.subtitle(FKListSubtitleRow(title: "Message \(index)", subtitle: "Swipe leading/trailing"))),
        swipeActions: swipe
      )
    }
    return FKListSnapshot(items: items)
  }
}
