import FKUIKit
import UIKit

/// Grouped index for ``FKCopyChip`` demos.
final class FKCopyChipExamplesHubViewController: UITableViewController {

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
    DemoSection(title: "Display & copy", items: [
      DemoItem(
        title: "Order ID",
        subtitle: "prefix, middle truncation, copyText copies the full ID while the chip shows a short form.",
        factory: { FKCopyChipExampleOrderIDViewController() }
      ),
      DemoItem(
        title: "Monospaced tracking",
        subtitle: "usesMonospacedFont, tail truncation, logistics-style tracking numbers.",
        factory: { FKCopyChipExampleMonospacedViewController() }
      ),
    ]),
    DemoSection(title: "Feedback", items: [
      DemoItem(
        title: "Toast success",
        subtitle: "FKCopyChipFeedback.toast, custom message, optional haptic with toast.",
        factory: { FKCopyChipExampleToastViewController() }
      ),
      DemoItem(
        title: "Haptic only",
        subtitle: "Light impact feedback without toast or spoken announcement.",
        factory: { FKCopyChipExampleHapticViewController() }
      ),
      DemoItem(
        title: "Silent copy",
        subtitle: "feedback.none — no toast, haptic, flash, or VoiceOver announcement.",
        factory: { FKCopyChipExampleSilentViewController() }
      ),
    ]),
    DemoSection(title: "Integration", items: [
      DemoItem(
        title: "Configuration playground",
        subtitle: "Size S/M, corner style, copy symbol, success flash, disabled state.",
        factory: { FKCopyChipExamplePlaygroundViewController() }
      ),
      DemoItem(
        title: "Callbacks & notifications",
        subtitle: "onCopy, Notification.Name.fk_copyChipDidCopy, primaryActionTriggered.",
        factory: { FKCopyChipExampleCallbacksViewController() }
      ),
      DemoItem(
        title: "SwiftUI bridge",
        subtitle: "FKCopyChipRepresentable with configuration and onCopy binding.",
        factory: { FKCopyChipExampleSwiftUIViewController() }
      ),
      DemoItem(
        title: "RTL & appearance",
        subtitle: "Forced RTL, light/dark styles, custom accessibility label.",
        factory: { FKCopyChipExampleEnvironmentViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "CopyChip"
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
