import UIKit

/// Placement of the embedded ``FKTabBar`` relative to the page host.
public enum FKPagingTabBarPosition: Equatable, Sendable {
  /// Tab strip below the safe-area top edge; pages fill the area below the strip.
  case top
  /// Tab strip above the safe-area bottom edge; pages fill the area above the strip.
  ///
  /// Pair with ``FKTabBarPresets/bottomDocked(showsIndicator:)`` when the strip should include home-indicator padding.
  case bottom
}

/// Horizontal navigation direction between page indices.
public enum FKPagingNavigationDirection: Equatable, Sendable {
  /// Toward a higher page index.
  case forward
  /// Toward a lower page index.
  case reverse
}

/// Policy for resolving horizontal pan conflicts with nested scroll views inside pages.
public enum FKPagingNestedHorizontalScrollPolicy: Equatable, Sendable {
  /// Pager pan always evaluates (default).
  case pagerPreferred
  /// Installs ``UIGestureRecognizer/require(toFail:)`` between the pager pan and each horizontally
  /// scrollable view in the settled page subtree so nested carousels can claim the gesture first.
  case preferNestedHorizontalScroll
}

/// Tab strip height policy for the embedded ``FKTabBar`` in ``FKPagingController``.
public enum FKPagingTabBarHeightPolicy: Equatable, Sendable {
  /// Fixed height in points (minimum 36).
  case fixed(CGFloat)
  /// Uses ``FKTabBar/intrinsicContentSize`` height, including Dynamic Type growth.
  case automatic
}

/// Optional placeholder when ``FKPagingController/pageCount`` is zero.
public struct FKPagingEmptyStateConfiguration: Equatable, Sendable {
  /// When `false`, no placeholder is shown for an empty page set.
  public var isEnabled: Bool
  /// Centered message shown when ``FKPagingController/pageCount`` is `0`.
  public var message: String

  public init(isEnabled: Bool = true, message: String = "No pages") {
    self.isEnabled = isEnabled
    self.message = message
  }
}
