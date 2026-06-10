import UIKit

/// Gradient story ring drawn outside avatar bounds.
final class FKAvatarStoryRingLayer: CALayer {
  private let gradientLayer = CAGradientLayer()
  private let maskLayer = CAShapeLayer()

  var ringWidth: CGFloat = 2.5 {
    didSet { setNeedsLayout() }
  }

  var ringPadding: CGFloat = 2 {
    didSet { setNeedsLayout() }
  }

  var gradientColors: [UIColor] = [.systemPink, .systemOrange, .systemPurple] {
    didSet { updateColors() }
  }

  override init() {
    super.init()
    gradientLayer.type = .conic
    gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
    gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
    gradientLayer.mask = maskLayer
    addSublayer(gradientLayer)
    updateColors()
  }

  override init(layer: Any) {
    super.init(layer: layer)
    if let source = layer as? FKAvatarStoryRingLayer {
      ringWidth = source.ringWidth
      ringPadding = source.ringPadding
      gradientColors = source.gradientColors
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  override func layoutSublayers() {
    super.layoutSublayers()
    gradientLayer.frame = bounds
    maskLayer.frame = bounds

    let outer = min(bounds.width, bounds.height) / 2
    let inner = max(0, outer - ringWidth)
    let center = CGPoint(x: bounds.midX, y: bounds.midY)

    let outerPath = UIBezierPath(
      arcCenter: center,
      radius: outer,
      startAngle: 0,
      endAngle: .pi * 2,
      clockwise: true
    )
    let innerPath = UIBezierPath(
      arcCenter: center,
      radius: inner,
      startAngle: 0,
      endAngle: .pi * 2,
      clockwise: true
    )
    outerPath.append(innerPath.reversing())
    maskLayer.path = outerPath.cgPath
    maskLayer.fillRule = .evenOdd
  }

  private func updateColors() {
    gradientLayer.colors = gradientColors.map(\.cgColor)
  }
}
