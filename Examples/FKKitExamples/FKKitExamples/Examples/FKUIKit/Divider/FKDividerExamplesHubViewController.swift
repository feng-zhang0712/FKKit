import UIKit
import FKCoreKit

/// Entry table for focused FKDivider demos.
final class FKDividerExamplesHubViewController: UITableViewController {

  private struct Row {
    let title: String
    let subtitle: String
    let controllerType: UIViewController.Type
  }

  private let rows: [Row] = [
    Row(
      title: FKExamplesI18n.string("examples.hub.fkdividerexampleshubviewcontroller.0.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkdividerexampleshubviewcontroller.0.subtitle"),
      controllerType: FKDividerExampleBasicsViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkdividerexampleshubviewcontroller.1.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkdividerexampleshubviewcontroller.1.subtitle"),
      controllerType: FKDividerExampleLineStyleViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkdividerexampleshubviewcontroller.2.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkdividerexampleshubviewcontroller.2.subtitle"),
      controllerType: FKDividerExampleLayoutViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkdividerexampleshubviewcontroller.3.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkdividerexampleshubviewcontroller.3.subtitle"),
      controllerType: FKDividerExampleAdaptiveViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkdividerexampleshubviewcontroller.4.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkdividerexampleshubviewcontroller.4.subtitle"),
      controllerType: FKDividerExampleSwiftUIViewController.self
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKDivider"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = rows[indexPath.row]
    var cfg = cell.defaultContentConfiguration()
    cfg.text = row.title
    cfg.secondaryText = row.subtitle
    cfg.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = cfg
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
