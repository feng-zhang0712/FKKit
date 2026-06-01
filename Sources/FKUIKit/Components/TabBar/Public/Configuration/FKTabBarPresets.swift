import UIKit

/// Factory presets for common ``FKTabBar`` integration scenarios.
///
/// Presets return a fully configured ``FKTabBarConfiguration``. Hosts may mutate the result
/// before assigning it to ``FKTabBar/configuration``.
@MainActor
public enum FKTabBarPresets {
  /// Scrollable pager header: intrinsic widths, ``FKTabBarSelectionScrollPosition/minimalVisible``,
  /// and a line indicator with ``FKTabBarIndicatorFollowMode/trackContentProgress``.
  public static func pagerHeader(indicatorThickness: CGFloat = 3) -> FKTabBarConfiguration {
    var config = FKTabBarConfiguration()
    config.layout.isScrollable = true
    config.layout.widthMode = .intrinsic
    config.layout.selectionScrollPosition = .minimalVisible
    config.appearance.indicatorStyle = .line(
      FKTabBarLineIndicatorConfiguration(
        thickness: indicatorThickness,
        followMode: .trackContentProgress
      )
    )
    config.animation.allowsProgressiveColorTransition = true
    return config
  }

  /// Bottom-docked bar surface: vertical item layout, safe-area height, blur background, top divider.
  public static func bottomDocked(showsIndicator: Bool = false) -> FKTabBarConfiguration {
    var config = FKTabBarConfiguration()
    config.layout.isScrollable = false
    config.layout.widthMode = .fillEqually
    config.layout.itemLayoutDirection = .vertical
    config.layout.minimumItemHeight = 48
    config.layout.preferredBarHeight = 56
    config.layout.bottomSafeAreaBehavior = .bottomDocked
    config.appearance.backgroundStyle = .systemBlur(.systemMaterial)
    config.appearance.showsDivider = true
    config.appearance.dividerPosition = .top
    config.appearance.shadow = .custom(color: .black, opacity: 0.12, radius: 10, offset: CGSize(width: 0, height: -2))
    if showsIndicator {
      config.appearance.indicatorStyle = .pill(FKTabBarBackgroundIndicatorConfiguration())
    } else {
      config.appearance.indicatorStyle = .none
    }
    return config
  }

  /// Segmented control: non-scrollable, equal-width items, pill backdrop indicator.
  public static func segmentedControl(itemSpacing: CGFloat = 0) -> FKTabBarConfiguration {
    var config = FKTabBarConfiguration()
    config.layout.isScrollable = false
    config.layout.widthMode = .fillEqually
    config.layout.itemSpacing = itemSpacing
    config.appearance.indicatorStyle = .pill(FKTabBarBackgroundIndicatorConfiguration())
    return config
  }

  /// Filter / dropdown anchor strip: scrollable intrinsic widths, extra trailing inset for accessories.
  public static func filterStrip() -> FKTabBarConfiguration {
    var config = FKTabBarConfiguration()
    config.layout.isScrollable = true
    config.layout.widthMode = .intrinsic
    config.layout.selectionScrollPosition = .minimalVisible
    config.layout.contentInsets = .init(top: 0, leading: 12, bottom: 0, trailing: 16)
    config.layout.scrollEdgeFade = FKTabBarScrollEdgeFade(isEnabled: true)
    config.appearance.indicatorStyle = .line(FKTabBarLineIndicatorConfiguration(followMode: .trackSelectedFrame))
    return config
  }
}
