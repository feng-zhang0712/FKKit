import Foundation

/// High-level search page UI state for ``FKSearchViewController``.
public enum FKSearchPresentationState: Sendable, Equatable {
  case idle
  case editing
  case loading(query: String)
  case results(query: String, itemCount: Int)
  case empty(query: String, scenario: FKEmptyStateScenario)
  case error(query: String, error: FKSearchError)
}
