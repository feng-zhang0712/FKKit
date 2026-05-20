import UIKit

/// Entry table for all FKPluggable protocol contract demos under `FKCoreKit/Pluggable`.
final class FKPluggableExamplesHubViewController: UITableViewController {

  private struct Row {
    let title: String
    let subtitle: String
    let controllerType: UIViewController.Type
  }

  private let rows: [Row] = [
    Row(
      title: "Core",
      subtitle: "Contract version, observation tokens, app lifecycle observing",
      controllerType: FKPluggableCoreExampleViewController.self
    ),
    Row(
      title: "Networking",
      subtitle: "API client, interceptors, signing, credentials, token refresh, reachability",
      controllerType: FKPluggableNetworkingExampleViewController.self
    ),
    Row(
      title: "Analytics",
      subtitle: "Events, common parameters, uploader, tracking, flush",
      controllerType: FKPluggableAnalyticsExampleViewController.self
    ),
    Row(
      title: "Storage",
      subtitle: "FKKeyValueStoring, FKCodableStoring JSON helpers",
      controllerType: FKPluggableStorageExampleViewController.self
    ),
    Row(
      title: "Session",
      subtitle: "FKUserSessionProviding, authentication observers",
      controllerType: FKPluggableSessionExampleViewController.self
    ),
    Row(
      title: "Configuration",
      subtitle: "Environment, feature flags, remote config",
      controllerType: FKPluggableConfigurationExampleViewController.self
    ),
    Row(
      title: "Localization",
      subtitle: "FKLocalizing, FKTranslating with placeholders",
      controllerType: FKPluggableLocalizationExampleViewController.self
    ),
    Row(
      title: "Routing",
      subtitle: "Deeplink parsing, handler chain, FKDeeplinkRouting",
      controllerType: FKPluggableRoutingExampleViewController.self
    ),
    Row(
      title: "Logging",
      subtitle: "FKPluggableLogging levels and convenience helpers",
      controllerType: FKPluggableLoggingExampleViewController.self
    ),
    Row(
      title: "Media",
      subtitle: "FKImageLoading, FKImageCaching",
      controllerType: FKPluggableMediaExampleViewController.self
    ),
    Row(
      title: "UIKit — List Cells",
      subtitle: "FKCellReusable, table/collection configurables, register/dequeue helpers",
      controllerType: FKPluggableListCellExampleViewController.self
    ),
    Row(
      title: "UIKit — Text Input",
      subtitle: "FKTextFormatting, FKTextValidating, FKTextAsyncValidating",
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
