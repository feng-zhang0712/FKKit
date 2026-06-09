import FKCoreKit
import UIKit

/// Silent capability probing for every ``FKBiometricPolicy`` (no system UI).
final class FKBiometricAuthExampleCapabilityViewController: FKBiometricAuthExampleBaseViewController {
  private let auth = FKBiometricAuthExampleSupport.liveAuth

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Capability"

    addInfoLabel(
      "Uses canEvaluatePolicy only — never evaluatePolicy. Re-run after returning from Settings or on didBecomeActive."
    )

    addActionButton("capability() — default policy") { [weak self] in
      self?.probe(label: "default") { self?.auth.capability() }
    }

    addActionButton("capability(for: .biometricsOnly)") { [weak self] in
      self?.probe(label: "biometricsOnly") { self?.auth.capability(for: .biometricsOnly) }
    }

    addActionButton("capability(for: .biometricsOrPasscode)") { [weak self] in
      self?.probe(label: "biometricsOrPasscode") { self?.auth.capability(for: .biometricsOrPasscode) }
    }

    addActionButton("capability(for: .devicePasscode)") { [weak self] in
      self?.probe(label: "devicePasscode") { self?.auth.capability(for: .devicePasscode) }
    }

    addActionButton("Probe all policies") { [weak self] in
      guard let self else { return }
      for policy: FKBiometricPolicy in [.biometricsOnly, .biometricsOrPasscode, .devicePasscode] {
        let cap = auth.capability(for: policy)
        appendLog("--- \(policy) ---")
        appendLog(FKBiometricAuthExampleSupport.formatCapability(cap))
      }
    }

    addClearLogButton()
    appendLog("Ready. On simulator: Features → Face ID → Enrolled for live auth demos.")
  }

  private func probe(label: String, _ block: () -> FKBiometricCapability?) {
    guard let cap = block() else { return }
    appendLog("[\(label)]")
    appendLog(FKBiometricAuthExampleSupport.formatCapability(cap))
  }
}
