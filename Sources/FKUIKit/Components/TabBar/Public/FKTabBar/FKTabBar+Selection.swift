//
// FKTabBar+Selection.swift
//
// Selection gating, title presentation resolution, and callback emission.
//

import UIKit

extension FKTabBar {
  // MARK: - Selection & State

  func selectionEvent(for reason: SelectionReason, index: Int) -> FKTabBarSelectionEvent {
    switch reason {
    case .userTap:
      return .userTap(index)
    case .programmatic:
      return .programmatic(index)
    case .interaction:
      return .gestureCommit(index)
    }
  }

  func interpolatedProgressRect(from: CGRect, to: CGRect, progress: CGFloat) -> CGRect {
    let p = max(0, min(1, progress))
    let isRTL = collectionView.effectiveUserInterfaceLayoutDirection == .rightToLeft
    let fromLogicalX: CGFloat
    let toLogicalX: CGFloat
    if isRTL {
      // Convert physical X into logical X against a stable container width.
      fromLogicalX = backgroundHost.bounds.width - from.maxX
      toLogicalX = backgroundHost.bounds.width - to.maxX
    } else {
      fromLogicalX = from.minX
      toLogicalX = to.minX
    }
    let logicalX = fromLogicalX + (toLogicalX - fromLogicalX) * p
    let y = from.minY + (to.minY - from.minY) * p
    let w = from.width + (to.width - from.width) * p
    let h = from.height + (to.height - from.height) * p
    let physicalX = isRTL ? (backgroundHost.bounds.width - logicalX - w) : logicalX
    return CGRect(x: physicalX, y: y, width: w, height: h)
  }

  func resolvedTitlePresentation(
    layout: FKTabBarLayoutConfiguration
  ) -> (overflowMode: FKTabBarTitleOverflowMode, maximumTitleLines: Int, shouldIncreaseHeightForLargeText: Bool) {
    let baseOverflow = resolvedOverflowMode(for: layout)
    guard traitCollection.preferredContentSizeCategory.isAccessibilityCategory else {
      let defaultLines = resolvedAppearance().typography.allowsTwoLineTitle ? 2 : 1
      return (baseOverflow, defaultLines, false)
    }
    switch layout.largeTextLayoutStrategy {
    case .automatic:
      let defaultLines = resolvedAppearance().typography.allowsTwoLineTitle ? 2 : 1
      return (baseOverflow, defaultLines, false)
    case .truncate:
      return (.truncate, 1, false)
    case .shrink(let factor):
      return (.shrink(minimumScaleFactor: factor), 1, false)
    case .wrap(let maxLines):
      return (.wrap, max(1, maxLines), false)
    case .wrapAndIncreaseHeight(let maxLines):
      return (.wrap, max(1, maxLines), true)
    }
  }

  func resolvedOverflowMode(for layout: FKTabBarLayoutConfiguration) -> FKTabBarTitleOverflowMode {
    guard !layout.isScrollable else { return layout.titleOverflowMode }
    switch layout.nonScrollableOverflowPolicy {
    case .shrink:
      if case .shrink = layout.titleOverflowMode { return layout.titleOverflowMode }
      if case .wrap = layout.titleOverflowMode { return layout.titleOverflowMode }
      return .shrink(minimumScaleFactor: 0.8)
    case .truncate, .clip:
      if case .wrap = layout.titleOverflowMode { return layout.titleOverflowMode }
      return .truncate
    }
  }

  func shouldAllowSelection(index: Int, item: FKTabBarItem, reason: SelectionReason) -> Bool {
    guard item.isEnabled else { return false }
    if shouldSelect?(item, index, reason) == false { return false }
    if delegate?.tabBar(self, shouldSelect: item, at: index, reason: reason) == false { return false }
    return true
  }

  func emitDidSelectIfNeeded(index: Int, item: FKTabBarItem, reason: SelectionReason, notify: Bool) {
    guard notify else { return }
    onSelectionChanged?(item, index, reason)
    delegate?.tabBar(self, didSelect: item, at: index, reason: reason)
  }

  func emitReselectIfNeeded(index: Int, item: FKTabBarItem, notify: Bool) {
    guard notify else { return }
    onReselect?(item, index)
    delegate?.tabBar(self, didReselect: item, at: index)
  }

  func triggerHapticsIfNeeded(reason: SelectionReason) {
    guard isHapticFeedbackEnabled, reason == .userTap else { return }
    selectionFeedbackGenerator.selectionChanged()
  }
}
