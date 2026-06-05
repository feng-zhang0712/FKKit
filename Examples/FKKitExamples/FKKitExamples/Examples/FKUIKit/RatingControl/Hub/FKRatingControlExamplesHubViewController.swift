import FKUIKit
import UIKit

/// Lists ``FKRatingControl`` example screens.
final class FKRatingControlExamplesHubViewController: UITableViewController {

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
    DemoSection(title: "Basics", items: [
      DemoItem(
        title: "Interactive stars",
        subtitle: "Tap and drag, whole vs half steps, live value readout.",
        factory: { FKRatingExampleInteractiveViewController() }
      ),
      DemoItem(
        title: "Read-only display",
        subtitle: "Product-style 4.5★ summary and review list rows.",
        factory: { FKRatingExampleReadOnlyViewController() }
      ),
      DemoItem(
        title: "Convenience factories",
        subtitle: "`readOnlyStars` and `interactiveStars` helpers.",
        factory: { FKRatingExampleConvenienceViewController() }
      ),
    ]),
    DemoSection(title: "Icons & labels", items: [
      DemoItem(
        title: "Icon presets",
        subtitle: "Star, heart, and thumb SF Symbol presets.",
        factory: { FKRatingExampleIconPresetsViewController() }
      ),
      DemoItem(
        title: "Custom symbols & images",
        subtitle: "`.symbols` and `.images` icon styles.",
        factory: { FKRatingExampleCustomIconsViewController() }
      ),
      DemoItem(
        title: "Value caption",
        subtitle: "Trailing, bottom, prefix/suffix, and custom label text.",
        factory: { FKRatingExampleLabelPlacementViewController() }
      ),
    ]),
    DemoSection(title: "Interaction", items: [
      DemoItem(
        title: "Playground",
        subtitle: "Live preview of major configuration groups.",
        factory: { FKRatingExamplePlaygroundViewController() }
      ),
      DemoItem(
        title: "Modes & feedback",
        subtitle: "Disabled, tap-only, haptics, and selection animation.",
        factory: { FKRatingExampleInteractionModesViewController() }
      ),
    ]),
    DemoSection(title: "Integration", items: [
      DemoItem(
        title: "Center sheet + rating",
        subtitle: "FKSheetPresentationController `.center` with quick rate, feedback, and App Store prompts.",
        factory: { FKRatingExampleSheetIntegrationViewController() }
      ),
      DemoItem(
        title: "Delegate event log",
        subtitle: "`FKRatingControlDelegate` and `onValueChanged`.",
        factory: { FKRatingExampleDelegateLogViewController() }
      ),
      DemoItem(
        title: "SwiftUI bridge",
        subtitle: "`FKRatingControlRepresentable` bindings.",
        factory: { FKRatingExampleSwiftUIViewController() }
      ),
    ]),
    DemoSection(title: "Layout & accessibility", items: [
      DemoItem(
        title: "RTL & VoiceOver copy",
        subtitle: "Forced RTL and custom accessibility strings.",
        factory: { FKRatingExampleEnvironmentViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKRatingControl"
    navigationItem.largeTitleDisplayMode = .never
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
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
    let vc = sections[indexPath.section].items[indexPath.row].factory()
    navigationController?.pushViewController(vc, animated: true)
  }
}
