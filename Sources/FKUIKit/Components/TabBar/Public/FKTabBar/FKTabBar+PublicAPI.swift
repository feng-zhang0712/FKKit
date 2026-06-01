//
// FKTabBar+PublicAPI.swift
//
// Public host-facing API: configuration, items, selection, badges, and batch updates.
//

import UIKit

extension FKTabBar {
  // MARK: - Public API

  /// Applies a configuration and performs the minimum necessary visual refresh.
  public func applyConfiguration(_ configuration: FKTabBarConfiguration, animated: Bool = false) {
    assertMainThreadInDebug()
    configurationApplyAnimated = animated
    self.configuration = configuration
  }

  /// Returns the effective title overflow and line-count policy for the current trait environment.
  public func resolvedTitlePresentationForCurrentEnvironment() -> FKTabBarResolvedTitlePresentation {
    let layout = resolvedLayoutForCurrentEnvironment()
    let presentation = resolvedTitlePresentation(layout: layout)
    return FKTabBarResolvedTitlePresentation(
      overflowMode: presentation.overflowMode,
      maximumTitleLines: presentation.maximumTitleLines,
      shouldIncreaseBarHeight: presentation.shouldIncreaseHeightForLargeText
    )
  }

  /// Returns effective layout hints for the current trait environment and strip geometry.
  public func resolvedLayoutHintsForCurrentEnvironment() -> FKTabBarResolvedLayoutHints {
    let layout = resolvedLayoutForCurrentEnvironment()
    let titlePresentation = resolvedTitlePresentationForCurrentEnvironment()
    let containerWidth = max(collectionView.bounds.width, bounds.width)
    let alignmentActive = !visibleItems.isEmpty
      && layout.widthMode != .fillEqually
      && contentDistribution(for: layout, in: containerWidth) != nil
    return FKTabBarResolvedLayoutHints(
      titlePresentation: titlePresentation,
      bottomSafeAreaBehavior: layout.bottomSafeAreaBehavior,
      isContentAlignmentActive: alignmentActive,
      usesPerIndexCustomSpacing: flowLayout.spacingAfterIndex != nil
    )
  }

  /// Returns the underlying `FKButton` for the given visible index if its cell is currently visible.
  ///
  /// Composite components (for example, a filter bar that presents an anchored panel) may use this
  /// as the presentation anchor without re-implementing the tab bar’s layout logic.
  ///
  /// - Parameter index: Index in the visible items list.
  /// - Returns: The `FKButton` hosted by the corresponding cell, or `nil` if the cell is currently off-screen.
  public func visibleItemButton(at index: Int) -> FKButton? {
    guard visibleItems.indices.contains(index) else { return nil }
    guard let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? FKTabBarItemCell else { return nil }
    return cell.interactiveButtonForIntegration()
  }

  /// Reloads the tab bar with a new item list using ID-based diff when possible.
  ///
  /// When the visible ID sequence is unchanged, only affected cells are refreshed.
  /// Structural changes use batch insert/delete; a full reload is used only as a fallback.
  ///
  /// - Parameters:
  ///   - items: New item list.
  ///   - updatePolicy: Selection retention behavior.
  public func reload(items: [FKTabBarItem], updatePolicy: ItemsUpdatePolicy = .preserveSelection) {
    manualItems = items
    applyReload(items: items, updatePolicy: updatePolicy, animated: false, completion: nil)
  }

  /// Applies batched visible-strip mutations with minimal collection view work.
  ///
  /// - Returns: `false` when any change is invalid (for example, index out of range or ID mismatch); no partial application is performed.
  @discardableResult
  public func applyChanges(
    _ changes: [FKTabBarItemChange],
    updatePolicy: ItemsUpdatePolicy = .preserveSelection,
    animated: Bool = false,
    completion: (() -> Void)? = nil
  ) -> Bool {
    assertMainThreadInDebug()
    guard !changes.isEmpty else {
      completion?()
      return true
    }

    let oldVisible = visibleItems
    var nextVisible = visibleItems
    var nextItems = items

    for change in changes {
      do {
        try FKTabBarItemListMutator.apply(change, visibleItems: &nextVisible, items: &nextItems)
      } catch {
        completion?()
        return false
      }
    }

    manualItems = nextItems
    applyVisibleItemsTransition(
      from: oldVisible,
      to: nextVisible,
      allItems: nextItems,
      updatePolicy: updatePolicy,
      animated: animated,
      completion: completion
    )
    return true
  }

  /// Reloads tab items from `dataSource` when available.
  ///
  /// If `dataSource` is `nil`, this method reloads from the last manual `reload(items:)` cache.
  public func reloadData(updatePolicy: ItemsUpdatePolicy = .preserveSelection) {
    let sourceItems: [FKTabBarItem]
    if let dataSource {
      let count = max(0, dataSource.numberOfItems(in: self))
      sourceItems = (0..<count).map { dataSource.tabBar(self, itemAt: $0) }
    } else {
      sourceItems = manualItems
    }
    applyReload(items: sourceItems, updatePolicy: updatePolicy, animated: false, completion: nil)
  }

  func applyReload(
    items: [FKTabBarItem],
    updatePolicy: ItemsUpdatePolicy,
    animated: Bool,
    completion: (() -> Void)?
  ) {
    let oldVisible = visibleItems
    let newVisible = items.filter { !$0.isHidden }
    manualItems = items
    applyVisibleItemsTransition(
      from: oldVisible,
      to: newVisible,
      allItems: items,
      updatePolicy: updatePolicy,
      animated: animated,
      completion: completion
    )
  }

  func applyVisibleItemsTransition(
    from oldVisible: [FKTabBarItem],
    to newVisible: [FKTabBarItem],
    allItems: [FKTabBarItem],
    updatePolicy: ItemsUpdatePolicy,
    animated: Bool,
    completion: (() -> Void)?
  ) {
    assertMainThreadInDebug()
    if isPerformingVisibleItemsBatchUpdate {
      pendingVisibleItemsTransition = PendingVisibleItemsTransition(
        allItems: allItems,
        newVisible: newVisible,
        updatePolicy: updatePolicy,
        animated: animated,
        completion: completion
      )
      return
    }

    let previousID = visibleItems[safe: selectedIndex]?.id
    itemsStorage = allItems

    let targetIndex = FKTabBarIndexSynchronizer.resolveTargetIndex(
      previousVisibleID: previousID,
      previousSelectedIndex: selectedIndex,
      visibleItems: newVisible,
      policy: updatePolicy
    )

    let out = FKTabBarSelectionReducer.reduce(
      snapshot: snapshot,
      event: .itemsChanged(count: newVisible.count),
      count: newVisible.count
    )
    snapshot = out.snapshot
    snapshot.selectedIndex = targetIndex
    selectedIndexStorage = targetIndex
    switchPhaseStorage = snapshot.phase
    clearProgressSnapshot()

    let plan = FKTabBarItemDiffEngine.plan(oldVisible: oldVisible, newVisible: newVisible)
    switch plan {
    case .contentUpdates(let indices):
      visibleItemsStorage = newVisible
      for index in indices {
        refreshCellIfVisible(at: index)
      }
      if !indices.isEmpty {
        collectionView.collectionViewLayout.invalidateLayout()
      }
      finalizeItemsTransition(animated: animated, completion: completion)

    case .fullReload:
      visibleItemsStorage = newVisible
      collectionView.reloadData()
      finalizeItemsTransition(animated: animated, completion: completion)

    case .structural(let removals, let insertions):
      isPerformingVisibleItemsBatchUpdate = true
      visibleItemsStorage = oldVisible
      collectionView.performBatchUpdates { [weak self] in
        guard let self else { return }
        for offset in removals.sorted(by: >) {
          guard self.visibleItems.indices.contains(offset) else { continue }
          self.visibleItemsStorage.remove(at: offset)
          self.collectionView.deleteItems(at: [IndexPath(item: offset, section: 0)])
        }
        for offset in insertions.sorted(by: <) {
          guard newVisible.indices.contains(offset) else { continue }
          self.visibleItemsStorage.insert(newVisible[offset], at: offset)
          self.collectionView.insertItems(at: [IndexPath(item: offset, section: 0)])
        }
      } completion: { [weak self] _ in
        guard let self else { return }
        self.isPerformingVisibleItemsBatchUpdate = false
        self.visibleItemsStorage = newVisible
        self.finalizeItemsTransition(animated: animated, completion: completion)
        self.drainPendingVisibleItemsTransition()
      }
    }
  }

  func drainPendingVisibleItemsTransition() {
    guard let pending = pendingVisibleItemsTransition else { return }
    pendingVisibleItemsTransition = nil
    let oldVisible = visibleItems
    applyVisibleItemsTransition(
      from: oldVisible,
      to: pending.newVisible,
      allItems: pending.allItems,
      updatePolicy: pending.updatePolicy,
      animated: pending.animated,
      completion: pending.completion
    )
  }

  func finalizeItemsTransition(animated: Bool, completion: (() -> Void)?) {
    invalidateItemSizeCache()
    let layout = resolvedLayoutForCurrentEnvironment()
    let animatedScroll = animated && layout.isScrollable && layout.isSelectionScrollAnimationEnabled
    updateEmptyStatePresentation()
    invalidateLayoutAndRelayout(animatedScroll: animatedScroll)
    updateIndicatorFrame(animated: animated)
    delegate?.tabBar(self, didReloadItems: items, visibleItems: visibleItems, selectedIndex: selectedIndex)
    completion?()
  }

  /// Programmatically selects a tab.
  ///
  /// Selection is reduced through the state reducer so taps, programmatic requests,
  /// and interactive commits share deterministic behavior under rapid updates.
  public func setSelectedIndex(_ index: Int, animated: Bool = true, reason: SelectionReason = .programmatic) {
    assertMainThreadInDebug()
    setSelectedIndex(index, animated: animated, notify: true, reason: reason)
  }

  /// Selects a tab index.
  ///
  /// This API unifies programmatic selection for global users who often need:
  /// - **visual selection** changes, but
  /// - **no outward notifications** (e.g. when syncing state from an external controller).
  ///
  /// - Parameters:
  ///   - index: Target index in the visible items list.
  ///   - animated: Whether to animate scrolling and indicator movement.
  ///   - notify: When `false`, suppresses `onSelectionChanged`, `delegate` callbacks, and VoiceOver announcement.
  ///   - reason: Semantic selection reason (defaults to `.programmatic`).
  ///
  /// - Important: `notify == false` does not prevent UI updates; it only suppresses callbacks.
  public func setSelectedIndex(
    _ index: Int,
    animated: Bool = true,
    notify: Bool,
    reason: SelectionReason = .programmatic
  ) {
    assertMainThreadInDebug()
    guard !visibleItems.isEmpty else { return }
    let output = FKTabBarSelectionReducer.reduce(
      snapshot: snapshot,
      event: selectionEvent(for: reason, index: index),
      count: visibleItems.count
    )

    switch output.change {
    case .none:
      return
    case .reselected(let idx):
      guard let item = visibleItems[safe: idx] else { return }
      emitReselectIfNeeded(index: idx, item: item, notify: notify)
      if reason == .userTap, tapEventTriggerBehavior == .always {
        emitDidSelectIfNeeded(index: idx, item: item, reason: reason, notify: notify)
      }
      triggerHapticsIfNeeded(reason: reason)
      return
    case .selected(_, let to):
      let previous = snapshot.selectedIndex
      guard let item = visibleItems[safe: to], item.isEnabled else { return }
      guard shouldAllowSelection(index: to, item: item, reason: reason) else { return }
      if reason == .userTap, selectionControlMode == .controlled {
        onSelectionRequest?(item, to)
        delegate?.tabBar(self, didRequestSelection: item, at: to)
        return
      }
      delegate?.tabBar(self, willSelect: item, at: to, reason: reason)

      snapshot = output.snapshot
      selectedIndexStorage = to
      switchPhaseStorage = output.snapshot.phase
      progressFromIndex = nil
      progressToIndex = nil
      progressValue = 0
      clearProgressSnapshot()

      // Avoid full reload for selection changes to prevent whole-strip flicker.
      relayoutForSelectionChange(from: previous, to: to, animated: animated)

      if notify, UIAccessibility.isVoiceOverRunning, reason == .userTap {
        UIAccessibility.post(notification: .announcement, argument: item.accessibilityLabel ?? item.title.normal.text ?? item.id)
      }

      emitDidSelectIfNeeded(index: to, item: item, reason: reason, notify: notify)
      triggerHapticsIfNeeded(reason: reason)
    case .progress:
      break
    }
  }

  /// Selects the tab with the given stable item identifier.
  ///
  /// - Returns: `false` when no visible tab matches `itemID` or the strip is empty.
  @discardableResult
  public func setSelectedIndex(
    forItemID itemID: String,
    animated: Bool = true,
    notify: Bool = true,
    reason: SelectionReason = .programmatic
  ) -> Bool {
    assertMainThreadInDebug()
    guard let index = visibleItems.firstIndex(where: { $0.id == itemID }) else { return false }
    setSelectedIndex(index, animated: animated, notify: notify, reason: reason)
    return true
  }

  // MARK: - Public API: Layout / Indicator

  /// Performs a batch of updates with a single layout invalidation and indicator refresh.
  ///
  /// Use this when you want to update multiple inputs at once (for example: appearance + items + selection)
  /// while minimizing redundant `reloadData()` and repeated layout work.
  ///
  /// - Complexity: Expected to be \(O(v)\) where \(v\) is the number of visible cells affected.
  public func performBatchUpdates(_ updates: () -> Void, completion: (() -> Void)? = nil) {
    assertMainThreadInDebug()
    UIView.performWithoutAnimation {
      updates()
    }
    collectionView.collectionViewLayout.invalidateLayout()
    collectionView.layoutIfNeeded()
    updateIndicatorFrame(animated: false)
    completion?()
  }
  /// Forces layout refresh and realigns selected item and indicator.
  ///
  /// Use this after container rotation or major bounds/safe-area changes.
  public func realignSelection(animated: Bool = false) {
    assertMainThreadInDebug()
    invalidateLayoutAndRelayout(animatedScroll: animated)
    updateIndicatorFrame(animated: false)
  }

  /// Updates indicator and item rendering for an in-flight selection transition.
  ///
  /// This API is intended for interactive containers (such as pagers) and accepts
  /// normalized progress in `[0, 1]`.
  ///
  /// - Important: To avoid indicator jitter under fast updates and strip scrolling, this method
  ///   captures stable source/target item frames once per `(from,to)` pair and interpolates within
  ///   that snapshot space until selection settles.
  public func setSelectionProgress(from fromIndex: Int, to toIndex: Int, progress: CGFloat) {
    assertMainThreadInDebug()
    guard visibleItems.indices.contains(fromIndex), visibleItems.indices.contains(toIndex) else { return }
    let output = FKTabBarSelectionReducer.reduce(
      snapshot: snapshot,
      event: .gestureProgress(from: fromIndex, to: toIndex, progress: progress),
      count: visibleItems.count
    )
    snapshot = output.snapshot
    switchPhaseStorage = output.snapshot.phase
    captureProgressSnapshotIfNeeded(from: fromIndex, to: toIndex)
    progressFromIndex = fromIndex
    progressToIndex = toIndex
    progressValue = max(0, min(1, progress))
    onSelectionProgress?(fromIndex, toIndex, progressValue)
    updateIndicatorFrame(animated: false)
    // Update only currently visible cells to keep interaction smooth for long tab lists.
    collectionView.visibleCells.forEach { cell in
      guard let indexPath = collectionView.indexPath(for: cell), let tabCell = cell as? FKTabBarItemCell else { return }
      tabCell.apply(
        modelForCell(at: indexPath.item, selectionProgress: progressForCell(indexPath.item)),
        customization: customization,
        badgeConfiguration: badgeConfiguration,
        badgeAnimation: badgeAnimation
      )
    }
  }

  // MARK: - Public API: Badge

  /// Updates one tab's badge with minimal UI work.
  ///
  /// This method updates the in-memory item model and refreshes only the target visible cell
  /// when possible, avoiding a full `reloadData()`.
  ///
  /// - Parameters:
  ///   - badge: New badge payload.
  ///   - index: Visible item index.
  ///   - animated: Whether to animate indicator/badge refresh.
  ///   - accessibilityValue: Optional localized VoiceOver value for the badge; `nil` keeps auto-generated text.
  public func setBadge(
    _ badge: FKTabBarBadgeContent,
    at index: Int,
    animated: Bool = false,
    accessibilityValue: String? = nil
  ) {
    assertMainThreadInDebug()
    guard visibleItems.indices.contains(index) else { return }
    let visibleID = visibleItems[index].id
    guard let fullIndex = items.firstIndex(where: { $0.id == visibleID }) else { return }
    itemsStorage[fullIndex].badge.state.normal = badge
    itemsStorage[fullIndex].badge.accessibilityValue = accessibilityValue
    visibleItemsStorage[index].badge.state.normal = badge
    visibleItemsStorage[index].badge.accessibilityValue = accessibilityValue
    refreshCellIfVisible(at: index)
    updateIndicatorFrame(animated: animated)
  }

  /// Updates one tab's badge by stable item identifier.
  ///
  /// - Parameters:
  ///   - badge: New badge payload.
  ///   - itemID: Stable tab item identifier.
  ///   - animated: Whether to animate indicator/badge refresh.
  ///   - accessibilityValue: Optional localized VoiceOver value for the badge; `nil` keeps auto-generated text.
  public func setBadge(
    _ badge: FKTabBarBadgeContent,
    forItemID itemID: String,
    animated: Bool = false,
    accessibilityValue: String? = nil
  ) {
    assertMainThreadInDebug()
    guard let visibleIndex = visibleItems.firstIndex(where: { $0.id == itemID }) else { return }
    setBadge(badge, at: visibleIndex, animated: animated, accessibilityValue: accessibilityValue)
  }

  // MARK: - Public API: Item updates

  /// Re-renders the visible cell at `index` from the current in-memory ``visibleItems`` model.
  ///
  /// This does **not** fetch new data from ``FKTabBarDataSource`` or accept a new model payload.
  /// To apply model changes, use ``setItem(_:at:animated:)`` / ``setItem(_:forItemID:animated:)``,
  /// ``setBadge(_:at:animated:)``, ``applyChanges(_:)``, or ``reload(items:)``.
  @discardableResult
  public func updateItem(at index: Int, animated: Bool = false) -> Bool {
    assertMainThreadInDebug()
    guard visibleItems.indices.contains(index) else { return false }
    refreshCellIfVisible(at: index)
    updateIndicatorFrame(animated: animated)
    return true
  }

  /// Re-renders a visible cell by stable identifier from the current in-memory model.
  ///
  /// See ``updateItem(at:animated:)`` for semantics; this is the ID-based convenience overload.
  @discardableResult
  public func updateItem(forItemID itemID: String, animated: Bool = false) -> Bool {
    assertMainThreadInDebug()
    guard let index = visibleItems.firstIndex(where: { $0.id == itemID }) else { return false }
    return updateItem(at: index, animated: animated)
  }

  /// Applies a new item model at the visible index, syncing both ``items`` and ``visibleItems``.
  @discardableResult
  public func setItem(_ item: FKTabBarItem, at index: Int, animated: Bool = false) -> Bool {
    assertMainThreadInDebug()
    guard visibleItems.indices.contains(index) else { return false }
    guard visibleItems[index].id == item.id else { return false }
    guard let fullIndex = items.firstIndex(where: { $0.id == item.id }) else { return false }

    replaceStoredItem(item, atFullIndex: fullIndex)
    if item.isHidden {
      applyChanges(
        [FKTabBarItemChange(kind: .delete(visibleIndex: index))],
        updatePolicy: .preserveSelection,
        animated: animated
      )
      return true
    }
    visibleItemsStorage[index] = item
    refreshCellIfVisible(at: index)
    updateIndicatorFrame(animated: animated)
    return true
  }

  /// Same as ``setItem(_:at:animated:)`` keyed by stable id (visible strip only).
  @discardableResult
  public func setItem(_ item: FKTabBarItem, forItemID itemID: String, animated: Bool = false) -> Bool {
    assertMainThreadInDebug()
    guard let index = visibleItems.firstIndex(where: { $0.id == itemID }) else { return false }
    return setItem(item, at: index, animated: animated)
  }

  func replaceStoredItem(_ item: FKTabBarItem, atFullIndex: Int) {
    var next = itemsStorage
    next[atFullIndex] = item
    itemsStorage = next
    manualItems = next
  }
}
