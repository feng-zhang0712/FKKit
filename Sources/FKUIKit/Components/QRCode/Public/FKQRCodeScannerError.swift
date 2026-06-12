import Foundation

/// Errors surfaced by ``FKQRCodeScannerViewController``.
public enum FKQRCodeScannerError: Error, Sendable, Equatable {
  /// No video capture device is available (simulator or hardware restriction).
  case cameraUnavailable
  /// Camera permission was denied or restricted.
  case permissionDenied
  /// `AVCaptureSession` could not be configured.
  case sessionConfigurationFailed
  /// Reserved for future session-interruption handling.
  case interrupted
}

extension FKQRCodeScannerError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .cameraUnavailable:
      return FKUIKitI18n.string("fkuikit.qrcode.error.camera_unavailable")
    case .permissionDenied:
      return FKUIKitI18n.string("fkuikit.qrcode.error.permission_denied")
    case .sessionConfigurationFailed:
      return FKUIKitI18n.string("fkuikit.qrcode.error.session_configuration_failed")
    case .interrupted:
      return FKUIKitI18n.string("fkuikit.qrcode.error.interrupted")
    }
  }
}
