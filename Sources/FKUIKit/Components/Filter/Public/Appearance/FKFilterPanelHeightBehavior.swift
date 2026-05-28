import UIKit

public enum FKFilterPanelHeightBehavior: Sendable {
  /// Use content height, floored by `minimum`, optionally floored by a fraction of the main screen height, and optionally capped by `maximumScreenFraction` of the screen (content scrolls inside the panel beyond that).
  case automatic(
    minimum: CGFloat = 80,
    screenMinimumFraction: CGFloat? = nil,
    maximumScreenFraction: CGFloat? = nil
  )
  /// Use content height but cap it to `maximum` and keep at least `minimum`.
  case capped(maximum: CGFloat, minimum: CGFloat = 80)
  /// Always use a fixed height.
  case fixed(CGFloat)
  /// Use a fraction of screen height. You may still clamp via min/max.
  case screenFraction(CGFloat, minimum: CGFloat = 80, maximum: CGFloat? = nil)

  func resolvedHeight(for estimatedContentHeight: CGFloat) -> CGFloat {
    switch self {
    case let .automatic(minimum, screenMinimumFraction, maximumScreenFraction):
      let screenHeight = UIScreen.main.bounds.height
      var result = max(estimatedContentHeight, minimum)
      if let fraction = screenMinimumFraction {
        let clamped = max(0, min(fraction, 1))
        result = max(result, screenHeight * clamped)
      }
      if let maxFraction = maximumScreenFraction {
        let clampedMax = max(0.1, min(maxFraction, 1))
        result = min(result, screenHeight * clampedMax)
      }
      return max(result, 1)
    case let .capped(maximum, minimum):
      return max(min(estimatedContentHeight, maximum), minimum)
    case let .fixed(height):
      return max(height, 1)
    case let .screenFraction(fraction, minimum, maximum):
      let normalized = max(0.1, min(fraction, 1.0))
      let screenBased = UIScreen.main.bounds.height * normalized
      let withMin = max(screenBased, minimum)
      if let maximum {
        return min(withMin, maximum)
      }
      return withMin
    }
  }
}

