import UIKit
import FKCoreKit

/// B4 — ``FKBackgroundTaskHandle`` success, failure, expiration, and manual ``complete(success:)``.
final class FKBackgroundTaskExampleHandlerLifecycleViewController: FKBackgroundTaskExampleBaseViewController {
  private let mock = FKMockBackgroundTaskScheduler()
  private let handlerID = "fkkit.example.mock.handler"

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "HandlerLifecycle"

    addInfoLabel(
      """
      Uses ``FKMockBackgroundTaskScheduler/simulateLaunch(identifier:simulateExpiration:)`` to exercise \
      ``FKBackgroundTaskHandle`` without the system scheduler.
      """
    )

    do {
      try mock.registerAppRefresh(identifier: handlerID) { handle in
        try? await Task.sleep(nanoseconds: 200_000_000)
        return !handle.isExpired
      }
      try mock.installRegistrations([.init(identifier: handlerID, kind: .appRefresh)])
      appendLog("Mock handler registered for \(handlerID)")
    } catch {
      appendLog("Setup failed: \(FKBackgroundTaskExampleSupport.formatError(error))")
    }

    addActionButton("simulateLaunch → success") { [weak self] in
      guard let self else { return }
      self.runTask("launch success") {
        await self.mock.simulateLaunch(identifier: self.handlerID)
        self.appendLog("Handler returned success path")
      }
    }

    addActionButton("simulateLaunch → handler returns false") { [weak self] in
      guard let self else { return }
      self.mock.simulateHandler = { _ in false }
      self.runTask("launch false") {
        await self.mock.simulateLaunch(identifier: self.handlerID)
        self.mock.simulateHandler = nil
        self.appendLog("Handler returned false — system may lower future priority")
      }
    }

    addActionButton("simulateLaunch(simulateExpiration: true)") { [weak self] in
      guard let self else { return }
      self.runTask("launch expired") {
        await self.mock.simulateLaunch(identifier: self.handlerID, simulateExpiration: true)
        self.appendLog("Expiration applied before handler — expect isExpired=true")
      }
    }

    addActionButton("Handler calls complete() early") { [weak self] in
      guard let self else { return }
      let earlyID = "fkkit.example.mock.early.\(UUID().uuidString.prefix(6))"
      do {
        try self.mock.registerAppRefresh(identifier: earlyID) { handle in
          handle.complete(success: true)
          return false
        }
        try self.mock.installRegistrations([.init(identifier: earlyID, kind: .appRefresh)])
      } catch {
        self.appendLog("Setup failed: \(FKBackgroundTaskExampleSupport.formatError(error))")
        return
      }
      self.runTask("early complete") {
        await self.mock.simulateLaunch(identifier: earlyID)
        self.appendLog("complete() is idempotent — framework defer is ignored after first complete")
      }
    }

    addClearLogButton()
  }
}
