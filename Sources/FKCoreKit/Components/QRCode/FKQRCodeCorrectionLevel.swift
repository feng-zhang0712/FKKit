import Foundation

/// QR error-correction level passed to `CIQRCodeGenerator`.
public enum FKQRCodeCorrectionLevel: String, Sendable, CaseIterable, Equatable {
  /// ~7% recovery.
  case L
  /// ~15% recovery.
  case M
  /// ~25% recovery.
  case Q
  /// ~30% recovery (recommended when embedding a center logo).
  case H
}
