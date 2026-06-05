import UIKit

/// Index of EmptyState demos. Sources live under `Basics/`, `Advanced/`, and `Support/`.
final class FKEmptyStateExamplesHubViewController: UITableViewController {
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
      title: "Common scenarios",
      rows: [
        Row(
          title: "Basic empty state",
          subtitle: "Default copy, icon and a minimal action",
          make: { FKEmptyStateBasicExampleViewController() }
        ),
        Row(
          title: "No results + clear filters",
          subtitle: "Search query interpolation with clear filters action",
          make: { FKEmptyStateSearchNoResultsExampleViewController() }
        ),
        Row(
          title: "Error + retry loading action",
          subtitle: "Retry button enters loading state before resolving",
          make: { FKEmptyStateErrorRetryExampleViewController() }
        ),
        Row(
          title: "Offline + open docs/check network",
          subtitle: "Primary retry plus custom secondary bordered styling",
          make: { FKEmptyStateOfflineExampleViewController() }
        ),
        Row(
          title: "Permission denied + request access",
          subtitle: "Permission copy, request access and contact admin",
          make: { FKEmptyStatePermissionDeniedExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Layout & transitions",
      rows: [
        Row(
          title: "Loading placeholder -> empty",
          subtitle: "Skeleton loading overlay, then instant in-place swap to empty state",
          make: { FKEmptyStateLoadingTransitionExampleViewController() }
        ),
        Row(
          title: "Action styles & transitions",
          subtitle: "Primary, secondary, tertiary, link, and all content transition modes",
          make: { FKEmptyStateActionsAndTransitionsExampleViewController() }
        ),
        Row(
          title: "Full page vs inline section",
          subtitle: "Compare container layout strategies side-by-side",
          make: { FKEmptyStateLayoutComparisonExampleViewController() }
        ),
        Row(
          title: "Layout density, axis & link action",
          subtitle: "Compact spacing, horizontal row layout, tinted icon, and link-style tertiary",
          make: { FKEmptyStateCapabilitiesExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Customization",
      rows: [
        Row(
          title: "Custom icon/illustration (lazy)",
          subtitle: "Lazy-load an accessory view and icon-only edge case",
          make: { FKEmptyStateCustomIllustrationExampleViewController() }
        ),
        Row(
          title: "Dark mode + token override",
          subtitle: "Theme override with custom color tokens",
          make: { FKEmptyStateDarkModeExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Localization",
      rows: [
        Row(
          title: "RTL layout example",
          subtitle: "Force RTL direction with Arabic copy",
          make: { FKEmptyStateRTLExampleViewController() }
        ),
        Row(
          title: "i18n example (en + zh-CN)",
          subtitle: "Factory-based localized copy with interpolation",
          make: { FKEmptyStateI18nExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Advanced",
      rows: [
        Row(
          title: "State resolver example",
          subtitle: "Resolve semantic type from loading/offline/permission/data/query/error",
          make: { FKEmptyStateResolverExampleViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    FKEmptyStateExampleFactory.configureGlobalStyleIfNeeded()
    title = "FKEmptyState"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.rowHeight = 72
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    sections.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    sections[section].title
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    sections[section].rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = sections[indexPath.section].rows[indexPath.row]
    var content = cell.defaultContentConfiguration()
    content.text = row.title
    content.secondaryText = row.subtitle
    content.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = content
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let destination = sections[indexPath.section].rows[indexPath.row].make()
    navigationController?.pushViewController(destination, animated: true)
  }
}
