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
      title: "Language Switcher",
      subtitle: "All 11 recommended locales — live greeting, RTL badge, persistence",
      controllerType: FKI18nLanguageSwitcherExampleViewController.self
    ),
    Row(
      title: "Bundle Strings",
      subtitle: "`.lproj` lookup via FKI18nConfiguration.bundle and FKI18nDemo.strings",
      controllerType: FKI18nBundleExampleViewController.self
    ),
    Row(
      title: "Format & Variables",
      subtitle: "{token} interpolation, String(format:), formatters, plural counts",
      controllerType: FKI18nFormatExampleViewController.self
    ),
    Row(
      title: "Dictionary Backend",
      subtitle: "FKI18nStaticDictionaryTranslator overlay before bundle lookup",
      controllerType: FKI18nDictionaryExampleViewController.self
    ),
    Row(
      title: "Observers",
      subtitle: "observeLanguageChange token + NotificationCenter broadcast",
      controllerType: FKI18nObserverExampleViewController.self
    ),
    Row(
      title: "RTL Layout",
      subtitle: "Arabic direction — semanticContentAttribute and leading/trailing",
      controllerType: FKI18nRTLExampleViewController.self
    ),
    Row(
      title: "Integration",
      subtitle: "FKLocalizing protocol and FKBusinessI18nManager adapter",
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
