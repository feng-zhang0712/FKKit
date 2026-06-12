import UIKit

enum FKThemeDefaultFactory {
  static func makeDefault() -> FKTheme {
    makeTheme(id: FKTheme.defaultIdentifier)
  }

  static func makeDefaultDark() -> FKTheme {
    makeTheme(id: FKTheme.defaultDarkIdentifier)
  }

  private static func makeTheme(id: String) -> FKTheme {
    FKTheme(
      id: id,
      colors: makeDefaultPalette(),
      typography: makeDefaultTypography(),
      metrics: FKThemeMetrics(),
      shadows: makeDefaultShadows()
    )
  }

  private static func makeDefaultPalette() -> FKThemeColorPalette {
    FKThemeColorPalette(
      primary: .init(dynamic: .systemBlue),
      onPrimary: .init(fixed: .white),
      secondary: .init(dynamic: .secondarySystemFill),
      onSecondary: .init(dynamic: .label),
      destructive: .init(dynamic: .systemRed),
      onDestructive: .init(fixed: .white),
      background: .init(dynamic: .systemBackground),
      surface: .init(dynamic: .secondarySystemBackground),
      surfaceElevated: .init(dynamic: .tertiarySystemBackground),
      onSurface: .init(dynamic: .label),
      onSurfaceSecondary: .init(dynamic: .secondaryLabel),
      outline: .init(dynamic: .separator),
      scrim: .init(
        light: UIColor.black.withAlphaComponent(0.45),
        dark: UIColor.black.withAlphaComponent(0.55)
      ),
      statusSuccess: statusColor(for: .success),
      statusWarning: statusColor(for: .warning),
      statusError: statusColor(for: .error),
      statusInfo: statusColor(for: .info),
      statusNeutral: statusColor(for: .neutral)
    )
  }

  private static func statusColor(for semantic: FKWidgetStatusSemantic) -> FKThemeColor {
    let palette = FKWidgetStatusColorTokens.palette(for: semantic)
    return FKThemeColor(fixed: palette.foreground)
  }

  private static func makeDefaultTypography() -> FKThemeTypography {
    let fonts: [FKThemeTextStyle: UIFont] = [
      .largeTitle: UIFont.systemFont(ofSize: 34, weight: .semibold),
      .title1: UIFont.systemFont(ofSize: 28, weight: .regular),
      .title2: UIFont.systemFont(ofSize: 22, weight: .regular),
      .title3: UIFont.systemFont(ofSize: 20, weight: .regular),
      .headline: UIFont.systemFont(ofSize: 17, weight: .semibold),
      .body: UIFont.systemFont(ofSize: 17, weight: .regular),
      .callout: UIFont.systemFont(ofSize: 16, weight: .regular),
      .subheadline: UIFont.systemFont(ofSize: 15, weight: .regular),
      .footnote: UIFont.systemFont(ofSize: 13, weight: .regular),
      .caption1: UIFont.systemFont(ofSize: 12, weight: .regular),
      .caption2: UIFont.systemFont(ofSize: 11, weight: .regular),
    ]
    return FKThemeTypography(baseFonts: fonts)
  }

  private static func makeDefaultShadows() -> FKThemeShadowTokens {
    FKThemeShadowTokens(
      elevationLow: .custom(
        color: UIColor.black.withAlphaComponent(0.12),
        opacity: 1,
        radius: 4,
        offset: CGSize(width: 0, height: 2)
      ),
      elevationMedium: .custom(
        color: UIColor.black.withAlphaComponent(0.16),
        opacity: 1,
        radius: 8,
        offset: CGSize(width: 0, height: 4)
      ),
      elevationHigh: .custom(
        color: UIColor.black.withAlphaComponent(0.22),
        opacity: 1,
        radius: 12,
        offset: CGSize(width: 0, height: 6)
      )
    )
  }
}
