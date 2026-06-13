import FKUIKit
import UIKit

private final class FKListKitExampleCollectionPromoHeaderView: UICollectionReusableView {
  static let reuseIdentifier = "FKListKitExampleCollectionPromoHeaderView"

  private let titleLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    titleLabel.font = .preferredFont(forTextStyle: .footnote)
    titleLabel.textColor = .secondaryLabel
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(title: String) {
    titleLabel.text = title
  }
}

/// Demonstrates ``FKListSectionLayoutHints``, custom section headers, and ``compositionalLayoutProvider``.
final class FKListKitCollectionLayoutHintsExampleViewController: FKDiffableCollectionViewController {
  private var usesWideLayout = false

  init() {
    var config = FKListDefaults.defaultConfiguration
    config.refresh.isPullToRefreshEnabled = false
    config.refresh.isLoadMoreEnabled = false
    super.init(configuration: config, layoutPreset: .insetGroupedList)
    compositionalLayoutProvider = { [weak self] snapshot in
      guard let self else {
        return FKListCollectionLayoutFactory.makeLayout(preset: .insetGroupedList, snapshot: snapshot)
      }
      if self.usesWideLayout {
        return FKListCollectionLayoutFactory.makeLayout(preset: .grid(columns: 2, spacing: 12), snapshot: snapshot)
      }
      return FKListCollectionLayoutFactory.makeLayout(preset: .insetGroupedList, snapshot: snapshot)
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Collection · Layout Hints"
    view.backgroundColor = .systemGroupedBackground
    collectionView.backgroundColor = .systemGroupedBackground
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Toggle grid",
      primaryAction: UIAction { [weak self] _ in self?.toggleLayout() }
    )

    collectionView.register(
      FKListKitExampleCollectionPromoHeaderView.self,
      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
      withReuseIdentifier: FKListKitExampleCollectionPromoHeaderView.reuseIdentifier
    )

    registerSectionHeaderProvider(id: "promo-header") { collectionView, indexPath in
      let view = collectionView.dequeueReusableSupplementaryView(
        ofKind: UICollectionView.elementKindSectionHeader,
        withReuseIdentifier: FKListKitExampleCollectionPromoHeaderView.reuseIdentifier,
        for: indexPath
      ) as! FKListKitExampleCollectionPromoHeaderView
      view.apply(title: "Custom header provider")
      return view
    }

    applySnapshot(buildSnapshot(), animatingDifferences: false)
  }

  private func toggleLayout() {
    usesWideLayout.toggle()
    applySnapshot(currentSnapshot, animatingDifferences: true)
  }

  private func buildSnapshot() -> FKListSnapshot {
    FKListSnapshot(sections: [
      FKListSection(
        id: "promo",
        items: [
          FKListItem.text(id: "tile-a", title: "Inset grouped tile A"),
          FKListItem.text(id: "tile-b", title: "Inset grouped tile B"),
        ],
        header: .custom(viewProviderID: "promo-header"),
        layoutHints: FKListSectionLayoutHints(
          contentInsets: FKListDirectionalInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        )
      ),
      FKListSection(
        id: "more",
        items: [
          FKListItem.subtitle(id: "more-1", title: "Section without hints", subtitle: "Uses preset defaults"),
        ],
        header: .title("Default insets")
      ),
    ])
  }
}
