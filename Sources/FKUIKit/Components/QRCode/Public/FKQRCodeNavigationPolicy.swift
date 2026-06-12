import Foundation

/// Post-scan URL handling policy for ``FKQRCodeScannerViewController``.
public enum FKQRCodeNavigationPolicy: Sendable, Equatable {
  /// Delegate receives the payload; no automatic URL open (default, safest).
  case callbackOnly
  /// Opens `http`/`https` URLs in an in-app `SFSafariViewController` after the delegate callback.
  case openHTTPInApp
  /// Opens URLs with `UIApplication.shared.open` after the delegate callback (use with caution).
  case openExternally
}
