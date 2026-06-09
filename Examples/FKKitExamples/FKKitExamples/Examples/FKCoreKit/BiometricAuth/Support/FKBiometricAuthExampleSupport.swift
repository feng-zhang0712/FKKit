import FKCoreKit
import Foundation

/// Demo Keychain payload for the unlock-pattern example.
nonisolated struct FKBiometricExampleKeychainToken: Codable, Sendable {
  let value: String
  let issuedAt: TimeInterval
}

/// Shared helpers for FKBiometricAuth examples.
enum FKBiometricAuthExampleSupport {
  static let liveAuth = FKBiometricAuth.shared

  static func keychainStorage() -> FKKeychainStorage {
    let id = Bundle.main.bundleIdentifier ?? "FKKitExamples"
    return FKKeychainStorage(service: "\(id).fkbiometric.example")
  }

  static func formatCapability(_ capability: FKBiometricCapability) -> String {
    """
    evaluatedPolicy: \(capability.evaluatedPolicy)
    canAuthenticate: \(capability.canAuthenticate)
    biometryType: \(capability.biometryType)
    isBiometryEnrolled: \(capability.isBiometryEnrolled)
    isPasscodeSet: \(capability.isPasscodeSet)
    probeError: \(formatError(capability.probeError))
    """
  }

  static func formatError(_ error: FKBiometricError?) -> String {
    guard let error else { return "nil" }
    return describeBiometricError(error)
  }

  static func formatError(_ error: Error) -> String {
    if let biometric = error as? FKBiometricError {
      return describeBiometricError(biometric)
    }
    return error.localizedDescription
  }

  private static func describeBiometricError(_ error: FKBiometricError) -> String {
    "\(error) — \(error.localizedDescription)"
  }

  static func mock(
    capability: FKBiometricCapability? = nil,
    outcome: Result<Void, FKBiometricError>
  ) -> FKMockBiometricAuthenticator {
    FKMockBiometricAuthenticator(
      capabilityResult: capability ?? FKBiometricCapability(
        canAuthenticate: outcome.isSuccess,
        biometryType: .faceID,
        isBiometryEnrolled: true,
        isPasscodeSet: true,
        evaluatedPolicy: .biometricsOrPasscode
      ),
      authenticateOutcome: outcome
    )
  }

  static let allSampleErrors: [FKBiometricError] = [
    .biometryNotAvailable,
    .biometryNotEnrolled,
    .biometryLockout,
    .passcodeNotSet,
    .authenticationFailed,
    .userCancelled,
    .userFallback,
    .systemCancelled,
    .appCancelled,
    .invalidContext,
    .notInteractive,
    .invalidReason,
    .authenticationInProgress,
    .watchNotAvailable,
    .underlying(code: 1, domain: "ExampleDomain"),
  ]
}

private extension Result where Success == Void, Failure == FKBiometricError {
  var isSuccess: Bool {
    if case .success = self { return true }
    return false
  }
}
