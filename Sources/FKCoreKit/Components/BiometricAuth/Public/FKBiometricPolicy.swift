import Foundation

/// Maps to Apple `LAPolicy` with documented passcode fallback behavior.
public enum FKBiometricPolicy: Sendable, Equatable {
  /// Face ID / Touch ID only; fails when biometry is unavailable (no passcode fallback).
  case biometricsOnly

  /// Biometry with device passcode fallback (most common for app unlock).
  case biometricsOrPasscode

  /// Device passcode authentication (biometry may still appear on some OS versions).
  case devicePasscode
}
