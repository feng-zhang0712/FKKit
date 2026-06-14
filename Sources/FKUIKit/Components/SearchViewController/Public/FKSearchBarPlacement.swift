import Foundation

/// Placement of the embedded ``FKSearchBar`` relative to the results list.
public enum FKSearchBarPlacement: Sendable, Equatable {
  /// ``FKSearchBarNavigationHosting`` on `navigationItem.titleView`.
  case navigationBar
  /// Pinned below the navigation bar / safe area; list content scrolls underneath.
  case stickyHeader
  /// Installed as `UITableView.tableHeaderView` with frame-managed sizing.
  case tableHeader
  /// Pinned above the keyboard / home indicator; follows ``UIView/keyboardLayoutGuide`` when the keyboard is visible.
  case stickyFooter
}
