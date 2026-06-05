import UIKit
import FKCoreKit

/// Table of links into focused FKBadge demo screens.
final class FKBadgeExamplesHubViewController: UITableViewController {

  private struct Row {
    let title: String
    let subtitle: String
    let controllerType: UIViewController.Type
  }

  private let rows: [Row] = [
    Row(
      title: FKExamplesI18n.string("examples.hub.fkbadgeexampleshubviewcontroller.0.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkbadgeexampleshubviewcontroller.0.subtitle"),
      controllerType: FKBadgeExampleBasicsViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkbadgeexampleshubviewcontroller.1.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkbadgeexampleshubviewcontroller.1.subtitle"),
      controllerType: FKBadgeExampleAnchorsViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkbadgeexampleshubviewcontroller.2.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkbadgeexampleshubviewcontroller.2.subtitle"),
      controllerType: FKBadgeExampleAppearanceViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkbadgeexampleshubviewcontroller.3.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkbadgeexampleshubviewcontroller.3.subtitle"),
      controllerType: FKBadgeExampleIntegrationViewController.self
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKBadge"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    let row = rows[indexPath.row]
    let vc = row.controllerType.init(nibName: nil, bundle: nil)
    vc.title = row.title
    navigationController?.pushViewController(vc, animated: true)
  }
}
