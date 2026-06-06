import UIKit

/// Visual chrome for an empty-state action button (filled configuration on iOS 15+).
///
/// Button copy comes from ``FKEmptyStateAction/title``; this type controls colors, fonts, and padding only.
public struct FKEmptyStateButtonStyle {
  /// Foreground (text) color.
  public var titleColor: UIColor
  /// Title font (also applied where configuration supports it).
  public var font: UIFont
  /// Fill color for filled button style.
  public var backgroundColor: UIColor
  /// Corner radius applied through `UIButton.Configuration` background (iOS 15+).
  public var cornerRadius: CGFloat
  /// Padding inside the button around the title.
  public var contentInsets: UIEdgeInsets
  /// Optional stroke; `nil` means no border.
  public var borderColor: UIColor?
  /// Hairline width when `borderColor` is set.
  public var borderWidth: CGFloat

  public init(
    titleColor: UIColor = .white,
    font: UIFont = .systemFont(ofSize: 15, weight: .semibold),
    backgroundColor: UIColor = .systemBlue,
    cornerRadius: CGFloat = 10,
    contentInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16),
    borderColor: UIColor? = nil,
    borderWidth: CGFloat = 0
  ) {
    self.titleColor = titleColor
    self.font = font
    self.backgroundColor = backgroundColor
    self.cornerRadius = cornerRadius
    self.contentInsets = contentInsets
    self.borderColor = borderColor
    self.borderWidth = borderWidth
  }
}

/// Primary, secondary, and tertiary button chrome for ``FKEmptyStateView``.
public struct FKEmptyStateButtonAppearance {
  /// Filled primary action styling.
  public var primary: FKEmptyStateButtonStyle
  /// Optional override for the secondary (bordered) action; `nil` derives a bordered variant from ``primary``.
  public var secondary: FKEmptyStateButtonStyle?
  /// Optional override for the tertiary / plain action; `nil` derives a plain variant from ``primary``.
  public var tertiary: FKEmptyStateButtonStyle?

  public init(
    primary: FKEmptyStateButtonStyle = FKEmptyStateButtonStyle(),
    secondary: FKEmptyStateButtonStyle? = nil,
    tertiary: FKEmptyStateButtonStyle? = nil
  ) {
    self.primary = primary
    self.secondary = secondary
    self.tertiary = tertiary
  }

  /// Returns the effective secondary button style (explicit override or derived from ``primary``).
  public func resolvedSecondary() -> FKEmptyStateButtonStyle {
    if let secondary { return secondary }
    return FKEmptyStateButtonStyle(
      titleColor: primary.backgroundColor,
      font: primary.font,
      backgroundColor: .clear,
      cornerRadius: primary.cornerRadius,
      contentInsets: primary.contentInsets,
      borderColor: primary.backgroundColor,
      borderWidth: 1
    )
  }

  /// Returns the effective tertiary / link button style (explicit override or derived from ``primary``).
  public func resolvedTertiary() -> FKEmptyStateButtonStyle {
    if let tertiary { return tertiary }
    return FKEmptyStateButtonStyle(
      titleColor: primary.backgroundColor,
      font: primary.font,
      backgroundColor: .clear,
      cornerRadius: 0,
      contentInsets: primary.contentInsets,
      borderColor: nil,
      borderWidth: 0
    )
  }
}
