import FKUIKit
import UIKit

/// Grouped index for ``FKIconView`` demos.
final class FKIconViewExamplesHubViewController: UITableViewController {

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
    DemoSection(title: "Display & sizing", items: [
      DemoItem(
        title: "Three sizes",
        subtitle: "FKIconViewSize.s / .m / .l — 24, 28, and 32 pt containers with matched symbol point sizes.",
        factory: { FKIconViewExampleThreeSizesViewController() }
      ),
      DemoItem(
        title: "Background styles",
        subtitle: "Transparent, circle fill, and rounded-rect chrome for list and settings rows.",
        factory: { FKIconViewExampleBackgroundsViewController() }
      ),
      DemoItem(
        title: "Content sources",
        subtitle: "SF Symbol vs UIImage; image takes priority; template tint vs original aspect-fit.",
        factory: { FKIconViewExampleContentSourcesViewController() }
      ),
      DemoItem(
        title: "Empty & placeholder",
        subtitle: "emptyContentBehavior.hidden vs .placeholder when symbolName and image are nil.",
        factory: { FKIconViewExampleEmptyContentViewController() }
      ),
    ]),
    DemoSection(title: "Integration", items: [
      DemoItem(
        title: "With badge",
        subtitle: "applyDefaultBadgeAnchor, dot/count/text badges via UIView.fk_badge.",
        factory: { FKIconViewExampleWithBadgeViewController() }
      ),
      DemoItem(
        title: "Settings list row",
        subtitle: "Leading FKIconView in a typical settings cell with rounded background.",
        factory: { FKIconViewExampleInListRowViewController() }
      ),
      DemoItem(
        title: "In chip leading",
        subtitle: "Same FKWidgetIcon payload on FKIconView and FKChip for consistent glyphs.",
        factory: { FKIconViewExampleInChipLeadingViewController() }
      ),
      DemoItem(
        title: "WidgetIcon apply",
        subtitle: "applyWidgetIcon(_:) with .symbol and .image cases from FKWidgetIcon.",
        factory: { FKIconViewExampleWidgetIconViewController() }
      ),
    ]),
    DemoSection(title: "Configuration & environment", items: [
      DemoItem(
        title: "Playground",
        subtitle: "Live size, background, symbol weight, and tint.",
        factory: { FKIconViewExamplePlaygroundViewController() }
      ),
      DemoItem(
        title: "Accessibility",
        subtitle: "Decorative (hidden from VoiceOver) vs semantic icons with custom label and hint.",
        factory: { FKIconViewExampleAccessibilityViewController() }
      ),
      DemoItem(
        title: "SwiftUI bridge",
        subtitle: "FKIconViewRepresentable with configuration, symbolName, image, and tintColor.",
        factory: { FKIconViewExampleSwiftUIViewController() }
      ),
      DemoItem(
        title: "RTL & appearance",
        subtitle: "Forced RTL layout, light/dark interface styles, badge anchor mirroring.",
        factory: { FKIconViewExampleEnvironmentViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "IconView"
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
