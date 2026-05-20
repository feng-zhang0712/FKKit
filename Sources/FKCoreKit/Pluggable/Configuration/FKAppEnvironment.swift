import Foundation

/// Deployment environment for build-time or runtime configuration.
public enum FKAppEnvironment: String, Sendable, Hashable, CaseIterable {
  case development
  case staging
  case production

  /// Whether verbose logging and debug menus are typically enabled.
  public var isDebuggable: Bool {
    switch self {
    case .development, .staging:
      return true
    case .production:
      return false
    }
  }
}

/// Supplies environment-specific endpoints and flags.
public protocol FKAppEnvironmentProviding: Sendable {
  /// Active deployment environment.
  var environment: FKAppEnvironment { get }

  /// API base URL for the active environment.
  var apiBaseURL: URL { get }

  /// Optional web base URL (H5, marketing pages).
  var webBaseURL: URL? { get }
}

/// Boolean or multivariate feature flags (local defaults + remote overrides).
public protocol FKFeatureFlagProviding: Sendable {
  /// Returns whether a flag is enabled.
  ///
  /// - Parameter key: Stable flag key.
  /// - Returns: Resolved value; `false` when unknown unless documented otherwise.
  func isEnabled(_ key: String) -> Bool

  /// Returns an optional string payload for multivariate flags.
  func stringValue(for key: String) -> String?
}

/// Fetches remote configuration dictionaries (Firebase Remote Config, internal CMS, etc.).
public protocol FKRemoteConfigProviding: Sendable {
  /// Activates latest remote values.
  func fetch() async throws

  /// Returns a string config value.
  func string(forKey key: String) -> String?

  /// Returns a boolean config value when defined.
  func bool(forKey key: String) -> Bool?
}
