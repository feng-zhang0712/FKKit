import UIKit

/// Grouped index of baseline (B1–B9) and enhancement (E1–E3) ``FKBusinessKit`` scenarios.
final class FKBusinessKitExamplesHubViewController: UITableViewController {
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
      title: "Baseline (B1–B9)",
      rows: [
        Row(title: "B1 VersionCheck", subtitle: "Mock provider + optional update decision", make: { FKBusinessKitExampleVersionCheckViewController() }),
        Row(title: "B2 VersionForceUpdate", subtitle: "Force update prompt path", make: { FKBusinessKitExampleVersionForceUpdateViewController() }),
        Row(title: "B3 AnalyticsBufferFlush", subtitle: "Enqueue events + manual/background flush", make: { FKBusinessKitExampleAnalyticsBufferFlushViewController() }),
        Row(title: "B4 LanguageSwitch", subtitle: "setLanguageCode + relative time refresh", make: { FKBusinessKitExampleLanguageSwitchViewController() }),
        Row(title: "B5 LifecycleLog", subtitle: "Lifecycle state stream", make: { FKBusinessKitExampleLifecycleLogViewController() }),
        Row(title: "B6 DeeplinkRoute", subtitle: "register routes + simulate URLs", make: { FKBusinessKitExampleDeeplinkRouteViewController() }),
        Row(title: "B7 MaskAndFormat", subtitle: "mask + number + time formatters", make: { FKBusinessKitExampleMaskAndFormatViewController() }),
        Row(title: "B8 StartupTasks", subtitle: "Priority + delay orchestration", make: { FKBusinessKitExampleStartupTasksViewController() }),
        Row(title: "B9 AlertPresentOnce", subtitle: "System alert de-duplication by id", make: { FKBusinessKitExampleAlertPresentOnceViewController() }),
      ]
    ),
    Section(
      title: "Enhancements (E1–E3)",
      rows: [
        Row(title: "E1 AlertBackendFKAlert", subtitle: "alertBackend .fkAlert + injected presenter", make: { FKBusinessKitExampleAlertBackendFKAlertViewController() }),
        Row(title: "E2 PluggableBridge", subtitle: "Lifecycle + Analytics Pluggable adapters", make: { FKBusinessKitExamplePluggableBridgeViewController() }),
        Row(title: "E3 BannerVersionCompose", subtitle: "Doc pattern: check → host FKBanner (when available)", make: { FKBusinessKitExampleBannerVersionComposeViewController() }),
      ]
    ),
    Section(
      title: "Catalog",
      rows: [
        Row(
          title: "H0 All-in-One",
          subtitle: "Single-screen tour of every FKBusinessKit API",
          make: { FKBusinessKitExampleViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKBusinessKit"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
  }

  override func numberOfSections(in tableView: UITableView) -> Int { sections.count }

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
    config.secondaryTextProperties.numberOfLines = 2
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(sections[indexPath.section].rows[indexPath.row].make(), animated: true)
  }
}
