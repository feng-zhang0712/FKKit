import Foundation

/// Stable, integration-friendly error classification for biometric authentication.
public enum FKBiometricError: Error, Sendable, Equatable {
  /// Biometric hardware is not available on this device.
  case biometryNotAvailable

  /// Biometric hardware exists but no Face ID / Touch ID is enrolled.
  case biometryNotEnrolled

  /// Biometric authentication is locked; passcode or waiting is required.
  case biometryLockout

  /// Device passcode is not set.
  case passcodeNotSet

  /// Authentication failed (wrong biometry or passcode).
  case authenticationFailed

  /// User tapped Cancel in the system UI.
  case userCancelled

  /// User chose passcode fallback when available.
  case userFallback

  /// System cancelled the authentication (e.g. another app took foreground).
  case systemCancelled

  /// Host app cancelled via ``FKBiometricAuthenticating/cancelAuthentication()``.
  case appCancelled

  /// `LAContext` is invalid (often after reuse without recreation).
  case invalidContext

  /// App is not active or cannot present authentication UI.
  case notInteractive

  /// Empty or whitespace-only authentication reason.
  case invalidReason

  /// Another authentication is already in progress (custom implementations).
  case authenticationInProgress

  /// Apple Watch is not available for authentication.
  case watchNotAvailable

  /// Unmapped error from LocalAuthentication or another domain.
  case underlying(code: Int, domain: String)
}

extension FKBiometricError: LocalizedError {
  /// Human-readable description via FKI18n (not for programmatic branching).
  public var errorDescription: String? {
    switch self {
    case .biometryNotAvailable:
      return FKI18n.string("fkcore.biometric.error.biometry_not_available")
    case .biometryNotEnrolled:
      return FKI18n.string("fkcore.biometric.error.biometry_not_enrolled")
    case .biometryLockout:
      return FKI18n.string("fkcore.biometric.error.biometry_lockout")
    case .passcodeNotSet:
      return FKI18n.string("fkcore.biometric.error.passcode_not_set")
    case .authenticationFailed:
      return FKI18n.string("fkcore.biometric.error.authentication_failed")
    case .userCancelled:
      return FKI18n.string("fkcore.biometric.error.user_cancelled")
    case .userFallback:
      return FKI18n.string("fkcore.biometric.error.user_fallback")
    case .systemCancelled:
      return FKI18n.string("fkcore.biometric.error.system_cancelled")
    case .appCancelled:
      return FKI18n.string("fkcore.biometric.error.app_cancelled")
    case .invalidContext:
      return FKI18n.string("fkcore.biometric.error.invalid_context")
    case .notInteractive:
      return FKI18n.string("fkcore.biometric.error.not_interactive")
    case .invalidReason:
      return FKI18n.string("fkcore.biometric.error.invalid_reason")
    case .authenticationInProgress:
      return FKI18n.string("fkcore.biometric.error.authentication_in_progress")
    case .watchNotAvailable:
      return FKI18n.string("fkcore.biometric.error.watch_not_available")
    case let .underlying(code, domain):
      return FKI18n.format("fkcore.biometric.error.underlying", code, domain)
    }
  }
}
