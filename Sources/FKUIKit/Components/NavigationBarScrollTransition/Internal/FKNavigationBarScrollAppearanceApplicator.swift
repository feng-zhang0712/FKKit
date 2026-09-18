import FKCoreKit
import UIKit

/// Builds and applies ``UINavigationBarAppearance`` values from a scroll-transition snapshot.
@MainActor
enum FKNavigationBarScrollAppearanceApplicator {
  private static let transparentEpsilon: CGFloat = 0.01

  static func makeBarAppearance(
    from appearance: FKNavigationBarScrollAppearance
  ) -> UINavigationBarAppearance {
    let bar = UINavigationBarAppearance()
    let baseColor = appearance.backgroundColor ?? .systemBackground

    if appearance.backgroundAlpha <= transparentEpsilon {
      // Fully clear — no system material / blur / Liquid Glass fill.
      bar.configureWithTransparentBackground()
      bar.backgroundEffect = nil
      bar.backgroundColor = .clear
    } else if appearance.backgroundAlpha >= 1 - transparentEpsilon {
      // Fully opaque solid fill — avoid default blur material.
      bar.configureWithOpaqueBackground()
      bar.backgroundEffect = nil
      bar.backgroundColor = baseColor
    } else {
      // Mid-transition: flat color with alpha, still no blur material.
      bar.configureWithTransparentBackground()
      bar.backgroundEffect = nil
      bar.backgroundColor = baseColor.withAlphaComponent(appearance.backgroundAlpha)
    }

    if let titleColor = appearance.titleColor {
      let alpha = titleColor.fk_rgbaComponents?.alpha ?? 1
      let resolved = titleColor.withAlphaComponent(alpha * appearance.titleAlpha)
      bar.titleTextAttributes = [.foregroundColor: resolved]
      bar.largeTitleTextAttributes = [.foregroundColor: resolved]
    }

    if appearance.shadowAlpha <= transparentEpsilon {
      bar.shadowColor = .clear
      bar.shadowImage = UIImage()
    } else {
      bar.shadowColor = UIColor.separator.withAlphaComponent(appearance.shadowAlpha)
    }

    return bar
  }

  static func apply(
    appearance: FKNavigationBarScrollAppearance,
    to navigationItem: UINavigationItem
  ) {
    let barAppearance = makeBarAppearance(from: appearance)
    navigationItem.standardAppearance = barAppearance
    navigationItem.scrollEdgeAppearance = barAppearance
    navigationItem.compactAppearance = barAppearance
    navigationItem.compactScrollEdgeAppearance = barAppearance
  }

  static func apply(
    appearance: FKNavigationBarScrollAppearance,
    to navigationBar: UINavigationBar
  ) {
    let barAppearance = makeBarAppearance(from: appearance)
    navigationBar.standardAppearance = barAppearance
    navigationBar.scrollEdgeAppearance = barAppearance
    navigationBar.compactAppearance = barAppearance
    navigationBar.compactScrollEdgeAppearance = barAppearance
    applyBarChrome(appearance: appearance, to: navigationBar)
  }

  /// Writes the resolved snapshot onto the shared bar (appearances, tint, translucency).
  static func applySharedNavigationBar(
    appearance: FKNavigationBarScrollAppearance,
    navigationBar: UINavigationBar?
  ) {
    guard let navigationBar else { return }
    apply(appearance: appearance, to: navigationBar)
  }

  /// Hides the system scroll-edge glass that otherwise paints a frosted band under the nav bar.
  static func suppressSystemScrollEdgeEffect(on scrollView: UIScrollView?) {
    guard let scrollView else { return }
    if #available(iOS 26.0, *) {
      scrollView.topEdgeEffect.isHidden = true
    }
  }

  /// Updates bar-level chrome that `UINavigationBarAppearance` alone cannot express.
  ///
  /// `isTranslucent` must be `true` for content to show through a clear / translucent bar;
  /// hosts that force `isTranslucent = false` (opaque Settings-style bars) otherwise keep a
  /// solid or material backdrop even when item appearances request transparency.
  private static func applyBarChrome(
    appearance: FKNavigationBarScrollAppearance,
    to navigationBar: UINavigationBar
  ) {
    let needsUnderlap = appearance.backgroundAlpha < 1 - transparentEpsilon
    navigationBar.isTranslucent = needsUnderlap
    if let tintColor = appearance.tintColor {
      navigationBar.tintColor = tintColor
    }
  }
}
