import UIKit
import FKCoreKit

/// B6 — ``cancelScheduledTask(withIdentifier:)`` and ``pendingTaskRequests()``.
final class FKBackgroundTaskExampleCancelAndPendingViewController: FKBackgroundTaskExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "CancelAndPending"

    addInfoLabel(
      "Schedule tasks, inspect `pendingTaskRequests()`, then cancel and verify the pending list."
    )

    addActionButton("Schedule refresh + processing") { [weak self] in
      self?.runTask("schedule both") {
        try await FKBackgroundTaskExampleSupport.manager.scheduleAppRefresh(
          FKBackgroundAppRefreshRequest(
            identifier: FKBackgroundTaskExampleSupport.refreshConfigID,
            earliestBeginDate: Date().addingTimeInterval(1800)
          )
        )
        try await FKBackgroundTaskExampleSupport.manager.scheduleProcessing(
          FKBackgroundProcessingRequest(
            identifier: FKBackgroundTaskExampleSupport.processingCleanupID,
            earliestBeginDate: Date().addingTimeInterval(7200),
            requiresNetworkConnectivity: true
          )
        )
      }
    }

    addActionButton("pendingTaskRequests()") { [weak self] in
      self?.runTask("pending") {
        let pending = await FKBackgroundTaskExampleSupport.manager.pendingTaskRequests()
        self?.appendLog(FKBackgroundTaskExampleSupport.formatPending(pending))
      }
    }

    addActionButton("cancelScheduledTask(refresh.config)") { [weak self] in
      self?.runTask("cancel refresh") {
        try await FKBackgroundTaskExampleSupport.manager.cancelScheduledTask(
          withIdentifier: FKBackgroundTaskExampleSupport.refreshConfigID
        )
      }
    }

    addActionButton("cancelScheduledTask(processing.cleanup)") { [weak self] in
      self?.runTask("cancel processing") {
        try await FKBackgroundTaskExampleSupport.manager.cancelScheduledTask(
          withIdentifier: FKBackgroundTaskExampleSupport.processingCleanupID
        )
      }
    }

    addActionButton("Schedule before install (separate manager → notInstalled)") { [weak self] in
      let fresh = FKBackgroundTaskManager()
      self?.runTask("notInstalled") {
        try await fresh.scheduleAppRefresh(
          FKBackgroundAppRefreshRequest(identifier: FKBackgroundTaskExampleSupport.refreshConfigID)
        )
      }
    }

    addClearLogButton()
  }
}
