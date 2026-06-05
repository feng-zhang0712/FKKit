import UIKit
import FKCoreKit

/// Index of ``FKActionSheet`` examples, grouped by integration path.
final class FKActionSheetExamplesHubViewController: UITableViewController {
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
      title: "Getting started",
      rows: [
        Row(
          title: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.0.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.0.subtitle"),
          make: { FKActionSheetExampleBasicsViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.1.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.1.subtitle"),
          make: { FKActionSheetExamplePresentationViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.2.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.2.subtitle"),
          make: { FKActionSheetExampleCenteredViewController() }
        ),
      ]
    ),
    Section(
      title: "Rows & appearance",
      rows: [
        Row(
          title: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.3.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.3.subtitle"),
          make: { FKActionSheetExampleAppearanceViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.4.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.4.subtitle"),
          make: { FKActionSheetExampleSymbolsAndStatesViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.5.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.5.subtitle"),
          make: { FKActionSheetExampleCustomContentViewController() }
        ),
      ]
    ),
    Section(
      title: "Selection & behavior",
      rows: [
        Row(
          title: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.6.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.6.subtitle"),
          make: { FKActionSheetExampleLongListViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.7.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.7.subtitle"),
          make: { FKActionSheetExampleSelectionViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.8.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.8.subtitle"),
          make: { FKActionSheetExampleHandlersViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.9.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.9.subtitle"),
          make: { FKActionSheetExampleLiveUpdatesViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.10.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.10.subtitle"),
          make: { FKActionSheetExampleLoadingContentViewController() }
        ),
      ]
    ),
    Section(
      title: FKExamplesI18n.string("examples.hub.fki18nexampleshubviewcontroller.6.title"),
      rows: [
        Row(
          title: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.11.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.11.subtitle"),
          make: { FKActionSheetExampleBuilderViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.12.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkactionsheetexampleshubviewcontroller.12.subtitle"),
          make: { FKActionSheetExampleSwiftUIViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKActionSheet"
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

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
