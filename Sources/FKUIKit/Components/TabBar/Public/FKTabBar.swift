import UIKit

/// High-performance UIKit tab strip backed by `UICollectionView`.
///
/// Contributor note: shipped API sources live under `Public/`; helpers under `Internal/`. See `README.md` alongside this target.

/// A high-performance tab header component.
///
/// `FKTabBar` is UI-only: it manages tab rendering, selection state, and indicator animation.
///
/// ## Responsibility boundaries
/// `FKTabBar` does **not** perform page switching, navigation, or controller containment.
/// It does not manage a paging controller, `UITabBarController`, or any view-controller lifecycle.
/// Instead, hosts should:
/// - drive selection via `setSelectedIndex(_:animated:notify:reason:)`, or
/// - bind interactive transitions via `setSelectionProgress(from:to:progress:)`.
///
/// - Important: All public APIs are `@MainActor` and must be used on the main thread.
@MainActor
public final class FKTabBar: UIView {
  // MARK: - Public API Types

  /// Selection ownership mode.
  public enum SelectionControlMode {
    /// `FKTabBar` applies user-tap selection immediately.
    ///
    /// Choose this mode when this view is the source of truth for `selectedIndex`.
    case uncontrolled
    /// `FKTabBar` emits a selection request and waits for host confirmation.
    ///
    /// In this mode, taps call `onSelectionRequest` and do not commit selection until
    /// host code calls `setSelectedIndex(_:animated:reason:)`.
    case controlled
  }
  /// Selection reason.
  public enum SelectionReason {
    /// Selection came from a user tap on a tab item.
    case userTap
    /// Selection came from host code.
    case programmatic
    /// Selection committed by an interactive container transition.
    case interaction
  }

  /// Tap callback trigger behavior when user taps tab items.
  public enum TapEventTriggerBehavior {
    /// Emit selection callbacks only when selection actually changes.
    ///
    /// In this mode:
    /// - first tap on a new tab => `didSelect`
    /// - tap on already-selected tab => `didReselect` only
    case onceAfterSelection
    /// Emit selection callbacks for every user tap.
    ///
    /// In this mode, tapping an already-selected tab emits:
    /// - `didReselect` (reselect semantic)
    /// - and an additional `didSelect` callback for tap analytics/event parity.
    case always
  }

  /// Interaction phase emitted to custom button animation hooks.
  public enum ItemInteractionPhase {
    /// User tapped the item.
    case tap
    /// User long-pressed the item.
    case longPress
  }

  /// Items update policy.
  public enum ItemsUpdatePolicy {
    /// Keep current selection when possible, otherwise clamp.
    case preserveSelection
    /// Always reset selection to zero after update.
    case resetSelection
    /// Map to nearest visible and enabled item.
    ///
    /// This is useful when selected item is removed/hidden/disabled by dynamic updates.
    case nearestAvailable
  }

  // MARK: - Public API: Configuration / Appearance

  /// Optional delegate for selection gating and event callbacks.
  public weak var delegate: FKTabBarDelegate?
  /// Optional data source for supplying tab items.
  ///
  /// Coexistence with direct `reload(items:)`:
  /// - `reload(items:)` applies provided items immediately and updates the manual cache.
  /// - `reloadData()` uses `dataSource` when non-`nil`; otherwise it reloads from manual cache.
  public weak var dataSource: FKTabBarDataSource? {
    didSet { reloadData(updatePolicy: .preserveSelection) }
  }
  /// Determines whether tap selection is self-managed or host-managed.
  public var selectionControlMode: SelectionControlMode = .uncontrolled

  /// Root configuration.
  ///
  /// This is the single public configuration entry point for layout/appearance/animation.
  public var configuration: FKTabBarConfiguration = FKTabBarDefaults.defaultConfiguration {
    didSet {
      invalidateIntrinsicContentSize()
      let domains = FKTabBarConfigurationApplier.domains(from: oldValue, to: configuration)
      applyConfigurationDomains(domains, animated: configurationApplyAnimated)
      configurationApplyAnimated = false
      lastAppliedConfiguration = configuration
    }
  }

  /// Full input items list before visibility filtering.
  ///
  /// Hidden items remain in this array so hosts can toggle visibility without rebuilding IDs.
  public private(set) var items: [FKTabBarItem] = []
  private var manualItems: [FKTabBarItem] = []
  /// Tabs currently laid out in the strip, in order (`isHidden` items excluded).
  public private(set) var visibleItems: [FKTabBarItem] = []

  /// Current selected index.
  public private(set) var selectedIndex: Int = 0

  /// Current selection phase.
  public private(set) var switchPhase: FKTabBarSwitchPhase = .idle

  /// Read-only selection snapshot for host coordination (paging, analytics).
  public var selectionSnapshot: FKTabBarSelectionSnapshot {
    FKTabBarSelectionSnapshot(
      selectedIndex: snapshot.selectedIndex,
      previousIndex: snapshot.previousIndex,
      phase: snapshot.phase,
      selectedItemID: visibleItems[safe: snapshot.selectedIndex]?.id
    )
  }

  /// Stable identifier of the currently selected visible tab; `nil` when the strip is empty.
  public var selectedItemID: String? {
    visibleItems[safe: selectedIndex]?.id
  }

  /// Fired during interactive progress updates from ``setSelectionProgress(from:to:progress:)``.
  public var onSelectionProgress: ((_ fromIndex: Int, _ toIndex: Int, _ progress: CGFloat) -> Void)?

  /// Minimum press duration for long-press recognition on a tab item.
  ///
  /// Long-press is handled by each tab's underlying `FKButton` so the gesture matches the tappable element.
  /// - Important: Long-press is UI-only. It does not change selection by itself.
  public var longPressMinimumDuration: TimeInterval = 0.5

  /// Closure callback for committed selection changes.
  ///
  /// Called after `selectedIndex` updates and visual state is applied.
  ///
  /// Event ordering (single pipeline):
  /// 1. `shouldSelect` closure
  /// 2. `delegate.shouldSelect`
  /// 3. `delegate.willSelect`
  /// 4. commit visual state
  /// 5. `onSelectionChanged`
  /// 6. `delegate.didSelect`
  ///
  /// If both closure and delegate are set, both are invoked in this order.
  public var onSelectionChanged: ((_ item: FKTabBarItem, _ index: Int, _ reason: SelectionReason) -> Void)?

  /// Called before applying a new selection.
  ///
  /// Return `false` to block this selection.
  ///
  /// If both this closure and `delegate.shouldSelect` are set, both must return `true` to proceed.
  /// Disabled items never trigger this callback.
  public var shouldSelect: ((_ item: FKTabBarItem, _ index: Int, _ reason: SelectionReason) -> Bool)?
  /// Called when controlled mode receives a user selection request.
  ///
  /// This callback is only triggered for `.userTap` while `selectionControlMode == .controlled`.
  /// Order in controlled mode: `onSelectionRequest` then `delegate.didRequestSelection`.
  public var onSelectionRequest: ((_ item: FKTabBarItem, _ index: Int) -> Void)?

  /// Closure callback for long-press on an item.
  ///
  /// This callback is fired when the long-press gesture enters `.began`.
  public var onLongPress: ((_ item: FKTabBarItem, _ index: Int) -> Void)?
  /// Closure callback for tapping the already selected item.
  ///
  /// Invoked before `delegate.didReselect` when both are set.
  public var onReselect: ((_ item: FKTabBarItem, _ index: Int) -> Void)?
  /// Controls how tap-driven callbacks are emitted.
  public var tapEventTriggerBehavior: TapEventTriggerBehavior = .onceAfterSelection
  /// Enables haptic feedback for user-driven interactions.
  ///
  /// Default is `true`. Programmatic selection does not emit haptic feedback.
  public var isHapticFeedbackEnabled: Bool = true
  /// Enables long-press events for tab items.
  ///
  /// Default is `false`. When disabled, long-press handlers are not attached.
  public var isLongPressEnabled: Bool = false {
    didSet { refreshVisibleCellsForCurrentState() }
  }

  /// Optional host customization for layout, rendering, and indicator hooks.
  public var customization: FKTabBarCustomization? {
    didSet {
      syncCustomizationHooks()
      refreshVisibleCellsForCurrentState()
    }
  }

  /// Visual expanded state for accessory chevrons (for example filter panels). Does not affect selection.
  public var expandedItemID: String? {
    didSet {
      guard oldValue != expandedItemID else { return }
      refreshVisibleCellsForCurrentState()
    }
  }

  /// Optional shared `FKBadge` visual configuration for tab badges.
  ///
  /// Set this to customize count overflow (for example `99+`) and badge styling without replacing badge logic.
  public var badgeConfiguration: FKBadgeConfiguration? {
    didSet { refreshVisibleCellsForCurrentState() }
  }
  /// Optional emphasis animation used when applying non-custom badge updates.
  ///
  /// - Important: This animation is applied on visible cells only.
  public var badgeAnimation: FKBadgeAnimation = .none

  // MARK: - Selection & State (Internal Storage)

  private var snapshot = FKTabBarSelectionReducerSnapshot(selectedIndex: 0)
  private var lastAppliedConfiguration: FKTabBarConfiguration?
  private var configurationApplyAnimated = false

  private struct PendingVisibleItemsTransition {
    let allItems: [FKTabBarItem]
    let newVisible: [FKTabBarItem]
    let updatePolicy: ItemsUpdatePolicy
    let animated: Bool
    let completion: (() -> Void)?
  }

  private var isPerformingVisibleItemsBatchUpdate = false
  private var pendingVisibleItemsTransition: PendingVisibleItemsTransition?

  private let backgroundHost = UIView()
  private let divider = UIView()
  private let indicator = FKTabBarIndicatorView()
  private let scrollEdgeFadeOverlay = FKTabBarScrollEdgeFadeOverlay()
  private let collectionView: UICollectionView
  private let emptyStateLabel = UILabel()

  private var lastLayoutSize: CGSize = .zero
  private var progressFromIndex: Int?
  private var progressToIndex: Int?
  private var progressValue: CGFloat = 0
  private var progressSnapshotFromFrame: CGRect?
  private var progressSnapshotToFrame: CGRect?
  private let selectionFeedbackGenerator = UISelectionFeedbackGenerator()

  // MARK: - Lifecycle / Overrides

  public override init(frame: CGRect) {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumInteritemSpacing = 0
    layout.minimumLineSpacing = 0
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    super.init(frame: frame)
    commonInit()
  }

  /// Creates a tab view with initial items.
  ///
  /// This initializer first applies configuration, then sets items, then clamps and applies
  /// initial selection. Keeping this order avoids temporary indicator/selection mismatch.
  public convenience init(
    items: [FKTabBarItem],
    selectedIndex: Int = 0,
    configuration: FKTabBarConfiguration = FKTabBarDefaults.defaultConfiguration
  ) {
    self.init(frame: .zero)
    self.configuration = configuration
    reload(items: items, updatePolicy: .preserveSelection)
    setSelectedIndex(selectedIndex, animated: false, reason: .programmatic)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func layoutSubviews() {
    assertMainThreadInDebug()
    super.layoutSubviews()
    backgroundHost.frame = bounds
    collectionView.frame = backgroundHost.bounds
    let ap = resolvedAppearance()
    let shadowPath = UIBezierPath(rect: backgroundHost.bounds).cgPath
    if case .custom(_, let opacity, let radius, _) = ap.shadow, opacity > 0, radius > 0 {
      backgroundHost.layer.shadowPath = shadowPath
    } else {
      backgroundHost.layer.shadowPath = nil
    }
    let dividerHeight: CGFloat = ap.showsDivider ? 1 / UIScreen.main.scale : 0
    let dividerY: CGFloat
    switch ap.dividerPosition {
    case .top:
      dividerY = 0
    case .bottom:
      dividerY = bounds.height - dividerHeight
    }
    divider.frame = CGRect(x: 0, y: dividerY, width: bounds.width, height: dividerHeight)
    if bounds.size != lastLayoutSize, !visibleItems.isEmpty {
      // Size changes (rotation, split view, parent relayout) are funneled into one relayout path
      // to keep item geometry, selected visibility, and indicator position in sync.
      lastLayoutSize = bounds.size
      invalidateLayoutAndRelayout(animatedScroll: false)
    }
    updateIndicatorFrame(animated: false)
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    assertMainThreadInDebug()
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.layoutDirection != previousTraitCollection?.layoutDirection {
      applySemanticDirection()
      invalidateLayoutAndRelayout(animatedScroll: false)
    }
    if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
      // Dynamic Type changes affect text measurement and thus intrinsic item widths/heights.
      // Invalidate layout and reload to keep item sizing and indicator geometry stable.
      invalidateIntrinsicContentSize()
      collectionView.reloadData()
      invalidateLayoutAndRelayout(animatedScroll: false)
    }
  }

  public override func safeAreaInsetsDidChange() {
    assertMainThreadInDebug()
    super.safeAreaInsetsDidChange()
    invalidateIntrinsicContentSize()
    invalidateLayoutAndRelayout(animatedScroll: false)
  }

  public override var intrinsicContentSize: CGSize {
    assertMainThreadInDebug()
    let layout = resolvedLayoutForCurrentEnvironment()
    let presentation = resolvedTitlePresentation(layout: layout)
    let preferredBase = layout.preferredBarHeight ?? layout.minimumItemHeight
    let baseHeight = max(44, preferredBase)
    guard presentation.shouldIncreaseHeightForLargeText else {
      let safeAreaAddition = layout.safeAreaHeightPolicy == .includeBottomSafeArea ? safeAreaInsets.bottom : 0
      return CGSize(width: UIView.noIntrinsicMetric, height: baseHeight + safeAreaAddition + layout.contentInsets.top + layout.contentInsets.bottom)
    }
    let typography = resolvedAppearance().typography
    let scaledFont: UIFont = typography.adjustsForContentSizeCategory
      ? UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: typography.selectedFont)
      : typography.selectedFont
    let textHeight = ceil(scaledFont.lineHeight * CGFloat(max(1, presentation.maximumTitleLines)))
    let iconReserve: CGFloat = resolvedLayout().itemLayoutDirection == .vertical ? 28 : 0
    let preferredHeight = max(baseHeight, textHeight + iconReserve + 24)
    let safeAreaAddition = layout.safeAreaHeightPolicy == .includeBottomSafeArea ? safeAreaInsets.bottom : 0
    return CGSize(width: UIView.noIntrinsicMetric, height: preferredHeight + safeAreaAddition + layout.contentInsets.top + layout.contentInsets.bottom)
  }

  // MARK: - Public API

  /// Applies a configuration and performs the minimum necessary visual refresh.
  public func applyConfiguration(_ configuration: FKTabBarConfiguration, animated: Bool = false) {
    assertMainThreadInDebug()
    configurationApplyAnimated = animated
    self.configuration = configuration
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
  public func applyChanges(
    _ changes: [FKTabBarItemChange],
    updatePolicy: ItemsUpdatePolicy = .preserveSelection,
    animated: Bool = false,
    completion: (() -> Void)? = nil
  ) {
    assertMainThreadInDebug()
    guard !changes.isEmpty else {
      completion?()
      return
    }

    let oldVisible = visibleItems
    var nextVisible = visibleItems
    var nextItems = items

    for change in changes {
      do {
        try FKTabBarItemListMutator.apply(change, visibleItems: &nextVisible, items: &nextItems)
      } catch {
        completion?()
        return
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

  private func applyReload(
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

  private func applyVisibleItemsTransition(
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
    items = allItems

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
    selectedIndex = targetIndex
    switchPhase = snapshot.phase
    clearProgressSnapshot()

    let plan = FKTabBarItemDiffEngine.plan(oldVisible: oldVisible, newVisible: newVisible)
    switch plan {
    case .contentUpdates(let indices):
      visibleItems = newVisible
      for index in indices {
        refreshCellIfVisible(at: index)
      }
      if !indices.isEmpty {
        collectionView.collectionViewLayout.invalidateLayout()
      }
      finalizeItemsTransition(animated: animated, completion: completion)

    case .fullReload:
      visibleItems = newVisible
      collectionView.reloadData()
      finalizeItemsTransition(animated: animated, completion: completion)

    case .structural(let removals, let insertions):
      isPerformingVisibleItemsBatchUpdate = true
      visibleItems = oldVisible
      collectionView.performBatchUpdates { [weak self] in
        guard let self else { return }
        for offset in removals.sorted(by: >) {
          guard self.visibleItems.indices.contains(offset) else { continue }
          self.visibleItems.remove(at: offset)
          self.collectionView.deleteItems(at: [IndexPath(item: offset, section: 0)])
        }
        for offset in insertions.sorted(by: <) {
          guard newVisible.indices.contains(offset) else { continue }
          self.visibleItems.insert(newVisible[offset], at: offset)
          self.collectionView.insertItems(at: [IndexPath(item: offset, section: 0)])
        }
      } completion: { [weak self] _ in
        guard let self else { return }
        self.isPerformingVisibleItemsBatchUpdate = false
        self.visibleItems = newVisible
        self.finalizeItemsTransition(animated: animated, completion: completion)
        self.drainPendingVisibleItemsTransition()
      }
    }
  }

  private func drainPendingVisibleItemsTransition() {
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

  private func finalizeItemsTransition(animated: Bool, completion: (() -> Void)?) {
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
      selectedIndex = to
      switchPhase = output.snapshot.phase
      progressFromIndex = nil
      progressToIndex = nil
      progressValue = 0
      clearProgressSnapshot()

      // Avoid full reload for selection changes to prevent whole-strip flicker.
      refreshVisibleCellsForCurrentState()
      refreshCellIfVisible(at: previous)
      refreshCellIfVisible(at: to)
      scrollSelectedIntoView(animated: animated)
      updateIndicatorFrame(animated: animated)

      if notify, UIAccessibility.isVoiceOverRunning, reason == .userTap {
        UIAccessibility.post(notification: .announcement, argument: item.accessibilityLabel ?? item.title.normal.text ?? item.id)
      }

      emitDidSelectIfNeeded(index: to, item: item, reason: reason, notify: notify)
      triggerHapticsIfNeeded(reason: reason)
    case .progress:
      break
    }
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
    switchPhase = output.snapshot.phase
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
    items[fullIndex].badge.state.normal = badge
    items[fullIndex].badge.accessibilityValue = accessibilityValue
    visibleItems[index].badge.state.normal = badge
    visibleItems[index].badge.accessibilityValue = accessibilityValue
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

  /// Updates a single visible item in place without full `reloadData()` when possible.
  @discardableResult
  public func updateItem(at index: Int, animated: Bool = false) -> Bool {
    assertMainThreadInDebug()
    guard visibleItems.indices.contains(index) else { return false }
    refreshCellIfVisible(at: index)
    updateIndicatorFrame(animated: animated)
    return true
  }

  /// Updates a single item by stable identifier.
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
    visibleItems[index] = item
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

  private func replaceStoredItem(_ item: FKTabBarItem, atFullIndex: Int) {
    var next = items
    next[atFullIndex] = item
    items = next
    manualItems = next
  }

  // MARK: - Configuration / Appearance

  private func commonInit() {
    addSubview(backgroundHost)
    backgroundHost.addSubview(collectionView)
    backgroundHost.addSubview(scrollEdgeFadeOverlay)
    backgroundHost.insertSubview(indicator, belowSubview: collectionView)
    addSubview(divider)

    collectionView.backgroundColor = .clear
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.contentInsetAdjustmentBehavior = .never
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.register(FKTabBarItemCell.self, forCellWithReuseIdentifier: "FKTabBarItemCell")

    emptyStateLabel.font = .preferredFont(forTextStyle: .footnote)
    emptyStateLabel.textColor = .secondaryLabel
    emptyStateLabel.textAlignment = .center
    emptyStateLabel.numberOfLines = 0
    emptyStateLabel.isHidden = true
    emptyStateLabel.isAccessibilityElement = true
    emptyStateLabel.accessibilityTraits = .staticText
    emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
    backgroundHost.addSubview(emptyStateLabel)
    let emptyStateLeading = emptyStateLabel.leadingAnchor.constraint(
      greaterThanOrEqualTo: backgroundHost.leadingAnchor,
      constant: 16
    )
    let emptyStateTrailing = emptyStateLabel.trailingAnchor.constraint(
      lessThanOrEqualTo: backgroundHost.trailingAnchor,
      constant: -16
    )
    let emptyStateMaxWidth = emptyStateLabel.widthAnchor.constraint(
      lessThanOrEqualTo: backgroundHost.widthAnchor,
      constant: -32
    )
    emptyStateLeading.priority = .defaultHigh
    emptyStateTrailing.priority = .defaultHigh
    emptyStateMaxWidth.priority = .defaultHigh
    NSLayoutConstraint.activate([
      emptyStateLabel.centerXAnchor.constraint(equalTo: backgroundHost.centerXAnchor),
      emptyStateLabel.centerYAnchor.constraint(equalTo: backgroundHost.centerYAnchor),
      emptyStateLeading,
      emptyStateTrailing,
      emptyStateMaxWidth,
    ])

    syncCustomizationHooks()

    applyConfigurationDomains(
      [
        .appearanceBackground,
        .appearanceIndicator,
        .layout,
        .scrollBehavior,
      ],
      animated: false
    )
    applySemanticDirection()
    lastAppliedConfiguration = configuration
  }

  private func resolvedAppearance() -> FKTabBarAppearance { configuration.appearance }
  private func resolvedLayout() -> FKTabBarLayoutConfiguration { configuration.layout }
  private func resolvedAnimation() -> FKTabBarAnimationConfiguration { configuration.animation }

  private func resolvedLayoutForCurrentEnvironment() -> FKTabBarLayoutConfiguration {
    var layout = resolvedLayout()
    if layout.includesBottomSafeAreaInset {
      // We treat safe-area as additional bottom padding so content remains visible above the home indicator.
      // This impacts size measurement, section insets, and scroll alignment.
      layout.contentInsets.bottom += safeAreaInsets.bottom
    }
    return layout
  }

  private func syncCustomizationHooks() {
    indicator.customViewProvider = { [weak customization] id in
      customization?.customIndicatorView(id: id)
    }
    indicator.customRenderer = { [weak customization] id, bounds, container in
      customization?.renderCustomIndicator(id: id, bounds: bounds, container: container)
    }
  }

  private func applyBackgroundAppearance() {
    let ap = resolvedAppearance()
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
    divider.isHidden = !ap.showsDivider
    divider.backgroundColor = ap.colors.divider
    backgroundHost.layer.masksToBounds = false
    let shadowPath = UIBezierPath(rect: backgroundHost.bounds).cgPath
    backgroundHost.layer.fk_applyShadow(ap.shadow, path: shadowPath)
    updateScrollEdgeFadeAppearance()
    setNeedsLayout()
  }

  private func applyIndicatorAppearance() {
    let ap = resolvedAppearance()
    indicator.style = ap.indicatorStyle
    indicator.color = ap.colors.indicator
    updateIndicatorZOrder(for: ap.indicatorStyle)
    updateIndicatorFrame(animated: false)
  }

  private func updateScrollEdgeFadeAppearance() {
    let layout = resolvedLayout()
    let fade = layout.scrollEdgeFade
    guard layout.isScrollable, fade.isEnabled else {
      scrollEdgeFadeOverlay.isHidden = true
      return
    }
    scrollEdgeFadeOverlay.isHidden = false
    let fadeColor: UIColor
    switch resolvedAppearance().backgroundStyle {
    case .solid(let color):
      fadeColor = color
    case .systemBlur:
      fadeColor = backgroundHost.backgroundColor ?? .systemBackground
    }
    scrollEdgeFadeOverlay.configure(fadeColor: fadeColor, fadeWidth: fade.width)
    scrollEdgeFadeOverlay.frame = backgroundHost.bounds
    scrollEdgeFadeOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    backgroundHost.bringSubviewToFront(scrollEdgeFadeOverlay)
    backgroundHost.bringSubviewToFront(collectionView)
    updateScrollEdgeFadeOpacity()
  }

  private func updateScrollEdgeFadeOpacity() {
    let layout = resolvedLayout()
    guard layout.isScrollable, layout.scrollEdgeFade.isEnabled else { return }
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

  private func applyLayoutScrollBehavior() {
    let layout = resolvedLayout()
    collectionView.isScrollEnabled = layout.isScrollable
    let allowsBounce = layout.isScrollable && layout.allowsHorizontalBounce
    collectionView.alwaysBounceHorizontal = allowsBounce
    collectionView.bounces = allowsBounce
    collectionView.clipsToBounds = !layout.isScrollable && layout.nonScrollableOverflowPolicy == .clip
    updateScrollEdgeFadeAppearance()
  }

  private func updateEmptyStatePresentation() {
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

  private func applyConfigurationDomains(
    _ domains: FKTabBarConfigurationApplier.ChangeDomains,
    animated: Bool
  ) {
    if domains.contains(.appearanceBackground) {
      applyBackgroundAppearance()
    }
    if domains.contains(.appearanceIndicator) {
      applyIndicatorAppearance()
    }
    if domains.contains(.appearanceColors) || domains.contains(.appearanceTypography) {
      refreshVisibleCellsForCurrentState()
      if domains.contains(.appearanceTypography) {
        invalidateIntrinsicContentSize()
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
      updateEmptyStatePresentation()
      invalidateLayoutAndRelayout(animatedScroll: animated && resolvedLayout().isSelectionScrollAnimationEnabled)
      refreshVisibleCellsForCurrentState()
      updateIndicatorFrame(animated: animated)
      updateScrollEdgeFadeAppearance()
    }
    if domains.contains(.animation) {
      refreshVisibleCellsForCurrentState()
    }
  }

  private func scrollSelectedIntoView(animated: Bool) {
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

  private func modelForCell(at index: Int, selectionProgress: CGFloat) -> FKTabBarItemCell.Model {
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
      itemInsets: layout.itemInsets,
      isAccessoryExpanded: expandedItemID == item.id
    )
  }

  private func progressForCell(_ index: Int) -> CGFloat {
    guard let from = progressFromIndex, let to = progressToIndex else {
      return index == selectedIndex ? 1 : 0
    }
    if index == from { return 1 - progressValue }
    if index == to { return progressValue }
    return index == selectedIndex ? 1 : 0
  }

  // MARK: - Indicator

  private func indicatorFrameForItem(_ frame: CGRect, referenceIndex: Int) -> CGRect {
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

  private func updateIndicatorFrame(animated: Bool) {
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

  private func refreshVisibleCellsForCurrentState() {
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

  private func refreshCellIfVisible(at index: Int) {
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

  private func captureProgressSnapshotIfNeeded(from: Int, to: Int) {
    // Re-capture only when interaction endpoints change or snapshot is absent.
    // This keeps interpolation deterministic across rapid progress callbacks.
    if progressFromIndex != from || progressToIndex != to || progressSnapshotFromFrame == nil || progressSnapshotToFrame == nil {
      collectionView.layoutIfNeeded()
      progressSnapshotFromFrame = resolvedItemFrame(at: from)
      progressSnapshotToFrame = resolvedItemFrame(at: to)
    }
  }

  private func clearProgressSnapshot() {
    progressSnapshotFromFrame = nil
    progressSnapshotToFrame = nil
  }

  // MARK: - Selection & State

  private func interpolatedProgressRect(from: CGRect, to: CGRect, progress: CGFloat) -> CGRect {
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

  private func resolvedTitlePresentation(
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

  private func resolvedOverflowMode(for layout: FKTabBarLayoutConfiguration) -> FKTabBarTitleOverflowMode {
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

  private func shouldAllowSelection(index: Int, item: FKTabBarItem, reason: SelectionReason) -> Bool {
    guard item.isEnabled else { return false }
    if shouldSelect?(item, index, reason) == false { return false }
    if delegate?.tabBar(self, shouldSelect: item, at: index, reason: reason) == false { return false }
    return true
  }

  private func emitDidSelectIfNeeded(index: Int, item: FKTabBarItem, reason: SelectionReason, notify: Bool) {
    guard notify else { return }
    onSelectionChanged?(item, index, reason)
    delegate?.tabBar(self, didSelect: item, at: index, reason: reason)
  }

  private func emitReselectIfNeeded(index: Int, item: FKTabBarItem, notify: Bool) {
    guard notify else { return }
    onReselect?(item, index)
    delegate?.tabBar(self, didReselect: item, at: index)
  }

  private func triggerHapticsIfNeeded(reason: SelectionReason) {
    guard isHapticFeedbackEnabled, reason == .userTap else { return }
    selectionFeedbackGenerator.selectionChanged()
  }

  // MARK: - Accessibility

  private func updateIndicatorZOrder(for style: FKTabBarIndicatorStyle) {
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

  // MARK: - Private Helpers

  @inline(__always)
  private func assertMainThreadInDebug(file: StaticString = #fileID, line: UInt = #line) {
#if DEBUG
    dispatchPrecondition(condition: .onQueue(.main))
#endif
  }
}

// MARK: - UICollectionViewDataSource

extension FKTabBar: UICollectionViewDataSource {
  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    visibleItems.count
  }

  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FKTabBarItemCell", for: indexPath) as! FKTabBarItemCell
    cell.apply(
      modelForCell(at: indexPath.item, selectionProgress: progressForCell(indexPath.item)),
      customization: customization,
      badgeConfiguration: badgeConfiguration,
      badgeAnimation: badgeAnimation
    )
    cell.onTap = { [weak self, weak cell] button in
      guard let self else { return }
      // Ignore taps if the cell is no longer visible/reused.
      guard let cell, let actualIndexPath = collectionView.indexPath(for: cell) else { return }
      guard let item = self.visibleItems[safe: actualIndexPath.item] else { return }
      self.customization?.animateInteraction(on: button, phase: .tap, item: item)
      self.setSelectedIndex(actualIndexPath.item, animated: true, reason: .userTap)
    }
    cell.onLongPress = { [weak self, weak cell] button in
      guard let self else { return }
      guard self.isLongPressEnabled else { return }
      guard let cell, let actualIndexPath = collectionView.indexPath(for: cell) else { return }
      let index = actualIndexPath.item
      guard let item = self.visibleItems[safe: index] else { return }
      guard item.isEnabled else { return }
      self.customization?.animateInteraction(on: button, phase: .longPress, item: item)
      self.onLongPress?(item, index)
      self.delegate?.tabBar(self, didLongPress: item, at: index)
    }
    return cell
  }

}

// MARK: - UICollectionViewDelegate

extension FKTabBar: UICollectionViewDelegate {
  public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
    // FKButton is the interactive surface, but we still guard collection selection for safety.
    visibleItems[safe: indexPath.item]?.isEnabled ?? false
  }

}

// MARK: - Gesture Handling

extension FKTabBar: UIScrollViewDelegate {
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard scrollView === collectionView else { return }
    // Keep indicator anchored while user manually scrolls the strip without changing selection.
    updateIndicatorFrame(animated: false)
    updateScrollEdgeFadeOpacity()
  }

}

// MARK: - UICollectionViewDelegateFlowLayout

extension FKTabBar: UICollectionViewDelegateFlowLayout {
  public func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let layout = resolvedLayoutForCurrentEnvironment()
    let titlePresentation = resolvedTitlePresentation(layout: layout)
    guard let item = visibleItems[safe: indexPath.item] else {
      let height = max(44, layout.minimumItemHeight)
      return CGSize(width: 44, height: height)
    }
    return FKTabBarItemWidthStrategy.sizeForItem(
      item: item,
      index: indexPath.item,
      visibleItemsCount: visibleItems.count,
      collectionBounds: collectionView.bounds,
      layout: layout,
      appearance: resolvedAppearance(),
      effectiveOverflowMode: titlePresentation.overflowMode,
      maximumTitleLines: titlePresentation.maximumTitleLines,
      shouldIncreaseHeightForLargeText: titlePresentation.shouldIncreaseHeightForLargeText,
      customization: customization,
      tabBar: self
    )
  }

  private func resolvedCustomSpacing(for layout: FKTabBarLayoutConfiguration) -> CGFloat? {
    guard let customization else { return nil }
    let context = FKTabBarLayoutConfiguration.SpacingContext(
      visibleItemsCount: visibleItems.count,
      isScrollable: layout.isScrollable,
      defaultSpacing: layout.itemSpacing
    )
    var values: [CGFloat] = []
    let gapCount = max(0, visibleItems.count - 1)
    if gapCount == 0 { return nil }
    for index in 0..<gapCount {
      if let spacing = customization.customSpacing(after: index, context: context) {
        values.append(max(0, spacing))
      }
    }
    return values.max()
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    minimumLineSpacingForSectionAt section: Int
  ) -> CGFloat {
    let layout = resolvedLayoutForCurrentEnvironment()
    if layout.widthMode == .fillEqually { return 0 }
    if let distribution = contentDistribution(for: layout, in: collectionView.bounds.width), distribution.dynamicSpacing != nil {
      return distribution.dynamicSpacing ?? layout.itemSpacing
    }
    if let customSpacing = resolvedCustomSpacing(for: layout) {
      return customSpacing
    }
    return layout.itemSpacing
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    insetForSectionAt section: Int
  ) -> UIEdgeInsets {
    let layout = resolvedLayoutForCurrentEnvironment()
    if layout.widthMode == .fillEqually {
      return UIEdgeInsets(top: layout.contentInsets.top, left: layout.contentInsets.leading, bottom: layout.contentInsets.bottom, right: layout.contentInsets.trailing)
    }
    if let distribution = contentDistribution(for: layout, in: collectionView.bounds.width) {
      return UIEdgeInsets(
        top: layout.contentInsets.top,
        left: distribution.leadingInset,
        bottom: layout.contentInsets.bottom,
        right: distribution.trailingInset
      )
    }
    return UIEdgeInsets(top: layout.contentInsets.top, left: layout.contentInsets.leading, bottom: layout.contentInsets.bottom, right: layout.contentInsets.trailing)
  }

  private func applySemanticDirection() {
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

  private func invalidateLayoutAndRelayout(animatedScroll: Bool) {
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

  private struct ContentDistribution {
    var leadingInset: CGFloat
    var trailingInset: CGFloat
    var dynamicSpacing: CGFloat?
  }

  private func contentDistribution(for layout: FKTabBarLayoutConfiguration, in containerWidth: CGFloat) -> ContentDistribution? {
    guard !visibleItems.isEmpty else { return nil }
    guard layout.widthMode != .fillEqually else { return nil }
    let itemWidths = (0..<visibleItems.count).map {
      collectionView(
        collectionView,
        layout: collectionView.collectionViewLayout,
        sizeForItemAt: IndexPath(item: $0, section: 0)
      ).width
    }
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
      return distributionFromLogical(logicalLeft: logicalLeftInset, logicalRight: logicalRightInset, direction: direction, spacing: nil)
    case .trailing:
      let logicalLeftInset = baseLeading + extra
      let logicalRightInset = baseTrailing
      return distributionFromLogical(logicalLeft: logicalLeftInset, logicalRight: logicalRightInset, direction: direction, spacing: nil)
    case .center:
      let left = baseLeading + extra * 0.5
      let right = baseTrailing + extra * 0.5
      return distributionFromLogical(logicalLeft: left, logicalRight: right, direction: direction, spacing: nil)
    case .spaceBetween:
      guard visibleItems.count > 1 else {
        return distributionFromLogical(logicalLeft: baseLeading + extra * 0.5, logicalRight: baseTrailing + extra * 0.5, direction: direction, spacing: nil)
      }
      let spacing = baseSpacing + extra / CGFloat(visibleItems.count - 1)
      return distributionFromLogical(logicalLeft: baseLeading, logicalRight: baseTrailing, direction: direction, spacing: spacing)
    case .spaceAround:
      let slot = extra / CGFloat(visibleItems.count)
      let spacing = baseSpacing + slot
      let left = baseLeading + slot * 0.5
      let right = baseTrailing + slot * 0.5
      return distributionFromLogical(logicalLeft: left, logicalRight: right, direction: direction, spacing: spacing)
    case .spaceEvenly:
      let slot = extra / CGFloat(visibleItems.count + 1)
      let spacing = baseSpacing + slot
      let left = baseLeading + slot
      let right = baseTrailing + slot
      return distributionFromLogical(logicalLeft: left, logicalRight: right, direction: direction, spacing: spacing)
    }
  }

  private func distributionFromLogical(
    logicalLeft: CGFloat,
    logicalRight: CGFloat,
    direction: UIUserInterfaceLayoutDirection,
    spacing: CGFloat?
  ) -> ContentDistribution {
    if direction == .rightToLeft {
      return ContentDistribution(
        leadingInset: logicalRight,
        trailingInset: logicalLeft,
        dynamicSpacing: spacing
      )
    }
    return ContentDistribution(
      leadingInset: logicalLeft,
      trailingInset: logicalRight,
      dynamicSpacing: spacing
    )
  }

  private func resolvedFollowMode() -> FKTabBarIndicatorFollowMode {
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

  private func shouldInterpolateIndicatorProgress(for followMode: FKTabBarIndicatorFollowMode) -> Bool {
    switch followMode {
    case .trackContentProgress:
      return true
    case .trackSelectedFrame, .trackContentFrame, .lockedUntilSettle, .custom:
      return false
    }
  }

  private func selectionEvent(for reason: SelectionReason, index: Int) -> FKTabBarSelectionEvent {
    switch reason {
    case .userTap:
      return .userTap(index)
    case .programmatic:
      return .programmatic(index)
    case .interaction:
      return .gestureCommit(index)
    }
  }

}

