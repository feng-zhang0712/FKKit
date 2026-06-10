import UIKit

/// Applies optional leading/trailing gradient masks for marquee fade edges.
@MainActor
enum FKMarqueeFadeMaskLayer {
  static func apply(fadeWidth: CGFloat, to view: UIView) {
    guard fadeWidth > 0 else {
      view.layer.mask = nil
      return
    }

    let bounds = view.bounds
    guard bounds.width > fadeWidth * 2 else {
      view.layer.mask = nil
      return
    }

    let fadePortion = fadeWidth / bounds.width
    let locations: [NSNumber] = [
      0,
      NSNumber(value: Double(fadePortion)),
      NSNumber(value: Double(1 - fadePortion)),
      1,
    ]

    let gradient: CAGradientLayer
    if let existing = view.layer.mask as? CAGradientLayer {
      gradient = existing
    } else {
      gradient = CAGradientLayer()
      gradient.startPoint = CGPoint(x: 0, y: 0.5)
      gradient.endPoint = CGPoint(x: 1, y: 0.5)
      gradient.colors = [
        UIColor.clear.cgColor,
        UIColor.black.cgColor,
        UIColor.black.cgColor,
        UIColor.clear.cgColor,
      ]
      view.layer.mask = gradient
    }

    gradient.frame = bounds
    gradient.locations = locations
  }
}
