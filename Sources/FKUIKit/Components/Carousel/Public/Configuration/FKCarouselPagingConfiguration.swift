import UIKit

/// Paging and scroll behavior configuration.
public struct FKCarouselPagingConfiguration: Equatable, Sendable {
  /// Whether the user can scroll between pages.
  public var isScrollEnabled: Bool

  /// Scroll view deceleration rate (`\.fast` stops sooner; `\.normal` coasts farther).
  public var decelerationRate: UIScrollView.DecelerationRate

  /// Fraction of page width required to advance on slow drags (`0...1`).
  public var pageChangeThreshold: CGFloat

  /// Whether to expose fractional scroll progress to delegates.
  public var reportsScrollProgress: Bool

  /// Whether the collection view bounces at content edges.
  ///
  /// Prefer `false` with infinite looping so clone-page handoff is not interrupted by rubber-banding.
  public var bounces: Bool

  /// Whether horizontal bouncing is allowed even when content is smaller than the viewport.
  public var alwaysBounceHorizontal: Bool

  /// Creates paging configuration.
  public init(
    isScrollEnabled: Bool = true,
    decelerationRate: UIScrollView.DecelerationRate = .normal,
    pageChangeThreshold: CGFloat = 0.5,
    reportsScrollProgress: Bool = true,
    bounces: Bool = true,
    alwaysBounceHorizontal: Bool = false
  ) {
    self.isScrollEnabled = isScrollEnabled
    self.decelerationRate = decelerationRate
    self.pageChangeThreshold = pageChangeThreshold
    self.reportsScrollProgress = reportsScrollProgress
    self.bounces = bounces
    self.alwaysBounceHorizontal = alwaysBounceHorizontal
  }
}
