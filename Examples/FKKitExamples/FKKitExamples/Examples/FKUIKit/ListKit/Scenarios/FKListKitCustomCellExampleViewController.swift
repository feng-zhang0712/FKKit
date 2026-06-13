import FKCoreKit
import FKUIKit
import UIKit

// MARK: - Custom cell demo

private struct FKListKitExampleCustomPayload: Sendable {
  let title: String
  let tintHex: String
}

private final class FKListKitExampleCustomCell: UITableViewCell, FKListTableCellConfigurable {
  private let colorView = UIView()
  private let titleLabel = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    colorView.layer.cornerRadius = 6
    colorView.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(colorView)
    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      colorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      colorView.widthAnchor.constraint(equalToConstant: 28),
      colorView.heightAnchor.constraint(equalToConstant: 28),
      titleLabel.leadingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: 12),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with item: FKListKitExampleCustomPayload) {
    titleLabel.text = item.title
    colorView.backgroundColor = UIColor(hex: item.tintHex) ?? .systemBlue
  }
}

private extension UIColor {
  convenience init?(hex: String) {
    var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if cleaned.hasPrefix("#") { cleaned.removeFirst() }
    guard cleaned.count == 6, let value = Int(cleaned, radix: 16) else { return nil }
    self.init(
      red: CGFloat((value >> 16) & 0xFF) / 255,
      green: CGFloat((value >> 8) & 0xFF) / 255,
      blue: CGFloat(value & 0xFF) / 255,
      alpha: 1
    )
  }
}

/// Demonstrates custom cell registration and payload side store.
final class FKListKitCustomCellExampleViewController: FKDiffableTableViewController {
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
    title = "Custom Cell"
    register(FKListKitExampleCustomCell.self, forPayloadType: FKListKitExampleCustomPayload.self)
    let payloads: [(FKListItemID, FKListKitExampleCustomPayload)] = [
      (FKListItemID("custom-1"), FKListKitExampleCustomPayload(title: "Host-defined cell A", tintHex: "FF6B6B")),
      (FKListItemID("custom-2"), FKListKitExampleCustomPayload(title: "Host-defined cell B", tintHex: "4ECDC4")),
      (FKListItemID("custom-3"), FKListKitExampleCustomPayload(title: "Host-defined cell C", tintHex: "FFE66D")),
    ]
    let items = payloads.map { id, payload in
      setPayload(FKListItemPayload(payload), for: id)
      return FKListItem.custom(id: id, cellTypeIdentifier: String(describing: FKListKitExampleCustomCell.self))
    }
    applySnapshot(FKListSnapshot(items: items), animatingDifferences: false)
  }
}
