import UIKit

/// Optional protocol for custom results view controllers used with ``FKSearchResultsPresentationMode/customViewController``.
///
/// ``FKDiffableTableViewController`` subclasses receive snapshot updates directly and do not need this protocol.
@MainActor
public protocol FKSearchResultsDisplaying: AnyObject {
  func applySearchResultsUpdate(
    _ update: FKSearchResultsPresentationUpdate,
    from searchViewController: FKSearchViewController
  )
}
