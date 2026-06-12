import Foundation

/// Mock authenticator for tests, previews, and FKKitExamples.
public struct FKMockBiometricAuthenticator: FKBiometricAuthenticating, Sendable {
  /// Fixed capability returned by ``capability(for:)`` and ``capability()``.
  public var capabilityResult: FKBiometricCapability

  /// Outcome returned by ``authenticate(reason:policy:options:)``.
  public var authenticateOutcome: Result<Void, FKBiometricError>

  /// Creates a mock with configurable capability and authenticate outcome.
  public init(
    capabilityResult: FKBiometricCapability = FKBiometricCapability(
      canAuthenticate: true,
      biometryType: .faceID,
      isBiometryEnrolled: true,
      isPasscodeSet: true,
      evaluatedPolicy: .biometricsOrPasscode
    ),
    authenticateOutcome: Result<Void, FKBiometricError> = .success(())
  ) {
    self.capabilityResult = capabilityResult
    self.authenticateOutcome = authenticateOutcome
  }

  /// Returns ``capabilityResult`` with ``evaluatedPolicy`` updated.
  public func capability(for policy: FKBiometricPolicy) -> FKBiometricCapability {
    var result = capabilityResult
    result.evaluatedPolicy = policy
    return result
  }

  /// Returns ``capabilityResult``.
  public func capability() -> FKBiometricCapability {
    capabilityResult
  }

  /// Returns ``authenticateOutcome`` or throws its error.
  public func authenticate(
    reason: String,
    policy: FKBiometricPolicy,
    options: FKBiometricAuthOptions
  ) async throws {
    let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      throw FKBiometricError.invalidReason
    }
    switch authenticateOutcome {
    case .success:
      return
    case let .failure(error):
      throw error
    }
  }

  /// Authenticates using ``authenticateOutcome``.
  public func authenticate(reason: String) async throws {
    try await authenticate(reason: reason, policy: .biometricsOrPasscode, options: .init())
  }

  /// No-op for mock implementations.
  public func cancelAuthentication() {}
}
