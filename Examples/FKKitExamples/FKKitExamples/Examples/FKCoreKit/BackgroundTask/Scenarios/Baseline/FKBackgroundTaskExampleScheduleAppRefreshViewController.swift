import UIKit
import FKCoreKit

/// B2 — ``scheduleAppRefresh`` and Xcode background task simulation.
final class FKBackgroundTaskExampleScheduleAppRefreshViewController: FKBackgroundTaskExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "ScheduleAppRefresh"

    addInfoLabel(
      """
      Submits a BGAppRefreshTaskRequest for `\(FKBackgroundTaskExampleSupport.refreshConfigID)`. \
      Simulator execution is unreliable — use a physical device and Xcode → Debug → Simulate Background Tasks.
      """
    )

    addActionButton("Schedule refresh (+15 min)") { [weak self] in
      self?.runTask("schedule +15m") {
        try await FKBackgroundTaskExampleSupport.manager.scheduleAppRefresh(
          FKBackgroundAppRefreshRequest(
            identifier: FKBackgroundTaskExampleSupport.refreshConfigID,
            earliestBeginDate: Date().addingTimeInterval(15 * 60)
          )
        )
        self?.appendLog("Submitted earliestBeginDate = now + 15m")
      }
    }

    addActionButton("Schedule refresh (ASAP)") { [weak self] in
      self?.runTask("schedule ASAP") {
        try await FKBackgroundTaskExampleSupport.manager.scheduleAppRefresh(
          FKBackgroundAppRefreshRequest(identifier: FKBackgroundTaskExampleSupport.refreshConfigID)
        )
        self?.appendLog("Submitted with nil earliestBeginDate (as soon as system allows)")
      }
    }

    addActionButton("pendingTaskRequests()") { [weak self] in
      self?.runTask("pending") {
        let pending = await FKBackgroundTaskExampleSupport.manager.pendingTaskRequests()
        self?.appendLog(FKBackgroundTaskExampleSupport.formatPending(pending))
      }
    }

    addActionButton("Refresh handler execution log") { [weak self] in
      self?.refreshExecutionLog()
    }

    addSectionHeading("Xcode simulate steps")
    addInfoLabel(
      """
      1. Run on a device with Background fetch capability enabled.
      2. Schedule a task above, then background the app.
      3. Xcode → Debug → Simulate Background Tasks → select `\(FKBackgroundTaskExampleSupport.refreshConfigID)`.
      4. Return to this screen and tap “Refresh handler execution log”.
      """
    )

    addClearLogButton()
  }
}
