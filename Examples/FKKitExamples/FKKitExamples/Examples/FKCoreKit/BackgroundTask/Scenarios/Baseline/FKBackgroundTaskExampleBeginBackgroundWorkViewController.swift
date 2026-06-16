import UIKit
import FKCoreKit

/// B5 — ``FKBackgroundWorkExtending`` / ``FKBackgroundWorkToken`` with production manager and mock expiration.
final class FKBackgroundTaskExampleBeginBackgroundWorkViewController: FKBackgroundTaskExampleBaseViewController {
  private let mockApp = MockBackgroundApplication()
  private lazy var mockScheduler = FKMockBackgroundTaskScheduler(application: mockApp)
  private var activeToken: FKBackgroundWorkToken?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "BeginBackgroundWork"

    addInfoLabel(
      """
      `beginBackgroundWork` returns a token synchronously; work runs in a detached `Task`. \
      Merge multiple quick jobs into one block per `didEnterBackground` (v1 does not nest tokens).
      """
    )

    addSectionHeading("FKBackgroundTaskManager.shared")
    addActionButton("beginBackgroundWork (production)") { [weak self] in
      guard let self else { return }
      let token = FKBackgroundTaskExampleSupport.manager.beginBackgroundWork(name: "demo-flush") {
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        await MainActor.run { self.appendLog("Production work finished") }
      }
      self.activeToken = token
      self.appendLog("Token returned immediately — isValid=\(token.isValid)")
    }

    addActionButton("End active token early") { [weak self] in
      guard let self else { return }
      guard let token = self.activeToken, token.isValid else {
        self.appendLog("No active token — start production work first")
        return
      }
      token.end()
      self.appendLog("token.end() — isValid=\(token.isValid)")
      self.activeToken = nil
    }

    addSectionHeading("MockBackgroundApplication")
    addActionButton("Mock beginBackgroundWork + simulateExpiration") { [weak self] in
      guard let self else { return }
      _ = self.mockScheduler.beginBackgroundWork(name: "mock-expire") {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        await MainActor.run { self.appendLog("Mock work finished (unexpected if expired)") }
      }
      self.appendLog("Mock activeTasks=\(self.mockApp.activeTaskCount)")
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
        guard let self else { return }
        if let id = self.mockApp.simulateExpirationForFirstActiveTask() {
          self.appendLog("Simulated expiration for UIBackgroundTaskIdentifier(\(id.rawValue))")
        } else {
          self.appendLog("No active mock background task to expire")
        }
      }
    }

    addActionButton("Mock work completes normally") { [weak self] in
      guard let self else { return }
      _ = self.mockScheduler.beginBackgroundWork(name: "mock-complete") {
        try? await Task.sleep(nanoseconds: 400_000_000)
        await MainActor.run { self.appendLog("Mock work completed — token auto-ended") }
      }
      self.appendLog("Scheduled short mock work (auto end on completion)")
    }

    addSectionHeading("FKBackgroundWorkExtending (Pluggable)")
    addActionButton("Call through protocol existential") { [weak self] in
      guard let self else { return }
      let extender: any FKBackgroundWorkExtending = FKBackgroundTaskExampleSupport.manager
      let token = extender.beginBackgroundWork(name: "pluggable") {
        await MainActor.run { self.appendLog("Work via `any FKBackgroundWorkExtending`") }
      }
      self.appendLog("Pluggable token isValid=\(token.isValid)")
    }

    addClearLogButton()
  }
}
