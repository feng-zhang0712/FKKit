//
// FKTabBar+Indicator.swift
//
// Indicator geometry, progressive interpolation, and visible-cell refresh.
//

import UIKit

extension FKTabBar {
  // MARK: - Indicator

  func indicatorFrameForItem(_ frame: CGRect, referenceIndex: Int) -> CGRect {
    let style = resolvedAppearance().indicatorStyle
    let contentFrame: CGRect = {
      guard let cell = collectionView.cellForItem(at: IndexPath(item: referenceIndex, section: 0)) as? FKTabBarItemCell else { return frame }
      return cell.contentFrame(in: backgroundHost)
    }()
    let customResolver: ((_ itemFrame: CGRect, _ containerBounds: CGRect) -> CGRect)?
    if let customization {
      customResolver = { itemFrame, containerBounds in
        if let custom = customization.customIndicatorFrame(itemFrame: itemFrame, containerBounds: containerBounds) {
          return custom
        }
        return FKTabBarIndicatorFrameCalculator.frame(
          style: style,
          itemFrame: itemFrame,
          contentFrame: contentFrame,
          containerBounds: containerBounds,
          customResolver: nil
        )
      }
    } else {
      customResolver = nil
    }
    return FKTabBarIndicatorFrameCalculator.frame(
      style: style,
      itemFrame: frame,
      contentFrame: contentFrame,
      containerBounds: backgroundHost.bounds,
      customResolver: customResolver
    )
  }

  func updateIndicatorFrame(animated: Bool) {
    guard visibleItems.indices.contains(selectedIndex) else {
      indicator.isHidden = true
      return
    }
    if case .none = resolvedAppearance().indicatorStyle {
      indicator.isHidden = true
      return
    }

    // Ensure frames are up-to-date when called from scroll/delegate callbacks.
    collectionView.layoutIfNeeded()
    updateIndicatorZOrder(for: resolvedAppearance().indicatorStyle)
    let followMode = resolvedFollowMode()

    let target: CGRect
    if let from = progressFromIndex, let to = progressToIndex,
       shouldInterpolateIndicatorProgress(for: followMode),
       let fromFrame = progressSnapshotFromFrame ?? resolvedItemFrame(at: from),
       let toFrame = progressSnapshotToFrame ?? resolvedItemFrame(at: to) {
      // Interpolate between stable source/target frames captured when progress starts.
      // This avoids per-tick frame drift caused by concurrent collection scrolling/reuse/layout invalidation.
      //
      // In RTL, we interpolate in a logical LTR coordinate space and map back to physical space.
      // Doing this keeps motion direction consistent with index transitions and prevents apparent
      // reverse jumps when UIKit mirrors scroll coordinates.
      let fromF = backgroundHost.convert(fromFrame, from: collectionView)
      let toF = backgroundHost.convert(toFrame, from: collectionView)
      let interpolated = interpolatedProgressRect(from: fromF, to: toF, progress: progressValue)
      target = indicatorFrameForItem(interpolated, referenceIndex: to)
    } else if let selectedFrame = resolvedItemFrame(at: selectedIndex) {
      target = indicatorFrameForItem(backgroundHost.convert(selectedFrame, from: collectionView), referenceIndex: selectedIndex)
    } else {
      return
    }

    indicator.isHidden = false
    indicator.move(to: target, animation: resolvedAnimation().indicatorAnimation, animated: animated)
  }

  /// Re-applies the current `visibleItems` to already-visible cells.
  ///
  /// Call after you replace models via ``reload(items:updatePolicy:)`` when `selectedIndex` is unchanged,
  /// because the selection reducer may skip per-cell refresh for the same index.
  public func reapplyVisibleItemConfigurations() {
    assertMainThreadInDebug()
    refreshVisibleCellsForCurrentState()
  }

  func refreshVisibleCellsForCurrentState() {
    collectionView.visibleCells.forEach { cell in
      guard let indexPath = collectionView.indexPath(for: cell),
            let tabCell = cell as? FKTabBarItemCell,
            visibleItems.indices.contains(indexPath.item) else { return }
      tabCell.apply(
        modelForCell(at: indexPath.item, selectionProgress: progressForCell(indexPath.item)),
        customization: customization,
        badgeConfiguration: badgeConfiguration,
        badgeAnimation: badgeAnimation
      )
    }
  }

  func refreshCellIfVisible(at index: Int) {
    let indexPath = IndexPath(item: index, section: 0)
    guard let cell = collectionView.cellForItem(at: indexPath) as? FKTabBarItemCell,
          visibleItems.indices.contains(index) else { return }
    cell.apply(
      modelForCell(at: index, selectionProgress: progressForCell(index)),
      customization: customization,
      badgeConfiguration: badgeConfiguration,
      badgeAnimation: badgeAnimation
    )
  }

private func resolvedItemFrame(at index: Int) -> CGRect? {
    let indexPath = IndexPath(item: index, section: 0)
    if let cell = collectionView.cellForItem(at: indexPath) {
      return cell.frame
    }
    return collectionView.layoutAttributesForItem(at: indexPath)?.frame
  }

  func captureProgressSnapshotIfNeeded(from: Int, to: Int) {
    // Re-capture only when interaction endpoints change or snapshot is absent.
    // This keeps interpolation deterministic across rapid progress callbacks.
    if progressFromIndex != from || progressToIndex != to || progressSnapshotFromFrame == nil || progressSnapshotToFrame == nil {
      collectionView.layoutIfNeeded()
      progressSnapshotFromFrame = resolvedItemFrame(at: from)
      progressSnapshotToFrame = resolvedItemFrame(at: to)
    }
  }

  func clearProgressSnapshot() {
    progressSnapshotFromFrame = nil
    progressSnapshotToFrame = nil
  }

// MARK: - Accessibility

  func updateIndicatorZOrder(for style: FKTabBarIndicatorStyle) {
    if case .none = style { return }

    let order = resolvedAppearance().indicatorZOrder
    let belowItems: Bool
    switch order {
    case .belowTabItems:
      belowItems = true
    case .aboveTabItems:
      belowItems = false
    case .automatic:
      switch style {
      case .backdrop, .custom:
        belowItems = true
      case .line:
        belowItems = false
      case .none:
        return
      }
    }

    if belowItems {
      backgroundHost.insertSubview(indicator, belowSubview: collectionView)
    } else {
      backgroundHost.bringSubviewToFront(indicator)
    }
  }
}
