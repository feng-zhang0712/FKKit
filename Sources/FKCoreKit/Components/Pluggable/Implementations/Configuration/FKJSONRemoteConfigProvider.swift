import Foundation

/// Configuration for ``FKJSONRemoteConfigProvider``.
public struct FKJSONRemoteConfigConfiguration: Sendable {
  /// Bundled JSON resource name without extension (for example `"remote_config_default"`).
  public var bundleResourceName: String?
  /// Bundle that contains ``bundleResourceName``; defaults to `Bundle.main`.
  public var bundle: Bundle
  /// Optional remote JSON endpoint fetched on ``FKJSONRemoteConfigProvider/fetch()``.
  public var remoteURL: URL?
  /// Timeout for remote fetches.
  public var fetchTimeout: TimeInterval
  /// Optional on-disk cache directory name under Application Support.
  public var cacheDirectoryName: String?

  /// Creates remote-config provider settings.
  public init(
    bundleResourceName: String? = nil,
    bundle: Bundle = .main,
    remoteURL: URL? = nil,
    fetchTimeout: TimeInterval = 30,
    cacheDirectoryName: String? = "FKRemoteConfig"
  ) {
    self.bundleResourceName = bundleResourceName
    self.bundle = bundle
    self.remoteURL = remoteURL
    self.fetchTimeout = fetchTimeout
    self.cacheDirectoryName = cacheDirectoryName
  }
}

/// Lightweight JSON-backed ``FKRemoteConfigProviding`` for bundled defaults and optional HTTP refresh.
public final class FKJSONRemoteConfigProvider: FKRemoteConfigProviding, @unchecked Sendable {
  private let configuration: FKJSONRemoteConfigConfiguration
  private var snapshot: [String: String] = [:]
  private let lock = NSLock()
  private let session: URLSession

  /// Creates a provider and loads bundled defaults when configured.
  ///
  /// When ``FKJSONRemoteConfigConfiguration/bundleResourceName`` is set, bundled JSON is loaded
  /// synchronously. A missing resource or invalid JSON is **ignored** (snapshot stays empty for
  /// that source) — verify the resource name and bundle in development.
  ///
  /// - Parameter configuration: Data sources and fetch behavior.
  public init(configuration: FKJSONRemoteConfigConfiguration) {
    self.configuration = configuration
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = configuration.fetchTimeout
    session = URLSession(configuration: config)
    if let name = configuration.bundleResourceName {
      try? loadBundledDefaults(resourceName: name)
    }
  }

  /// Fetches remote JSON when ``FKJSONRemoteConfigConfiguration/remoteURL`` is set and activates the merged snapshot.
  public func fetch() async throws {
    guard let remoteURL = configuration.remoteURL else {
      throw FKRemoteConfigError.missingSource
    }
    var request = URLRequest(url: remoteURL)
    request.timeoutInterval = configuration.fetchTimeout
    let data: Data
    do {
      (data, _) = try await session.data(for: request)
    } catch {
      throw FKRemoteConfigError.fetchFailed(underlying: error)
    }
    let merged = try parsePayload(data)
    applyMergedSnapshot(merged)
    try persistCache(data)
  }

  private func applyMergedSnapshot(_ merged: [String: String]) {
    lock.lock()
    snapshot.merge(merged) { _, new in new }
    lock.unlock()
  }

  /// Returns a string config value from the active snapshot.
  public func string(forKey key: String) -> String? {
    lock.lock()
    defer { lock.unlock() }
    return snapshot[key]
  }

  /// Returns a boolean config value when the snapshot entry can be parsed.
  ///
  /// Parsing uses NSString rules: `"true"`, `"yes"`, and `"1"` (case insensitive) are `true`;
  /// `"false"`, `"0"`, and other strings are `false`.
  public func bool(forKey key: String) -> Bool? {
    guard let raw = string(forKey: key) else { return nil }
    return (raw as NSString).boolValue
  }

  private func loadBundledDefaults(resourceName: String) throws {
    guard let url = configuration.bundle.url(forResource: resourceName, withExtension: "json") else {
      throw FKRemoteConfigError.missingSource
    }
    let data = try Data(contentsOf: url)
    let parsed = try parsePayload(data)
    lock.lock()
    snapshot.merge(parsed) { _, new in new }
    lock.unlock()
  }

  private func parsePayload(_ data: Data) throws -> [String: String] {
    let object = try JSONSerialization.jsonObject(with: data)
    guard let dictionary = object as? [String: Any] else {
      throw FKRemoteConfigError.invalidPayload
    }
    var result: [String: String] = [:]
    for (key, value) in dictionary {
      switch value {
      case let string as String:
        result[key] = string
      case let number as NSNumber:
        result[key] = number.stringValue
      case let bool as Bool:
        result[key] = bool ? "true" : "false"
      default:
        continue
      }
    }
    return result
  }

  private func persistCache(_ data: Data) throws {
    guard let directoryName = configuration.cacheDirectoryName else { return }
    let storage = try FKFileStorage(directoryName: directoryName)
    try storage.set(data, key: "remote_config.snapshot")
  }
}
