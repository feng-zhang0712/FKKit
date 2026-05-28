import Foundation

/// Load-more footer lifecycle for scroll-based base controllers (``FKBaseTableViewController``, ``FKBaseCollectionViewController``).
public enum FKBaseTableLoadMoreState: Equatable {
  case idle
  case loading
  case completed
  case failed
}
