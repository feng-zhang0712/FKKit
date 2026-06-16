import UIKit
import FKCoreKit

/// B7 — BusinessKit lifecycle recipe: ``beginBackgroundWork`` + ``scheduleAppRefresh`` on background.
final class FKBackgroundTaskExampleLifecycleFlushRecipeViewController: FKBackgroundTaskExampleBaseViewController {
  private var lifecycleToken: FKBusinessObservationToken?
  private let kit = FKBusinessKit.shared

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "LifecycleFlushRecipe"

    addInfoLabel(
      """
      Recommended pattern on `lifecycle.background`: run a short `beginBackgroundWork` flush, \
      then schedule a deferred `BGAppRefreshTask` as a fallback. Complements BusinessKit's timer-based flush.
      """
    )

    kit.updateConfiguration { $0.analyticsFlushInterval = 30 }
    kit.track.setUploader(FKBusinessKitDemoAnalyticsUploader(logger: { [weak self] in self?.appendLog($0) }))

    lifecycleToken = kit.lifecycle.observe { [weak self] state in
      Task { @MainActor in
        guard let self else { return }
        guard state == .background else { return }
        self.appendLog("lifecycle → .background")

        _ = FKBackgroundTaskExampleSupport.manager.beginBackgroundWork(name: "analytics-flush") {
          await self.kit.track.flush()
          await MainActor.run { self.appendLog("beginBackgroundWork flush completed") }
        }

        do {
          try await FKBackgroundTaskExampleSupport.manager.scheduleAppRefresh(
            FKBackgroundAppRefreshRequest(
              identifier: FKBackgroundTaskExampleSupport.refreshAnalyticsID,
              earliestBeginDate: Date().addingTimeInterval(3600)
            )
          )
          self.appendLog("Scheduled refresh.analytics fallback (+1h)")
        } catch {
          self.appendLog("scheduleAppRefresh error: \(FKBackgroundTaskExampleSupport.formatError(error))")
        }
      }
    }

    addActionButton("Track demo events") { [weak self] in
      self?.kit.track.trackPageView("BackgroundTaskDemo", parameters: ["scene": "B7"])
      self?.kit.track.trackClick("FlushRecipe", page: "BackgroundTaskDemo", parameters: nil)
      self?.appendLog("Events queued in analytics buffer.")
    }

    addActionButton("Simulate background (send app to home briefly)") { [weak self] in
      self?.appendLog("Press Home now — lifecycle observer will run the recipe.")
      self?.appendLog("Return to FKKitExamples and check the log.")
    }

    addActionButton("Manual beginBackgroundWork flush") { [weak self] in
      guard let self else { return }
      _ = FKBackgroundTaskExampleSupport.manager.beginBackgroundWork(name: "manual-flush") {
        await self.kit.track.flush()
        await MainActor.run { self.appendLog("Manual flush completed") }
      }
      self.appendLog("Started manual beginBackgroundWork flush")
    }

    addActionButton("Refresh handler execution log") { [weak self] in
      self?.refreshExecutionLog()
    }

    addClearLogButton()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isMovingFromParent {
      lifecycleToken?.invalidate()
      lifecycleToken = nil
    }
  }
}
