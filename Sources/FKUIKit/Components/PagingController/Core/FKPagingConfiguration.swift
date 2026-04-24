import UIKit

/// Controller retention strategy for page instances.
public enum FKPagingRetentionPolicy: Equatable {
  /// Keep every created page alive.
  case keepAll
  /// Keep selected page and neighbors in the configured distance.
  case keepNear(distance: Int)
}

/// Gesture conflict policy for paging pan gesture.
public enum FKPagingGesturePolicy: Equatable {
  /// Paging gesture is exclusive.
  case exclusive
  /// Allow simultaneous recognition with sibling gestures.
  case allowSimultaneous
  /// Prioritize navigation back gesture near leading edge.
  case preferNavigationBackGesture(edgeWidth: CGFloat)
}

/// Scroll alignment strategy for tab after page settlement.
public enum FKPagingTabAlignment: Equatable {
  case followTabBarDefault
  case alwaysCenter
}

/// Runtime options for `FKPagingController`.
public struct FKPagingConfiguration: Equatable {
  /// Header height.
  public var tabBarHeight: CGFloat
  /// Whether swipe gesture is enabled.
  public var allowsSwipePaging: Bool
  /// Number of neighbors preloaded around the selected index.
  public var preloadRange: Int
  /// Retention policy for created pages.
  public var retentionPolicy: FKPagingRetentionPolicy
  /// Gesture conflict behavior.
  public var gesturePolicy: FKPagingGesturePolicy
  /// Alignment policy applied when transition settles.
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
