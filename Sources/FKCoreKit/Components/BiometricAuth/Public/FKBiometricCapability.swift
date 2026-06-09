import Foundation

/// Snapshot of device biometric readiness. Probing does not present authentication UI.
public struct FKBiometricCapability: Sendable, Equatable {
  /// `true` when the requested policy can be evaluated (UI may still appear on authenticate).
  public var canAuthenticate: Bool

  /// Biometric hardware type on this device.
  public var biometryType: FKBiometryType

  /// Whether Face ID / Touch ID is enrolled.
  public var isBiometryEnrolled: Bool

  /// Whether a device passcode is set (required before biometry).
  public var isPasscodeSet: Bool

  /// Policy used for this snapshot.
  public var evaluatedPolicy: FKBiometricPolicy

  /// Mapped probe error when ``canAuthenticate`` is `false`.
  public var probeError: FKBiometricError?

  /// Creates a capability snapshot.
  public init(
    canAuthenticate: Bool,
    biometryType: FKBiometryType,
    isBiometryEnrolled: Bool,
    isPasscodeSet: Bool,
    evaluatedPolicy: FKBiometricPolicy,
    probeError: FKBiometricError? = nil
  ) {
    self.canAuthenticate = canAuthenticate
    self.biometryType = biometryType
    self.isBiometryEnrolled = isBiometryEnrolled
    self.isPasscodeSet = isPasscodeSet
    self.evaluatedPolicy = evaluatedPolicy
    self.probeError = probeError
  }
}
