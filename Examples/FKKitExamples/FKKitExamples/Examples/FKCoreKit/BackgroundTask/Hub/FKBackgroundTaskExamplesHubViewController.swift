import UIKit

/// Grouped index of ``FKBackgroundTaskManager`` examples under `FKCoreKit/Components/BackgroundTask`.
final class FKBackgroundTaskExamplesHubViewController: UITableViewController {
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
      title: "Host setup",
      rows: [
        Row(
          title: "Install registrations",
          subtitle: "Launch wiring, Info.plist identifiers, Background Modes, FKBackgroundTaskManagerConfiguration",
          make: { FKBackgroundTaskExampleInstallRegistrationsViewController() }
        ),
      ]
    ),
    Section(
      title: "BGTaskScheduler scheduling",
      rows: [
        Row(
          title: "Schedule app refresh",
          subtitle: "FKBackgroundAppRefreshRequest, earliestBeginDate, pendingTaskRequests, Xcode simulate",
          make: { FKBackgroundTaskExampleScheduleAppRefreshViewController() }
        ),
        Row(
          title: "Schedule processing",
          subtitle: "FKBackgroundProcessingRequest network/power constraints at submit time",
          make: { FKBackgroundTaskExampleScheduleProcessingViewController() }
        ),
        Row(
          title: "Cancel & pending query",
          subtitle: "cancelScheduledTask, pendingTaskRequests, notInstalled on fresh manager",
          make: { FKBackgroundTaskExampleCancelAndPendingViewController() }
        ),
      ]
    ),
    Section(
      title: "Handler lifecycle & short work",
      rows: [
        Row(
          title: "Handler lifecycle",
          subtitle: "FKBackgroundTaskHandle success/fail, simulateExpiration, idempotent complete()",
          make: { FKBackgroundTaskExampleHandlerLifecycleViewController() }
        ),
        Row(
          title: "Begin background work",
          subtitle: "FKBackgroundWorkToken, production manager, MockBackgroundApplication, FKBackgroundWorkExtending",
          make: { FKBackgroundTaskExampleBeginBackgroundWorkViewController() }
        ),
      ]
    ),
    Section(
      title: "Integration & testing",
      rows: [
        Row(
          title: "Lifecycle flush recipe",
          subtitle: "BusinessKit lifecycle → beginBackgroundWork flush + scheduleAppRefresh fallback",
          make: { FKBackgroundTaskExampleLifecycleFlushRecipeViewController() }
        ),
        Row(
          title: "Mock & Pluggable",
          subtitle: "FKMockBackgroundTaskScheduler, FKBackgroundTaskScheduling, errors, simulateLaunch",
          make: { FKBackgroundTaskExampleMockAndPluggableViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "BackgroundTask"
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
