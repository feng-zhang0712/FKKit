import CoreGraphics
import FKCoreKit
import Foundation
import UIKit

/// Chrome snapshot used as a scroll-transition endpoint (`from` / `to`).
///
/// Continuous fields are interpolated by ``FKNavigationBarScrollAppearance/interpolated(from:to:progress:)``.
/// ``statusBarStyle`` is discrete and flips at ``FKNavigationBarScrollConfiguration/discreteThreshold``.
public struct FKNavigationBarScrollAppearance: @unchecked Sendable, Equatable {
  /// Bar background color. Combined with ``backgroundAlpha`` when applied.
  public var backgroundColor: UIColor?

  /// Background opacity in `0...1`. Values near `0` configure a transparent bar background.
  public var backgroundAlpha: CGFloat

  /// Navigation title color before ``titleAlpha`` is applied.
  public var titleColor: UIColor?

  /// Multiplier applied to the title color’s alpha (`0...1`).
  public var titleAlpha: CGFloat

  /// Bar button / bar tint color.
  public var tintColor: UIColor?

  /// Hairline / shadow opacity (`0` hides the shadow).
  public var shadowAlpha: CGFloat

  /// Status-bar style at this endpoint. Applied discretely via progress threshold.
  public var statusBarStyle: UIStatusBarStyle?

  /// Creates an appearance snapshot.
  public init(
    backgroundColor: UIColor? = nil,
    backgroundAlpha: CGFloat = 1,
    titleColor: UIColor? = nil,
    titleAlpha: CGFloat = 1,
    tintColor: UIColor? = nil,
    shadowAlpha: CGFloat = 0,
    statusBarStyle: UIStatusBarStyle? = nil
  ) {
    self.backgroundColor = backgroundColor
    self.backgroundAlpha = min(max(backgroundAlpha, 0), 1)
    self.titleColor = titleColor
    self.titleAlpha = min(max(titleAlpha, 0), 1)
    self.tintColor = tintColor
    self.shadowAlpha = min(max(shadowAlpha, 0), 1)
    self.statusBarStyle = statusBarStyle
  }

  /// Transparent bar over hero content (light controls by default).
  public static func transparent(
    tint: UIColor = .white,
    titleColor: UIColor = .white,
    titleAlpha: CGFloat = 0,
    statusBarStyle: UIStatusBarStyle = .lightContent
  ) -> FKNavigationBarScrollAppearance {
    FKNavigationBarScrollAppearance(
      backgroundColor: .clear,
      backgroundAlpha: 0,
      titleColor: titleColor,
      titleAlpha: titleAlpha,
      tintColor: tint,
      shadowAlpha: 0,
      statusBarStyle: statusBarStyle
    )
  }

  /// Opaque solid bar endpoint.
  public static func solid(
    backgroundColor: UIColor,
    titleColor: UIColor = .label,
    tintColor: UIColor = .label,
    titleAlpha: CGFloat = 1,
    shadowAlpha: CGFloat = 1,
    statusBarStyle: UIStatusBarStyle = .darkContent
  ) -> FKNavigationBarScrollAppearance {
    FKNavigationBarScrollAppearance(
      backgroundColor: backgroundColor,
      backgroundAlpha: 1,
      titleColor: titleColor,
      titleAlpha: titleAlpha,
      tintColor: tintColor,
      shadowAlpha: shadowAlpha,
      statusBarStyle: statusBarStyle
    )
  }

  /// Linearly interpolates continuous fields. Status bar style is taken from `to` when
  /// `progress >= discreteThreshold`, otherwise from `from`.
  public static func interpolated(
    from: FKNavigationBarScrollAppearance,
    to: FKNavigationBarScrollAppearance,
    progress: CGFloat,
    discreteThreshold: CGFloat = 0.5
  ) -> FKNavigationBarScrollAppearance {
    let t = min(max(progress, 0), 1)
    let backgroundColor = FKNavigationBarScrollColorInterpolation.lerp(
      from.backgroundColor,
      to.backgroundColor,
      t: t
    )
    let titleColor = FKNavigationBarScrollColorInterpolation.lerp(
      from.titleColor,
      to.titleColor,
      t: t
    )
    let tintColor = FKNavigationBarScrollColorInterpolation.lerp(
      from.tintColor,
      to.tintColor,
      t: t
    )
    let statusBarStyle: UIStatusBarStyle?
    if t >= discreteThreshold {
      statusBarStyle = to.statusBarStyle ?? from.statusBarStyle
    } else {
      statusBarStyle = from.statusBarStyle ?? to.statusBarStyle
    }
    return FKNavigationBarScrollAppearance(
      backgroundColor: backgroundColor,
      backgroundAlpha: CGFloat.fk_lerp(from.backgroundAlpha, to.backgroundAlpha, t: t),
      titleColor: titleColor,
      titleAlpha: CGFloat.fk_lerp(from.titleAlpha, to.titleAlpha, t: t),
      tintColor: tintColor,
      shadowAlpha: CGFloat.fk_lerp(from.shadowAlpha, to.shadowAlpha, t: t),
      statusBarStyle: statusBarStyle
    )
  }
}
