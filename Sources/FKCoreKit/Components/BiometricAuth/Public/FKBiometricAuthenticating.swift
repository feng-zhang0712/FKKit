import Foundation

/// Pluggable boundary for device-owner authentication (Face ID, Touch ID, passcode).
public protocol FKBiometricAuthenticating: Sendable {
  /// Probes capability for a policy without presenting authentication UI.
  func capability(for policy: FKBiometricPolicy) -> FKBiometricCapability

  /// Probes capability using the conforming type's default policy (``FKBiometricAuth`` uses ``FKBiometricAuthConfiguration/defaultPolicy``).
  func capability() -> FKBiometricCapability

  /// Authenticates with explicit policy and options.
  func authenticate(
    reason: String,
    policy: FKBiometricPolicy,
    options: FKBiometricAuthOptions
  ) async throws

  /// Authenticates using default policy and options.
  func authenticate(reason: String) async throws

  /// Cancels an in-flight authentication by invalidating the active `LAContext`.
  func cancelAuthentication()
}
