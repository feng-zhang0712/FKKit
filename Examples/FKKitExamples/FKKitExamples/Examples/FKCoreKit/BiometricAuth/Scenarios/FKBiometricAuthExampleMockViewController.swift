import FKCoreKit
import UIKit

/// FKMockBiometricAuthenticator and every ``FKBiometricError`` LocalizedError string.
final class FKBiometricAuthExampleMockViewController: FKBiometricAuthExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Mock & Errors"

    addInfoLabel(
      "Use FKMockBiometricAuthenticator for simulator CI and Pluggable DI. Lockout and cancel outcomes avoid real hardware."
    )

    addSectionHeading("FKMockBiometricAuthenticator")
    addActionButton("Mock success") { [weak self] in
      self?.runMock(outcome: .success(()), label: "mock.success")
    }
    addActionButton("Mock biometryLockout") { [weak self] in
      self?.runMock(outcome: .failure(.biometryLockout), label: "mock.lockout")
    }
    addActionButton("Mock userCancelled") { [weak self] in
      self?.runMock(outcome: .failure(.userCancelled), label: "mock.userCancelled")
    }
    addActionButton("Mock biometryNotEnrolled capability") { [weak self] in
      let cap = FKBiometricCapability(
        canAuthenticate: false,
        biometryType: .faceID,
        isBiometryEnrolled: false,
        isPasscodeSet: true,
        evaluatedPolicy: .biometricsOrPasscode,
        probeError: .biometryNotEnrolled
      )
      let mock = FKBiometricAuthExampleSupport.mock(capability: cap, outcome: .failure(.biometryNotEnrolled))
      self?.appendLog(FKBiometricAuthExampleSupport.formatCapability(mock.capability()))
      self?.runAuthTask("mock.notEnrolled") {
        try await mock.authenticate(reason: FKBiometricReason.unlockApp())
      }
    }

    addSectionHeading("Pluggable (FKBiometricAuthenticating)")
    addActionButton("Inject mock via protocol type") { [weak self] in
      let authenticator: FKBiometricAuthenticating = FKMockBiometricAuthenticator(
        authenticateOutcome: .success(())
      )
      self?.runAuthTask("pluggable") {
        try await authenticator.authenticate(reason: "Pluggable boundary demo")
      }
    }

    addSectionHeading("FKBiometricError catalog (FKI18n)")
    addActionButton("Print all LocalizedError descriptions") { [weak self] in
      for error in FKBiometricAuthExampleSupport.allSampleErrors {
        self?.appendLog("\(error): \(error.localizedDescription)")
      }
    }

    addClearLogButton()
  }

  private func runMock(outcome: Result<Void, FKBiometricError>, label: String) {
    let mock = FKBiometricAuthExampleSupport.mock(outcome: outcome)
    runAuthTask(label) {
      try await mock.authenticate(reason: FKBiometricReason.confirmAction())
    }
  }
}
