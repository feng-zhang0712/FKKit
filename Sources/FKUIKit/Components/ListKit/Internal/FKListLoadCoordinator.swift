import Foundation

/// Token-safe coordinator for initial, refresh, and load-more operations.
@MainActor
final class FKListLoadCoordinator {
  enum Operation: Sendable {
    case initial
    case refresh
    case loadMore
  }

  private(set) var hasMorePages = true
  private var tokens: [Operation: UInt64] = [:]

  func begin(_ operation: Operation) -> UInt64 {
    let next = (tokens[operation] ?? 0) &+ 1
    tokens[operation] = next
    if operation == .refresh {
      tokens[.initial] = (tokens[.initial] ?? 0) &+ 1
    }
    return next
  }

  func isCurrent(token: UInt64, for operation: Operation) -> Bool {
    tokens[operation] == token
  }

  func cancel(_ operation: Operation) {
    tokens[operation] = (tokens[operation] ?? 0) &+ 1
  }

  func cancelLoadMore() {
    cancel(.loadMore)
  }

  func updateHasMorePages(_ value: Bool) {
    hasMorePages = value
  }

  func resetPaginationState() {
    hasMorePages = true
  }
}
