import UIKit

/// Grouped index of ``FKLocalNotificationManager`` examples under `FKCoreKit/Components/LocalNotification`.
final class FKLocalNotificationExamplesHubViewController: UITableViewController {
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
      title: "Permission & authorization",
      rows: [
        Row(
          title: "Permission gate",
          subtitle: "FKPermissions pre-prompt → system authorization → canScheduleNotifications → schedule",
          make: { FKLocalNotificationExamplePermissionGateViewController() }
        ),
      ]
    ),
    Section(
      title: "Scheduling & triggers",
      rows: [
        Row(
          title: "Interval, immediate & content",
          subtitle: "10s delay, immediate delivery, rich content fields, repeating interval (≥60s), foreground delegate",
          make: { FKLocalNotificationExampleScheduleIntervalViewController() }
        ),
        Row(
          title: "Calendar daily repeat",
          subtitle: "FKLocalNotificationCalendarTrigger with timezone; inspect pendingRequests()",
          make: { FKLocalNotificationExampleScheduleCalendarViewController() }
        ),
      ]
    ),
    Section(
      title: "Categories & presentation",
      rows: [
        Row(
          title: "Category actions",
          subtitle: "registerCategories, Mark Read / Snooze actions, custom dismiss, response handler",
          make: { FKLocalNotificationExampleCategoryActionsViewController() }
        ),
        Row(
          title: "Foreground presentation",
          subtitle: "installDelegate presentation options: banner, list, sound, badge",
          make: { FKLocalNotificationExampleDelegatePresentationViewController() }
        ),
      ]
    ),
    Section(
      title: "Lifecycle, query & badge",
      rows: [
        Row(
          title: "Cancel, replace & query",
          subtitle: "Same-id replace, batch schedule/cancel, pending & delivered queries, removeDelivered",
          make: { FKLocalNotificationExampleCancelReplaceViewController() }
        ),
        Row(
          title: "Badge count",
          subtitle: "setBadgeCount, clearBadge (iOS 16+ API with iOS 15 fallback)",
          make: { FKLocalNotificationExampleBadgeViewController() }
        ),
      ]
    ),
    Section(
      title: "Routing & testing",
      rows: [
        Row(
          title: "Deeplink on tap",
          subtitle: "userInfo deeplink URL, useBusinessKitDeeplink, custom router, route-before-handler config",
          make: { FKLocalNotificationExampleDeeplinkTapViewController() }
        ),
        Row(
          title: "Mock & Pluggable",
          subtitle: "FKMockLocalNotificationScheduler, protocol injection, validation errors, LocalizedError catalog",
          make: { FKLocalNotificationExampleMockSchedulerViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "LocalNotification"
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
    config.secondaryTextProperties.numberOfLines = 3
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(sections[indexPath.section].rows[indexPath.row].make(), animated: true)
  }
}
