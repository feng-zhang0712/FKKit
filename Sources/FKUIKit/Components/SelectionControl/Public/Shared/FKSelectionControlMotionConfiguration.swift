import Foundation

/// Selection transition timing for checkbox and radio controls.
public struct FKSelectionControlMotionConfiguration: Sendable, Equatable {
  /// Duration for selection animations; capped at 0.2s by the renderer.
  public var animationDuration: TimeInterval
  /// Style of the selection transition.
  public var selectionAnimation: FKSelectionControlSelectionAnimation
  /// When `true`, Reduce Motion forces an instantaneous update.
  public var respectsReducedMotion: Bool

  public init(
    animationDuration: TimeInterval = 0.18,
    selectionAnimation: FKSelectionControlSelectionAnimation = .crossfade,
    respectsReducedMotion: Bool = true
  ) {
    self.animationDuration = min(0.2, max(0, animationDuration))
    self.selectionAnimation = selectionAnimation
    self.respectsReducedMotion = respectsReducedMotion
  }
}
