import FKUIKit
import UIKit

/// Grouped index for ``FKStatusPill`` demos.
final class FKStatusPillExamplesHubViewController: UITableViewController {

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
    DemoSection(title: "Workflow styles", items: [
      DemoItem(
        title: "Order status pills",
        subtitle: "FKStatusPillStyle success / warning / error / info / neutral — workflow semantics via FKWidgetStatusColorTokens.",
        factory: { FKStatusPillExampleOrderStatusesViewController() }
      ),
      DemoItem(
        title: "With leading dot",
        subtitle: "showsDot, dotDiameter, dotSpacing — 8 pt dot with 6 pt gap before title.",
        factory: { FKStatusPillExampleWithDotViewController() }
      ),
      DemoItem(
        title: "Custom backend enum",
        subtitle: "FKStatusPillStyle.custom(FKStatusPillCustomAppearance) for server-driven states.",
        factory: { FKStatusPillExampleCustomBackendViewController() }
      ),
      DemoItem(
        title: "Info pulse dot",
        subtitle: "appearance.pulsesDotForInfoStyle — optional animated dot for in-progress info style.",
        factory: { FKStatusPillExampleInfoPulseViewController() }
      ),
    ]),
    DemoSection(title: "Layout & integration", items: [
      DemoItem(
        title: "Size tiers",
        subtitle: "FKStatusPillSize.s (28 pt) vs .m (32 pt) with scaled caption fonts.",
        factory: { FKStatusPillExampleSizesViewController() }
      ),
      DemoItem(
        title: "Configuration playground",
        subtitle: "maxWidth truncation, cornerStyle, dotColorOverride, and textStyle.",
        factory: { FKStatusPillExamplePlaygroundViewController() }
      ),
      DemoItem(
        title: "List row with Tag",
        subtitle: "FKTag metadata + FKStatusPill workflow status on the same order row.",
        factory: { FKStatusPillExampleListRowWithTagViewController() }
      ),
    ]),
    DemoSection(title: "Accessibility & SwiftUI", items: [
      DemoItem(
        title: "Accessibility",
        subtitle: "customLabel, includesStatusSuffix, and localized “{title}, status” VoiceOver label.",
        factory: { FKStatusPillExampleAccessibilityViewController() }
      ),
      DemoItem(
        title: "SwiftUI bridge",
        subtitle: "FKStatusPillView with configuration, style, title, and showsDot.",
        factory: { FKStatusPillExampleSwiftUIViewController() }
      ),
      DemoItem(
        title: "Light & dark",
        subtitle: "System adaptive status palettes in light and dark interface styles.",
        factory: { FKStatusPillExampleAppearanceViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "StatusPill"
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
