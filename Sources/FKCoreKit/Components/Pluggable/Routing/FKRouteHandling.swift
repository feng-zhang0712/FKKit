import Foundation

/// Parses URLs into ``FKRouteContext`` values.
public protocol FKDeeplinkParsing: Sendable {
  /// Attempts to parse `url` into a route context.
  ///
  /// - Parameter url: Incoming universal link or custom scheme URL.
  /// - Returns: Parsed context or `nil` when the URL is not supported.
  func parse(url: URL) -> FKRouteContext?
}

/// Handles a single route pattern (host/path) in a pluggable router chain.
///
/// Register multiple handlers; the router dispatches until one returns `.handled`.
public protocol FKRouteHandling: Sendable {
  /// Stable handler name for logging.
  var routeHandlerName: String { get }

  /// Whether this handler can process `context`.
  func canHandle(_ context: FKRouteContext) -> Bool

  /// Performs navigation or side effects for `context`.
  ///
  /// - Parameter context: Parsed route payload.
  /// - Returns: Handling result for the dispatcher.
  @MainActor
  func handle(_ context: FKRouteContext) -> FKRouteHandlingResult
}

/// Coordinates deep link parsing and handler dispatch.
@MainActor
public protocol FKDeeplinkRouting: AnyObject, Sendable {
  /// Registers a route handler.
  func register(_ handler: any FKRouteHandling)

  /// Opens a URL through the parser + handler chain.
  @MainActor
  func open(url: URL) -> FKRouteHandlingResult
}
