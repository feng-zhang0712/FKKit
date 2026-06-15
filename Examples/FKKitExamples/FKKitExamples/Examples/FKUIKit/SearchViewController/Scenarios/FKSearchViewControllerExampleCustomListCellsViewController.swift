import FKCoreKit
import FKUIKit
import UIKit

// MARK: - Custom cell

private struct FKSearchViewControllerExampleColorPayload: Sendable {
  let title: String
  let tintHex: String
}

private final class FKSearchViewControllerExampleColorCell: UITableViewCell, FKListTableCellConfigurable {
  private let swatch = UIView()
  private let titleLabel = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    swatch.layer.cornerRadius = 6
    swatch.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(swatch)
    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      swatch.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      swatch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      swatch.widthAnchor.constraint(equalToConstant: 28),
      swatch.heightAnchor.constraint(equalToConstant: 28),
      titleLabel.leadingAnchor.constraint(equalTo: swatch.trailingAnchor, constant: 12),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with item: FKSearchViewControllerExampleColorPayload) {
    titleLabel.text = item.title
    swatch.backgroundColor = UIColor(hex: item.tintHex) ?? .systemBlue
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

/// Override ``makeListViewController()`` to register host custom cells.
final class FKSearchViewControllerExampleCustomListCellsViewController: FKSearchViewController, FKSearchLocalFilterProviding {
  private let baseline: FKListSnapshot

  private let payloads: [FKListItemID: FKSearchViewControllerExampleColorPayload]

  init() {
    let payloads: [(FKListItemID, FKSearchViewControllerExampleColorPayload)] = [
      (FKListItemID("color-apple"), FKSearchViewControllerExampleColorPayload(title: "Apple", tintHex: "FF6B6B")),
      (FKListItemID("color-banana"), FKSearchViewControllerExampleColorPayload(title: "Banana", tintHex: "FFE66D")),
      (FKListItemID("color-blueberry"), FKSearchViewControllerExampleColorPayload(title: "Blueberry", tintHex: "4ECDC4")),
      (FKListItemID("color-cherry"), FKSearchViewControllerExampleColorPayload(title: "Cherry", tintHex: "E056FD")),
      (FKListItemID("color-grape"), FKSearchViewControllerExampleColorPayload(title: "Grape", tintHex: "845EF7")),
      (FKListItemID("color-mango"), FKSearchViewControllerExampleColorPayload(title: "Mango", tintHex: "FFA94D")),
    ]
    self.payloads = Dictionary(uniqueKeysWithValues: payloads)
    let items = payloads.map { id, _ in FKListItem.custom(id: id, cellTypeIdentifier: "ColorCell") }
    baseline = FKListSnapshot(items: items)
    super.init(
      configuration: FKSearchViewControllerDefaults.localFilter(placement: .stickyHeader),
      placeholder: "Filter custom rows"
    )
    localFilterProvider = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var baselineSnapshot: FKListSnapshot { baseline }

  func filteredSnapshot(for query: String) -> FKListSnapshot {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return baseline }
    let filtered = baseline.sections.flatMap(\.items).filter { item in
      guard let payload = payloads[item.id] else { return false }
      return payload.title.localizedCaseInsensitiveContains(trimmed)
    }
    return FKListSnapshot(items: filtered)
  }

  override func makeListViewController() -> FKDiffableTableViewController {
    let list = super.makeListViewController()
    list.register(FKSearchViewControllerExampleColorCell.self, forPayloadType: FKSearchViewControllerExampleColorPayload.self)
    for (id, payload) in payloads {
      list.setPayload(FKListItemPayload(payload), for: id)
    }
    return list
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom List Cells"
  }
}
