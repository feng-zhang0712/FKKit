import UIKit

/// Semantic color roles for a theme snapshot.
public struct FKThemeColorPalette: Sendable, Equatable {
  public var primary: FKThemeColor
  public var onPrimary: FKThemeColor
  public var secondary: FKThemeColor
  public var onSecondary: FKThemeColor
  public var destructive: FKThemeColor
  public var onDestructive: FKThemeColor
  public var background: FKThemeColor
  public var surface: FKThemeColor
  public var surfaceElevated: FKThemeColor
  public var onSurface: FKThemeColor
  public var onSurfaceSecondary: FKThemeColor
  public var outline: FKThemeColor
  public var scrim: FKThemeColor
  public var statusSuccess: FKThemeColor
  public var statusWarning: FKThemeColor
  public var statusError: FKThemeColor
  public var statusInfo: FKThemeColor
  public var statusNeutral: FKThemeColor

  /// Creates a palette with explicit semantic colors.
  public init(
    primary: FKThemeColor,
    onPrimary: FKThemeColor,
    secondary: FKThemeColor,
    onSecondary: FKThemeColor,
    destructive: FKThemeColor,
    onDestructive: FKThemeColor,
    background: FKThemeColor,
    surface: FKThemeColor,
    surfaceElevated: FKThemeColor,
    onSurface: FKThemeColor,
    onSurfaceSecondary: FKThemeColor,
    outline: FKThemeColor,
    scrim: FKThemeColor,
    statusSuccess: FKThemeColor,
    statusWarning: FKThemeColor,
    statusError: FKThemeColor,
    statusInfo: FKThemeColor,
    statusNeutral: FKThemeColor
  ) {
    self.primary = primary
    self.onPrimary = onPrimary
    self.secondary = secondary
    self.onSecondary = onSecondary
    self.destructive = destructive
    self.onDestructive = onDestructive
    self.background = background
    self.surface = surface
    self.surfaceElevated = surfaceElevated
    self.onSurface = onSurface
    self.onSurfaceSecondary = onSurfaceSecondary
    self.outline = outline
    self.scrim = scrim
    self.statusSuccess = statusSuccess
    self.statusWarning = statusWarning
    self.statusError = statusError
    self.statusInfo = statusInfo
    self.statusNeutral = statusNeutral
  }

  /// Returns the color for a semantic role.
  public func color(for role: FKThemeColorRole) -> FKThemeColor {
    switch role {
    case .primary: primary
    case .onPrimary: onPrimary
    case .secondary: secondary
    case .onSecondary: onSecondary
    case .destructive: destructive
    case .onDestructive: onDestructive
    case .background: background
    case .surface: surface
    case .surfaceElevated: surfaceElevated
    case .onSurface: onSurface
    case .onSurfaceSecondary: onSurfaceSecondary
    case .outline: outline
    case .scrim: scrim
    case .statusSuccess: statusSuccess
    case .statusWarning: statusWarning
    case .statusError: statusError
    case .statusInfo: statusInfo
    case .statusNeutral: statusNeutral
    }
  }

  /// Returns the status color aligned with ``FKWidgetStatusSemantic``.
  public func color(for semantic: FKWidgetStatusSemantic) -> FKThemeColor {
    switch semantic {
    case .success: statusSuccess
    case .warning: statusWarning
    case .error: statusError
    case .info: statusInfo
    case .neutral: statusNeutral
    }
  }
}
