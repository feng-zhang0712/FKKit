import FKCoreKit
import UIKit

/// Side-by-side ``FKBiometricPolicy`` behavior on a real device or enrolled simulator.
final class FKBiometricAuthExamplePolicyViewController: FKBiometricAuthExampleBaseViewController {
  private let auth = FKBiometricAuthExampleSupport.liveAuth

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Policies"

    addSimulatorFaceIDGuide()
    addInfoLabel(
      "biometricsOnly may hide passcode fallback. biometricsOrPasscode allows passcode. devicePasscode uses deviceOwnerAuthentication (biometry may still appear on some OS versions)."
    )

    addActionButton("biometricsOnly") { [weak self] in
      self?.authenticate(policy: .biometricsOnly, allowFallback: true, label: "biometricsOnly")
    }

    addActionButton("biometricsOrPasscode (fallback allowed)") { [weak self] in
      self?.authenticate(policy: .biometricsOrPasscode, allowFallback: true, label: "orPasscode+fallback")
    }

    addActionButton("biometricsOrPasscode (fallback disabled)") { [weak self] in
      self?.authenticate(policy: .biometricsOrPasscode, allowFallback: false, label: "orPasscode-noFallback")
    }

    addActionButton("devicePasscode") { [weak self] in
      self?.authenticate(policy: .devicePasscode, allowFallback: true, label: "devicePasscode")
    }

    addSimulatorRecoverySection(auth: auth)

    addClearLogButton()
  }

  private func authenticate(policy: FKBiometricPolicy, allowFallback: Bool, label: String) {
    let options = FKBiometricAuthOptions(allowPasscodeFallback: allowFallback)
    runAuthTask(label) { [weak self] in
      try await self?.auth.authenticate(
        reason: "Compare policy: \(label)",
        policy: policy,
        options: options
      ) ?? ()
    }
  }
}
