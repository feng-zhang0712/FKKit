import FKCoreKit
import UIKit

/// cancelAuthentication() while system UI is visible.
final class FKBiometricAuthExampleCancelInFlightViewController: FKBiometricAuthExampleBaseViewController {
  private let auth = FKBiometricAuth.shared

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Cancel In Flight"

    addSimulatorFaceIDGuide()
    addInfoLabel(
      "Start authentication, then tap Cancel auth while the system sheet is visible. Pending authenticate should end with appCancelled."
    )

    addActionButton("Start authentication") { [weak self] in
      self?.runAuthTask("authenticate") {
        try await self?.auth.authenticate(reason: "Cancel in flight demo") ?? ()
      }
    }

    addActionButton("Cancel authentication (cancelAuthentication)") { [weak self] in
      self?.auth.cancelAuthentication()
      self?.appendLog("cancelAuthentication() dispatched")
    }

    addClearLogButton()
  }
}
