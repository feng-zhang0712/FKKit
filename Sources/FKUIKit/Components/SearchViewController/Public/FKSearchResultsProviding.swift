import Foundation

/// Async remote search data source for ``FKSearchMode/remote``.
@MainActor
public protocol FKSearchResultsProviding: AnyObject {
  func search(query: String) async throws -> FKSearchResultsResponse
}

/// Payload returned by ``FKSearchResultsProviding/search(query:)``.
public struct FKSearchResultsResponse: Sendable, Equatable {
  public var snapshot: FKListSnapshot
  public var emptyScenario: FKEmptyStateScenario?

  public init(snapshot: FKListSnapshot, emptyScenario: FKEmptyStateScenario? = nil) {
    self.snapshot = snapshot
    self.emptyScenario = emptyScenario
  }
}
