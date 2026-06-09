import FKCoreKit
import UIKit

/// FKI18n reasons, fallback title, and custom ``FKBiometricAuthConfiguration``.
final class FKBiometricAuthExampleConfigurationViewController: FKBiometricAuthExampleBaseViewController {
  private lazy var configuredAuth = FKBiometricAuth(
    configuration: FKBiometricAuthConfiguration(
      defaultPolicy: .biometricsOrPasscode,
      reuseDuration: nil,
      localizedFallbackTitle: "Enter Passcode",
      invalidateContextAfterSuccess: true,
      invalidateContextAfterFailure: true
    )
  )

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Configuration"

    addSimulatorFaceIDGuide()
    addInfoLabel("FKBiometricReason resolves FKI18n keys. localizedFallbackTitle maps to LAContext.localizedFallbackTitle.")

    addSectionHeading("FKBiometricReason")
    addActionButton("unlockApp() reason") { [weak self] in
      self?.appendLog("unlockApp: \(FKBiometricReason.unlockApp())")
      self?.runConfigured(reason: FKBiometricReason.unlockApp(), label: "unlockApp")
    }
    addActionButton("confirmAction() reason") { [weak self] in
      self?.appendLog("confirmAction: \(FKBiometricReason.confirmAction())")
      self?.runConfigured(reason: FKBiometricReason.confirmAction(), label: "confirmAction")
    }
    addActionButton("custom(\"fkcore.common.ok\")") { [weak self] in
      let reason = FKBiometricReason.custom("fkcore.common.ok")
      self?.appendLog("custom: \(reason)")
      self?.runConfigured(reason: reason, label: "customKey")
    }

    addSectionHeading("Per-call options override")
    addActionButton("Override fallback title for one call") { [weak self] in
      self?.runAuthTask("overrideFallback") { [weak self] in
        try await self?.configuredAuth.authenticate(
          reason: FKBiometricReason.confirmAction(),
          policy: .biometricsOrPasscode,
          options: FKBiometricAuthOptions(localizedFallbackTitle: "Use device passcode")
        ) ?? ()
      }
    }

    addSimulatorRecoverySection(auth: configuredAuth)

    addClearLogButton()
  }

  private func runConfigured(reason: String, label: String) {
    runAuthTask(label) { [weak self] in
      try await self?.configuredAuth.authenticate(reason: reason) ?? ()
    }
  }
}
