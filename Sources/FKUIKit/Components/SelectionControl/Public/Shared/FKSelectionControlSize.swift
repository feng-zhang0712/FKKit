import CoreGraphics
import Foundation

/// Discrete indicator size for checkbox and radio controls.
public enum FKSelectionControlSize: String, Sendable, Equatable, CaseIterable {
  /// 16×16 pt indicator.
  case small
  /// 22×22 pt indicator (default).
  case medium
  /// 28×28 pt indicator.
  case large
}

extension FKSelectionControlSize {
  /// Side length (checkbox) or outer diameter (radio) in points.
  public var indicatorSide: CGFloat {
    switch self {
    case .small: return 16
    case .medium: return 22
    case .large: return 28
    }
  }
}
