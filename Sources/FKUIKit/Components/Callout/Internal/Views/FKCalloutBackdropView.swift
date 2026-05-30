import UIKit

/// Dimmed full-screen layer with an optional rounded spotlight cutout.
final class FKCalloutBackdropView: UIView {
  private let dimLayer = CAShapeLayer()

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    backgroundColor = .clear
    layer.addSublayer(dimLayer)
    dimLayer.fillRule = .evenOdd
    isHidden = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  func update(style: FKCalloutBackdropStyle, spotlightRectInBounds: CGRect?) {
    isHidden = !style.showsDimmedBackdrop
    guard style.showsDimmedBackdrop, bounds.width > 0, bounds.height > 0 else {
      dimLayer.path = nil
      return
    }

    let path = UIBezierPath(rect: bounds)
    if style.spotlightsAnchor, let spotlightRectInBounds, !spotlightRectInBounds.isNull, spotlightRectInBounds.width > 0 {
      let inset = spotlightRectInBounds.insetBy(dx: -4, dy: -4)
      let radius = min(style.spotlightCornerRadius, min(inset.width, inset.height) * 0.5)
      path.append(UIBezierPath(roundedRect: inset, cornerRadius: radius))
    }
    dimLayer.path = path.cgPath
    dimLayer.fillColor = resolvedDimColor(style).cgColor
    dimLayer.frame = bounds
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    dimLayer.frame = bounds
  }

  private func resolvedDimColor(_ style: FKCalloutBackdropStyle) -> UIColor {
    style.dimColor ?? UIColor.black.withAlphaComponent(0.45)
  }
}
