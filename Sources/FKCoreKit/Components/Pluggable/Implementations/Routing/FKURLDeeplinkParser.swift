import Foundation

/// Default ``FKDeeplinkParsing`` implementation for HTTP(S) and custom-scheme URLs.
public struct FKURLDeeplinkParser: FKDeeplinkParsing, Sendable {
  /// Creates the default URL parser.
  public init() {}

  /// Parses `url` into ``FKRouteContext`` using path and query components.
  public func parse(url: URL) -> FKRouteContext? {
    FKRouteContext.from(url: url)
  }
}
