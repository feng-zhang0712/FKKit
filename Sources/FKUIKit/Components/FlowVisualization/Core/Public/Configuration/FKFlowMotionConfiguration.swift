import UIKit

/// Animation and reduced-motion behavior for flow controls.
public struct FKFlowMotionConfiguration: Sendable, Equatable {
  /// Duration for state and connector transitions; `0` disables animation.
  public var animationDuration: TimeInterval
  /// Timing curve for transitions.
  public var timing: FKFlowTiming
  /// When `true`, respects Reduce Motion by skipping animations and pulse.
  public var respectsReducedMotion: Bool
  /// Pulses the current node when `true` and Reduce Motion is off.
  public var pulsesCurrentNode: Bool

  public init(
    animationDuration: TimeInterval = 0.22,
    timing: FKFlowTiming = .default,
    respectsReducedMotion: Bool = true,
    pulsesCurrentNode: Bool = true
  ) {
    self.animationDuration = max(0, animationDuration)
    self.timing = timing
    self.respectsReducedMotion = respectsReducedMotion
    self.pulsesCurrentNode = pulsesCurrentNode
  }

  /// Whether animations should run for the current accessibility settings.
  @MainActor
  public var shouldAnimate: Bool {
    if respectsReducedMotion, UIAccessibility.isReduceMotionEnabled {
      return false
    }
    return animationDuration > 0
  }
}
