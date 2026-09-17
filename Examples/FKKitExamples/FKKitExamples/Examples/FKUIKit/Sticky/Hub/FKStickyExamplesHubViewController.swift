import UIKit

/// Index of FKSticky demos, grouped by capability area.
final class FKStickyExamplesHubViewController: UITableViewController {
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
      title: "Basics",
      rows: [
        Row(
          title: "Single top sticky (UIScrollView)",
          subtitle: "fk_addStickyTarget + default top edge / KVO observation",
          make: { FKStickySingleTopExampleViewController() }
        ),
        Row(
          title: "UITableView header strip",
          subtitle: "Sticky target hosted in tableHeaderView",
          make: { FKStickyTableViewExampleViewController() }
        ),
        Row(
          title: "UICollectionView content strip",
          subtitle: "Sticky strip as a collection-view subview in content coordinates",
          make: { FKStickyCollectionViewExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Edges & insets",
      rows: [
        Row(
          title: "Bottom edge",
          subtitle: "FKStickyEdge.bottom pin above the home indicator inset",
          make: { FKStickyBottomEdgeExampleViewController() }
        ),
        Row(
          title: "Sticky inset & provider",
          subtitle: "configuration.stickyInset + stickyInsetProvider (dynamic chrome)",
          make: { FKStickyInsetProviderExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Collision",
      rows: [
        Row(
          title: "Push-off (multi-target)",
          subtitle: "FKStickyCollisionBehavior.pushOff — next bar replaces the current",
          make: { FKStickyPushOffExampleViewController() }
        ),
        Row(
          title: "Stack (multi-target)",
          subtitle: "FKStickyCollisionBehavior.stack — simultaneous stacked pins",
          make: { FKStickyStackExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Appearance & callbacks",
      rows: [
        Row(
          title: "Progress, lifecycle & engine shadow",
          subtitle: "onProgressChange / will·did stick·unstick + appliesStuckShadow",
          make: { FKStickyProgressLifecycleExampleViewController() }
        ),
        Row(
          title: "Stuck-set observation & queries",
          subtitle: "onStuckTargetsChange, stuckTargetIDs, progress/state/target(id:)",
          make: { FKStickyStuckSetExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Runtime controls",
      rows: [
        Row(
          title: "Enable, force stick & target toggle",
          subtitle: "setEnabled, forceStick/clearForcedStick, target.isEnabled, remove/reset",
          make: { FKStickyRuntimeControlsExampleViewController() }
        ),
        Row(
          title: "Reload layout while stuck",
          subtitle: "fk_reloadStickyLayout remasures size / placeholder while pinned",
          make: { FKStickyReloadLayoutExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Observation",
      rows: [
        Row(
          title: "Manual scroll forwarding",
          subtitle: "observesAutomatically = false + fk_handleStickyScroll / handleScroll",
          make: { FKStickyManualObservationExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Configuration details",
      rows: [
        Row(
          title: "Placeholder, hysteresis, priority & override",
          subtitle: "preservesPlaceholder, unstickHysteresis, priority, stickyInsetOverride",
          make: { FKStickyConfigurationDetailsExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Combined",
      rows: [
        Row(
          title: "Interactive playground",
          subtitle: "Toggle edge, collision, shadow, hysteresis, inset, observation live",
          make: { FKStickyPlaygroundExampleViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKSticky"
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
    sections[section].rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = sections[indexPath.section].rows[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let row = sections[indexPath.section].rows[indexPath.row]
    navigationController?.pushViewController(row.make(), animated: true)
  }
}
