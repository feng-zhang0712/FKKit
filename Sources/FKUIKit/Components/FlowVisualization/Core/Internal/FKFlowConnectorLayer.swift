import QuartzCore
import UIKit

final class FKFlowConnectorLayer: CALayer {
  private let trackLayer = CAShapeLayer()
  private var progressLayer: CAShapeLayer?

  override init() {
    super.init()
    addSublayer(trackLayer)
  }

  override init(layer: Any) {
    super.init(layer: layer)
    if let source = layer as? FKFlowConnectorLayer {
      progressLayer = source.progressLayer
    }
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    addSublayer(trackLayer)
  }

  func apply(style: FKFlowConnectorStyle, completed: Bool, partialProgress: CGFloat? = nil) {
    trackLayer.lineWidth = style.thickness
    trackLayer.fillColor = nil
    trackLayer.lineCap = style.capStyle

    if let dashPattern = style.dashPattern, !dashPattern.isEmpty {
      let pattern = dashPattern.map { NSNumber(value: Double($0)) }
      trackLayer.lineDashPattern = pattern
      if let progressLayer {
        progressLayer.lineDashPattern = pattern
      }
    } else {
      trackLayer.lineDashPattern = nil
      if let progressLayer {
        progressLayer.lineDashPattern = nil
      }
    }

    if let partialProgress {
      let clamped = min(max(partialProgress, 0), 1)
      let progress = ensureProgressLayer()
      progress.lineWidth = style.thickness
      progress.fillColor = nil
      progress.lineCap = style.capStyle
      trackLayer.strokeColor = style.upcomingColor.cgColor
      progress.strokeColor = style.completedColor.cgColor
      progress.isHidden = clamped <= 0
      trackLayer.isHidden = false
      return
    }

    removeProgressLayer()
    trackLayer.isHidden = false
    trackLayer.strokeColor = (completed ? style.completedColor : style.upcomingColor).cgColor
  }

  func updatePath(from start: CGPoint, to end: CGPoint, partialProgress: CGFloat? = nil, animated: Bool, duration: TimeInterval) {
    let path = UIBezierPath()
    path.move(to: start)
    path.addLine(to: end)

    if animated, duration > 0 {
      let animation = CABasicAnimation(keyPath: "path")
      animation.fromValue = trackLayer.path
      animation.toValue = path.cgPath
      animation.duration = duration
      trackLayer.add(animation, forKey: "path")
    }

    trackLayer.path = path.cgPath
    trackLayer.frame = bounds

    if let partialProgress, let progressLayer {
      let clamped = min(max(partialProgress, 0), 1)
      progressLayer.isHidden = clamped <= 0
      progressLayer.path = path.cgPath
      progressLayer.frame = bounds
      progressLayer.strokeStart = 0
      progressLayer.strokeEnd = clamped
    }
  }

  override func layoutSublayers() {
    super.layoutSublayers()
    trackLayer.frame = bounds
    if let progressLayer {
      progressLayer.frame = bounds
    }
  }

  func setHiddenFromAccessibility(_ hidden: Bool) {
    isAccessibilityElement = false
    accessibilityElementsHidden = hidden
    trackLayer.isAccessibilityElement = false
    if let progressLayer {
      progressLayer.isAccessibilityElement = false
    }
  }

  private func ensureProgressLayer() -> CAShapeLayer {
    if let progressLayer { return progressLayer }
    let layer = CAShapeLayer()
    addSublayer(layer)
    progressLayer = layer
    return layer
  }

  private func removeProgressLayer() {
    progressLayer?.removeFromSuperlayer()
    progressLayer = nil
  }
}
