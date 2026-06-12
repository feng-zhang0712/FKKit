import UIKit

/// Elevation presets mapped to ``FKLayerShadowStyle``.
public struct FKThemeShadowTokens: Sendable, Equatable {
  public var elevationLow: FKLayerShadowStyle
  public var elevationMedium: FKLayerShadowStyle
  public var elevationHigh: FKLayerShadowStyle

  /// Creates shadow tokens.
  public init(
    elevationLow: FKLayerShadowStyle,
    elevationMedium: FKLayerShadowStyle,
    elevationHigh: FKLayerShadowStyle
  ) {
    self.elevationLow = elevationLow
    self.elevationMedium = elevationMedium
    self.elevationHigh = elevationHigh
  }
}
