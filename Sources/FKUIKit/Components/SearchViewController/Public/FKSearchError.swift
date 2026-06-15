import Foundation

/// Errors surfaced by ``FKSearchViewController`` remote search flows.
public enum FKSearchError: Error, Sendable, Equatable {
  case providerFailed(String)
  case cancelled
}
