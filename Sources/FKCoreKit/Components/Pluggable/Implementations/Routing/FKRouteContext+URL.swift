import Foundation

public extension FKRouteContext {
  /// Builds a route context from a universal link or custom-scheme URL.
  ///
  /// Path segments exclude leading slashes; query items are flattened to `[String: String]`.
  static func from(url: URL) -> FKRouteContext {
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
