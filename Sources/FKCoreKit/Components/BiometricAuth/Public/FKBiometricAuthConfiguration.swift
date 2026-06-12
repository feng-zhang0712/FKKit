import Foundation

/// Long-lived configuration for ``FKBiometricAuth``.
public struct FKBiometricAuthConfiguration: Sendable, Equatable {
  /// Default policy when callers omit an explicit policy.
  public var defaultPolicy: FKBiometricPolicy

  /// Optional reuse window forwarded to `LAContext` (nil = prompt every time).
  public var reuseDuration: TimeInterval?

  /// Default fallback button title (e.g. "Enter Passcode").
  public var localizedFallbackTitle: String?

  /// Invalidates `LAContext` after successful authentication.
  public var invalidateContextAfterSuccess: Bool

  /// Invalidates `LAContext` after failed authentication.
  public var invalidateContextAfterFailure: Bool

  /// Creates configuration with FKKit defaults.
  public init(
    defaultPolicy: FKBiometricPolicy = .biometricsOrPasscode,
    reuseDuration: TimeInterval? = nil,
    localizedFallbackTitle: String? = nil,
    invalidateContextAfterSuccess: Bool = true,
    invalidateContextAfterFailure: Bool = true
  ) {
    self.defaultPolicy = defaultPolicy
    self.reuseDuration = reuseDuration
    self.localizedFallbackTitle = localizedFallbackTitle
    self.invalidateContextAfterSuccess = invalidateContextAfterSuccess
    self.invalidateContextAfterFailure = invalidateContextAfterFailure
  }
}
