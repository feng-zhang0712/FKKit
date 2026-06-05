import Foundation

/// Parsed deep link or in-app route payload passed to handlers.
public struct FKRouteContext: Sendable, Hashable {
  /// Original URL when routing started from a link.
  public var url: URL?
  /// Matched path segments (for example `["product", "42"]`).
  public var pathComponents: [String]
  /// Query parameters.
  public var queryItems: [String: String]
  /// Arbitrary user info attached by parsers.
  public var userInfo: [String: String]

  /// Creates a route context.
  public init(
    url: URL? = nil,
    pathComponents: [String] = [],
    queryItems: [String: String] = [:],
    userInfo: [String: String] = [:]
  ) {
    self.url = url
    self.pathComponents = pathComponents
    self.queryItems = queryItems
    self.userInfo = userInfo
  }
}

/// Result of attempting to handle a route.
public enum FKRouteHandlingResult: Sendable, Equatable {
  /// Handler consumed the route.
  case handled
  /// Handler declined; router should try the next handler.
  case notHandled
  /// Handler failed; router may surface an error UI.
  case failed(message: String)
}
