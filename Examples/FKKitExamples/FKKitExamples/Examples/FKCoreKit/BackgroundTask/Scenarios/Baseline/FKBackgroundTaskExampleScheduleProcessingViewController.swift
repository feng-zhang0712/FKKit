import UIKit
import FKCoreKit

/// B3 — ``scheduleProcessing`` with network and external-power constraints.
final class FKBackgroundTaskExampleScheduleProcessingViewController: FKBackgroundTaskExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "ScheduleProcessing"

    addInfoLabel(
      """
      Processing constraints (`requiresNetworkConnectivity`, `requiresExternalPower`) are set on \
      ``FKBackgroundProcessingRequest`` at submit time — not during `registerProcessing`.
      """
    )

    addActionButton("Schedule processing (network + power, +1h)") { [weak self] in
      self?.runTask("processing constrained") {
        try await FKBackgroundTaskExampleSupport.manager.scheduleProcessing(
          FKBackgroundProcessingRequest(
            identifier: FKBackgroundTaskExampleSupport.processingCleanupID,
            earliestBeginDate: Date().addingTimeInterval(3600),
            requiresNetworkConnectivity: true,
            requiresExternalPower: true
          )
        )
        self?.appendLog("requiresNetworkConnectivity=true, requiresExternalPower=true")
      }
    }

    addActionButton("Schedule processing (network only)") { [weak self] in
      self?.runTask("processing network") {
        try await FKBackgroundTaskExampleSupport.manager.scheduleProcessing(
          FKBackgroundProcessingRequest(
            identifier: FKBackgroundTaskExampleSupport.processingCleanupID,
            requiresNetworkConnectivity: true,
            requiresExternalPower: false
          )
        )
      }
    }

    addActionButton("Schedule processing (no constraints)") { [weak self] in
      self?.runTask("processing default") {
        try await FKBackgroundTaskExampleSupport.manager.scheduleProcessing(
          FKBackgroundProcessingRequest(identifier: FKBackgroundTaskExampleSupport.processingCleanupID)
        )
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

    addClearLogButton()
  }
}
