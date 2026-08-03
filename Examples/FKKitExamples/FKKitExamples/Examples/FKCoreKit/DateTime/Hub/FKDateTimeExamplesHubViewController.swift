import UIKit

/// Grouped index of ``FKDateTime`` examples under `FKCoreKit/Components/DateTime`.
final class FKDateTimeExamplesHubViewController: UITableViewController {
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
      title: "Construction & context",
      rows: [
        Row(
          title: "Basics & Codable",
          subtitle: "now, unix s/ms, components, Date.fk_dateTime, description, encode/decode",
          make: { FKDateTimeExampleBasicsViewController() }
        ),
        Row(
          title: "Configuration",
          subtitle: ".default / .utc, with(timeZone/locale/calendar), in(timeZone/locale)",
          make: { FKDateTimeExampleConfigurationViewController() }
        ),
      ]
    ),
    Section(
      title: "Parse & format",
      rows: [
        Row(
          title: "Parse & format",
          subtitle: "presets, custom format, localized template, multi-format parse, ISO-8601, styles, unix",
          make: { FKDateTimeExampleParseFormatViewController() }
        ),
      ]
    ),
    Section(
      title: "Calendar math",
      rows: [
        Row(
          title: "Arithmetic & boundaries",
          subtitle: "add/subtract, startOf/endOf, replacing, setting hour/unit",
          make: { FKDateTimeExampleArithmeticViewController() }
        ),
        Row(
          title: "Query & compare",
          subtitle: "components, flags, compare, sameOr*, isPast/isFuture, age, min/max",
          make: { FKDateTimeExampleQueryCompareViewController() }
        ),
        Row(
          title: "Diff & duration",
          subtitle: "diff(_:unit:), diff(to:), daysUntil, durationDescription (span length)",
          make: { FKDateTimeExampleDiffViewController() }
        ),
      ]
    ),
    Section(
      title: "Relative display",
      rows: [
        Row(
          title: "WeChat chat style",
          subtitle: ".chat — same day, yesterday, weekday, same year, other year",
          make: { FKDateTimeExampleRelativeChatViewController() }
        ),
        Row(
          title: "WeChat feed style",
          subtitle: ".feed — just now, minutes, hours, yesterday, MM-dd / yyyy-MM-dd",
          make: { FKDateTimeExampleRelativeFeedViewController() }
        ),
        Row(
          title: "Standard & system",
          subtitle: ".standard past/future, fromNow, from(_:), .system(.full/.abbreviated)",
          make: { FKDateTimeExampleRelativeStandardViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKDateTime"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func numberOfSections(in tableView: UITableView) -> Int { sections.count }

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
    config.secondaryTextProperties.numberOfLines = 2
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(sections[indexPath.section].rows[indexPath.row].make(), animated: true)
  }
}
