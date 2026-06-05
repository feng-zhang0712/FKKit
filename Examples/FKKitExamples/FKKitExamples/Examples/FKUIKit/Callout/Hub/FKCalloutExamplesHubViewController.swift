import UIKit
import FKCoreKit

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
          title: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.0.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.0.subtitle"),
          make: { FKCalloutTooltipBasicsExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "FKPopover · Content",
      rows: [
        Row(
          title: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.1.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.1.subtitle"),
          make: { FKCalloutPopoverContentExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.2.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.2.subtitle"),
          make: { FKCalloutCoachMarkExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.3.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.3.subtitle"),
          make: { FKCalloutPopoverActionsExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "FKPopover · Menus",
      rows: [
        Row(
          title: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.4.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.4.subtitle"),
          make: { FKCalloutActionMenuExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.5.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.5.subtitle"),
          make: { FKCalloutSelectMenuExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.6.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.6.subtitle"),
          make: { FKCalloutAccountMenuExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Layout & chrome",
      rows: [
        Row(
          title: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.7.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.7.subtitle"),
          make: { FKCalloutPlacementGridExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.8.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.8.subtitle"),
          make: { FKCalloutBeakStylesExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.9.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.9.subtitle"),
          make: { FKCalloutFrostedGlassExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.10.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.10.subtitle"),
          make: { FKCalloutLayoutBehaviorExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Custom & advanced",
      rows: [
        Row(
          title: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.11.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.11.subtitle"),
          make: { FKCalloutScrollablePanelsExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.12.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.12.subtitle"),
          make: { FKCalloutInteractivePlaygroundViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.13.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.13.subtitle"),
          make: { FKCalloutAdvancedExampleViewController() }
        ),
        Row(
          title: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.14.title"),
          subtitle: FKExamplesI18n.string("examples.hub.fkcalloutexampleshubviewcontroller.14.subtitle"),
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
