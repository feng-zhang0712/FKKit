//
// FKTabBar+Configuration.swift
//
// Configuration resolution, appearance application, and layout-behavior sync.
//

import UIKit

extension FKTabBar {
  // MARK: - Configuration / Appearance

  func resolvedAppearance() -> FKTabBarAppearance { configuration.appearance }
  func resolvedLayout() -> FKTabBarLayoutConfiguration { configuration.layout }
  func resolvedAnimation() -> FKTabBarAnimationConfiguration { configuration.animation }

  func resolvedLayoutForCurrentEnvironment() -> FKTabBarLayoutConfiguration {
    var layout = resolvedLayout()
    if layout.bottomSafeAreaBehavior == .padContent || layout.bottomSafeAreaBehavior == .bottomDocked {
      // We treat safe-area as additional bottom padding so content remains visible above the home indicator.
      // This impacts size measurement, section insets, and scroll alignment.
      layout.contentInsets.bottom += safeAreaInsets.bottom
    }
    return layout
  }

  func syncCustomizationHooks() {
    indicator.customViewProvider = { [weak customization] id in
      customization?.customIndicatorView(id: id)
    }
    indicator.customRenderer = { [weak customization] id, bounds, container in
      customization?.renderCustomIndicator(id: id, bounds: bounds, container: container)
    }
  }

  func applyBackgroundAppearance() {
    let ap = resolvedAppearance()
    let layout = resolvedLayout()
    let navigationBarChrome = layout.hostingContext == .navigationBarTitleView

    if navigationBarChrome {
      backgroundHost.backgroundColor = .clear
      backgroundHost.subviews.filter { $0 is UIVisualEffectView }.forEach { $0.removeFromSuperview() }
    } else {
      switch ap.backgroundStyle {
      case .solid(let color):
        backgroundHost.backgroundColor = color
        backgroundHost.subviews.filter { $0 is UIVisualEffectView }.forEach { $0.removeFromSuperview() }
      case .systemBlur(let style):
        backgroundHost.backgroundColor = .clear
        backgroundHost.subviews.filter { $0 is UIVisualEffectView }.forEach { $0.removeFromSuperview() }
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: style))
        blur.frame = backgroundHost.bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundHost.insertSubview(blur, at: 0)
      }
    }

    divider.isHidden = navigationBarChrome || !ap.showsDivider
    divider.backgroundColor = ap.colors.divider
    backgroundHost.layer.masksToBounds = false
    let shadowPath = UIBezierPath(rect: backgroundHost.bounds).cgPath
    if navigationBarChrome {
      backgroundHost.layer.fk_applyShadow(.none, path: nil)
    } else {
      backgroundHost.layer.fk_applyShadow(ap.shadow, path: shadowPath)
    }
    updateScrollEdgeFadeAppearance()
    setNeedsLayout()
  }

  func applyIndicatorAppearance() {
    let ap = resolvedAppearance()
    indicator.applyAppearance(style: ap.indicatorStyle, color: ap.colors.indicator)
    updateIndicatorZOrder(for: ap.indicatorStyle)
    updateIndicatorFrame(animated: false)
  }

  func updateScrollEdgeFadeAppearance() {
    let layout = resolvedLayout()
    let fade = layout.scrollEdgeFade
    let fadeEnabled = fade.isEnabled || (layout.hostingContext == .navigationBarTitleView && layout.isScrollable)
    guard layout.isScrollable, fadeEnabled else {
      scrollEdgeFadeOverlay.isHidden = true
      return
    }
    scrollEdgeFadeOverlay.isHidden = false
    let fadeColor: UIColor
    if layout.hostingContext == .navigationBarTitleView {
      fadeColor = .systemBackground
    } else {
      switch resolvedAppearance().backgroundStyle {
      case .solid(let color):
        fadeColor = color
      case .systemBlur:
        fadeColor = backgroundHost.backgroundColor ?? .systemBackground
      }
    }
    scrollEdgeFadeOverlay.configure(fadeColor: fadeColor, fadeWidth: fade.width)
    scrollEdgeFadeOverlay.frame = backgroundHost.bounds
    scrollEdgeFadeOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    backgroundHost.bringSubviewToFront(collectionView)
    backgroundHost.bringSubviewToFront(scrollEdgeFadeOverlay)
    updateScrollEdgeFadeOpacity()
  }

  func updateScrollEdgeFadeOpacity() {
    let layout = resolvedLayout()
    let fadeEnabled = layout.scrollEdgeFade.isEnabled || (layout.hostingContext == .navigationBarTitleView && layout.isScrollable)
    guard layout.isScrollable, fadeEnabled else { return }
    let offsetX = collectionView.contentOffset.x
    let minOffset = -collectionView.contentInset.left
    let maxOffset = max(
      minOffset,
      collectionView.contentSize.width - collectionView.bounds.width + collectionView.contentInset.right
    )
    let fadeWidth = max(1, layout.scrollEdgeFade.width)
    let leading = min(1, max(0, (offsetX - minOffset) / fadeWidth))
    let trailing = min(1, max(0, (maxOffset - offsetX) / fadeWidth))
    scrollEdgeFadeOverlay.update(leadingOpacity: leading, trailingOpacity: trailing)
  }

  func applyLayoutScrollBehavior() {
    let layout = resolvedLayout()
    collectionView.isScrollEnabled = layout.isScrollable
    let allowsBounce = layout.isScrollable && layout.allowsHorizontalBounce
    collectionView.alwaysBounceHorizontal = allowsBounce
    collectionView.bounces = allowsBounce
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.clipsToBounds = !layout.isScrollable && layout.nonScrollableOverflowPolicy == .clip
    if !layout.isScrollable {
      let minOffsetX = -collectionView.contentInset.left
      if collectionView.contentOffset.x != minOffsetX {
        collectionView.contentOffset.x = minOffsetX
      }
    }
    updateScrollEdgeFadeAppearance()
  }

  func updateEmptyStatePresentation() {
    let message = resolvedLayout().emptyStateMessage?.trimmingCharacters(in: .whitespacesAndNewlines)
    let showsPlaceholder = visibleItems.isEmpty && !(message?.isEmpty ?? true)
    emptyStateLabel.text = message
    emptyStateLabel.isHidden = !showsPlaceholder
    collectionView.isHidden = visibleItems.isEmpty
    indicator.isHidden = visibleItems.isEmpty
    if visibleItems.isEmpty {
      scrollEdgeFadeOverlay.isHidden = true
    } else {
      updateScrollEdgeFadeAppearance()
    }
    if showsPlaceholder {
      backgroundHost.bringSubviewToFront(emptyStateLabel)
    }
  }

  func applyConfigurationDomains(
    _ domains: FKTabBarConfigurationApplier.ChangeDomains,
    animated: Bool
  ) {
    if domains.contains(.appearanceBackground) {
      applyBackgroundAppearance()
    }
    if domains.contains(.appearanceIndicator) {
      applyIndicatorAppearance()
    }
    if !domains.isDisjoint(with: FKTabBarConfigurationApplier.ChangeDomains.appearanceContentRefresh) {
      refreshVisibleCellsForCurrentState()
      if domains.contains(.appearanceTypography) {
        invalidateIntrinsicContentSize()
        invalidateItemSizeCache()
      }
      if !domains.contains(.appearanceIndicator) {
        updateIndicatorFrame(animated: animated)
      }
    }
    if domains.contains(.scrollBehavior) {
      applyLayoutScrollBehavior()
    }
    if domains.contains(.layout) {
      applySemanticDirection()
      applyLayoutScrollBehavior()
      if resolvedLayout().hostingContext == .navigationBarTitleView {
        applyBackgroundAppearance()
      }
      updateEmptyStatePresentation()
      invalidateItemSizeCache()
      syncFlowLayoutSpacingProvider()
      // Width mode / scrollability changes can leave stale flow-layout geometry (scrollable intrinsic → fillEqually).
      collectionView.reloadData()
      invalidateLayoutAndRelayout(animatedScroll: animated && resolvedLayout().isSelectionScrollAnimationEnabled)
      refreshVisibleCellsForCurrentState()
      updateIndicatorFrame(animated: animated)
      updateScrollEdgeFadeAppearance()
    }
    if domains.contains(.animation) {
      refreshVisibleCellsForCurrentState()
    }
  }

  func scrollSelectedIntoView(animated: Bool) {
    guard visibleItems.indices.contains(selectedIndex) else { return }
    guard let attrs = collectionView.layoutAttributesForItem(at: IndexPath(item: selectedIndex, section: 0)) else { return }
    let layout = resolvedLayoutForCurrentEnvironment()
    let targetOffset = FKTabBarScrollAlignmentStrategy.targetOffset(
      itemFrame: attrs.frame,
      layout: layout,
      scrollView: collectionView
    )
    let shouldAnimate = animated && layout.isSelectionScrollAnimationEnabled
    // Prefer UIScrollView's own offset animation. Wrapping contentOffset in UIView.animate can
    // interact poorly with concurrent reload/layout updates and cause unexpected cell appearances.
    collectionView.setContentOffset(targetOffset, animated: shouldAnimate)
  }

  func modelForCell(at index: Int, selectionProgress: CGFloat) -> FKTabBarItemCell.Model {
    let layout = resolvedLayout()
    let titlePresentation = resolvedTitlePresentation(layout: layout)
    let item = visibleItems[index]
    return FKTabBarItemCell.Model(
      item: item,
      isSelected: index == selectedIndex,
      appearance: resolvedAppearance(),
      animation: resolvedAnimation(),
      overflowMode: titlePresentation.overflowMode,
      selectionProgress: resolvedAnimation().allowsProgressiveColorTransition ? selectionProgress : (index == selectedIndex ? 1 : 0),
      layoutDirection: layout.itemLayoutDirection,
      rtlBehavior: layout.rtlBehavior,
      longPressMinimumDuration: longPressMinimumDuration,
      isLongPressEnabled: isLongPressEnabled,
      maximumTitleLines: titlePresentation.maximumTitleLines,
      itemInsets: layout.itemInsets
    )
  }

  func progressForCell(_ index: Int) -> CGFloat {
    guard let from = progressFromIndex, let to = progressToIndex else {
      return index == selectedIndex ? 1 : 0
    }
    if index == from { return 1 - progressValue }
    if index == to { return progressValue }
    return index == selectedIndex ? 1 : 0
  }
}
