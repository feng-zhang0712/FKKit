#if canImport(UIKit)
import CoreGraphics
import UIKit

public extension UIView {
  /// Applies a shadow using the layer; does not alter corner radius.
  func fk_applyShadow(
    color: UIColor = .black,
    offset: CGSize = CGSize(width: 0, height: 2),
    radius: CGFloat = 4,
    opacity: Float = 0.15
  ) {
    layer.shadowColor = color.cgColor
    layer.shadowOffset = offset
    layer.shadowRadius = radius
    layer.shadowOpacity = opacity
    layer.masksToBounds = false
  }

  /// Inserts a gradient layer sized to the current bounds (does not auto-resize on layout).
  @discardableResult
  func fk_addGradient(
    colors: [UIColor],
    startPoint: CGPoint = CGPoint(x: 0, y: 0),
    endPoint: CGPoint = CGPoint(x: 1, y: 1)
  ) -> CAGradientLayer {
    let gradient = CAGradientLayer()
    gradient.colors = colors.map(\.cgColor)
    gradient.startPoint = startPoint
    gradient.endPoint = endPoint
    gradient.frame = bounds
    layer.insertSublayer(gradient, at: 0)
    return gradient
  }
}

#endif
