import FKCoreKit
import UIKit

/// Demonstrates reuseDuration — second authenticate within the window may skip UI (device-dependent).
final class FKBiometricAuthExampleReuseDurationViewController: FKBiometricAuthExampleBaseViewController {
  private lazy var reuseAuth = FKBiometricAuth(
    configuration: FKBiometricAuthConfiguration(
      defaultPolicy: .biometricsOrPasscode,
      reuseDuration: 30,
      invalidateContextAfterSuccess: true,
      invalidateContextAfterFailure: true
    )
  )

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Reuse Duration"

    addSimulatorFaceIDGuide()
    addInfoLabel(
      "reuseDuration sets LAContext.touchIDAuthenticationAllowableReuseDuration. After a successful first auth, run again within ~30s — UI may be skipped per Apple policy (not guaranteed on all devices)."
    )

    addActionButton("1) Authenticate (establish reuse window)") { [weak self] in
      self?.runAuthTask("first") {
        try await self?.reuseAuth.authenticate(reason: "Establish reuse window") ?? ()
      }
    }

    addActionButton("2) Authenticate again immediately") { [weak self] in
      self?.runAuthTask("second.immediate") {
        try await self?.reuseAuth.authenticate(reason: "Second auth within window") ?? ()
      }
    }

    addActionButton("Authenticate with per-call reuse override (60s)") { [weak self] in
      self?.runAuthTask("override60s") { [weak self] in
        try await self?.reuseAuth.authenticate(
          reason: "Per-call reuse override",
          policy: .biometricsOrPasscode,
          options: FKBiometricAuthOptions(reuseDuration: 60)
        ) ?? ()
      }
    }

    addSimulatorRecoverySection(auth: reuseAuth)

    addClearLogButton()
  }
}
