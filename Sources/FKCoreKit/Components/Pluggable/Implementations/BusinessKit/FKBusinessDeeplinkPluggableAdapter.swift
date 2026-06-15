import Foundation

#if canImport(UIKit)
import UIKit

/// Bridges Pluggable ``FKDeeplinkRouting`` to ``FKBusinessDeeplinkRouting`` with an optional handler chain.
@MainActor
public final class FKBusinessDeeplinkPluggableAdapter: FKDeeplinkRouting, @unchecked Sendable {
  /// Underlying BusinessKit deeplink router used as fallback dispatch.
  private let router: FKBusinessDeeplinkRouting
  /// Pluggable handlers tried before BusinessKit fallback routing.
  private var handlers: [any FKRouteHandling] = []

  /// Creates an adapter over a BusinessKit deeplink router.
  ///
  /// - Parameter router: BusinessKit router (default shared router).
  public init(router: FKBusinessDeeplinkRouting = FKBusinessKit.shared.deeplink) {
    self.router = router
  }

  /// Registers a Pluggable route handler in the local chain.
  public func register(_ handler: any FKRouteHandling) {
    handlers.append(handler)
  }

  /// Opens a URL through Pluggable handlers, then BusinessKit fallback routing.
  public func open(url: URL) -> FKRouteHandlingResult {
    let context = Self.makeContext(from: url)
    for handler in handlers {
      guard handler.canHandle(context) else { continue }
      let result = handler.handle(context)
      switch result {
      case .handled:
        return .handled
      case .failed(let message):
        return .failed(message: message)
      case .notHandled:
        continue
      }
    }

    return router.route(url, source: .unknown) ? .handled : .notHandled
  }

  private static func makeContext(from url: URL) -> FKRouteContext {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    var queryItems: [String: String] = [:]
    for item in components?.queryItems ?? [] {
      guard let value = item.value else { continue }
      queryItems[item.name] = value
    }
    let pathComponents = url.path.split(separator: "/").map(String.init)
    return FKRouteContext(url: url, pathComponents: pathComponents, queryItems: queryItems)
  }
}

#endif
