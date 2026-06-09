import FKCoreKit
import UIKit

/// Simulates SwiftUI `.task` cancellation invalidating the active LAContext.
final class FKBiometricAuthExampleTaskCancellationViewController: FKBiometricAuthExampleBaseViewController {
  private let auth = FKBiometricAuth.shared
  private var authTask: Task<Void, Never>?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Task Cancellation"

    addSimulatorFaceIDGuide()
    addInfoLabel(
      "Starts authenticate inside a Swift Task. Cancel the Task (like a disappearing SwiftUI view) — FKBiometricAuth invalidates LAContext and throws appCancelled."
    )

    addActionButton("Start Task { authenticate }") { [weak self] in
      guard let self else { return }
      authTask?.cancel()
      authTask = runCancellableAuthTask("task.auth") { [weak self] in
        try await self?.auth.authenticate(reason: "Task cancellation demo") ?? ()
      }
    }

    addActionButton("Cancel Swift Task") { [weak self] in
      self?.authTask?.cancel()
      self?.authTask = nil
      self?.appendLog("Task.cancel() called")
    }

    addClearLogButton()
  }
}
