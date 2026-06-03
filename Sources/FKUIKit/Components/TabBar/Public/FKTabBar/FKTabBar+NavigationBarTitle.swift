//
// FKTabBar+NavigationBarTitle.swift
//
// Sizing for ``FKTabBarHostingContext/navigationBarTitleView`` when hosted in ``UINavigationItem/titleView``.
//

import UIKit

extension FKTabBar {
  /// Resolves a non-zero fitting size for navigation-bar ``titleView`` hosting.
  ///
  /// UIKit may call ``sizeThatFits(_:)`` before the title slot has a width proposal; this path supplies
  /// a content-based fallback so the strip is not laid out at zero width.
  func navigationBarTitleSizeThatFits(_ size: CGSize) -> CGSize {
    let layout = resolvedLayoutForCurrentEnvironment()
    let presentation = resolvedTitlePresentationForCurrentEnvironment()
    let safeAreaAddition = layout.bottomSafeAreaBehavior == .extendBarHeight || layout.bottomSafeAreaBehavior == .bottomDocked
      ? safeAreaInsets.bottom
      : 0
    let height = FKTabBarLayoutMetrics.resolvedBarHeight(
      layout: layout,
      appearance: resolvedAppearance(),
      presentation: presentation,
      safeAreaBottomAddition: safeAreaAddition
    )
    let width = resolvedNavigationBarTitleWidth(proposedContainerWidth: size.width)
    let resolvedHeight = size.height > 1 ? min(size.height, height) : height
    return CGSize(width: width, height: resolvedHeight)
  }

  func resolvedNavigationBarTitleWidth(proposedContainerWidth: CGFloat) -> CGFloat {
    if proposedContainerWidth > 1 { return proposedContainerWidth }
    if bounds.width > 1 { return bounds.width }
    return estimatedNavigationBarTitleContentWidth()
  }

  private func estimatedNavigationBarTitleContentWidth() -> CGFloat {
    guard !visibleItems.isEmpty else { return 0 }
    let layout = resolvedLayoutForCurrentEnvironment()
    switch layout.widthMode {
    case .fillEqually:
      return max(160, CGFloat(visibleItems.count) * 72)
    case .intrinsic, .fixed, .constrained:
      let measurementBounds = CGRect(x: 0, y: 0, width: 10_000, height: max(32, bounds.height))
      let titlePresentation = resolvedTitlePresentation(layout: layout)
      var total = layout.contentInsets.leading + layout.contentInsets.trailing
      for index in visibleItems.indices {
        let itemSize = FKTabBarItemWidthStrategy.sizeForItem(
          item: visibleItems[index],
          index: index,
          visibleItemsCount: visibleItems.count,
          collectionBounds: measurementBounds,
          layout: layout,
          appearance: resolvedAppearance(),
          effectiveOverflowMode: titlePresentation.overflowMode,
          maximumTitleLines: titlePresentation.maximumTitleLines,
          shouldIncreaseHeightForLargeText: titlePresentation.shouldIncreaseHeightForLargeText,
          customization: customization,
          tabBar: self
        )
        total += itemSize.width
        if index < visibleItems.count - 1 {
          total += layout.itemSpacing
        }
      }
      return max(120, total)
    }
  }
}
