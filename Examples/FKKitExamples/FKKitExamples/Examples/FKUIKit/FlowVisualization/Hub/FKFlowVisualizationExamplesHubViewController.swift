import FKUIKit
import UIKit

/// Lists ``FKStepIndicator`` and ``FKTimeline`` example screens.
final class FKFlowVisualizationExamplesHubViewController: UITableViewController {

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
    DemoSection(title: "FKStepIndicator — Flows", items: [
      DemoItem(
        title: "Checkout steps",
        subtitle: "Read-only preset, index-driven `currentStepIndex`, Next/Back controls.",
        factory: { FKFlowCheckoutStepsExampleViewController() }
      ),
      DemoItem(
        title: "Onboarding wizard",
        subtitle: "Tappable completed steps, haptics, onboarding preset.",
        factory: { FKFlowOnboardingWizardExampleViewController() }
      ),
      DemoItem(
        title: "Layout variants",
        subtitle: "Top labels, bottom labels, inline, and compact dots.",
        factory: { FKFlowStepLayoutsExampleViewController() }
      ),
    ]),
    DemoSection(title: "FKStepIndicator — States & icons", items: [
      DemoItem(
        title: "Step states",
        subtitle: "Explicit completed, current, upcoming, error, skipped, and disabled.",
        factory: { FKFlowStepStatesExampleViewController() }
      ),
      DemoItem(
        title: "Custom icons",
        subtitle: "Per-step SF Symbols, numbers, and default state glyphs.",
        factory: { FKFlowCustomIconsExampleViewController() }
      ),
      DemoItem(
        title: "Compact scrollable",
        subtitle: "10 steps, horizontal scroll, and edge fade masks.",
        factory: { FKFlowCompactScrollableExampleViewController() }
      ),
    ]),
    DemoSection(title: "FKStepIndicator — Progress", items: [
      DemoItem(
        title: "Partial connector & loading",
        subtitle: "`currentStepProgress`, `isLoading`, and partial connector fill.",
        factory: { FKFlowPartialProgressExampleViewController() }
      ),
    ]),
    DemoSection(title: "FKTimeline", items: [
      DemoItem(
        title: "Logistics tracking",
        subtitle: "Logistics preset, absolute timestamps, dotted tail, scroll-to-row.",
        factory: { FKFlowLogisticsTimelineExampleViewController() }
      ),
      DemoItem(
        title: "Audit log",
        subtitle: "Grouped sections, caption expansion, audit preset.",
        factory: { FKFlowAuditLogExampleViewController() }
      ),
      DemoItem(
        title: "Rail layouts",
        subtitle: "Leading, trailing, and embedded-in-list rails.",
        factory: { FKFlowTimelineLayoutsExampleViewController() }
      ),
      DemoItem(
        title: "Timestamps & tail styles",
        subtitle: "Relative, absolute, custom, hidden timestamps; none, dotted, to-future tails.",
        factory: { FKFlowTimelineFormattingExampleViewController() }
      ),
      DemoItem(
        title: "Row selection",
        subtitle: "Selectable rows with delegate gating and haptic feedback.",
        factory: { FKFlowTimelineSelectionExampleViewController() }
      ),
    ]),
    DemoSection(title: "Integration", items: [
      DemoItem(
        title: "Delegate event log",
        subtitle: "`FKStepIndicatorDelegate` and `onStepSelected` callbacks.",
        factory: { FKFlowDelegateLogExampleViewController() }
      ),
      DemoItem(
        title: "SwiftUI bridge",
        subtitle: "`FKStepIndicatorRepresentable` and `FKTimelineRepresentable`.",
        factory: { FKFlowSwiftUIExampleViewController() }
      ),
      DemoItem(
        title: "RTL, Dynamic Type & Reduce Motion",
        subtitle: "Forced RTL, AX5 content size, and pulse disabled.",
        factory: { FKFlowEnvironmentExampleViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FlowVisualization"
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
