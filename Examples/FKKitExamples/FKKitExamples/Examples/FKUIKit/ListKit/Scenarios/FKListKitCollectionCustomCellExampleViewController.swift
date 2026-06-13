import FKCoreKit
import FKUIKit
import UIKit

// MARK: - Collection custom cell demo

private struct FKListKitExampleCollectionPayload: Sendable {
  let title: String
  let badge: String
}

private final class FKListKitExampleCollectionCustomCell: UICollectionViewCell, FKListCollectionCellConfigurable {
  private let titleLabel = UILabel()
  private let badgeLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .secondarySystemGroupedBackground
    contentView.layer.cornerRadius = 10
    contentView.layer.masksToBounds = true

    titleLabel.font = .preferredFont(forTextStyle: .body)
    badgeLabel.font = .preferredFont(forTextStyle: .caption1)
    badgeLabel.textColor = .secondaryLabel
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    badgeLabel.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(titleLabel)
    contentView.addSubview(badgeLabel)
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      badgeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
      badgeLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      badgeLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
      badgeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with item: FKListKitExampleCollectionPayload) {
    titleLabel.text = item.title
    badgeLabel.text = item.badge
  }
}

/// Demonstrates ``FKListCollectionCellConfigurable`` registration on collection lists.
final class FKListKitCollectionCustomCellExampleViewController: FKDiffableCollectionViewController {
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
    super.viewDidLoad()
    title = "Collection · Custom Cell"
    view.backgroundColor = .systemGroupedBackground
    collectionView.backgroundColor = .systemGroupedBackground
    register(FKListKitExampleCollectionCustomCell.self, forPayloadType: FKListKitExampleCollectionPayload.self)

    let payloads: [(FKListItemID, FKListKitExampleCollectionPayload)] = [
      (FKListItemID("cv-1"), FKListKitExampleCollectionPayload(title: "Custom collection cell", badge: "Payload A")),
      (FKListItemID("cv-2"), FKListKitExampleCollectionPayload(title: "Host-defined layout", badge: "Payload B")),
      (FKListItemID("cv-3"), FKListKitExampleCollectionPayload(title: "register(_:forPayloadType:)", badge: "Payload C")),
    ]
    let items = payloads.map { id, payload in
      setPayload(FKListItemPayload(payload), for: id)
      return FKListItem.custom(id: id, cellTypeIdentifier: String(describing: FKListKitExampleCollectionCustomCell.self))
    }
    applySnapshot(FKListSnapshot(items: items), animatingDifferences: false)
  }
}
