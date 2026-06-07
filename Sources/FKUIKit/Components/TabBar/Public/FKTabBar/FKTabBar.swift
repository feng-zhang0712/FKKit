//
// FKTabBar.swift
//
// Type core: nested types, stored state, initializers, and UIView lifecycle overrides.
// Behavior is split across sibling files in this folder (`FKTabBar+*.swift`) by responsibility.
//

import UIKit

/// High-performance UIKit tab strip backed by `UICollectionView`.
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
/// Contributor note: shipped API sources live under `Public/`; helpers under `Internal/`. See `README.md`.
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
    }
  }

  /// Full input items list before visibility filtering.
  ///
  /// Hidden items remain in this array so hosts can toggle visibility without rebuilding IDs.
  var itemsStorage: [FKTabBarItem] = []
  public var items: [FKTabBarItem] { itemsStorage }
  var manualItems: [FKTabBarItem] = []
  /// Tabs currently laid out in the strip, in order (`isHidden` items excluded).
  var visibleItemsStorage: [FKTabBarItem] = []
  public var visibleItems: [FKTabBarItem] { visibleItemsStorage }

  /// Current selected index.
  var selectedIndexStorage: Int = 0
  public var selectedIndex: Int { selectedIndexStorage }

  /// Current selection phase.
  var switchPhaseStorage: FKTabBarSwitchPhase = .idle
  public var switchPhase: FKTabBarSwitchPhase { switchPhaseStorage }

  /// Read-only selection snapshot for host coordination (paging, analytics).
  public var selectionSnapshot: FKTabBarSelectionSnapshot {
    FKTabBarSelectionSnapshot(
      selectedIndex: snapshot.selectedIndex,
      previousIndex: snapshot.previousIndex,
      phase: snapshot.phase,
      selectedItemID: visibleItems[fk_safe: snapshot.selectedIndex]?.id
    )
  }

  /// Stable identifier of the currently selected visible tab; `nil` when the strip is empty.
  public var selectedItemID: String? {
    visibleItems[fk_safe: selectedIndex]?.id
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
      syncFlowLayoutSpacingProvider()
      refreshVisibleCellsForCurrentState()
    }
  }

  /// Host-owned expansion marker for accessory visuals (for example filter panels). Does not affect selection or layout.
  ///
  /// ``FKTabBar`` does not animate accessories when this changes. Use ``visibleItemAccessoryView(at:)`` in host code.
  public var expandedItemID: String?

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

  var snapshot = FKTabBarSelectionReducerSnapshot(selectedIndex: 0)
  var configurationApplyAnimated = false

  struct PendingVisibleItemsTransition {
    let allItems: [FKTabBarItem]
    let newVisible: [FKTabBarItem]
    let updatePolicy: ItemsUpdatePolicy
    let animated: Bool
    let completion: (() -> Void)?
  }

  var isPerformingVisibleItemsBatchUpdate = false
  var pendingVisibleItemsTransition: PendingVisibleItemsTransition?

  let backgroundHost = UIView()
  let divider = UIView()
  let indicator = FKTabBarIndicatorView()
  let scrollEdgeFadeOverlay = FKTabBarScrollEdgeFadeOverlay()
  let flowLayout = FKTabBarFlowLayout()
  let collectionView: UICollectionView
  let collectionCoordinator = FKTabBarCollectionCoordinator()
  let emptyStateLabel = UILabel()

  var lastLayoutSize: CGSize = .zero
  var progressFromIndex: Int?
  var progressToIndex: Int?
  var progressValue: CGFloat = 0
  var progressSnapshotFromFrame: CGRect?
  var progressSnapshotToFrame: CGRect?
  let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
  var cachedItemSizes: [CGSize] = []

  // MARK: - Lifecycle / Overrides

  public override init(frame: CGRect) {
    flowLayout.scrollDirection = .horizontal
    flowLayout.minimumInteritemSpacing = 0
    flowLayout.minimumLineSpacing = 0
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
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
    let priorConfiguration = self.configuration
    self.configuration = configuration
    let domains = FKTabBarConfigurationApplier.domains(from: priorConfiguration, to: configuration)
    applyConfigurationDomains(domains, animated: false)
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
    let layout = resolvedLayout()
    backgroundHost.frame = bounds
    backgroundHost.clipsToBounds = layout.hostingContext == .navigationBarTitleView
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
      invalidateItemSizeCache()
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
      invalidateItemSizeCache()
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
    return CGSize(width: UIView.noIntrinsicMetric, height: resolvedIntrinsicBarHeight())
  }

  public override func sizeThatFits(_ size: CGSize) -> CGSize {
    assertMainThreadInDebug()
    let layout = resolvedLayoutForCurrentEnvironment()
    if layout.hostingContext == .navigationBarTitleView {
      return navigationBarTitleSizeThatFits(size)
    }
    let height = resolvedIntrinsicBarHeight()
    if size.width > 0 {
      return CGSize(width: size.width, height: height)
    }
    return CGSize(width: bounds.width > 0 ? bounds.width : UIView.noIntrinsicMetric, height: height)
  }

  // MARK: - Setup

  func commonInit() {
    addSubview(backgroundHost)
    backgroundHost.addSubview(collectionView)
    backgroundHost.addSubview(scrollEdgeFadeOverlay)
    backgroundHost.insertSubview(indicator, belowSubview: collectionView)
    addSubview(divider)

    collectionView.backgroundColor = .clear
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.showsVerticalScrollIndicator = false
    collectionView.contentInsetAdjustmentBehavior = .never
    collectionCoordinator.host = self
    collectionView.dataSource = collectionCoordinator
    collectionView.delegate = collectionCoordinator
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
    syncFlowLayoutSpacingProvider()

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
  }
}
