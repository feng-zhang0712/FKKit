import Foundation

/// Result returned by ``FKListDataProviding`` fetch methods.
public struct FKListFetchResult: Sendable {
  public var snapshot: FKListSnapshot
  public var hasMorePages: Bool

  public init(snapshot: FKListSnapshot, hasMorePages: Bool) {
    self.snapshot = snapshot
    self.hasMorePages = hasMorePages
  }
}
