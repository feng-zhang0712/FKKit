import FKUIKit
import UIKit

/// Grouped index for ``FKTheme`` demos.
final class FKThemeExamplesHubViewController: UITableViewController {

  init() {
    super.init(style: .insetGrouped)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private struct DemoItem {
    let title: String
    let subtitle: String
    let factory: () -> UIViewController
  }

  private struct DemoSection {
    let title: String
    let items: [DemoItem]
  }

  private lazy var sections: [DemoSection] = [
    DemoSection(title: "Getting started", items: [
      DemoItem(
        title: "Default baseline",
        subtitle: "FKTheme.default without registration — FKButton and FKToast keep factory defaults.",
        factory: { FKThemeExampleDefaultBaselineViewController() }
      ),
      DemoItem(
        title: "Custom brand registration",
        subtitle: "FKThemeRegistry.register applies primary color to new FKButton instances and FKToast defaults.",
        factory: { FKThemeExampleCustomBrandViewController() }
      ),
      DemoItem(
        title: "Restore factory defaults",
        subtitle: "Re-register FKTheme.default to clear FKButtonGlobalStyle and FKToast.defaultConfiguration overrides.",
        factory: { FKThemeExampleRestoreDefaultsViewController() }
      ),
    ]),
    DemoSection(title: "Design tokens", items: [
      DemoItem(
        title: "Semantic color palette",
        subtitle: "All FKThemeColorRole swatches resolved with FKThemeResolver for the active trait collection.",
        factory: { FKThemeExampleColorPaletteViewController() }
      ),
      DemoItem(
        title: "Typography ramp",
        subtitle: "FKThemeTextStyle ladder with UIFontMetrics scaling across content size categories.",
        factory: { FKThemeExampleTypographyViewController() }
      ),
      DemoItem(
        title: "Metrics & spacing",
        subtitle: "FKThemeMetrics spacing tokens, corner radii, hairline, and minimumHitTarget (44 pt).",
        factory: { FKThemeExampleMetricsViewController() }
      ),
      DemoItem(
        title: "Shadow elevations",
        subtitle: "FKThemeShadowTokens mapped to FKLayerShadowStyle on sample surfaces.",
        factory: { FKThemeExampleShadowTokensViewController() }
      ),
      DemoItem(
        title: "Status semantics",
        subtitle: "Workflow status colors aligned with FKWidgetStatusSemantic and FKStatusPill.",
        factory: { FKThemeExampleStatusSemanticsViewController() }
      ),
    ]),
    DemoSection(title: "Registry & resolution", items: [
      DemoItem(
        title: "Registry & FKThemeAware",
        subtitle: "themeDidChangeNotification and FKThemeAware.apply(theme:) refresh live UI.",
        factory: { FKThemeExampleRegistryNotificationViewController() }
      ),
      DemoItem(
        title: "Resolver & scrim",
        subtitle: "FKThemeResolver.color(_:in:traitCollection:) and scrimColor with Reduce Transparency.",
        factory: { FKThemeExampleResolverViewController() }
      ),
      DemoItem(
        title: "Application options",
        subtitle: "FKThemeApplicationOptions — notification, window refresh, and component default toggles.",
        factory: { FKThemeExampleApplicationOptionsViewController() }
      ),
      DemoItem(
        title: "Built-in presets",
        subtitle: "Compare FKTheme.default and FKTheme.defaultDark identifiers and token snapshots.",
        factory: { FKThemeExampleBuiltInPresetsViewController() }
      ),
    ]),
    DemoSection(title: "Component integration", items: [
      DemoItem(
        title: "Button roles",
        subtitle: "makeButtonStateAppearances(for:) — primary, secondary, and destructive roles.",
        factory: { FKThemeExampleButtonRolesViewController() }
      ),
      DemoItem(
        title: "Toast defaults",
        subtitle: "makeToastConfiguration() surface colors, typography, and shadow from the active theme.",
        factory: { FKThemeExampleToastIntegrationViewController() }
      ),
      DemoItem(
        title: "Registration playground",
        subtitle: "Live primary color picker re-registers the brand theme and refreshes integrated components.",
        factory: { FKThemeExampleRegistrationPlaygroundViewController() }
      ),
    ]),
    DemoSection(title: "SwiftUI", items: [
      DemoItem(
        title: "Environment bridge",
        subtitle: "EnvironmentValues.fkTheme and View.fkTheme(_:) read-only theme injection.",
        factory: { FKThemeExampleSwiftUIViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Theme"
    navigationItem.largeTitleDisplayMode = .never
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    sections.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    sections[section].title
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    sections[section].items.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = sections[indexPath.section].items[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.secondaryTextProperties.numberOfLines = 0
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(sections[indexPath.section].items[indexPath.row].factory(), animated: true)
  }
}
