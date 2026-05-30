import UIKit

/// Entry table for FKCallout, FKTooltip, and FKPopover demos.
final class FKCalloutExamplesHubViewController: UITableViewController {
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
      title: "FKTooltip",
      rows: [
        Row(
          title: "Tooltip basics",
          subtitle: "Placements, multiline, iconMessage, light & dark styles",
          make: { FKCalloutTooltipBasicsExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "FKPopover · Content",
      rows: [
        Row(
          title: "Popover content",
          subtitle: "message, titleSubtitle, headerPanel, appearance styles",
          make: { FKCalloutPopoverContentExampleViewController() }
        ),
        Row(
          title: "Coach mark",
          subtitle: "FKPopover.showCoachMark with close and primary action",
          make: { FKCalloutCoachMarkExampleViewController() }
        ),
        Row(
          title: "Footer actions",
          subtitle: "FKPopover.show(message:actions:actionHandlers:)",
          make: { FKCalloutPopoverActionsExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "FKPopover · Menus",
      rows: [
        Row(
          title: "Action menu",
          subtitle: "Sectioned menu, header rows, frosted menu variant",
          make: { FKCalloutActionMenuExampleViewController() }
        ),
        Row(
          title: "Select menu",
          subtitle: "Content-sized menu, trailing checkmark, selection updates trigger",
          make: { FKCalloutSelectMenuExampleViewController() }
        ),
        Row(
          title: "Account menu",
          subtitle: "Single-column compositional list in customView popover",
          make: { FKCalloutAccountMenuExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Layout & chrome",
      rows: [
        Row(
          title: "Placements & beak offset",
          subtitle: "All 12 FKCalloutPlacement values and FKCalloutBeakOffset",
          make: { FKCalloutPlacementGridExampleViewController() }
        ),
        Row(
          title: "Beak styles",
          subtitle: "FKCalloutBeakStyle presets and customBeakViewProvider",
          make: { FKCalloutBeakStylesExampleViewController() }
        ),
        Row(
          title: "Frosted glass",
          subtitle: "FKCalloutAppearance.usesFrostedGlassBackground",
          make: { FKCalloutFrostedGlassExampleViewController() }
        ),
        Row(
          title: "Layout behavior",
          subtitle: "sourceRect, maxContentHeight, keyboardAvoidance, edge flip",
          make: { FKCalloutLayoutBehaviorExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Custom & advanced",
      rows: [
        Row(
          title: "Scrollable panels",
          subtitle: "UITableView and UIScrollView inside customView popovers",
          make: { FKCalloutScrollablePanelsExampleViewController() }
        ),
        Row(
          title: "Interactive playground",
          subtitle: "Live switches, segments, and sliders for configuration",
          make: { FKCalloutInteractivePlaygroundViewController() }
        ),
        Row(
          title: "FKCallout advanced",
          subtitle: "Builder, showOrUpdate, concurrent policy, lifecycle hooks",
          make: { FKCalloutAdvancedExampleViewController() }
        ),
        Row(
          title: "SwiftUI bridge",
          subtitle: "FKCalloutSwiftUIAnchorButton from FKUIKit",
          make: { FKCalloutExampleSwiftUIViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Callout"
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
