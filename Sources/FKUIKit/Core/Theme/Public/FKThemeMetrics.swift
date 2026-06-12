import UIKit

/// Spacing, corner radii, and layout constants for a theme.
public struct FKThemeMetrics: Sendable, Equatable {
  public var spacingXXS: CGFloat
  public var spacingXS: CGFloat
  public var spacingS: CGFloat
  public var spacingM: CGFloat
  public var spacingL: CGFloat
  public var spacingXL: CGFloat
  public var radiusSmall: CGFloat
  public var radiusMedium: CGFloat
  public var radiusLarge: CGFloat
  public var radiusFull: CGFloat
  public var minimumHitTarget: CGFloat
  public var hairline: CGFloat

  /// Creates a metrics bundle.
  public init(
    spacingXXS: CGFloat = 4,
    spacingXS: CGFloat = 8,
    spacingS: CGFloat = 12,
    spacingM: CGFloat = 16,
    spacingL: CGFloat = 24,
    spacingXL: CGFloat = 32,
    radiusSmall: CGFloat = 8,
    radiusMedium: CGFloat = 12,
    radiusLarge: CGFloat = 16,
    radiusFull: CGFloat = 10_000,
    minimumHitTarget: CGFloat = 44,
    hairline: CGFloat = 1
  ) {
    self.spacingXXS = spacingXXS
    self.spacingXS = spacingXS
    self.spacingS = spacingS
    self.spacingM = spacingM
    self.spacingL = spacingL
    self.spacingXL = spacingXL
    self.radiusSmall = radiusSmall
    self.radiusMedium = radiusMedium
    self.radiusLarge = radiusLarge
    self.radiusFull = radiusFull
    self.minimumHitTarget = minimumHitTarget
    self.hairline = hairline
  }

  /// Returns a spacing token by semantic size name.
  public func spacing(_ token: FKThemeSpacingToken) -> CGFloat {
    switch token {
    case .xxs: spacingXXS
    case .xs: spacingXS
    case .s: spacingS
    case .m: spacingM
    case .l: spacingL
    case .xl: spacingXL
    }
  }
}

/// Named spacing tokens in ``FKThemeMetrics``.
public enum FKThemeSpacingToken: Sendable, Equatable {
  case xxs
  case xs
  case s
  case m
  case l
  case xl
}
