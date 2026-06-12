import FKCoreKit
import UIKit

/// Host guidance when biometry is not enrolled or passcode is missing.
final class FKBiometricAuthExampleNotEnrolledViewController: FKBiometricAuthExampleBaseViewController {
  private let auth = FKBiometricAuthExampleSupport.liveAuth

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Not Enrolled"

    addInfoLabel(
      "Recommended host behavior: when isBiometryEnrolled is false, guide the user to Settings → Face ID & Passcode. When passcodeNotSet, prompt to set a device passcode."
    )

    addActionButton("Refresh capability snapshot") { [weak self] in
      self?.refreshGuidance()
    }

    addActionButton("Open Settings (UIApplication)") { [weak self] in
      guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
      UIApplication.shared.open(url)
      self?.appendLog("Opened app Settings — user can enable Face ID / passcode on device.")
    }

    addClearLogButton()
    refreshGuidance()
  }

  private func refreshGuidance() {
    let cap = auth.capability()
    appendLog(FKBiometricAuthExampleSupport.formatCapability(cap))

    if cap.isPasscodeSet == false {
      appendLog("→ Host action: explain device passcode is required before biometry.")
    } else if cap.isBiometryEnrolled == false, cap.biometryType != .none {
      appendLog("→ Host action: prompt Settings → Face ID & Passcode to enroll biometry.")
    } else if cap.canAuthenticate == false, let probeError = cap.probeError {
      appendLog("→ probeError UX: \(probeError.localizedDescription)")
    } else if cap.canAuthenticate {
      appendLog("→ Device ready — proceed to authenticate(reason:).")
    } else {
      appendLog("→ Biometry unavailable on this device — use devicePasscode policy or disable feature.")
    }
  }
}
