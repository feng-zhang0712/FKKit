import UIKit
import FKCoreKit

/// B8 — startup task priority and delay orchestration.
final class FKBusinessKitExampleStartupTasksViewController: FKBusinessKitExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "StartupTasks"
    addInfoLabel("Tasks run high → normal → low with configured delay.")
    addActionButton("Register + runAll") { [weak self] in
      guard let self else { return }
      self.kit.utils.startup.register(
        FKStartupTask(id: "high", priority: .high, delay: 0) {
          Task { @MainActor in self.appendLog("HIGH executed") }
        }
      )
      self.kit.utils.startup.register(
        FKStartupTask(id: "low_delayed", priority: .low, delay: 0.5) {
          Task { @MainActor in self.appendLog("LOW delayed executed") }
        }
      )
      Task { @MainActor in
        await self.kit.utils.startup.runAll()
        self.appendLog("runAll finished")
      }
    }
  }
}
