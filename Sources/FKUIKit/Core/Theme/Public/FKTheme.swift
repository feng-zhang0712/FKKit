import UIKit

/// Immutable design-token snapshot for FKUIKit components.
public struct FKTheme: Sendable, Equatable {
  /// Stable identifier for ``default``.
  public static let defaultIdentifier = "fk.theme.default"

  /// Stable identifier for ``defaultDark``.
  public static let defaultDarkIdentifier = "fk.theme.default-dark"

  /// Identifier for this theme instance.
  public var id: String
  /// Semantic colors.
  public var colors: FKThemeColorPalette
  /// Typography ramp.
  public var typography: FKThemeTypography
  /// Spacing and radii.
  public var metrics: FKThemeMetrics
  /// Shadow presets.
  public var shadows: FKThemeShadowTokens

  /// Creates a theme snapshot.
  public init(
    id: String,
    colors: FKThemeColorPalette,
    typography: FKThemeTypography,
    metrics: FKThemeMetrics,
    shadows: FKThemeShadowTokens
  ) {
    self.id = id
    self.colors = colors
    self.typography = typography
    self.metrics = metrics
    self.shadows = shadows
  }

  /// Built-in theme using Apple semantic colors. Registering this value restores factory component defaults.
  public static let `default`: FKTheme = FKThemeDefaultFactory.makeDefault()

  /// Built-in preset with the same adaptive tokens as ``default`` and a distinct ``id``.
  public static let defaultDark: FKTheme = FKThemeDefaultFactory.makeDefaultDark()
}
