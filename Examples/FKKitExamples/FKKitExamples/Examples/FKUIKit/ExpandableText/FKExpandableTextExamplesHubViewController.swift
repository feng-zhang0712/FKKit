import FKUIKit
import UIKit
import FKCoreKit

/// Lists ExpandableText sample screens; each row pushes one example view controller.
final class FKExpandableTextExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let rows: [Row] = [
    Row(title: FKExamplesI18n.string("examples.hub.fkexpandabletextexampleshubviewcontroller.0.title"), subtitle: FKExamplesI18n.string("examples.hub.fkexpandabletextexampleshubviewcontroller.0.subtitle"), make: { FKExpandableTextExampleLabelBasicViewController() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkexpandabletextexampleshubviewcontroller.1.title"), subtitle: FKExamplesI18n.string("examples.hub.fkexpandabletextexampleshubviewcontroller.1.subtitle"), make: { FKExpandableTextExampleTextViewRichViewController() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkexpandabletextexampleshubviewcontroller.2.title"), subtitle: FKExamplesI18n.string("examples.hub.fkexpandabletextexampleshubviewcontroller.2.subtitle"), make: { FKExpandableTextExampleLineLimitViewController() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkexpandabletextexampleshubviewcontroller.3.title"), subtitle: FKExamplesI18n.string("examples.hub.fkexpandabletextexampleshubviewcontroller.3.subtitle"), make: { FKExpandableTextExampleActionStyleViewController() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkexpandabletextexampleshubviewcontroller.4.title"), subtitle: FKExamplesI18n.string("examples.hub.fkexpandabletextexampleshubviewcontroller.4.subtitle"), make: { FKExpandableTextExampleOneWayExpandViewController() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkexpandabletextexampleshubviewcontroller.5.title"), subtitle: FKExamplesI18n.string("examples.hub.fkexpandabletextexampleshubviewcontroller.5.subtitle"), make: { FKExpandableTextExampleFullTextAreaViewController() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkexpandabletextexampleshubviewcontroller.6.title"), subtitle: FKExamplesI18n.string("examples.hub.fkexpandabletextexampleshubviewcontroller.6.subtitle"), make: { FKExpandableTextExampleDynamicTextViewController() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkexpandabletextexampleshubviewcontroller.7.title"), subtitle: FKExamplesI18n.string("examples.hub.fkexpandabletextexampleshubviewcontroller.7.subtitle"), make: { FKExpandableTextExampleUIKitCompositionViewController() }),
    Row(title: FKExamplesI18n.string("examples.hub.fkexpandabletextexampleshubviewcontroller.8.title"), subtitle: FKExamplesI18n.string("examples.hub.fkexpandabletextexampleshubviewcontroller.8.subtitle"), make: { FKExpandableTextExampleSwiftUIViewController() }),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "ExpandableText"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = rows[indexPath.row]
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
    navigationController?.pushViewController(rows[indexPath.row].make(), animated: true)
  }
}
