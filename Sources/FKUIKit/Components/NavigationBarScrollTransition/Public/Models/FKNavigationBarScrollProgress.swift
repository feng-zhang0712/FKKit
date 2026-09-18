import CoreGraphics
import Foundation
import UIKit

/// Snapshot of scroll-driven navigation-bar transition progress.
public struct FKNavigationBarScrollProgress: Sendable, Equatable {
  /// Normalized progress in `0...1` between ``FKNavigationBarScrollConfiguration/startOffset`` and
  /// ``FKNavigationBarScrollConfiguration/endOffset``.
  public var value: CGFloat

  /// Creates a progress snapshot. `value` is clamped to `0...1`.
  public init(value: CGFloat) {
    self.value = min(max(value, 0), 1)
  }

  /// Progress at the start of the transition (`value == 0`).
  public static let start = FKNavigationBarScrollProgress(value: 0)

  /// Progress at the end of the transition (`value == 1`).
  public static let end = FKNavigationBarScrollProgress(value: 1)

  /// Resolves a discrete status-bar style using `threshold` (typically
  /// ``FKNavigationBarScrollConfiguration/discreteThreshold``).
  public func resolvedStatusBarStyle(
    from: FKNavigationBarScrollAppearance,
    to: FKNavigationBarScrollAppearance,
    threshold: CGFloat
  ) -> UIStatusBarStyle {
    let style = value >= threshold ? to.statusBarStyle : from.statusBarStyle
    return style ?? .default
  }
}
