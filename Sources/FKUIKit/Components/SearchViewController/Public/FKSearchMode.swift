import Foundation

/// Search data source strategy for ``FKSearchViewController``.
public enum FKSearchMode: Sendable, Equatable {
  /// Filters an in-memory baseline snapshot via ``FKSearchLocalFilterProviding``.
  case localFilter
  /// Performs async queries via ``FKSearchResultsProviding`` (network, database, etc.).
  case remote
}
