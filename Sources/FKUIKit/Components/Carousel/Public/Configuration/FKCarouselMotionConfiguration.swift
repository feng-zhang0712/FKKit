import Foundation

/// Motion and haptic configuration.
public struct FKCarouselMotionConfiguration: Equatable, Sendable {
  /// Cross-fade duration for image success transitions.
  public var imageCrossFadeDuration: TimeInterval

  /// Whether indicator dot scaling is animated.
  public var animatesIndicatorDots: Bool

  /// Plays a light impact haptic on page settle.
  public var playsPageChangeHaptic: Bool

  /// Creates motion configuration.
  public init(
    imageCrossFadeDuration: TimeInterval = 0.25,
    animatesIndicatorDots: Bool = true,
    playsPageChangeHaptic: Bool = false
  ) {
    self.imageCrossFadeDuration = imageCrossFadeDuration
    self.animatesIndicatorDots = animatesIndicatorDots
    self.playsPageChangeHaptic = playsPageChangeHaptic
  }
}
