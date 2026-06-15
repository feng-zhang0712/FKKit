import Foundation

/// Pluggable contract for `UIApplication.beginBackgroundTask` short-lived background work.
public protocol FKBackgroundWorkExtending: Sendable {
  /// Starts a UIKit background task and returns a token immediately (does not wait for `work`).
  @discardableResult
  func beginBackgroundWork(
    name: String?,
    work: @escaping @Sendable () async -> Void
  ) -> FKBackgroundWorkToken
}
