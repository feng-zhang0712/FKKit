import UIKit

/// Button appearance roles derived from a theme.
public enum FKThemeButtonRole: Sendable, Equatable {
  case primary
  case secondary
  case destructive
}

/// Applies theme tokens to opt-in FKUIKit component defaults.
@MainActor
public enum FKThemeComponentIntegration {
  /// Synchronizes component defaults from `theme`. Built-in presets restore factory component defaults.
  public static func applyComponentDefaults(from theme: FKTheme) {
    if theme == .default || theme == .defaultDark {
      restoreFactoryComponentDefaults()
      return
    }
    applyButtonDefaults(from: theme)
    applyToastDefaults(from: theme)
    applyDividerDefaults(from: theme)
  }

  /// Clears theme-driven component defaults.
  public static func restoreFactoryComponentDefaults() {
    FKButtonGlobalStyle.defaultAppearances = nil
    FKButtonGlobalStyle.applyPerNewButton = nil
    FKToast.defaultConfiguration = FKToastConfiguration()
    FKDivider.defaultConfiguration = FKDividerConfiguration()
  }
}

// MARK: - Button

extension FKTheme {
  /// Builds ``FKButtonStateAppearances`` for a semantic button role.
  public func makeButtonStateAppearances(for role: FKThemeButtonRole) -> FKButtonStateAppearances {
    let cornerStyle = FKButtonCornerStyle(corner: .fixed(metrics.radiusMedium))
    switch role {
    case .primary:
      return FKButtonStateAppearances(
        normal: .filled(
          backgroundColor: colors.primary.uiColor(),
          cornerStyle: cornerStyle
        )
      )
    case .secondary:
      return FKButtonStateAppearances(
        normal: .outlined(
          borderColor: colors.outline.uiColor(),
          borderWidth: metrics.hairline,
          cornerStyle: cornerStyle
        )
      )
    case .destructive:
      return FKButtonStateAppearances(
        normal: .filled(
          backgroundColor: colors.destructive.uiColor(),
          cornerStyle: cornerStyle
        )
      )
    }
  }

  /// Returns the default title color for a themed button role.
  public func buttonTitleColor(for role: FKThemeButtonRole) -> UIColor {
    switch role {
    case .primary:
      colors.onPrimary.uiColor()
    case .secondary:
      colors.onSurface.uiColor()
    case .destructive:
      colors.onDestructive.uiColor()
    }
  }
}

@MainActor
private extension FKThemeComponentIntegration {
  static func applyButtonDefaults(from theme: FKTheme) {
    FKButtonGlobalStyle.defaultAppearances = theme.makeButtonStateAppearances(for: .primary)
    let titleColor = theme.buttonTitleColor(for: .primary)
    FKButtonGlobalStyle.applyPerNewButton = { button in
      applyThemeTitleColor(titleColor, to: button)
    }
  }

  static func applyThemeTitleColor(_ color: UIColor, to button: FKButton) {
    let states: [UIControl.State] = [.normal, .highlighted, .selected, .disabled]
    for state in states {
      var attributes = button.title(for: state) ?? FKButton.LabelAttributes()
      attributes.color = color
      button.setTitle(attributes, for: state)
    }
  }
}

// MARK: - Toast

extension FKTheme {
  /// Returns toast defaults mapped from theme surface colors.
  public func makeToastConfiguration() -> FKToastConfiguration {
    var configuration = FKToastConfiguration()
    configuration.textColor = colors.onSurface.uiColor()
    configuration.backgroundColor = colors.surfaceElevated.uiColor()
    configuration.cornerRadius = metrics.radiusMedium
    if case let .custom(_, opacity, radius, offset) = shadows.elevationMedium {
      configuration.showsShadow = true
      configuration.shadowOpacity = opacity
      configuration.shadowRadius = radius
      configuration.shadowOffset = offset
    }
    configuration.font = typography.font(for: .subheadline)
    configuration.titleFont = typography.font(for: .headline)
    return configuration
  }
}

// MARK: - Sheet

extension FKTheme {
  /// Builds a sheet backdrop style from the theme scrim token.
  public func makeBackdropStyle(traitCollection: UITraitCollection) -> FKBackdropStyle {
    FKThemeBackdropStyleBuilder.backdropStyle(
      from: FKThemeResolver.scrimColor(in: self, traitCollection: traitCollection)
    )
  }
}

private enum FKThemeBackdropStyleBuilder {
  static func backdropStyle(from scrimColor: UIColor) -> FKBackdropStyle {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    if scrimColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
      return .dim(color: UIColor(red: red, green: green, blue: blue, alpha: 1), alpha: alpha)
    }
    return .dim(color: .black, alpha: 0.45)
  }
}

@MainActor
private extension FKThemeComponentIntegration {
  static func applyToastDefaults(from theme: FKTheme) {
    FKToast.defaultConfiguration = theme.makeToastConfiguration()
  }

  static func applyDividerDefaults(from theme: FKTheme) {
    var configuration = FKDivider.defaultConfiguration
    configuration.color = theme.colors.outline.uiColor()
    FKDivider.defaultConfiguration = configuration
  }
}
