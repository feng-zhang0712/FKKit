import UIKit

@MainActor
enum FKCalloutAnimator {
  static func animateIn(
    view: UIView,
    style: FKCalloutAnimationStyle,
    duration: TimeInterval,
    completion: (() -> Void)?
  ) {
    let resolved = resolvedAnimation(style: style, duration: duration)
    view.alpha = 0
    switch resolved.style {
    case .fade:
      view.transform = .identity
    case .fadeScale:
      view.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
    }
    UIView.animate(
      withDuration: resolved.duration,
      delay: 0,
      usingSpringWithDamping: resolved.style == .fadeScale ? 0.92 : 1,
      initialSpringVelocity: 0.2,
      options: [.curveEaseOut, .allowUserInteraction]
    ) {
      view.alpha = 1
      view.transform = .identity
    } completion: { _ in
      completion?()
    }
  }

  static func animateOut(
    view: UIView,
    style: FKCalloutAnimationStyle,
    duration: TimeInterval,
    completion: (() -> Void)?
  ) {
    let resolved = resolvedAnimation(style: style, duration: duration)
    UIView.animate(
      withDuration: resolved.duration * 0.85,
      delay: 0,
      options: [.curveEaseIn, .beginFromCurrentState]
    ) {
      view.alpha = 0
      switch resolved.style {
      case .fade:
        break
      case .fadeScale:
        view.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
      }
    } completion: { _ in
      completion?()
    }
  }

  private static func resolvedAnimation(
    style: FKCalloutAnimationStyle,
    duration: TimeInterval
  ) -> (style: FKCalloutAnimationStyle, duration: TimeInterval) {
    guard UIAccessibility.isReduceMotionEnabled else {
      return (style, duration)
    }
    return (.fade, min(duration, 0.2))
  }
}
