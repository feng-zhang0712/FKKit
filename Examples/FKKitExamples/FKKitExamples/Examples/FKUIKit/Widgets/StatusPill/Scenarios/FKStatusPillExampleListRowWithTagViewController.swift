import FKUIKit
import UIKit

final class FKStatusPillExampleListRowWithTagViewController: UITableViewController {

  private struct OrderRow {
    let orderID: String
    let summary: String
    let tagTitle: String
    let tagVariant: FKTagVariant
    let statusTitle: String
    let statusStyle: FKStatusPillStyle
    let showsDot: Bool
  }

  private let rows: [OrderRow] = [
    OrderRow(
      orderID: "#10482",
      summary: "2 items · $128.00",
      tagTitle: "VIP",
      tagVariant: .brand,
      statusTitle: "Shipped",
      statusStyle: .success,
      showsDot: false
    ),
    OrderRow(
      orderID: "#10471",
      summary: "Express · $56.20",
      tagTitle: "Sale",
      tagVariant: .success,
      statusTitle: "In transit",
      statusStyle: .info,
      showsDot: true
    ),
    OrderRow(
      orderID: "#10455",
      summary: "1 item · $19.99",
      tagTitle: "New",
      tagVariant: .neutral,
      statusTitle: "Pending review",
      statusStyle: .warning,
      showsDot: true
    ),
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
    title = "List row with Tag"
    tableView.register(FKStatusPillExampleOrderCell.self, forCellReuseIdentifier: FKStatusPillExampleOrderCell.reuseID)
  }

  override func numberOfSections(in tableView: UITableView) -> Int { 1 }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    rows.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    "Orders — FKTag + FKStatusPill"
  }

  override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    "Tag carries promo/category metadata; StatusPill carries workflow state. Both are non-interactive static text for VoiceOver."
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: FKStatusPillExampleOrderCell.reuseID, for: indexPath)
      as! FKStatusPillExampleOrderCell
    let row = rows[indexPath.row]
    cell.configure(
      orderID: row.orderID,
      summary: row.summary,
      tagTitle: row.tagTitle,
      tagVariant: row.tagVariant,
      statusTitle: row.statusTitle,
      statusStyle: row.statusStyle,
      showsDot: row.showsDot
    )
    return cell
  }
}

private final class FKStatusPillExampleOrderCell: UITableViewCell {
  static let reuseID = "FKStatusPillExampleOrderCell"

  private let tagView = FKTag()
  private let statusPill = FKStatusPill()
  private let trailingStack = UIStackView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    selectionStyle = .default

    trailingStack.axis = .horizontal
    trailingStack.spacing = 8
    trailingStack.alignment = .center
    trailingStack.addArrangedSubview(tagView)
    trailingStack.addArrangedSubview(statusPill)
    accessoryView = trailingStack
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(
    orderID: String,
    summary: String,
    tagTitle: String,
    tagVariant: FKTagVariant,
    statusTitle: String,
    statusStyle: FKStatusPillStyle,
    showsDot: Bool
  ) {
    var tagConfig = FKTagConfiguration()
    tagConfig.layout.size = .xs
    tagView.configuration = tagConfig
    tagView.title = tagTitle
    tagView.variant = tagVariant

    statusPill.title = statusTitle
    statusPill.style = statusStyle
    statusPill.showsDot = showsDot

    textLabel?.text = orderID
    detailTextLabel?.text = summary

    tagView.setNeedsLayout()
    tagView.layoutIfNeeded()
    statusPill.setNeedsLayout()
    statusPill.layoutIfNeeded()

    let tagSize = tagView.intrinsicContentSize
    let pillSize = statusPill.intrinsicContentSize
    let spacing = trailingStack.spacing
    let stackHeight = max(tagSize.height, pillSize.height)
    let stackWidth = tagSize.width + spacing + pillSize.width
    let stackSize = CGSize(width: stackWidth, height: stackHeight)

    trailingStack.frame = CGRect(origin: .zero, size: stackSize)
    tagView.frame = CGRect(
      x: 0,
      y: (stackHeight - tagSize.height) / 2,
      width: tagSize.width,
      height: tagSize.height
    )
    statusPill.frame = CGRect(
      x: tagSize.width + spacing,
      y: (stackHeight - pillSize.height) / 2,
      width: pillSize.width,
      height: pillSize.height
    )
    accessoryView = trailingStack
  }
}
