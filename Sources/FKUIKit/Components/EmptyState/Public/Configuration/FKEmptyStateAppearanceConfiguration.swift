import UIKit

/// Title and body typography for ``FKEmptyStateView``.
public struct FKEmptyStateTypography {
  public var titleColor: UIColor
  public var descriptionColor: UIColor
  public var titleFont: UIFont
  public var descriptionFont: UIFont
  public var textAlignment: NSTextAlignment

  public init(
    titleColor: UIColor = .label,
    descriptionColor: UIColor = .secondaryLabel,
    titleFont: UIFont = .systemFont(ofSize: 18, weight: .semibold),
    descriptionFont: UIFont = .systemFont(ofSize: 14, weight: .regular),
    textAlignment: NSTextAlignment = .center
  ) {
    self.titleColor = titleColor
    self.descriptionColor = descriptionColor
    self.titleFont = titleFont
    self.descriptionFont = descriptionFont
    self.textAlignment = textAlignment
  }
}

/// Background, gradient, and dimming for the overlay root view.
public struct FKEmptyStateBackgroundAppearance {
  /// Root view background behind gradient/dimming (defaults to opaque system color).
  public var color: UIColor
  /// When non-empty, draws a `CAGradientLayer` under subviews.
  public var gradientColors: [UIColor]
  /// Unit gradient start (0…1).
  public var gradientStartPoint: CGPoint
  /// Unit gradient end (0…1).
  public var gradientEndPoint: CGPoint
  /// Extra black dimming alpha on `blockingDimmingView` (0 = invisible dimmer).
  public var blockingOverlayAlpha: CGFloat

  public init(
    color: UIColor = .systemBackground,
    gradientColors: [UIColor] = [],
    gradientStartPoint: CGPoint = CGPoint(x: 0.5, y: 0),
    gradientEndPoint: CGPoint = CGPoint(x: 0.5, y: 1),
    blockingOverlayAlpha: CGFloat = 0
  ) {
    self.color = color
    self.gradientColors = gradientColors
    self.gradientStartPoint = gradientStartPoint
    self.gradientEndPoint = gradientEndPoint
    self.blockingOverlayAlpha = min(1, max(0, blockingOverlayAlpha))
  }
}

/// Spinner styling for the loading phase.
public struct FKEmptyStateLoadingAppearance {
  /// Tint for `UIActivityIndicatorView` in loading phase.
  public var tintColor: UIColor
  /// Spinner size (`.medium` / `.large`, etc.).
  public var style: UIActivityIndicatorView.Style

  public init(
    tintColor: UIColor = .secondaryLabel,
    style: UIActivityIndicatorView.Style = .large
  ) {
    self.tintColor = tintColor
    self.style = style
  }
}

/// Colors, typography, buttons, and loading chrome for ``FKEmptyStateView``.
public struct FKEmptyStateAppearanceConfiguration {
  public var typography: FKEmptyStateTypography
  public var buttons: FKEmptyStateButtonAppearance
  public var background: FKEmptyStateBackgroundAppearance
  public var loading: FKEmptyStateLoadingAppearance

  public init(
    typography: FKEmptyStateTypography = FKEmptyStateTypography(),
    buttons: FKEmptyStateButtonAppearance = FKEmptyStateButtonAppearance(),
    background: FKEmptyStateBackgroundAppearance = FKEmptyStateBackgroundAppearance(),
    loading: FKEmptyStateLoadingAppearance = FKEmptyStateLoadingAppearance()
  ) {
    self.typography = typography
    self.buttons = buttons
    self.background = background
    self.loading = loading
  }
}
