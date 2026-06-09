import FKCoreKit
import UIKit

/// Core authenticate APIs: async, closure, authenticateIfAvailable, and invalid reason.
final class FKBiometricAuthExampleAuthenticationViewController: FKBiometricAuthExampleBaseViewController {
  private let auth = FKBiometricAuthExampleSupport.liveAuth

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Authentication"

    addSimulatorFaceIDGuide()
    addInfoLabel("Tap Cancel in the system sheet to observe userCancelled. Empty reason throws invalidReason without UI.")

    addSectionHeading("async/await")
    addActionButton("authenticate(reason:) — default policy") { [weak self] in
      self?.runAuthTask("async.default") {
        try await self?.auth.authenticate(reason: FKBiometricReason.unlockApp()) ?? ()
      }
    }

    addSectionHeading("authenticateIfAvailable")
    addActionButton("authenticateIfAvailable(reason:)") { [weak self] in
      self?.runAuthTask("ifAvailable") {
        try await self?.auth.authenticateIfAvailable(reason: FKBiometricReason.confirmAction()) ?? ()
      }
    }

    addSectionHeading("Closure API")
    addActionButton("authenticate(reason:completion:)") { [weak self] in
      guard let self else { return }
      runClosureAuth("closure", auth: auth, reason: FKBiometricReason.unlockApp())
    }

    addSectionHeading("Validation")
    addActionButton("authenticate with empty reason → invalidReason") { [weak self] in
      self?.runAuthTask("invalidReason") {
        try await self?.auth.authenticate(reason: "   ") ?? ()
      }
    }

    addSimulatorRecoverySection(auth: auth)

    addClearLogButton()
  }
}
