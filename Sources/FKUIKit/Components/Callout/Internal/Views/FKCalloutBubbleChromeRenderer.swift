import UIKit

/// Renders bubble body, beak, border, shadow, and frosted chrome for ``FKCalloutBubbleView``.
@MainActor
final class FKCalloutBubbleChromeRenderer {
  private let shapeLayer = CAShapeLayer()
  private let beakLayer = CAShapeLayer()
  private let borderLayer = CAShapeLayer()
  private var frostedEffectView: UIVisualEffectView?
  private let frostedMaskLayer = CAShapeLayer()

  func install(on view: UIView, below contentContainer: UIView) {
    view.layer.insertSublayer(shapeLayer, below: contentContainer.layer)
    view.layer.insertSublayer(beakLayer, below: contentContainer.layer)
    view.layer.insertSublayer(borderLayer, below: contentContainer.layer)
    shapeLayer.fillColor = UIColor.white.cgColor
    beakLayer.fillColor = UIColor.white.cgColor
    borderLayer.fillColor = UIColor.clear.cgColor
  }

  func apply(
    on view: UIView,
    below contentContainer: UIView,
    bounds: CGRect,
    metrics: FKCalloutBeakGeometry.LayoutMetrics,
    configuration: FKCalloutConfiguration,
    content: FKCalloutContent,
    traitCollection: UITraitCollection,
    usesCustomBeak: Bool,
    headerFillColor: UIColor?
  ) {
    let bodyPath = FKCalloutBeakGeometry.bodyPath(bounds: bounds, metrics: metrics)
    let beakPath = usesCustomBeak ? UIBezierPath() : FKCalloutBeakGeometry.beakPath(bounds: bounds, metrics: metrics)
    let unified = FKCalloutBeakGeometry.unifiedBubblePath(bounds: bounds, metrics: metrics, includesBeak: !usesCustomBeak)
    shapeLayer.path = bodyPath.cgPath
    beakLayer.path = beakPath.cgPath
    borderLayer.path = unified
    shapeLayer.frame = bounds
    beakLayer.frame = bounds
    borderLayer.frame = bounds

    let usesFrosted = configuration.appearance.usesFrostedGlassBackground
    let fill = configuration.appearance.resolvedBackgroundColor(traitCollection: traitCollection)
    if usesFrosted {
      let effectView = frostedEffectView ?? {
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        effectView.isUserInteractionEnabled = false
        view.insertSubview(effectView, belowSubview: contentContainer)
        frostedEffectView = effectView
        return effectView
      }()
      effectView.frame = bounds
      frostedMaskLayer.path = unified
      frostedMaskLayer.frame = bounds
      effectView.layer.mask = frostedMaskLayer
      shapeLayer.fillColor = UIColor.clear.cgColor
      beakLayer.fillColor = UIColor.clear.cgColor
    } else {
      frostedEffectView?.removeFromSuperview()
      frostedEffectView = nil
      frostedMaskLayer.path = nil
      shapeLayer.fillColor = fill.cgColor
      beakLayer.fillColor = (headerFillColor ?? fill).cgColor
    }

    if let borderColor = configuration.appearance.borderColor, configuration.appearance.borderWidth > 0 {
      borderLayer.strokeColor = borderColor.cgColor
      borderLayer.lineWidth = configuration.appearance.borderWidth
      borderLayer.isHidden = false
    } else {
      borderLayer.isHidden = true
    }

    if configuration.appearance.showsShadow {
      view.layer.shadowColor = UIColor.black.cgColor
      view.layer.shadowOpacity = configuration.appearance.shadowOpacity
      view.layer.shadowRadius = configuration.appearance.shadowRadius
      view.layer.shadowOffset = configuration.appearance.shadowOffset
      view.layer.shadowPath = unified
    } else {
      view.layer.shadowOpacity = 0
      view.layer.shadowPath = nil
    }
  }

  func unifiedPath(
    bounds: CGRect,
    metrics: FKCalloutBeakGeometry.LayoutMetrics,
    includesBeak: Bool
  ) -> CGPath {
    FKCalloutBeakGeometry.unifiedBubblePath(bounds: bounds, metrics: metrics, includesBeak: includesBeak)
  }
}
