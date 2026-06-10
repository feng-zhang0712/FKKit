import FKCoreKit
import UIKit

/// Applies shape, border, and corner radius to avatar subviews.
enum FKAvatarContentRenderer {
  static func resolvedCornerRadius(shape: FKAvatarShape, diameter: CGFloat) -> CGFloat {
    switch shape {
    case .circle:
      diameter / 2
    case .squircle(let cornerRadius):
      min(cornerRadius, diameter / 2)
    case .roundedRectangle(let cornerRadius):
      min(cornerRadius, diameter / 2)
    }
  }

  static func applyShape(
    to view: UIView,
    shape: FKAvatarShape,
    diameter: CGFloat
  ) {
    let radius = resolvedCornerRadius(shape: shape, diameter: diameter)
    view.layer.cornerRadius = radius
    switch shape {
    case .squircle:
      view.layer.cornerCurve = .continuous
    case .circle, .roundedRectangle:
      view.layer.cornerCurve = .circular
    }
    view.clipsToBounds = true
  }

  static func imageViewCornerStyle(shape: FKAvatarShape, diameter: CGFloat) -> FKImageViewCornerStyle {
    switch shape {
    case .circle:
      .capsule
    case .squircle(let cornerRadius), .roundedRectangle(let cornerRadius):
      .fixed(min(cornerRadius, diameter / 2))
    }
  }

  static func initialsFont(base: UIFont, diameter: CGFloat) -> UIFont {
    FKAvatarInitialsGenerator.scaledFont(base: base, avatarDiameter: diameter)
  }

  static func placeholderImage(
    symbolName: String,
    diameter: CGFloat
  ) -> UIImage? {
    let config = UIImage.SymbolConfiguration(pointSize: diameter * 0.45, weight: .regular)
    return UIImage(systemName: symbolName, withConfiguration: config)?
      .withRenderingMode(.alwaysTemplate)
  }

  static func verifiedBadgeImage(
    symbolName: String,
    diameter: CGFloat
  ) -> UIImage? {
    let config = UIImage.SymbolConfiguration(pointSize: diameter * 0.28, weight: .semibold)
    return UIImage(systemName: symbolName, withConfiguration: config)?
      .withRenderingMode(.alwaysTemplate)
  }
}
