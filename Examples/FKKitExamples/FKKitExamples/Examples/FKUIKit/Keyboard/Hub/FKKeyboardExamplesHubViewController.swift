import UIKit

/// Index of FKKeyboard demos, grouped by capability area.
final class FKKeyboardExamplesHubViewController: UITableViewController {
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
      title: "Observation",
      rows: [
        Row(
          title: "Observer & KeyboardInfo",
          subtitle: "Live frame, duration, curve, isLocal, overlapHeight, from(notification:)",
          make: { FKKeyboardObserverExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Avoidance",
      rows: [
        Row(
          title: "Content insets",
          subtitle: "FKKeyboardAvoidanceStrategy.adjustContentInsets on a scroll view",
          make: { FKKeyboardAvoidanceContentInsetsExampleViewController() }
        ),
        Row(
          title: "Minimum movement",
          subtitle: "alignsFocusedViewToKeyboard = false (scroll only when covered)",
          make: { FKKeyboardAvoidanceAlignToKeyboardExampleViewController() }
        ),
        Row(
          title: "Container translate",
          subtitle: ".adjustContainer moves the host / container upward",
          make: { FKKeyboardAvoidanceContainerExampleViewController() }
        ),
        Row(
          title: "Interactive strategy",
          subtitle: ".interactive on a scroll view → automatic insets fallback (no blank band)",
          make: { FKKeyboardAvoidanceInteractiveExampleViewController() }
        ),
        Row(
          title: "External observer feed",
          subtitle: "observesKeyboardAutomatically = false + handleKeyboardInfo(_:)",
          make: { FKKeyboardAvoidanceExternalFeedExampleViewController() }
        ),
        Row(
          title: "Disabled strategy",
          subtitle: "Baseline with .disabled — fields can be covered",
          make: { FKKeyboardAvoidanceDisabledExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Layout guide",
      rows: [
        Row(
          title: "Pin to keyboardLayoutGuide",
          subtitle: "FKKeyboardLayout.pinBottom / pinScrollViewBottom",
          make: { FKKeyboardLayoutGuideExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Focus & form",
      rows: [
        Row(
          title: "Focus scroller",
          subtitle: "Scroll first responder into view on keyboard + field changes",
          make: { FKKeyboardFocusScrollerExampleViewController() }
        ),
        Row(
          title: "Align cell to keyboard",
          subtitle: "alignContentRect — pin row bottom to composer (no extra top inset)",
          make: { FKKeyboardAlignCellToKeyboardExampleViewController() }
        ),
        Row(
          title: "Navigator + toolbar",
          subtitle: "discoverFields, install(onFormRoot:), Prev/Next/Done, focus tracking",
          make: { FKKeyboardFormNavigatorToolbarExampleViewController() }
        ),
        Row(
          title: "Return key handling",
          subtitle: "handleReturn(from:) advances or resigns",
          make: { FKKeyboardReturnKeyExampleViewController() }
        ),
        Row(
          title: "Toolbar configuration",
          subtitle: "Custom titles, nav-only / done-only visibility",
          make: { FKKeyboardToolbarConfigurationExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Dismiss",
      rows: [
        Row(
          title: "Tap to dismiss",
          subtitle: "FKKeyboardDismissController + cancelsTouches / ignore first responder",
          make: { FKKeyboardDismissExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Facade & recipes",
      rows: [
        Row(
          title: "Animate & endEditing",
          subtitle: "FKKeyboard.animate(alongside:) and endEditing helpers",
          make: { FKKeyboardAnimateEndEditingExampleViewController() }
        ),
        Row(
          title: "Full form recipe",
          subtitle: "Avoidance + focus + toolbar + dismiss + layout guide together",
          make: { FKKeyboardFullFormExampleViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKKeyboard"
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
