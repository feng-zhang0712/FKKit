import UIKit

/// Nested horizontal scroll arbitration policy.
public enum FKCarouselNestedScrollPolicy: Equatable, Sendable {
  /// UIKit default gesture behavior.
  case standard

  /// Carousel pan takes priority until the first or last page is reached.
  case failParentUntilCarouselAtEdge

  /// Allows parent and carousel pans to recognize simultaneously before axis lock.
  case simultaneous
}

/// Interaction and gesture configuration.
public struct FKCarouselInteractionConfiguration: Equatable, Sendable {
  /// Nested scroll policy when embedded in vertical scroll views.
  public var nestedScrollPolicy: FKCarouselNestedScrollPolicy

  /// Requires the navigation pop gesture to fail before carousel pan begins.
  public var requiresNavigationPopGestureToFail: Bool

  /// Opacity applied to non-interactive pages.
  public var nonInteractiveAlpha: CGFloat

  /// When `true`, tapping a non-current page (e.g. a peeking side card) scrolls to that page.
  ///
  /// The current page still reports selection via ``FKCarouselDelegate/carousel(_:didSelectPageAt:)``.
  public var scrollsToTappedPage: Bool

  /// Creates interaction configuration.
  public init(
    nestedScrollPolicy: FKCarouselNestedScrollPolicy = .standard,
    requiresNavigationPopGestureToFail: Bool = false,
    nonInteractiveAlpha: CGFloat = 1.0,
    scrollsToTappedPage: Bool = false
  ) {
    self.nestedScrollPolicy = nestedScrollPolicy
    self.requiresNavigationPopGestureToFail = requiresNavigationPopGestureToFail
    self.nonInteractiveAlpha = nonInteractiveAlpha
    self.scrollsToTappedPage = scrollsToTappedPage
  }
}
