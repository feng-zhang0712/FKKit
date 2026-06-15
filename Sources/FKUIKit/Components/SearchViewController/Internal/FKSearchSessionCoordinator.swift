import UIKit

/// Tracks in-flight remote search tasks and stale-result guards.
final class FKSearchSessionCoordinator: @unchecked Sendable {
  private(set) var generation: UInt64 = 0
  private var searchTask: Task<Void, Never>?

  @discardableResult
  func beginSearch() -> UInt64 {
    searchTask?.cancel()
    generation &+= 1
    return generation
  }

  func register(_ task: Task<Void, Never>) {
    searchTask = task
  }

  func cancelAll() {
    searchTask?.cancel()
    searchTask = nil
    generation &+= 1
  }

  func isCurrent(_ token: UInt64) -> Bool {
    token == generation
  }
}
