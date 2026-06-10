import FKUIKit
import UIKit

final class FKChipExampleListRowTagViewController: UITableViewController {

  private struct ProductRow {
    let title: String
    let subtitle: String
    let tagTitle: String
    let variant: FKTagVariant
  }

  private let rows: [ProductRow] = [
    ProductRow(title: "Wireless earbuds", subtitle: "In stock · ships today", tagTitle: "NEW", variant: .brand),
    ProductRow(title: "USB-C hub", subtitle: "Limited quantity", tagTitle: "Sale", variant: .success),
    ProductRow(title: "Screen protector", subtitle: "Backordered", tagTitle: "Pre-order", variant: .outline),
    ProductRow(title: "Power bank", subtitle: "Recalled batch", tagTitle: "Recall", variant: .error),
  ]

  init() {
    super.init(style: .insetGrouped)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "List row tag"
    tableView.register(FKChipExampleListCell.self, forCellReuseIdentifier: FKChipExampleListCell.reuseID)
  }

  override func numberOfSections(in tableView: UITableView) -> Int { 1 }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    rows.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    "Product list with FKTag trailing metadata"
  }

  override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    "FKTag is non-interactive (accessibilityTraits = .staticText). Pair with list rows for promo/category labels."
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: FKChipExampleListCell.reuseID, for: indexPath) as! FKChipExampleListCell
    let row = rows[indexPath.row]
    cell.configure(title: row.title, subtitle: row.subtitle, tagTitle: row.tagTitle, variant: row.variant)
    return cell
  }
}

private final class FKChipExampleListCell: UITableViewCell {
  static let reuseID = "FKChipExampleListCell"

  private let tagView = FKTag()
  private let trailingStack = UIStackView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    selectionStyle = .default

    trailingStack.axis = .horizontal
    trailingStack.alignment = .center
    trailingStack.addArrangedSubview(tagView)
    accessoryView = trailingStack
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(title: String, subtitle: String, tagTitle: String, variant: FKTagVariant) {
    var config = FKTagConfiguration()
    config.layout.size = .xs
    tagView.configuration = config
    tagView.title = tagTitle
    tagView.variant = variant
    textLabel?.text = title
    detailTextLabel?.text = subtitle
    tagView.setNeedsLayout()
    tagView.layoutIfNeeded()
    let tagSize = tagView.intrinsicContentSize
    trailingStack.frame = CGRect(origin: .zero, size: tagSize)
    tagView.frame = CGRect(origin: .zero, size: tagSize)
    accessoryView = trailingStack
  }
}
