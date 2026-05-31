import UIKit

@MainActor
final class FKTabBarScrollEdgeFadeOverlay: UIView {
  private let leadingGradient = CAGradientLayer()
  private let trailingGradient = CAGradientLayer()
  private var fadeWidth: CGFloat = 20

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    leadingGradient.startPoint = CGPoint(x: 0, y: 0.5)
    leadingGradient.endPoint = CGPoint(x: 1, y: 0.5)
    trailingGradient.startPoint = CGPoint(x: 1, y: 0.5)
    trailingGradient.endPoint = CGPoint(x: 0, y: 0.5)
    layer.addSublayer(leadingGradient)
    layer.addSublayer(trailingGradient)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let width = min(fadeWidth, bounds.width * 0.5)
    leadingGradient.frame = CGRect(x: 0, y: 0, width: width, height: bounds.height)
    trailingGradient.frame = CGRect(x: bounds.width - width, y: 0, width: width, height: bounds.height)
  }

  func configure(fadeColor: UIColor, fadeWidth: CGFloat) {
    self.fadeWidth = max(0, fadeWidth)
    let transparent = fadeColor.withAlphaComponent(0).cgColor
    let opaque = fadeColor.cgColor
    leadingGradient.colors = [opaque, transparent]
    trailingGradient.colors = [opaque, transparent]
    setNeedsLayout()
  }

  func update(leadingOpacity: CGFloat, trailingOpacity: CGFloat) {
    leadingGradient.opacity = Float(max(0, min(1, leadingOpacity)))
    trailingGradient.opacity = Float(max(0, min(1, trailingOpacity)))
    isHidden = leadingGradient.opacity == 0 && trailingGradient.opacity == 0
  }
}
