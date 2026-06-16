import FKUIKit
import UIKit

/// Demonstrates collection list swipe actions via ``FKListSwipeActionHandlerRegistry``.
final class FKListKitCollectionSwipeActionsExampleViewController: FKDiffableCollectionViewController {
  private var statusLabel: UILabel!

  init() {
    var config = FKListDefaults.defaultConfiguration
    config.refresh.isPullToRefreshEnabled = false
    config.refresh.isLoadMoreEnabled = false
    super.init(configuration: config, layoutPreset: .list)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    title = "Collection · Swipe"
    statusLabel = FKListKitExampleStatusStrip.install(on: self, above: collectionView)
    registerSwipeHandlers()
    super.viewDidLoad()
    applySnapshot(buildSnapshot(), animatingDifferences: false)
  }

  private func registerSwipeHandlers() {
    swipeActionHandlerRegistry.register(id: "pin") { [weak self] itemID in
      FKListKitExampleStatusStrip.append("Pinned \(itemID.rawValue)", to: self?.statusLabel)
    }
    swipeActionHandlerRegistry.register(id: "delete") { [weak self] itemID in
      guard let self else { return }
      FKListKitExampleStatusStrip.append("Deleted \(itemID.rawValue)", to: statusLabel)
      applyMutation(.deleteItems([itemID]), animatingDifferences: true)
    }
  }

  private func buildSnapshot() -> FKListSnapshot {
    let swipe = FKListSwipeActionConfiguration(
      leading: [
        FKListSwipeAction(id: "pin", title: "Pin", style: .normal, icon: FKListSwipeActionIcon(symbolName: "pin")),
      ],
      trailing: [
        FKListSwipeAction(id: "delete", title: "Delete", style: .destructive, icon: FKListSwipeActionIcon(symbolName: "trash")),
      ]
    )
    let items = (1 ... 8).map { index in
      FKListItem(
        id: FKListItemID("card-\(index)"),
        kind: .preset(.subtitle(FKListSubtitleRow(title: "Card \(index)", subtitle: "Collection swipe actions"))),
        swipeActions: swipe
      )
    }
    return FKListSnapshot(items: items)
  }
}
