import UIKit

/// Animation timing for fill changes and optional item bounce.
public struct FKRatingMotionConfiguration: Sendable, Equatable {
  /// Duration for animated fill updates; `0` disables implicit animation.
  public var animationDuration: TimeInterval
  /// Timing curve for fill transitions.
  public var timing: FKRatingTiming
  /// When `true`, respects Reduce Motion by skipping animations.
  public var respectsReducedMotion: Bool
  /// Lightweight bounce applied to items whose fill fraction changes.
  public var selectionAnimation: FKRatingSelectionAnimation

  public init(
    animationDuration: TimeInterval = 0.18,
    timing: FKRatingTiming = .default,
    respectsReducedMotion: Bool = true,
    selectionAnimation: FKRatingSelectionAnimation = .bounce
  ) {
    self.animationDuration = max(0, animationDuration)
    self.timing = timing
    self.respectsReducedMotion = respectsReducedMotion
    self.selectionAnimation = selectionAnimation
  }
}
