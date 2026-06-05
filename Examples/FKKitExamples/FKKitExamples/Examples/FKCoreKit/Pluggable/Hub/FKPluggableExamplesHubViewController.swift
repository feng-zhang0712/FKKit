import UIKit
import FKCoreKit

/// Entry table for all FKPluggable protocol contract demos under `FKCoreKit/Components/Pluggable`.
final class FKPluggableExamplesHubViewController: UITableViewController {

  private struct Row {
    let title: String
    let subtitle: String
    let controllerType: UIViewController.Type
  }

  private let rows: [Row] = [
    Row(
      title: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.0.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.0.subtitle"),
      controllerType: FKPluggableCoreExampleViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.1.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.1.subtitle"),
      controllerType: FKPluggableNetworkingExampleViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.2.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.2.subtitle"),
      controllerType: FKPluggableAnalyticsExampleViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.3.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.3.subtitle"),
      controllerType: FKPluggableStorageExampleViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.4.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.4.subtitle"),
      controllerType: FKPluggableSessionExampleViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.5.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.5.subtitle"),
      controllerType: FKPluggableConfigurationExampleViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.6.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.6.subtitle"),
      controllerType: FKPluggableLocalizationExampleViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.7.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.7.subtitle"),
      controllerType: FKPluggableRoutingExampleViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.8.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.8.subtitle"),
      controllerType: FKPluggableLoggingExampleViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.9.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.9.subtitle"),
      controllerType: FKPluggableMediaExampleViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.10.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.10.subtitle"),
      controllerType: FKPluggableListCellExampleViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.11.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fkpluggableexampleshubviewcontroller.11.subtitle"),
      controllerType: FKPluggableTextInputExampleViewController.self
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pluggable"
    view.backgroundColor = .systemGroupedBackground
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
    config.secondaryTextProperties.numberOfLines = 2
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(rows[indexPath.row].controllerType.init(), animated: true)
  }
}
