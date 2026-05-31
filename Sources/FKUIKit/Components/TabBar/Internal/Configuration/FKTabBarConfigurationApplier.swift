import UIKit

@MainActor
enum FKTabBarConfigurationApplier {
  struct ChangeDomains: OptionSet {
    let rawValue: Int

    static let appearanceColors = ChangeDomains(rawValue: 1 << 0)
    static let appearanceTypography = ChangeDomains(rawValue: 1 << 1)
    static let appearanceIndicator = ChangeDomains(rawValue: 1 << 2)
    static let appearanceBackground = ChangeDomains(rawValue: 1 << 3)
    static let layout = ChangeDomains(rawValue: 1 << 4)
    static let animation = ChangeDomains(rawValue: 1 << 5)
    static let scrollBehavior = ChangeDomains(rawValue: 1 << 6)

    static let appearanceTokens: ChangeDomains = [
      .appearanceColors,
      .appearanceTypography,
      .appearanceIndicator,
      .appearanceBackground,
    ]
  }

  static func domains(from old: FKTabBarConfiguration, to new: FKTabBarConfiguration) -> ChangeDomains {
    var domains: ChangeDomains = []
    if old.appearance.colors != new.appearance.colors { domains.insert(.appearanceColors) }
    if old.appearance.typography != new.appearance.typography { domains.insert(.appearanceTypography) }
    if old.appearance.subtitleConfiguration != new.appearance.subtitleConfiguration { domains.insert(.appearanceTypography) }
    if old.appearance.indicatorStyle != new.appearance.indicatorStyle {
      domains.insert(.appearanceIndicator)
    }
    if old.appearance.indicatorZOrder != new.appearance.indicatorZOrder { domains.insert(.appearanceIndicator) }
    if old.appearance.backgroundStyle != new.appearance.backgroundStyle { domains.insert(.appearanceBackground) }
    if old.appearance.showsDivider != new.appearance.showsDivider { domains.insert(.appearanceBackground) }
    if old.appearance.dividerPosition != new.appearance.dividerPosition { domains.insert(.appearanceBackground) }
    if old.appearance.shadow != new.appearance.shadow { domains.insert(.appearanceBackground) }
    if old.animation != new.animation { domains.insert(.animation) }
    if scrollBehaviorFieldsChanged(from: old.layout, to: new.layout) { domains.insert(.scrollBehavior) }
    if layoutFieldsChanged(from: old.layout, to: new.layout) { domains.insert(.layout) }
    return domains
  }

  private static func layoutFieldsChanged(
    from old: FKTabBarLayoutConfiguration,
    to new: FKTabBarLayoutConfiguration
  ) -> Bool {
    old.isScrollable != new.isScrollable
      || old.itemSpacing != new.itemSpacing
      || old.contentInsets != new.contentInsets
      || old.includesBottomSafeAreaInset != new.includesBottomSafeAreaInset
      || old.contentAlignment != new.contentAlignment
      || old.titleOverflowMode != new.titleOverflowMode
      || old.largeTextLayoutStrategy != new.largeTextLayoutStrategy
      || old.minimumItemHeight != new.minimumItemHeight
      || old.preferredBarHeight != new.preferredBarHeight
      || old.safeAreaHeightPolicy != new.safeAreaHeightPolicy
      || old.widthMode != new.widthMode
      || old.cellLayoutMargins != new.cellLayoutMargins
      || old.itemContentInsets != new.itemContentInsets
      || old.scrollEdgeFade != new.scrollEdgeFade
      || old.itemLayoutDirection != new.itemLayoutDirection
      || old.rtlBehavior != new.rtlBehavior
      || old.selectionScrollPosition != new.selectionScrollPosition
      || old.isSelectionScrollAnimationEnabled != new.isSelectionScrollAnimationEnabled
      || old.nonScrollableOverflowPolicy != new.nonScrollableOverflowPolicy
      || old.emptyStateMessage != new.emptyStateMessage
  }

  private static func scrollBehaviorFieldsChanged(
    from old: FKTabBarLayoutConfiguration,
    to new: FKTabBarLayoutConfiguration
  ) -> Bool {
    old.isScrollable != new.isScrollable
      || old.allowsHorizontalBounce != new.allowsHorizontalBounce
  }
}
