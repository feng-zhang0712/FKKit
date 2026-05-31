import Foundation

/// Origin of a page switch request handled by ``FKPagingController``.
public enum FKPagingSwitchReason: Equatable, Sendable {
  /// User tapped a tab in the embedded ``FKTabBar``.
  case userTabTap
  /// User completed or attempted an interactive swipe transition.
  case userSwipe
  /// Host called ``FKPagingController/setSelectedIndex(_:animated:)`` or ``FKPagingController/setSelectedIndex(forItemID:animated:)``.
  case programmatic
}

/// Which interaction paths honor ``FKPagingConfiguration/pageSwitchGate`` when it is `.controlled`.
public enum FKPagingPageSwitchGateScope: Equatable, Sendable {
  /// Only tab taps defer commit via ``FKPagingController/commitPageSwitch(to:animated:)`` (legacy default).
  case tabSelectionOnly
  /// Only interactive swipe paging defers commit.
  case swipePagingOnly
  /// Tab taps and swipe paging both defer commit.
  case all
}

/// Behavior when the user re-selects the already active tab.
public enum FKPagingReselectBehavior: Equatable, Sendable {
  /// Forward ``FKTabBarDelegate/tabBar(_:didReselect:at:)`` only.
  case passthrough
  /// Scroll the settled page's primary ``UIScrollView`` to the top when one is found.
  case scrollPageToTop
}
