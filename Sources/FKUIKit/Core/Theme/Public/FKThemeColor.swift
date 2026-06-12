import UIKit

/// A light/dark pair of colors resolved against a ``UITraitCollection``.
public struct FKThemeColor: @unchecked Sendable, Equatable {
  /// Color used when the user interface style is light (or unspecified).
  public var light: UIColor
  /// Color used when the user interface style is dark.
  public var dark: UIColor

  /// Creates a theme color pair.
  public init(light: UIColor, dark: UIColor) {
    self.light = light
    self.dark = dark
  }

  /// Creates a theme color that uses the same color in light and dark mode.
  public init(fixed color: UIColor) {
    light = color
    dark = color
  }

  /// Creates a theme color from a system-adaptive ``UIColor`` (for example `.label` or `.systemBlue`).
  public init(dynamic color: UIColor) {
    self.init(fixed: color)
  }

  /// Resolves the color for `traitCollection`, including high contrast when available.
  public func resolved(for traitCollection: UITraitCollection) -> UIColor {
    let style = traitCollection.userInterfaceStyle
    switch style {
    case .dark:
      return dark.resolvedColor(with: traitCollection)
    case .light, .unspecified:
      return light.resolvedColor(with: traitCollection)
    @unknown default:
      return light.resolvedColor(with: traitCollection)
    }
  }

  /// Returns a dynamic ``UIColor`` that tracks light/dark changes.
  public func uiColor() -> UIColor {
    UIColor { trait in
      resolved(for: trait)
    }
  }
}

extension FKThemeColor {
  public static func == (lhs: FKThemeColor, rhs: FKThemeColor) -> Bool {
    FKThemeColorComparison.isEqual(lhs.light, rhs.light)
      && FKThemeColorComparison.isEqual(lhs.dark, rhs.dark)
  }
}

enum FKThemeColorComparison {
  static func isEqual(_ lhs: UIColor, _ rhs: UIColor) -> Bool {
    lhs.cgColor == rhs.cgColor
  }
}

/// Semantic color roles exposed through ``FKThemeColorPalette``.
public enum FKThemeColorRole: Sendable, Equatable, CaseIterable {
  case primary
  case onPrimary
  case secondary
  case onSecondary
  case destructive
  case onDestructive
  case background
  case surface
  case surfaceElevated
  case onSurface
  case onSurfaceSecondary
  case outline
  case scrim
  case statusSuccess
  case statusWarning
  case statusError
  case statusInfo
  case statusNeutral
}
