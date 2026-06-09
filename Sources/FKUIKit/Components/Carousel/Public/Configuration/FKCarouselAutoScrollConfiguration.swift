import Foundation

/// Auto-scroll timer configuration.
public struct FKCarouselAutoScrollConfiguration: Equatable, Sendable {
  /// Enables timed page advancement.
  public var isEnabled: Bool

  /// Interval between automatic page changes.
  public var interval: TimeInterval

  /// Whether auto-scroll repeats after the last page.
  public var repeats: Bool

  /// Direction of automatic advancement.
  public var direction: FKCarouselScrollDirection

  /// Pauses auto-scroll while the user interacts.
  public var pausesOnUserInteraction: Bool

  /// Pauses auto-scroll when off-screen.
  public var pausesWhenOffscreen: Bool

  /// Pauses auto-scroll when the app is inactive.
  public var pausesWhenAppInactive: Bool

  /// Disables auto-scroll when Reduce Motion is enabled.
  public var respectsReducedMotion: Bool

  /// Creates auto-scroll configuration.
  public init(
    isEnabled: Bool = false,
    interval: TimeInterval = 3.0,
    repeats: Bool = true,
    direction: FKCarouselScrollDirection = .forward,
    pausesOnUserInteraction: Bool = true,
    pausesWhenOffscreen: Bool = true,
    pausesWhenAppInactive: Bool = true,
    respectsReducedMotion: Bool = true
  ) {
    self.isEnabled = isEnabled
    self.interval = interval
    self.repeats = repeats
    self.direction = direction
    self.pausesOnUserInteraction = pausesOnUserInteraction
    self.pausesWhenOffscreen = pausesWhenOffscreen
    self.pausesWhenAppInactive = pausesWhenAppInactive
    self.respectsReducedMotion = respectsReducedMotion
  }
}
