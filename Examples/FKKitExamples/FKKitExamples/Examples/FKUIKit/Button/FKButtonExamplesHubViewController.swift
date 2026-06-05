import UIKit
import FKCoreKit

/// Entry table for FKButton example screens (see `Scenarios/`).
final class FKButtonExamplesHubViewController: UITableViewController {

  private struct Row {
    let title: String
    let subtitle: String
    let controllerType: UIViewController.Type
  }

  private let rows: [Row] = [
    Row(
      title: FKExamplesI18n.string("examples.hub.fkbuttonexampleshubviewcontroller.0.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkbuttonexampleshubviewcontroller.0.subtitle"),
      controllerType: FKButtonExampleBasicsViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkbuttonexampleshubviewcontroller.1.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkbuttonexampleshubviewcontroller.1.subtitle"),
      controllerType: FKButtonExampleLayoutViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkbuttonexampleshubviewcontroller.2.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkbuttonexampleshubviewcontroller.2.subtitle"),
      controllerType: FKButtonExampleInteractionViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkbuttonexampleshubviewcontroller.3.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkbuttonexampleshubviewcontroller.3.subtitle"),
      controllerType: FKButtonExampleAppearanceViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkbuttonexampleshubviewcontroller.4.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkbuttonexampleshubviewcontroller.4.subtitle"),
      controllerType: FKButtonExampleLoadingViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkbuttonexampleshubviewcontroller.5.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkbuttonexampleshubviewcontroller.5.subtitle"),
      controllerType: FKButtonExampleProductionViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkbuttonexampleshubviewcontroller.6.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkbuttonexampleshubviewcontroller.6.subtitle"),
      controllerType: FKButtonExampleAdvancedViewController.self
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKButton"
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
