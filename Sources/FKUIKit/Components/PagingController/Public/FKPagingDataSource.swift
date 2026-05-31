import UIKit

/// Supplies tab items dynamically for ``FKPagingController``.
///
/// Call ``FKPagingController/reloadFromDataSource(selectedIndex:)`` to refresh tabs and page count.
/// Lazy page construction still uses the pager's `pageProvider`; eager hosts should conform to ``FKPagingEagerDataSource``.
@MainActor
public protocol FKPagingDataSource: AnyObject {
  /// Number of logical pages / data-source tab indices.
  func numberOfPages(in pagingController: FKPagingController) -> Int
  /// Tab model for a data-source index in `[0..<numberOfPages(in:))`.
  func pagingController(_ pagingController: FKPagingController, tabItemAt index: Int) -> FKTabBarItem
}

/// Extends ``FKPagingDataSource`` with eager page construction.
@MainActor
public protocol FKPagingEagerDataSource: FKPagingDataSource {
  /// View controller for a data-source index in `[0..<numberOfPages(in:))`.
  func pagingController(_ pagingController: FKPagingController, viewControllerAt index: Int) -> UIViewController
}
