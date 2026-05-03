import FKUIKit
import UIKit

/// Entry list for ``FKProgressBar`` samples (`Scenarios/`, `SwiftUI/`, `Shared/`).
///
/// The hub is grouped by intent so global teams can find integration, visual, and bridge demos quickly.
final class FKProgressBarExamplesHubViewController: UITableViewController {

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
    DemoSection(title: "Interactive", items: [
      DemoItem(
        title: "Playground (full configuration)",
        subtitle: "Goal: exercise every public knob on one live bar. Params: variant, axis, buffer, segments, motion, label, a11y, haptics. Expect: immediate visual feedback and safe edge values.",
        factory: { FKProgressBarPlaygroundDemoViewController() }
      ),
      DemoItem(
        title: "Progress as button",
        subtitle: "Goal: tap targets, custom titles, and UIControl actions for download-style flows. Params: interactionMode.button, labelContentMode, touchHaptic, minimumTouchTargetSize. Expect: primaryActionTriggered / touchUpInside and dimming when disabled.",
        factory: { FKProgressBarProgressButtonDemoViewController() }
      ),
      DemoItem(
        title: "Preset gallery",
        subtitle: "Goal: compare common product patterns side-by-side. Params: frozen configurations. Expect: quick visual regression and RTL-friendly layouts.",
        factory: { FKProgressBarGalleryDemoViewController() }
      ),
    ]),
    DemoSection(title: "Integration", items: [
      DemoItem(
        title: "Delegate event log",
        subtitle: "Goal: verify delegate hooks for analytics or chained UI. Params: animated progress + buffer. Expect: ordered log lines without retain cycles.",
        factory: { FKProgressBarDelegateLogDemoViewController() }
      ),
      DemoItem(
        title: "SwiftUI bridge",
        subtitle: "Goal: embed ``FKProgressBarView`` in SwiftUI state. Params: bindings + shared configuration. Expect: same semantics as UIKit host.",
        factory: { FKProgressBarSwiftUIDemoViewController() }
      ),
    ]),
    DemoSection(title: "Global layout & accessibility", items: [
      DemoItem(
        title: "RTL, semantics & VoiceOver copy",
        subtitle: "Goal: validate leading/trailing semantics and localized accessibility labels. Params: forced RTL + custom a11y strings. Expect: mirrored growth and readable VoiceOver.",
        factory: { FKProgressBarEnvironmentDemoViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKProgressBar"
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
