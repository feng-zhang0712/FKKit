import UIKit

/// Policy when there are zero carousel pages.
public enum FKCarouselEmptyStatePolicy: Equatable, Sendable {
  /// Collapse to zero height.
  case collapse

  /// Show an empty-state overlay for the given scenario.
  case showEmptyState(FKEmptyStateScenario)
}

/// Layered carousel configuration aligned with other FKUIKit controls.
public struct FKCarouselConfiguration: Equatable, @unchecked Sendable {
  /// Layout and geometry.
  public var layout: FKCarouselLayoutConfiguration

  /// Paging behavior.
  public var paging: FKCarouselPagingConfiguration

  /// Page indicator.
  public var indicator: FKCarouselIndicatorConfiguration

  /// Auto-scroll timer.
  public var autoScroll: FKCarouselAutoScrollConfiguration

  /// Gestures and interaction.
  public var interaction: FKCarouselInteractionConfiguration

  /// Motion and haptics.
  public var motion: FKCarouselMotionConfiguration

  /// Accessibility.
  public var accessibility: FKCarouselAccessibilityConfiguration

  /// Empty collection policy.
  public var emptyState: FKCarouselEmptyStatePolicy

  /// Creates carousel configuration.
  public init(
    layout: FKCarouselLayoutConfiguration = .init(),
    paging: FKCarouselPagingConfiguration = .init(),
    indicator: FKCarouselIndicatorConfiguration = .init(),
    autoScroll: FKCarouselAutoScrollConfiguration = .init(),
    interaction: FKCarouselInteractionConfiguration = .init(),
    motion: FKCarouselMotionConfiguration = .init(),
    accessibility: FKCarouselAccessibilityConfiguration = .init(),
    emptyState: FKCarouselEmptyStatePolicy = .collapse
  ) {
    self.layout = layout
    self.paging = paging
    self.indicator = indicator
    self.autoScroll = autoScroll
    self.interaction = interaction
    self.motion = motion
    self.accessibility = accessibility
    self.emptyState = emptyState
  }
}

/// Global carousel defaults.
@MainActor
public enum FKCarouselDefaults {
  /// Shared default carousel configuration.
  public static var configuration = FKCarouselConfiguration()

  /// Shared default image banner configuration.
  public static var imageBannerConfiguration = FKImageBannerConfiguration()
}
