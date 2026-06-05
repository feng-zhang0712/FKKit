import UIKit
import FKCoreKit

final class FKCornerShadowExamplesHubViewController: UITableViewController {

  private struct Row {
    let title: String
    let subtitle: String
    let controllerType: UIViewController.Type
  }

  private let rows: [Row] = [
    Row(
      title: FKExamplesI18n.string("examples.hub.fkcornershadowexampleshubviewcontroller.0.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkcornershadowexampleshubviewcontroller.0.subtitle"),
      controllerType: FKCornerShadowExampleBasicsViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkcornershadowexampleshubviewcontroller.1.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkcornershadowexampleshubviewcontroller.1.subtitle"),
      controllerType: FKCornerShadowExampleControlsViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkcornershadowexampleshubviewcontroller.2.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkcornershadowexampleshubviewcontroller.2.subtitle"),
      controllerType: FKCornerShadowExampleListViewController.self
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    FKCornerShadowExampleSupport.configureDefaultsIfNeeded()
    title = "FKCornerShadow"
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
