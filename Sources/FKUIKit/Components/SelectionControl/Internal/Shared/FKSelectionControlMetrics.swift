import UIKit

/// Design-token metrics for selection indicators and rows.
@MainActor
enum FKSelectionControlMetrics {
  static let rowMinHeight: CGFloat = 44
  static let imageTitleSpacing: CGFloat = 10
  static var separatorHeight: CGFloat { 1.0 / UIScreen.main.scale }
  static let defaultImageSize = CGSize(width: 24, height: 24)
  static let minimumTouchTarget: CGFloat = 44

  static func cornerRadius(for size: FKSelectionControlSize) -> CGFloat {
    switch size {
    case .small: return 3.5
    case .medium: return 5
    case .large: return 6
    }
  }

  static func uncheckedBorderWidth(for size: FKSelectionControlSize) -> CGFloat {
    switch size {
    case .small: return 1.5
    case .medium: return 1.75
    case .large: return 2
    }
  }

  static func radioRingWidth(for size: FKSelectionControlSize) -> CGFloat {
    switch size {
    case .small: return 1.5
    case .medium: return 2
    case .large: return 2.5
    }
  }

  /// Expands a frame to at least `minimum` centered on the original rect.
  static func expandedHitFrame(for frame: CGRect, minimum: CGFloat = minimumTouchTarget) -> CGRect {
    let width = max(frame.width, minimum)
    let height = max(frame.height, minimum)
    return CGRect(
      x: frame.midX - width / 2,
      y: frame.midY - height / 2,
      width: width,
      height: height
    )
  }
}
