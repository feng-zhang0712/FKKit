import UIKit

/// Where ``FKPagingController`` lays out or publishes its ``FKTabBar``.
public enum FKPagingTabBarPlacement: Equatable, Sendable {
  /// Tab strip inside the paging controller’s view (legacy default).
  case contentArea(FKPagingTabBarPosition)
  /// Tab strip in the resolved host’s ``UINavigationItem/titleView``.
  case navigationBar(FKPagingNavigationBarTabOptions)
  /// Host adds ``FKPagingController/tabBar`` to a custom container; pager does not layout the strip.
  case external

  /// Tab strip below the safe-area top edge inside the paging view.
  public static var contentTop: Self { .contentArea(.top) }

  /// Tab strip above the safe-area bottom edge inside the paging view.
  public static var contentBottom: Self { .contentArea(.bottom) }

  /// Default navigation-bar placement with factory options.
  public static var navigationBar: Self { .navigationBar(.init()) }
}

/// Options for ``FKPagingTabBarPlacement/navigationBar``.
public struct FKPagingNavigationBarTabOptions: Equatable, Sendable {
  /// Horizontal inset subtracted from the navigation-bar title slot width and applied as ``FKTabBar`` leading/trailing content insets.
  public var horizontalInset: CGFloat
  /// Preferred title-view height in points (clamped to 28…44).
  public var preferredHeight: CGFloat
  /// When `true`, clears the host ``UINavigationItem/title`` while the tab strip is active and restores on teardown.
  public var suppressesHostTitle: Bool

  public init(
    horizontalInset: CGFloat = 0,
    preferredHeight: CGFloat = 32,
    suppressesHostTitle: Bool = true
  ) {
    self.horizontalInset = max(0, horizontalInset)
    self.preferredHeight = min(44, max(28, preferredHeight))
    self.suppressesHostTitle = suppressesHostTitle
  }
}

/// Vertical position of the tab strip when ``FKPagingTabBarPlacement`` is ``FKPagingTabBarPlacement/contentArea``.
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
