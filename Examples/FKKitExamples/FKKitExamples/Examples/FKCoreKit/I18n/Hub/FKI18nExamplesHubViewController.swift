import UIKit
import FKCoreKit

/// Entry table for all FKI18n demos under `FKCoreKit/Components/I18n`.
final class FKI18nExamplesHubViewController: UITableViewController {

  private struct Row {
    let title: String
    let subtitle: String
    let controllerType: UIViewController.Type
  }

  private let rows: [Row] = [
    Row(
      title: FKExamplesI18n.string("examples.hub.fki18nexampleshubviewcontroller.0.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fki18nexampleshubviewcontroller.0.subtitle"),
      controllerType: FKI18nLanguageSwitcherExampleViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fki18nexampleshubviewcontroller.1.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fki18nexampleshubviewcontroller.1.subtitle"),
      controllerType: FKI18nBundleExampleViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fki18nexampleshubviewcontroller.2.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fki18nexampleshubviewcontroller.2.subtitle"),
      controllerType: FKI18nFormatExampleViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fki18nexampleshubviewcontroller.3.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fki18nexampleshubviewcontroller.3.subtitle"),
      controllerType: FKI18nDictionaryExampleViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fki18nexampleshubviewcontroller.4.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fki18nexampleshubviewcontroller.4.subtitle"),
      controllerType: FKI18nObserverExampleViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fki18nexampleshubviewcontroller.5.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fki18nexampleshubviewcontroller.5.subtitle"),
      controllerType: FKI18nRTLExampleViewController.self
    ),
    Row(
      title: FKExamplesI18n.string("examples.hub.fki18nexampleshubviewcontroller.6.title"),
      subtitle: FKExamplesI18n.string("examples.hub.fki18nexampleshubviewcontroller.6.subtitle"),
      controllerType: FKI18nIntegrationExampleViewController.self
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKI18n"
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
