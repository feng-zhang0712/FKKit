import UIKit
import FKCoreKit

/// B1 — Launch registration, Info.plist checklist, and ``FKBackgroundTaskManagerConfiguration``.
final class FKBackgroundTaskExampleInstallRegistrationsViewController: FKBackgroundTaskExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "InstallRegistrations"

    addInfoLabel(
      """
      FKBackgroundTaskManager registers handlers before application finishes launching. \
      This demo app calls FKBackgroundTaskExampleSupport.configureAtLaunch() from AppDelegate.
      """
    )

    addSectionHeading("Info.plist checklist")
    addMonospaceLabel(
      """
      BGTaskSchedulerPermittedIdentifiers:
      \(FKBackgroundTaskExampleSupport.plistIdentifiers.map { "  • \($0)" }.joined(separator: "\n"))

      UIBackgroundModes: fetch, processing
      Capabilities → Background Modes → Background fetch + Background processing
      """
    )

    addSectionHeading("Launch snippet")
    addMonospaceLabel(FKBackgroundTaskExampleSupport.launchSnippet)

    addSectionHeading("Actions")
    addActionButton("Show registered demo identifiers") { [weak self] in
      self?.appendLog("refresh.config → \(FKBackgroundTaskExampleSupport.refreshConfigID)")
      self?.appendLog("refresh.analytics → \(FKBackgroundTaskExampleSupport.refreshAnalyticsID)")
      self?.appendLog("processing.cleanup → \(FKBackgroundTaskExampleSupport.processingCleanupID)")
    }

    addActionButton("Retry installRegistrations (expect alreadyInstalled)") { [weak self] in
      self?.runTask("alreadyInstalled") {
        try FKBackgroundTaskExampleSupport.manager.installRegistrations([
          .init(identifier: FKBackgroundTaskExampleSupport.refreshConfigID, kind: .appRefresh),
        ])
      }
    }

    addActionButton("Manager with logScheduling enabled") { [weak self] in
      let configured = FKBackgroundTaskManager(
        configuration: FKBackgroundTaskManagerConfiguration(
          allowsMultipleInstall: false,
          logScheduling: true,
          debugLogPendingTasks: true
        )
      )
      self?.appendLog("Created FKBackgroundTaskManager(configuration: logScheduling=true, debugLogPendingTasks=true)")
      self?.appendLog("Use a dedicated instance when you need verbose FKLogger output without affecting shared.")
      _ = configured
    }

    addActionButton("Refresh handler execution log") { [weak self] in
      self?.refreshExecutionLog()
    }

    addActionButton("Clear handler execution store") {
      Task { await FKBackgroundTaskExampleExecutionStore.shared.clear() }
    }

    addClearLogButton()
  }
}
