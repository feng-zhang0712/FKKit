//
// FKTabBar+LayoutEngine.swift
//
// Item sizing cache, content distribution, RTL direction, and layout invalidation.
//

import UIKit

extension FKTabBar {
  // MARK: - Layout Engine

  @inline(__always)
  func assertMainThreadInDebug(file: StaticString = #fileID, line: UInt = #line) {
#if DEBUG
    dispatchPrecondition(condition: .onQueue(.main))
#endif
  }

  func resolvedCustomSpacing(after index: Int, layout: FKTabBarLayoutConfiguration) -> CGFloat? {
    guard let customization else { return nil }
    let context = FKTabBarLayoutConfiguration.SpacingContext(
      visibleItemsCount: visibleItems.count,
      isScrollable: layout.isScrollable,
      defaultSpacing: layout.itemSpacing
    )
    return customization.customSpacing(after: index, context: context).map { max(0, $0) }
  }

  func syncFlowLayoutSpacingProvider() {
    let layout = resolvedLayoutForCurrentEnvironment()
    guard layout.widthMode != .fillEqually,
          contentDistribution(for: layout, in: max(collectionView.bounds.width, bounds.width)) == nil,
          customization != nil else {
      flowLayout.spacingAfterIndex = nil
      return
    }
    flowLayout.spacingAfterIndex = { [weak self] index in
      guard let self else { return nil }
      return self.resolvedCustomSpacing(after: index, layout: self.resolvedLayoutForCurrentEnvironment())
    }
  }

  func invalidateItemSizeCache() {
    cachedItemSizes.removeAll(keepingCapacity: true)
  }

  func cachedItemSize(at index: Int) -> CGSize {
    if cachedItemSizes.count == visibleItems.count,
       cachedItemSizes.indices.contains(index) {
      return cachedItemSizes[index]
    }
    rebuildItemSizeCache()
    guard cachedItemSizes.indices.contains(index) else {
      return CGSize(width: 44, height: max(44, resolvedLayout().minimumItemHeight))
    }
    return cachedItemSizes[index]
  }

  func collectionMeasurementBounds() -> CGRect {
    let width = max(collectionView.bounds.width, bounds.width)
    let height = max(collectionView.bounds.height, bounds.height)
    return CGRect(x: 0, y: 0, width: width, height: height)
  }

  func rebuildItemSizeCache() {
    let layout = resolvedLayoutForCurrentEnvironment()
    let titlePresentation = resolvedTitlePresentation(layout: layout)
    let measurementBounds = collectionMeasurementBounds()
    cachedItemSizes = visibleItems.indices.map { index in
      guard let item = visibleItems[safe: index] else {
        return CGSize(width: 44, height: max(44, layout.minimumItemHeight))
      }
      return FKTabBarItemWidthStrategy.sizeForItem(
        item: item,
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
    }
  }

  func applySemanticDirection() {
    switch resolvedLayoutForCurrentEnvironment().rtlBehavior {
    case .automatic:
      semanticContentAttribute = .unspecified
      collectionView.semanticContentAttribute = .unspecified
    case .forceLeftToRight:
      semanticContentAttribute = .forceLeftToRight
      collectionView.semanticContentAttribute = .forceLeftToRight
    case .forceRightToLeft:
      semanticContentAttribute = .forceRightToLeft
      collectionView.semanticContentAttribute = .forceRightToLeft
    }
  }

  /// When `true`, selection changes invalidate item width cache and relayout the strip.
  func shouldRelayoutIntrinsicWidthsOnSelection(for layout: FKTabBarLayoutConfiguration) -> Bool {
    layout.widthMode != .fillEqually && layout.intrinsicWidthMeasurement == .adjustsOnSelection
  }

  func relayoutForSelectionChange(from previous: Int?, to: Int, animated: Bool) {
    let layout = resolvedLayoutForCurrentEnvironment()
    guard shouldRelayoutIntrinsicWidthsOnSelection(for: layout) else {
      refreshVisibleCellsForCurrentState()
      scrollSelectedIntoView(animated: animated)
      updateIndicatorFrame(animated: animated)
      return
    }
    invalidateItemSizeCache()
    invalidateLayoutAndRelayout(animatedScroll: animated && layout.isSelectionScrollAnimationEnabled)
    refreshVisibleCellsForCurrentState()
    updateIndicatorFrame(animated: animated)
  }

  func invalidateLayoutAndRelayout(animatedScroll: Bool) {
    guard !visibleItems.isEmpty else {
      return
    }
    // Defer until the strip has a real size so collection cells are not laid out at zero width/height.
    guard bounds.width > 0, bounds.height > 0 else {
      return
    }
    // All geometry-sensitive relayouts go through one path so indicator, scrolling, and cell frames
    // stay synchronized across rotation, trait changes, and host-driven layout updates.
    collectionView.collectionViewLayout.invalidateLayout()
    collectionView.layoutIfNeeded()
    clearProgressSnapshot()
    scrollSelectedIntoView(animated: animatedScroll)
  }

  struct ContentDistribution {
    var leadingInset: CGFloat
    var trailingInset: CGFloat
  }

  func contentDistribution(for layout: FKTabBarLayoutConfiguration, in containerWidth: CGFloat) -> ContentDistribution? {
    guard !visibleItems.isEmpty else { return nil }
    guard layout.widthMode != .fillEqually else { return nil }
    let itemWidths = (0..<visibleItems.count).map { cachedItemSize(at: $0).width }
    let totalItemsWidth = itemWidths.reduce(0, +)
    let baseSpacing = max(0, layout.itemSpacing)
    let minSpacingTotal = CGFloat(max(0, visibleItems.count - 1)) * baseSpacing
    let baseLeading = layout.contentInsets.leading
    let baseTrailing = layout.contentInsets.trailing
    let available = max(0, containerWidth - baseLeading - baseTrailing)
    let requiredAtBase = totalItemsWidth + minSpacingTotal
    guard requiredAtBase < available else { return nil }

    let extra = available - requiredAtBase
    let direction = effectiveUserInterfaceLayoutDirection
    switch layout.contentAlignment {
    case .leading:
      let logicalLeftInset = baseLeading
      let logicalRightInset = baseTrailing + extra
      return distributionFromLogical(logicalLeft: logicalLeftInset, logicalRight: logicalRightInset, direction: direction)
    case .trailing:
      let logicalLeftInset = baseLeading + extra
      let logicalRightInset = baseTrailing
      return distributionFromLogical(logicalLeft: logicalLeftInset, logicalRight: logicalRightInset, direction: direction)
    case .center:
      let left = baseLeading + extra * 0.5
      let right = baseTrailing + extra * 0.5
      return distributionFromLogical(logicalLeft: left, logicalRight: right, direction: direction)
    }
  }

  func distributionFromLogical(
    logicalLeft: CGFloat,
    logicalRight: CGFloat,
    direction: UIUserInterfaceLayoutDirection
  ) -> ContentDistribution {
    if direction == .rightToLeft {
      return ContentDistribution(
        leadingInset: logicalRight,
        trailingInset: logicalLeft
      )
    }
    return ContentDistribution(
      leadingInset: logicalLeft,
      trailingInset: logicalRight
    )
  }

  func resolvedFollowMode() -> FKTabBarIndicatorFollowMode {
    switch resolvedAppearance().indicatorStyle {
    case .line(let config):
      return config.followMode
    case .backdrop(let config):
      return config.followMode
    case .custom(let config):
      if case .custom(let id) = config.followMode,
         let resolved = customization?.indicatorFollowMode(forCustomID: id) {
        return resolved
      }
      return config.followMode
    case .none:
      return .trackSelectedFrame
    }
  }

  func shouldInterpolateIndicatorProgress(for followMode: FKTabBarIndicatorFollowMode) -> Bool {
    switch followMode {
    case .trackContentProgress:
      return true
    case .trackSelectedFrame, .trackContentFrame, .lockedUntilSettle, .custom:
      return false
    }
  }
}
