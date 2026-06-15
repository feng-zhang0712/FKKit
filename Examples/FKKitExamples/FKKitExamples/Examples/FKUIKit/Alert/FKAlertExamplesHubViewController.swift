import UIKit

/// Index of ``FKAlert`` examples, grouped by integration path.
final class FKAlertExamplesHubViewController: UITableViewController {
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
      title: "Getting started",
      rows: [
        Row(
          title: "Basics & helpers",
          subtitle: "Informational OK, FKAlert.confirm, FKAlert.prompt, presets",
          make: { FKAlertExampleBasicsViewController() }
        ),
        Row(
          title: "Destructive delete",
          subtitle: "Destructive styling, icon tint, destructiveConfirm preset",
          make: { FKAlertExampleDestructiveDeleteViewController() }
        ),
        Row(
          title: "SwiftUI bridge",
          subtitle: "View.fkAlert binding and result handling",
          make: { FKAlertExampleSwiftUIViewController() }
        ),
      ]
    ),
    Section(
      title: "Content & input",
      rows: [
        Row(
          title: "Text field rename",
          subtitle: "FKAlert.prompt, trimmed text in FKAlertResult",
          make: { FKAlertExampleTextFieldRenameViewController() }
        ),
        Row(
          title: "Validation failure",
          subtitle: "Inline FKTextField error without dismiss",
          make: { FKAlertExampleValidationFailureViewController() }
        ),
        Row(
          title: "Long legal message",
          subtitle: "Adaptive height with body scroll on overflow",
          make: { FKAlertExampleLongLegalMessageViewController() }
        ),
        Row(
          title: "Appearance & layout",
          subtitle: "Icons, attributed message, horizontal button pair",
          make: { FKAlertExampleAppearanceViewController() }
        ),
      ]
    ),
    Section(
      title: "Queue & presentation",
      rows: [
        Row(
          title: "Present once (dedup)",
          subtitle: "presentOnce(id:) suppresses duplicate alerts",
          make: { FKAlertExamplePresentOnceViewController() }
        ),
        Row(
          title: "Queued alerts",
          subtitle: "singleActive FIFO, replaceCurrent policy",
          make: { FKAlertExampleQueuedAlertsViewController() }
        ),
        Row(
          title: "Presentation policy",
          subtitle: "Backdrop tap, swipe opt-in, iPad center sizing",
          make: { FKAlertExamplePresentationPolicyViewController() }
        ),
        Row(
          title: "Checkbox-gated delete",
          subtitle: "Dangerous action switch gates destructive button",
          make: { FKAlertExampleCheckboxGatedDeleteViewController() }
        ),
      ]
    ),
    Section(
      title: "Advanced",
      rows: [
        Row(
          title: "Interaction & lifecycle",
          subtitle: "Loading state, dismissOnPrimaryAction, delegate, haptics",
          make: { FKAlertExampleInteractionViewController() }
        ),
        Row(
          title: "Accessibility",
          subtitle: "VoiceOver focus order, announcements, destructive hints",
          make: { FKAlertExampleAccessibilityViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKAlert"
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
