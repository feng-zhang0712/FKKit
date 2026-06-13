import UIKit

/// Text styles in the FK theme type ramp.
public enum FKThemeTextStyle: Sendable, Equatable, CaseIterable {
  case largeTitle
  case title1
  case title2
  case title3
  case headline
  case body
  case callout
  case subheadline
  case footnote
  case caption1
  case caption2
}

/// Layout metrics scaled for Dynamic Type.
public struct FKThemeScaledMetrics: Sendable, Equatable {
  /// The scaled value for the active content size category.
  public var scaledValue: CGFloat

  /// Creates scaled metrics.
  public init(scaledValue: CGFloat) {
    self.scaledValue = scaledValue
  }
}

/// Font ramp and scaling helpers for a theme.
public struct FKThemeTypography: Sendable, Equatable {
  /// Base fonts at the Large content size category.
  public var baseFonts: [FKThemeTextStyle: UIFont]

  /// Creates typography with explicit base fonts.
  public init(baseFonts: [FKThemeTextStyle: UIFont]) {
    self.baseFonts = baseFonts
  }

  /// Returns the UIKit text style used to scale each theme text style.
  public func uiTextStyle(for style: FKThemeTextStyle) -> UIFont.TextStyle {
    switch style {
    case .largeTitle: .largeTitle
    case .title1: .title1
    case .title2: .title2
    case .title3: .title3
    case .headline: .headline
    case .body: .body
    case .callout: .callout
    case .subheadline: .subheadline
    case .footnote: .footnote
    case .caption1: .caption1
    case .caption2: .caption2
    }
  }

  /// Returns a font scaled for `contentSizeCategory`.
  public func font(
    for style: FKThemeTextStyle,
    contentSizeCategory: UIContentSizeCategory = UITraitCollection.current.preferredContentSizeCategory
  ) -> UIFont {
    let base = baseFonts[style] ?? UIFont.preferredFont(forTextStyle: uiTextStyle(for: style))
    let metrics = UIFontMetrics(forTextStyle: uiTextStyle(for: style))
    let trait = UITraitCollection(preferredContentSizeCategory: contentSizeCategory)
    return metrics.scaledFont(for: base, compatibleWith: trait)
  }

  /// Returns scaled layout metrics derived from a base value tied to a text style.
  public func scaledMetrics(
    for style: FKThemeTextStyle,
    baseValue: CGFloat,
    contentSizeCategory: UIContentSizeCategory = UITraitCollection.current.preferredContentSizeCategory
  ) -> FKThemeScaledMetrics {
    let baseFont = baseFonts[style] ?? UIFont.preferredFont(forTextStyle: uiTextStyle(for: style))
    let metrics = UIFontMetrics(forTextStyle: uiTextStyle(for: style))
    let trait = UITraitCollection(preferredContentSizeCategory: contentSizeCategory)
    let scaled = metrics.scaledValue(for: baseValue, compatibleWith: trait)
    return FKThemeScaledMetrics(scaledValue: scaled)
  }
}

extension FKThemeTypography {
  public static func == (lhs: FKThemeTypography, rhs: FKThemeTypography) -> Bool {
    FKThemeTextStyle.allCases.allSatisfy { style in
      let left = lhs.baseFonts[style]?.fontDescriptor
      let right = rhs.baseFonts[style]?.fontDescriptor
      return left == right
    }
  }
}
