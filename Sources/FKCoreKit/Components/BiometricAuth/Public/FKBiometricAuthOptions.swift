import Foundation

/// Per-call overrides for ``FKBiometricAuthenticating/authenticate(reason:policy:options:)``.
public struct FKBiometricAuthOptions: Sendable, Equatable {
  /// Optional policy override; `nil` uses the `policy` argument passed to ``authenticate(reason:policy:options:)``.
  public var policy: FKBiometricPolicy?

  /// When `false` and policy supports fallback, uses biometrics-only evaluation.
  public var allowPasscodeFallback: Bool

  /// Reuse window override for this call.
  public var reuseDuration: TimeInterval?

  /// Fallback button title override for this call.
  public var localizedFallbackTitle: String?

  /// Default per-call options.
  public init(
    policy: FKBiometricPolicy? = nil,
    allowPasscodeFallback: Bool = true,
    reuseDuration: TimeInterval? = nil,
    localizedFallbackTitle: String? = nil
  ) {
    self.policy = policy
    self.allowPasscodeFallback = allowPasscodeFallback
    self.reuseDuration = reuseDuration
    self.localizedFallbackTitle = localizedFallbackTitle
  }
}
