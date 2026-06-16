import Foundation

#if canImport(UIKit)
import UIKit

/// Reference ``FKDeeplinkRouting`` implementation combining a parser and a handler chain.
///
/// Use for protocol-first apps that do not depend on ``FKBusinessKit`` deeplink registration.
@MainActor
public final class FKPluggableDeeplinkRouter: FKDeeplinkRouting, @unchecked Sendable {
  private let parser: any FKDeeplinkParsing
  private var handlers: [any FKRouteHandling] = []

  /// Creates a router with an injectable parser.
  ///
  /// - Parameter parser: Deeplink parser (default ``FKURLDeeplinkParser``).
  public init(parser: any FKDeeplinkParsing = FKURLDeeplinkParser()) {
    self.parser = parser
  }

  /// Appends a route handler to the dispatch chain (order matters).
  public func register(_ handler: any FKRouteHandling) {
    handlers.append(handler)
  }

  /// Parses `url` and dispatches to the first handler that can handle the context.
  public func open(url: URL) -> FKRouteHandlingResult {
    guard let context = parser.parse(url: url) else {
      return .failed(message: "Parser returned nil for \(url.absoluteString)")
    }
    for handler in handlers where handler.canHandle(context) {
      let result = handler.handle(context)
      if result != .notHandled {
        return result
      }
    }
    return .notHandled
  }
}

#endif
