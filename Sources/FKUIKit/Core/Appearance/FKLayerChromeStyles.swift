import UIKit

// MARK: - Shadow

/// Shared model for a `CALayer` drop shadow: off (``none``) or explicit Core Animation parameters (``custom``).
public enum FKLayerShadowStyle: Equatable, Hashable {
  /// No visible shadow; applying clears `shadowPath` and related layer properties.
  case none
  /// Maps to `CALayer.shadowColor`, `shadowOpacity`, `shadowRadius`, and `shadowOffset`.
  case custom(color: UIColor, opacity: Float, radius: CGFloat, offset: CGSize)

  /// Default shadow used by ``FKPresentationConfiguration`` for sheet-style presentations.
  public static var presentationDefault: FKLayerShadowStyle {
    .custom(color: .black, opacity: 0.18, radius: 16, offset: CGSize(width: 0, height: 8))
  }

  /// Values that produce a visible shadow, or `nil` when the style should be treated as off.
  public var resolvedParameters: (color: UIColor, opacity: Float, radius: CGFloat, offset: CGSize)? {
    switch self {
    case .none:
      return nil
    case .custom(let color, let opacity, let radius, let offset):
      guard opacity > 0, radius > 0 else { return nil }
      return (color, opacity, radius, offset)
    }
  }
}

// MARK: - Border

/// Shared model for a `CALayer` stroke drawn via `borderWidth` / `borderColor`.
public enum FKLayerBorderStyle: Equatable, Hashable {
  case none
  case custom(color: UIColor, width: CGFloat)

  public var resolvedParameters: (color: UIColor, width: CGFloat)? {
    switch self {
    case .none:
      return nil
    case .custom(let color, let width):
      guard width > 0 else { return nil }
      return (color, width)
    }
  }
}

// MARK: - CALayer

extension CALayer {
  /// Applies ``FKLayerShadowStyle``; when `path` is non-`nil` and the style resolves to visible shadow, sets `shadowPath`.
  func fk_applyShadow(_ style: FKLayerShadowStyle, path: CGPath?) {
    guard let p = style.resolvedParameters else {
      shadowColor = nil
      shadowOpacity = 0
      shadowRadius = 0
      shadowOffset = .zero
      shadowPath = nil
      return
    }
    shadowColor = p.color.cgColor
    shadowOpacity = p.opacity
    shadowRadius = p.radius
    shadowOffset = p.offset
    shadowPath = path
  }

  func fk_applyBorder(_ style: FKLayerBorderStyle) {
    guard let b = style.resolvedParameters else {
      borderWidth = 0
      borderColor = nil
      return
    }
    borderColor = b.color.cgColor
    borderWidth = b.width
  }
}
