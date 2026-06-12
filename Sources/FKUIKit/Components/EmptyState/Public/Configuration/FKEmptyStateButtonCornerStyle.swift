import CoreGraphics

/// Corner treatment for empty-state action buttons (applied through `UIButton.Configuration`).
public enum FKEmptyStateButtonCornerStyle: Equatable, Sendable {
  /// Fixed corner radius regardless of button height.
  case fixed(radius: CGFloat)
  /// True capsule shape that tracks the button's rendered height.
  case capsule
}
