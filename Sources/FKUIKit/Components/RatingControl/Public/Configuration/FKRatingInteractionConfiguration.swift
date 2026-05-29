import UIKit

/// Touch behavior, snapping, and expanded hit targets for ``FKRatingControl``.
public struct FKRatingInteractionConfiguration: Sendable, Equatable {
  /// Read-only vs interactive behavior.
  public var mode: FKRatingInteractionMode
  /// Step size applied after user input.
  public var step: FKRatingStep
  /// When `true`, drag gestures continuously update the value.
  public var allowsDragSelection: Bool
  /// Minimum hit target per item, centered on each icon (HIG recommends at least 44×44).
  public var minimumTouchTargetSize: CGSize
  /// Opacity multiplier while the control is disabled.
  public var disabledAlpha: CGFloat
  /// Haptic feedback when the snapped value changes.
  public var touchHaptic: FKRatingTouchHaptic

  public init(
    mode: FKRatingInteractionMode = .interactive,
    step: FKRatingStep = .whole,
    allowsDragSelection: Bool = true,
    minimumTouchTargetSize: CGSize = CGSize(width: 44, height: 44),
    disabledAlpha: CGFloat = 0.45,
    touchHaptic: FKRatingTouchHaptic = .none
  ) {
    self.mode = mode
    self.step = step
    self.allowsDragSelection = allowsDragSelection
    self.minimumTouchTargetSize = CGSize(
      width: max(24, minimumTouchTargetSize.width),
      height: max(24, minimumTouchTargetSize.height)
    )
    self.disabledAlpha = min(max(0.1, disabledAlpha), 1)
    self.touchHaptic = touchHaptic
  }
}
