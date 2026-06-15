import Foundation

/// Configurable ``FKNetworkReachabilityProviding`` mock for offline UI tests.
public struct FKMockReachability: FKNetworkReachabilityProviding, Sendable {
  /// Current reachability flag.
  public var isReachable: Bool

  /// Creates a reachability mock.
  ///
  /// - Parameter isReachable: Initial connectivity flag (default `true`).
  public init(isReachable: Bool = true) {
    self.isReachable = isReachable
  }
}
