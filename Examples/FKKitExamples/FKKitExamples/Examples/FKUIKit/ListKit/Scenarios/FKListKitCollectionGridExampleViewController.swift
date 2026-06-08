import FKUIKit
import UIKit

/// Demonstrates ``FKListCollectionLayoutPreset/grid(columns:spacing:)``.
final class FKListKitCollectionGridExampleViewController: FKDiffableCollectionViewController {
  init() {
    var config = FKListDefaults.defaultConfiguration
    config.refresh.isPullToRefreshEnabled = false
    config.refresh.isLoadMoreEnabled = false
    super.init(configuration: config, layoutPreset: .grid(columns: 2, spacing: 12))
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Collection · Grid"
    view.backgroundColor = .systemGroupedBackground
    collectionView.backgroundColor = .systemGroupedBackground
    let items = (1 ... 12).map { index in
      FKListItem.subtitle(id: FKListItemID("grid-\(index)"), title: "Tile \(index)", subtitle: "Grid cell")
    }
    applySnapshot(FKListSnapshot(items: items), animatingDifferences: false)
  }
}
