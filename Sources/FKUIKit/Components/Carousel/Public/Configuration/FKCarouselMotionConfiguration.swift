import CoreGraphics
import Foundation

/// Motion and haptic configuration.
public struct FKCarouselMotionConfiguration: Equatable, Sendable {
  /// Cross-fade duration for image success transitions.
  public var imageCrossFadeDuration: TimeInterval

  /// Whether indicator dot scaling is animated.
  public var animatesIndicatorDots: Bool

  /// Plays a light impact haptic on page settle.
  public var playsPageChangeHaptic: Bool

  /// Scale applied to pages one full page-span away from the viewport center.
  ///
  /// Values in `0...1`. Use `1` (default) for no focus scaling. Values below `1`
  /// enlarge the focused page relative to neighbors (e.g. `0.88` for centered card carousels).
  /// Interpolates continuously while scrolling. Ignored when Reduce Motion is enabled (stays `1`).
  public var sidePageScale: CGFloat

  /// Creates motion configuration.
  public init(
    imageCrossFadeDuration: TimeInterval = 0.25,
    animatesIndicatorDots: Bool = true,
    playsPageChangeHaptic: Bool = false,
    sidePageScale: CGFloat = 1
  ) {
    self.imageCrossFadeDuration = imageCrossFadeDuration
    self.animatesIndicatorDots = animatesIndicatorDots
    self.playsPageChangeHaptic = playsPageChangeHaptic
    self.sidePageScale = min(max(sidePageScale, 0), 1)
  }
}
