import Foundation

/// In-memory filter data source for ``FKSearchMode/localFilter``.
@MainActor
public protocol FKSearchLocalFilterProviding: AnyObject {
  /// Full dataset before filtering.
  var baselineSnapshot: FKListSnapshot { get }
  /// Returns a filtered snapshot; `query` is normalized (trimmed) by ``FKSearchBar``.
  func filteredSnapshot(for query: String) -> FKListSnapshot
}
