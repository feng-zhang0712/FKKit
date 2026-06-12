import UIKit

/// Page indicator visual style.
public enum FKCarouselIndicatorStyle: Equatable, Sendable {
  case dots
  case bar
  case fraction
  case line
  case custom(id: String)
  case none
}

/// Page indicator placement relative to the collection view.
public enum FKCarouselIndicatorPlacement: Equatable, Sendable {
  case overlayBottom(inset: CGFloat = 12)
  case overlayTop(inset: CGFloat = 12)
  case below(spacing: CGFloat = 8)
  case above(spacing: CGFloat = 8)
}

/// Page indicator configuration.
public struct FKCarouselIndicatorConfiguration: Equatable, Sendable {
  /// Indicator visual style.
  public var style: FKCarouselIndicatorStyle

  /// Indicator placement.
  public var placement: FKCarouselIndicatorPlacement

  /// Hides the indicator when `pageCount <= 1`.
  public var hidesForSinglePage: Bool

  /// Shows the indicator even when there is only one page.
  public var showsIndicatorForSinglePage: Bool

  /// Interpolates indicator position while dragging.
  public var indicatorFollowsScrollProgress: Bool

  /// Dot diameter for ``FKCarouselIndicatorStyle/dots``.
  public var dotDiameter: CGFloat

  /// Spacing between dots.
  public var dotSpacing: CGFloat

  /// Active dot color.
  public var activeColor: UIColor

  /// Inactive dot color.
  public var inactiveColor: UIColor

  /// Hides the indicator container from VoiceOver to avoid duplicate announcements.
  public var hidesIndicatorFromAccessibility: Bool

  /// Creates indicator configuration.
  public init(
    style: FKCarouselIndicatorStyle = .dots,
    placement: FKCarouselIndicatorPlacement = .overlayBottom(inset: 12),
    hidesForSinglePage: Bool = true,
    showsIndicatorForSinglePage: Bool = false,
    indicatorFollowsScrollProgress: Bool = true,
    dotDiameter: CGFloat = 8,
    dotSpacing: CGFloat = 8,
    activeColor: UIColor = .label,
    inactiveColor: UIColor = .tertiaryLabel,
    hidesIndicatorFromAccessibility: Bool = true
  ) {
    self.style = style
    self.placement = placement
    self.hidesForSinglePage = hidesForSinglePage
    self.showsIndicatorForSinglePage = showsIndicatorForSinglePage
    self.indicatorFollowsScrollProgress = indicatorFollowsScrollProgress
    self.dotDiameter = dotDiameter
    self.dotSpacing = dotSpacing
    self.activeColor = activeColor
    self.inactiveColor = inactiveColor
    self.hidesIndicatorFromAccessibility = hidesIndicatorFromAccessibility
  }
}
