import UIKit

/// Paging and scroll behavior configuration.
public struct FKCarouselPagingConfiguration: Equatable, Sendable {
  /// Whether the user can scroll between pages.
  public var isScrollEnabled: Bool

  /// Scroll view deceleration rate.
  public var decelerationRate: UIScrollView.DecelerationRate

  /// Fraction of page width required to advance on slow drags (`0...1`).
  public var pageChangeThreshold: CGFloat

  /// Whether to expose fractional scroll progress to delegates.
  public var reportsScrollProgress: Bool

  /// Creates paging configuration.
  public init(
    isScrollEnabled: Bool = true,
    decelerationRate: UIScrollView.DecelerationRate = .normal,
    pageChangeThreshold: CGFloat = 0.5,
    reportsScrollProgress: Bool = true
  ) {
    self.isScrollEnabled = isScrollEnabled
    self.decelerationRate = decelerationRate
    self.pageChangeThreshold = pageChangeThreshold
    self.reportsScrollProgress = reportsScrollProgress
  }
}
