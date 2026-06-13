import UIKit

// MARK: - Data providing

/// Optional ergonomic data layer; when set, list controllers wire refresh and load-more automatically.
@MainActor
public protocol FKListDataProviding: AnyObject {
  func fetchInitial(page: Int) async throws -> FKListFetchResult
  func fetchNextPage(after pagination: FKRefreshPagination) async throws -> FKListFetchResult
  func fetchRefresh(page: Int) async throws -> FKListFetchResult
}

// MARK: - Delegate

/// Lifecycle and interaction callbacks for table list controllers.
@MainActor
public protocol FKListDelegate: AnyObject {
  func list(_ list: FKDiffableTableViewController, willRefresh context: FKRefreshActionContext)
  func list(_ list: FKDiffableTableViewController, didRefresh success: Bool)
  func list(_ list: FKDiffableTableViewController, willLoadPage page: Int)
  func list(_ list: FKDiffableTableViewController, didLoadPage page: Int, result: FKListFetchResult)
  func list(_ list: FKDiffableTableViewController, didReachEnd: Void)
  func list(_ list: FKDiffableTableViewController, didSelect item: FKListItemID)
  func list(_ list: FKDiffableTableViewController, didDeselect item: FKListItemID)
  func list(_ list: FKDiffableTableViewController, presentationStateChanged state: FKListPresentationState)
  func list(_ list: FKDiffableTableViewController, prefetchItems ids: [FKListItemID])
  func list(_ list: FKDiffableTableViewController, cancelPrefetching ids: [FKListItemID])
}

public extension FKListDelegate {
  func list(_ list: FKDiffableTableViewController, willRefresh context: FKRefreshActionContext) {}
  func list(_ list: FKDiffableTableViewController, didRefresh success: Bool) {}
  func list(_ list: FKDiffableTableViewController, willLoadPage page: Int) {}
  func list(_ list: FKDiffableTableViewController, didLoadPage page: Int, result: FKListFetchResult) {}
  func list(_ list: FKDiffableTableViewController, didReachEnd: Void) {}
  func list(_ list: FKDiffableTableViewController, didSelect item: FKListItemID) {}
  func list(_ list: FKDiffableTableViewController, didDeselect item: FKListItemID) {}
  func list(_ list: FKDiffableTableViewController, presentationStateChanged state: FKListPresentationState) {}
  func list(_ list: FKDiffableTableViewController, prefetchItems ids: [FKListItemID]) {}
  func list(_ list: FKDiffableTableViewController, cancelPrefetching ids: [FKListItemID]) {}
}

// MARK: - Collection delegate

/// Lifecycle and interaction callbacks for collection list controllers.
@MainActor
public protocol FKListCollectionDelegate: AnyObject {
  func list(_ list: FKDiffableCollectionViewController, willRefresh context: FKRefreshActionContext)
  func list(_ list: FKDiffableCollectionViewController, didRefresh success: Bool)
  func list(_ list: FKDiffableCollectionViewController, willLoadPage page: Int)
  func list(_ list: FKDiffableCollectionViewController, didLoadPage page: Int, result: FKListFetchResult)
  func list(_ list: FKDiffableCollectionViewController, didReachEnd: Void)
  func list(_ list: FKDiffableCollectionViewController, didSelect item: FKListItemID)
  func list(_ list: FKDiffableCollectionViewController, didDeselect item: FKListItemID)
  func list(_ list: FKDiffableCollectionViewController, presentationStateChanged state: FKListPresentationState)
  func list(_ list: FKDiffableCollectionViewController, prefetchItems ids: [FKListItemID])
  func list(_ list: FKDiffableCollectionViewController, cancelPrefetching ids: [FKListItemID])
}

public extension FKListCollectionDelegate {
  func list(_ list: FKDiffableCollectionViewController, willRefresh context: FKRefreshActionContext) {}
  func list(_ list: FKDiffableCollectionViewController, didRefresh success: Bool) {}
  func list(_ list: FKDiffableCollectionViewController, willLoadPage page: Int) {}
  func list(_ list: FKDiffableCollectionViewController, didLoadPage page: Int, result: FKListFetchResult) {}
  func list(_ list: FKDiffableCollectionViewController, didReachEnd: Void) {}
  func list(_ list: FKDiffableCollectionViewController, didSelect item: FKListItemID) {}
  func list(_ list: FKDiffableCollectionViewController, didDeselect item: FKListItemID) {}
  func list(_ list: FKDiffableCollectionViewController, presentationStateChanged state: FKListPresentationState) {}
  func list(_ list: FKDiffableCollectionViewController, prefetchItems ids: [FKListItemID]) {}
  func list(_ list: FKDiffableCollectionViewController, cancelPrefetching ids: [FKListItemID]) {}
}
