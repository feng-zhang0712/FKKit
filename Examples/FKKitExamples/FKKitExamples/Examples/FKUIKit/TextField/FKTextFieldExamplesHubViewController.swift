import UIKit
import FKCoreKit

/// Entry table for FKTextField demos (mirrors ``FKBadgeExamplesHubViewController`` layout).
final class FKTextFieldExamplesHubViewController: UITableViewController {

  private struct Row {
    let title: String
    let subtitle: String
    let controllerType: UIViewController.Type
  }

  private let rows: [Row] = [
    Row(title: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.0.title"), subtitle: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.0.subtitle"), controllerType: FKTextFieldExampleBasicsViewController.self),
    Row(title: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.1.title"), subtitle: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.1.subtitle"), controllerType: FKTextFieldExampleFormatsViewController.self),
    Row(title: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.2.title"), subtitle: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.2.subtitle"), controllerType: FKTextFieldExampleStatusGalleryViewController.self),
    Row(title: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.3.title"), subtitle: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.3.subtitle"), controllerType: FKTextFieldExampleValidationViewController.self),
    Row(title: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.4.title"), subtitle: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.4.subtitle"), controllerType: FKTextFieldExampleFormViewController.self),
    Row(title: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.5.title"), subtitle: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.5.subtitle"), controllerType: FKTextFieldExampleOtpCounterViewController.self),
    Row(title: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.6.title"), subtitle: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.6.subtitle"), controllerType: FKTextFieldExamplePasswordViewController.self),
    Row(title: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.7.title"), subtitle: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.7.subtitle"), controllerType: FKTextFieldExampleKeyboardViewController.self),
    Row(title: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.8.title"), subtitle: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.8.subtitle"), controllerType: FKTextFieldExampleI18nViewController.self),
    Row(title: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.9.title"), subtitle: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.9.subtitle"), controllerType: FKTextFieldExampleThemeViewController.self),
    Row(title: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.10.title"), subtitle: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.10.subtitle"), controllerType: FKTextFieldExampleIBViewController.self),
    Row(title: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.11.title"), subtitle: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.11.subtitle"), controllerType: FKTextFieldExampleSwiftUIHostController.self),
    Row(title: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.12.title"), subtitle: FKExamplesI18n.string("examples.hub.fktextfieldexampleshubviewcontroller.12.subtitle"), controllerType: FKTextFieldExampleAdvancedCallbacksViewController.self),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "TextField"
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
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let type = rows[indexPath.row].controllerType
    navigationController?.pushViewController(type.init(), animated: true)
  }
}
