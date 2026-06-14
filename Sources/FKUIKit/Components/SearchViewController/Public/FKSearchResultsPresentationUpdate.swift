import Foundation

/// Unified results-surface update for ``FKSearchResultsDisplaying`` conformers.
public enum FKSearchResultsPresentationUpdate: Sendable, Equatable {
  case idle
  case loading(query: String)
  case results(query: String, snapshot: FKListSnapshot)
  case empty(query: String, scenario: FKEmptyStateScenario)
  case error(query: String, error: FKSearchError)
}
