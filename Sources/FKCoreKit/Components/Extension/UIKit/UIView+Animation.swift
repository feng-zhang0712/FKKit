#if canImport(UIKit)
import UIKit

public extension UIView {
  /// Performs a horizontal shake animation.
  ///
  /// - Parameters:
  ///   - amplitude: Translation amplitude in points.
  ///   - shakes: Number of back-and-forth shakes.
  ///   - duration: Total animation duration.
  ///
  /// Intended for validation feedback (for example invalid input).
  @MainActor
  func fk_shake(
    amplitude: CGFloat = 10,
    shakes: Int = 4,
    duration: TimeInterval = 0.35
  ) {
    guard amplitude > 0, shakes > 0, duration > 0 else { return }
    let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
    animation.timingFunction = CAMediaTimingFunction(name: .linear)
    animation.duration = duration

    let steps = shakes * 2 + 1
    var values: [CGFloat] = []
    values.reserveCapacity(steps)
    values.append(0)
    for i in 0..<(steps - 1) {
      let direction: CGFloat = (i % 2 == 0) ? 1 : -1
      let decay = max(0.4, 1.0 - (CGFloat(i) / CGFloat(max(1, steps - 1))))
      values.append(direction * amplitude * decay)
    }
    animation.values = values
    layer.add(animation, forKey: "fk.view.shake")
  }
}

#endif
