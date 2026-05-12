import UIKit

/// Shared model for a `CALayer` drop shadow: off (``none``) or explicit Core Animation parameters (``custom``).
public enum FKLayerShadowStyle: Equatable, Hashable {
  /// No visible shadow; applying clears `shadowPath` and related layer properties.
  case none
  /// Maps to `CALayer.shadowColor`, `shadowOpacity`, `shadowRadius`, and `shadowOffset`.
  case custom(color: UIColor, opacity: Float, radius: CGFloat, offset: CGSize)
}

extension CALayer {
  /// Applies ``FKLayerShadowStyle``; sets `shadowPath` to `path` when `path` is non-`nil`.
  func fk_applyShadow(_ style: FKLayerShadowStyle, path: CGPath?) {
    switch style {
    case .none:
      shadowColor = nil
      shadowOpacity = 0
      shadowRadius = 0
      shadowOffset = .zero
      shadowPath = nil
    case .custom(let color, let opacity, let radius, let offset):
      shadowColor = color.cgColor
      shadowOpacity = opacity
      shadowRadius = radius
      shadowOffset = offset
      shadowPath = path
    }
  }
}
