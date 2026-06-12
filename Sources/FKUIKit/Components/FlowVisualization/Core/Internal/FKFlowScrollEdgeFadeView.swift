import UIKit

@MainActor
final class FKFlowScrollEdgeFadeView: UIView {
  private let leadingGradient = CAGradientLayer()
  private let trailingGradient = CAGradientLayer()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func update(scrollView: UIScrollView, isEnabled: Bool) {
    isHidden = !isEnabled
    guard isEnabled else { return }

    let fadeWidth = min(24, bounds.width * 0.12)
    leadingGradient.isHidden = scrollView.contentOffset.x <= 0
    trailingGradient.isHidden = scrollView.contentOffset.x >= scrollView.contentSize.width - scrollView.bounds.width - 1

    leadingGradient.frame = CGRect(x: 0, y: 0, width: fadeWidth, height: bounds.height)
    trailingGradient.frame = CGRect(x: bounds.width - fadeWidth, y: 0, width: fadeWidth, height: bounds.height)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    leadingGradient.frame.size.height = bounds.height
    trailingGradient.frame.size.height = bounds.height
    trailingGradient.frame.origin.x = bounds.width - trailingGradient.frame.width
  }

  private func commonInit() {
    isUserInteractionEnabled = false
    layer.addSublayer(leadingGradient)
    layer.addSublayer(trailingGradient)

    let background = UIColor.systemBackground.cgColor
    let clear = UIColor.systemBackground.withAlphaComponent(0).cgColor
    leadingGradient.colors = [background, clear]
    leadingGradient.startPoint = CGPoint(x: 0, y: 0.5)
    leadingGradient.endPoint = CGPoint(x: 1, y: 0.5)
    trailingGradient.colors = [clear, background]
    trailingGradient.startPoint = CGPoint(x: 0, y: 0.5)
    trailingGradient.endPoint = CGPoint(x: 1, y: 0.5)
    isHidden = true
  }
}
