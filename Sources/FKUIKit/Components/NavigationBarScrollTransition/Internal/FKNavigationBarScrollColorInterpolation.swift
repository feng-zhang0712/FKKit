import CoreGraphics
import FKCoreKit
import UIKit

/// RGBA linear interpolation helpers for navigation-bar chrome.
enum FKNavigationBarScrollColorInterpolation {
  /// Interpolates two optional colors. Missing sides fall back to the other; unresolved dynamic
  /// colors fall back to an end-stop pick (no hue-space conversion).
  static func lerp(_ from: UIColor?, _ to: UIColor?, t: CGFloat) -> UIColor? {
    let clamped = min(max(t, 0), 1)
    switch (from, to) {
    case (nil, nil):
      return nil
    case (let from?, nil):
      return from
    case (nil, let to?):
      return to
    case (let from?, let to?):
      guard let a = resolvedRGBA(from), let b = resolvedRGBA(to) else {
        return clamped < 0.5 ? from : to
      }
      return UIColor(
        red: CGFloat.fk_lerp(a.red, b.red, t: clamped),
        green: CGFloat.fk_lerp(a.green, b.green, t: clamped),
        blue: CGFloat.fk_lerp(a.blue, b.blue, t: clamped),
        alpha: CGFloat.fk_lerp(a.alpha, b.alpha, t: clamped)
      )
    }
  }

  private static func resolvedRGBA(
    _ color: UIColor
  ) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
    if let components = color.fk_rgbaComponents {
      return components
    }
    // Resolve dynamic provider colors against the current trait collection.
    let resolved = color.resolvedColor(with: .current)
    return resolved.fk_rgbaComponents
  }
}
