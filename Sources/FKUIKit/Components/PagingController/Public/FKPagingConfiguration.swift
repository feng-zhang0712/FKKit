import UIKit

/// Retention strategy for lazily created page view controllers.
public enum FKPagingRetentionPolicy: Equatable {
  /// Retain every instantiated page for the lifetime of the paging controller.
  case keepAll
  /// Retain the selected page and neighbors within `distance` indices.
  case keepNear(distance: Int)
}

/// Gesture arbitration policy for the embedded `UIPageViewController` scroll view.
///
/// - Important: UIKit requires the built-in ``UIScrollView/panGestureRecognizer`` delegate to be the scroll view itself.
///   Policies are therefore implemented with supported APIs (for example ``UIGestureRecognizer/require(toFail:)``), not by replacing that delegate.
public enum FKPagingGesturePolicy: Equatable {
  /// Default interaction: no extra relationships are installed beyond UIKit defaults.
  case exclusive
  /// When embedded in a navigation stack, installs ``UIGestureRecognizer/require(toFail:)`` so the navigation
  /// interactive pop gesture can evaluate before horizontal paging begins.
  ///
  /// `edgeWidth` is retained for API stability; recognizer relationships are installed at the scroll-view level.
  case preferNavigationBackGesture(edgeWidth: CGFloat)
}

/// Tab strip alignment behavior after a page finishes settling.
public enum FKPagingTabAlignment: Equatable {
  /// Respect ``FKTabBar``’s own layout configuration.
  case followTabBarDefault
  /// Force centered selection scrolling after each settled transition (mutates ``FKTabBar/configuration`` layout).
  case alwaysCenter
}

/// Page switch gating policy for tab-driven navigation.
public enum FKPagingPageSwitchGate: Equatable {
  /// Tab taps switch pages immediately.
  case immediate
  /// Tab taps request a switch; host commits via ``FKPagingController/commitPageSwitch(to:animated:)``.
  case controlled
}

/// Runtime configuration for ``FKPagingController``.
public struct FKPagingConfiguration: Equatable {
  /// Height policy for the embedded ``FKTabBar``.
  public var tabBarHeightPolicy: FKPagingTabBarHeightPolicy
  /// Enables horizontal swipe paging via `UIPageViewController` scroll style.
  public var allowsSwipePaging: Bool
  /// Tab-driven page switch gating policy.
  public var pageSwitchGate: FKPagingPageSwitchGate
  /// Interaction paths that honor ``pageSwitchGate`` when it is `.controlled``.
  public var pageSwitchGateScope: FKPagingPageSwitchGateScope
  /// Horizontal spacing between adjacent pages in the embedded `UIPageViewController`.
  ///
  /// - Note: Changing this value after initialization rebuilds the internal page host on the next configuration apply.
  public var interPageSpacing: CGFloat
  /// Number of neighbor indices to eagerly instantiate on each side of the selection (lazy mode only).
  public var preloadRange: Int
  /// Cache eviction policy for lazy page construction.
  public var retentionPolicy: FKPagingRetentionPolicy
  /// How the paging pan interacts with sibling recognizers (navigation pop, nested scroll views).
  public var gesturePolicy: FKPagingGesturePolicy
  /// Optional tab alignment override applied when updates commit.
  public var tabAlignment: FKPagingTabAlignment
  /// Behavior when the active tab is tapped again.
  public var reselectBehavior: FKPagingReselectBehavior
  /// Where the tab strip is laid out relative to the paging controller and navigation chrome.
  public var tabBarPlacement: FKPagingTabBarPlacement
  /// Nested horizontal scroll arbitration policy for page content.
  public var nestedHorizontalScrollPolicy: FKPagingNestedHorizontalScrollPolicy
  /// Placeholder configuration when ``FKPagingController/pageCount`` is zero.
  public var emptyStateConfiguration: FKPagingEmptyStateConfiguration
  /// When `true`, memory warnings compact lazy caches to the selected page only.
  public var evictPagesOnMemoryWarning: Bool
  /// When non-`nil`, returns whether swipe paging is allowed from the given settled page index.
  ///
  /// Ignored when ``allowsSwipePaging`` is `false`. Not compared by ``Equatable`` conformance.
  public var allowsSwipePagingFrom: (@MainActor (Int) -> Bool)?
  /// When non-`nil`, returns whether swipe paging toward ``FKPagingNavigationDirection`` is allowed from `index`.
  ///
  /// Evaluated after ``allowsSwipePagingFrom``. Not compared by ``Equatable`` conformance.
  public var allowsSwipePagingTo: (@MainActor (Int, FKPagingNavigationDirection) -> Bool)?

  public init(
    tabBarHeightPolicy: FKPagingTabBarHeightPolicy = .fixed(48),
    allowsSwipePaging: Bool = true,
    pageSwitchGate: FKPagingPageSwitchGate = .immediate,
    pageSwitchGateScope: FKPagingPageSwitchGateScope = .tabSelectionOnly,
    interPageSpacing: CGFloat = 0,
    preloadRange: Int = 1,
    retentionPolicy: FKPagingRetentionPolicy = .keepNear(distance: 1),
    gesturePolicy: FKPagingGesturePolicy = .preferNavigationBackGesture(edgeWidth: 24),
    tabAlignment: FKPagingTabAlignment = .followTabBarDefault,
    reselectBehavior: FKPagingReselectBehavior = .passthrough,
    tabBarPlacement: FKPagingTabBarPlacement = .contentTop,
    nestedHorizontalScrollPolicy: FKPagingNestedHorizontalScrollPolicy = .pagerPreferred,
    emptyStateConfiguration: FKPagingEmptyStateConfiguration = FKPagingEmptyStateConfiguration(),
    evictPagesOnMemoryWarning: Bool = true,
    allowsSwipePagingFrom: (@MainActor (Int) -> Bool)? = nil,
    allowsSwipePagingTo: (@MainActor (Int, FKPagingNavigationDirection) -> Bool)? = nil
  ) {
    self.tabBarHeightPolicy = tabBarHeightPolicy
    self.allowsSwipePaging = allowsSwipePaging
    self.pageSwitchGate = pageSwitchGate
    self.pageSwitchGateScope = pageSwitchGateScope
    self.interPageSpacing = max(0, interPageSpacing)
    self.preloadRange = max(0, preloadRange)
    self.retentionPolicy = retentionPolicy
    self.gesturePolicy = gesturePolicy
    self.tabAlignment = tabAlignment
    self.reselectBehavior = reselectBehavior
    self.tabBarPlacement = tabBarPlacement
    self.nestedHorizontalScrollPolicy = nestedHorizontalScrollPolicy
    self.emptyStateConfiguration = emptyStateConfiguration
    self.evictPagesOnMemoryWarning = evictPagesOnMemoryWarning
    self.allowsSwipePagingFrom = allowsSwipePagingFrom
    self.allowsSwipePagingTo = allowsSwipePagingTo
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.tabBarHeightPolicy == rhs.tabBarHeightPolicy
      && lhs.allowsSwipePaging == rhs.allowsSwipePaging
      && lhs.pageSwitchGate == rhs.pageSwitchGate
      && lhs.pageSwitchGateScope == rhs.pageSwitchGateScope
      && lhs.interPageSpacing == rhs.interPageSpacing
      && lhs.preloadRange == rhs.preloadRange
      && lhs.retentionPolicy == rhs.retentionPolicy
      && lhs.gesturePolicy == rhs.gesturePolicy
      && lhs.tabAlignment == rhs.tabAlignment
      && lhs.reselectBehavior == rhs.reselectBehavior
      && lhs.tabBarPlacement == rhs.tabBarPlacement
      && lhs.nestedHorizontalScrollPolicy == rhs.nestedHorizontalScrollPolicy
      && lhs.emptyStateConfiguration == rhs.emptyStateConfiguration
      && lhs.evictPagesOnMemoryWarning == rhs.evictPagesOnMemoryWarning
  }
}
