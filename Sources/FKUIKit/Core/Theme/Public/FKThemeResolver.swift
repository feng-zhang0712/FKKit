import UIKit

/// Resolves theme tokens against traits and accessibility settings.
public enum FKThemeResolver {
  /// Resolves a semantic color from `theme` for `traitCollection`.
  public static func color(
    _ role: FKThemeColorRole,
    in theme: FKTheme,
    traitCollection: UITraitCollection
  ) -> UIColor {
    theme.colors.color(for: role).resolved(for: traitCollection)
  }

  /// Resolves a semantic color from the active registry theme.
  @MainActor
  public static func color(
    _ role: FKThemeColorRole,
    traitCollection: UITraitCollection = UITraitCollection.current
  ) -> UIColor {
    color(role, in: FKThemeRegistry.current, traitCollection: traitCollection)
  }

  /// Returns a scrim color adjusted for Reduce Transparency.
  public static func scrimColor(
    in theme: FKTheme,
    traitCollection: UITraitCollection
  ) -> UIColor {
    opacityBoostedIfNeeded(theme.colors.scrim.resolved(for: traitCollection))
  }

  /// Returns a surface color adjusted for Reduce Transparency.
  public static func surfaceColor(
    elevated: Bool = false,
    in theme: FKTheme,
    traitCollection: UITraitCollection
  ) -> UIColor {
    let token = elevated ? theme.colors.surfaceElevated : theme.colors.surface
    return opacityBoostedIfNeeded(token.resolved(for: traitCollection))
  }

  /// Returns a workflow status color from `theme`.
  public static func statusColor(
    for semantic: FKWidgetStatusSemantic,
    in theme: FKTheme,
    traitCollection: UITraitCollection
  ) -> UIColor {
    theme.colors.color(for: semantic).resolved(for: traitCollection)
  }

  /// Returns a workflow status color from the active registry theme.
  @MainActor
  public static func statusColor(
    for semantic: FKWidgetStatusSemantic,
    traitCollection: UITraitCollection = UITraitCollection.current
  ) -> UIColor {
    statusColor(for: semantic, in: FKThemeRegistry.current, traitCollection: traitCollection)
  }

  /// Returns a font from `theme` scaled for the supplied content size category.
  public static func font(
    _ style: FKThemeTextStyle,
    in theme: FKTheme,
    contentSizeCategory: UIContentSizeCategory
  ) -> UIFont {
    theme.typography.font(for: style, contentSizeCategory: contentSizeCategory)
  }

  private static func opacityBoostedIfNeeded(_ color: UIColor, factor: CGFloat = 1.35) -> UIColor {
    guard UIAccessibility.isReduceTransparencyEnabled else {
      return color
    }
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
      return color.withAlphaComponent(min(color.cgColor.alpha * factor, 1))
    }
    return UIColor(red: red, green: green, blue: blue, alpha: min(alpha * factor, 1))
  }
}
