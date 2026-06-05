import FKUIKit
import UIKit

/// Lists ExpandableText sample screens; each row pushes one example view controller.
final class FKExpandableTextExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private struct Section {
    let title: String
    let rows: [Row]
  }

  private let sections: [Section] = [
    Section(
      title: "Host views",
      rows: [
        Row(title: "UILabel — basic", subtitle: "Default configuration", make: { FKExpandableTextExampleLabelBasicViewController() }),
        Row(title: "UITextView — rich text + links", subtitle: "`FKExpandableText.attach`", make: { FKExpandableTextExampleTextViewRichViewController() }),
      ]
    ),
    Section(
      title: "Configuration",
      rows: [
        Row(title: "Custom line limit", subtitle: "`collapseRule: .lines(2)`", make: { FKExpandableTextExampleLineLimitViewController() }),
        Row(title: "Custom action styling", subtitle: "Token, fonts, `trailingBottom`", make: { FKExpandableTextExampleActionStyleViewController() }),
        Row(title: "One-way expand", subtitle: "`oneWayExpand`", make: { FKExpandableTextExampleOneWayExpandViewController() }),
        Row(title: "Tap full text area", subtitle: "`interactionMode: .fullTextArea`", make: { FKExpandableTextExampleFullTextAreaViewController() }),
      ]
    ),
    Section(
      title: "Dynamic & composition",
      rows: [
        Row(title: "Dynamic text", subtitle: "Runtime `fk_setExpandableText`", make: { FKExpandableTextExampleDynamicTextViewController() }),
        Row(title: "UIKit composition", subtitle: "Label + text view", make: { FKExpandableTextExampleUIKitCompositionViewController() }),
      ]
    ),
    Section(
      title: "SwiftUI",
      rows: [
        Row(title: "SwiftUI bridge", subtitle: "`FKExpandableTextView`", make: { FKExpandableTextExampleSwiftUIViewController() }),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "ExpandableText"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    sections.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    sections[section].title
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    sections[section].rows.count
  }

  override func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = sections[indexPath.section].rows[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let row = sections[indexPath.section].rows[indexPath.row]
    navigationController?.pushViewController(row.make(), animated: true)
  }
}
