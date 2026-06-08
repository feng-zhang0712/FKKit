import FKUIKit
import UIKit

/// Demonstrates ``FKListCollectionLayoutPreset/insetGroupedList`` with section headers.
final class FKListKitCollectionInsetGroupedExampleViewController: FKDiffableCollectionViewController {
  init() {
    var config = FKListDefaults.defaultConfiguration
    config.refresh.isPullToRefreshEnabled = false
    config.refresh.isLoadMoreEnabled = false
    super.init(configuration: config, layoutPreset: .insetGroupedList)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Collection · Inset Grouped"
    view.backgroundColor = .systemGroupedBackground
    collectionView.backgroundColor = .systemGroupedBackground
    applySnapshot(
      FKListSnapshot(sections: [
        FKListSection(
          id: "general",
          items: [
            FKListItem.text(id: "airplane", title: "Airplane Mode"),
            FKListItem.text(id: "wifi", title: "Wi‑Fi"),
          ],
          header: .title("General")
        ),
        FKListSection(
          id: "display",
          items: [
            FKListItem.subtitle(id: "brightness", title: "Brightness", subtitle: "Automatic"),
            FKListItem.subtitle(id: "text", title: "Text Size", subtitle: "Medium"),
          ],
          header: .subtitle(title: "Display", subtitle: "Appearance settings")
        ),
      ]),
      animatingDifferences: false
    )
  }
}
