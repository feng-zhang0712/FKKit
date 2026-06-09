import Foundation

/// Biometric hardware type reported by the device.
public enum FKBiometryType: Sendable, Equatable {
  /// No biometric hardware is available.
  case none
  /// Touch ID sensor.
  case touchID
  /// Face ID sensor.
  case faceID
  /// Optic ID sensor (Vision Pro and supported devices).
  case opticID
}
