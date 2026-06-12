import UIKit

/// Scan frame overlay with dimmed mask, corner brackets, and optional scan line animation.
final class FKQRCodeOverlayView: UIView {
  private let dimLayer = CAShapeLayer()
  private let cornersLayer = CAShapeLayer()
  private let scanLineLayer = CALayer()
  private var style = FKQRCodeOverlayStyle.default

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    backgroundColor = .clear

    dimLayer.fillRule = .evenOdd
    dimLayer.fillColor = UIColor.black.withAlphaComponent(0.45).cgColor
    layer.addSublayer(dimLayer)

    cornersLayer.fillColor = UIColor.clear.cgColor
    cornersLayer.strokeColor = UIColor.systemGreen.cgColor
    cornersLayer.lineCap = .round
    layer.addSublayer(cornersLayer)

    scanLineLayer.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.85).cgColor
    layer.addSublayer(scanLineLayer)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(style: FKQRCodeOverlayStyle) {
    self.style = style
    cornersLayer.lineWidth = style.cornerLineWidth
    setNeedsLayout()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    guard bounds.width > 0, bounds.height > 0 else { return }

    let side = min(bounds.width, bounds.height) * style.scanRegionRelativeSize
    let scanRect = CGRect(
      x: (bounds.width - side) / 2,
      y: (bounds.height - side) / 2,
      width: side,
      height: side
    )

    let path = UIBezierPath(rect: bounds)
    path.append(UIBezierPath(roundedRect: scanRect, cornerRadius: 8))
    dimLayer.path = path.cgPath

    cornersLayer.path = cornerPath(in: scanRect, length: style.cornerLength).cgPath

    scanLineLayer.frame = CGRect(
      x: scanRect.minX + 8,
      y: scanRect.minY + 8,
      width: scanRect.width - 16,
      height: 2
    )

    updateScanLineAnimation(in: scanRect)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    setNeedsLayout()
  }

  private func updateScanLineAnimation(in scanRect: CGRect) {
    scanLineLayer.removeAnimation(forKey: "scan")

    let reduceMotion = UIAccessibility.isReduceMotionEnabled
    let shouldAnimate = style.showsScanLineAnimation && !reduceMotion
    scanLineLayer.isHidden = !shouldAnimate
    guard shouldAnimate, scanRect.height > 0 else { return }

    let animation = CABasicAnimation(keyPath: "position.y")
    animation.fromValue = scanRect.minY + 12
    animation.toValue = scanRect.maxY - 12
    animation.duration = 2.0
    animation.autoreverses = true
    animation.repeatCount = .infinity
    animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    scanLineLayer.add(animation, forKey: "scan")
  }

  private func cornerPath(in rect: CGRect, length: CGFloat) -> UIBezierPath {
    let path = UIBezierPath()
    let inset = style.cornerLineWidth / 2

    // Top-left
    path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY + length))
    path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
    path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY + inset))

    // Top-right
    path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY + inset))
    path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + inset))
    path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + length))

    // Bottom-left
    path.move(to: CGPoint(x: rect.minX + inset, y: rect.maxY - length))
    path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY - inset))
    path.addLine(to: CGPoint(x: rect.minX + length, y: rect.maxY - inset))

    // Bottom-right
    path.move(to: CGPoint(x: rect.maxX - length, y: rect.maxY - inset))
    path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY - inset))
    path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY - length))

    return path
  }
}
