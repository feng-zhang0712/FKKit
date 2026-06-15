import Foundation

/// In-memory ``FKFeatureFlagProviding`` with optional runtime overrides.
public final class FKInMemoryFeatureFlags: FKFeatureFlagProviding, @unchecked Sendable {
  private var boolFlags: [String: Bool]
  private var stringFlags: [String: String]
  private let lock = NSLock()

  /// Creates a feature-flag provider seeded with default tables.
  ///
  /// - Parameters:
  ///   - defaults: Boolean flag defaults; unknown keys resolve to `false`.
  ///   - stringDefaults: Multivariate string payloads; unknown keys resolve to `nil`.
  public init(
    defaults: [String: Bool] = [:],
    stringDefaults: [String: String] = [:]
  ) {
    boolFlags = defaults
    stringFlags = stringDefaults
  }

  /// Returns whether a boolean flag is enabled.
  public func isEnabled(_ key: String) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    return boolFlags[key] ?? false
  }

  /// Returns a multivariate string payload when defined.
  public func stringValue(for key: String) -> String? {
    lock.lock()
    defer { lock.unlock() }
    return stringFlags[key]
  }

  /// Overrides a boolean flag at runtime (reference-implementation extension).
  public func setEnabled(_ enabled: Bool, forKey key: String) {
    lock.lock()
    boolFlags[key] = enabled
    lock.unlock()
  }

  /// Overrides a multivariate string payload at runtime (reference-implementation extension).
  public func setStringValue(_ value: String?, forKey key: String) {
    lock.lock()
    if let value {
      stringFlags[key] = value
    } else {
      stringFlags.removeValue(forKey: key)
    }
    lock.unlock()
  }
}

/// Test-oriented alias for ``FKInMemoryFeatureFlags``.
public typealias FKMockFeatureFlags = FKInMemoryFeatureFlags
