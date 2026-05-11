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
  /// interactive pop gesture can evaluate before horizontal paging begins (improves edge-back vs pager conflicts).
  ///
  /// The `edgeWidth` value is reserved for documentation / future refinement; relationship setup is recognizer-level.
  case preferNavigationBackGesture(edgeWidth: CGFloat)
}

/// Tab strip alignment behavior after a page finishes settling.
public enum FKPagingTabAlignment: Equatable {
  /// Respect ``FKTabBar``’s own layout configuration.
  case followTabBarDefault
  /// Force centered selection scrolling after each settled transition (mutates ``FKTabBar/layoutConfiguration``).
  case alwaysCenter
}

/// Runtime configuration for ``FKPagingController``.
public struct FKPagingConfiguration: Equatable {
  /// Height of the embedded ``FKTabBar``.
  public var tabBarHeight: CGFloat
  /// Enables horizontal swipe paging via `UIPageViewController` scroll style.
  public var allowsSwipePaging: Bool
  /// Number of neighbor indices to eagerly instantiate on each side of the selection (lazy mode only).
  public var preloadRange: Int
  /// Cache eviction policy for lazy page construction.
  public var retentionPolicy: FKPagingRetentionPolicy
  /// How the paging pan interacts with sibling recognizers (navigation pop, nested scroll views).
  public var gesturePolicy: FKPagingGesturePolicy
  /// Optional tab alignment override applied when updates commit.
  public var tabAlignment: FKPagingTabAlignment

  public init(
    tabBarHeight: CGFloat = 48,
    allowsSwipePaging: Bool = true,
    preloadRange: Int = 1,
    retentionPolicy: FKPagingRetentionPolicy = .keepNear(distance: 1),
    gesturePolicy: FKPagingGesturePolicy = .preferNavigationBackGesture(edgeWidth: 24),
    tabAlignment: FKPagingTabAlignment = .followTabBarDefault
  ) {
    self.tabBarHeight = max(36, tabBarHeight)
    self.allowsSwipePaging = allowsSwipePaging
    self.preloadRange = max(0, preloadRange)
    self.retentionPolicy = retentionPolicy
    self.gesturePolicy = gesturePolicy
    self.tabAlignment = tabAlignment
  }
}
