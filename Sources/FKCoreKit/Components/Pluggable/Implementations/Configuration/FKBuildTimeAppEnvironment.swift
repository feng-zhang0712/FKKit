import Foundation

/// Build-time / Info.plist backed ``FKAppEnvironmentProviding`` snapshot.
///
/// Reads custom Info.plist keys:
/// - `FKAppEnvironment` — `development`, `staging`, or `production`
/// - `FKAPIBaseURL` — API base URL string (**required in production**; see fallback below)
/// - `FKWebBaseURL` — optional web/H5 base URL string
///
/// When `FKAppEnvironment` is absent, `#if DEBUG` maps to `.development`; Release maps to `.production`.
/// When `FKAPIBaseURL` is absent, falls back to `https://api.example.com` — configure the plist key
/// before shipping; use ``init(environment:apiBaseURL:webBaseURL:)`` in tests.
public struct FKBuildTimeAppEnvironment: FKAppEnvironmentProviding, Sendable {
  /// Active deployment environment.
  public let environment: FKAppEnvironment
  /// API base URL for the active environment.
  public let apiBaseURL: URL
  /// Optional web base URL.
  public let webBaseURL: URL?

  /// Creates an immutable environment snapshot from an Info.plist dictionary.
  ///
  /// - Parameter plist: Typically `Bundle.main.infoDictionary`.
  public init(plist: [String: Any] = Bundle.main.infoDictionary ?? [:]) {
    environment = Self.resolveEnvironment(from: plist)
    apiBaseURL = Self.resolveURL(from: plist, key: "FKAPIBaseURL")
      ?? URL(string: "https://api.example.com")!
    if let webString = plist["FKWebBaseURL"] as? String, let url = URL(string: webString) {
      webBaseURL = url
    } else {
      webBaseURL = nil
    }
  }

  /// Creates an explicit environment snapshot (tests and Examples).
  public init(environment: FKAppEnvironment, apiBaseURL: URL, webBaseURL: URL? = nil) {
    self.environment = environment
    self.apiBaseURL = apiBaseURL
    self.webBaseURL = webBaseURL
  }

  private static func resolveEnvironment(from plist: [String: Any]) -> FKAppEnvironment {
    if let raw = plist["FKAppEnvironment"] as? String,
       let resolved = FKAppEnvironment(rawValue: raw.lowercased()) {
      return resolved
    }
    #if DEBUG
    return .development
    #else
    return .production
    #endif
  }

  private static func resolveURL(from plist: [String: Any], key: String) -> URL? {
    guard let raw = plist[key] as? String else { return nil }
    return URL(string: raw)
  }
}
