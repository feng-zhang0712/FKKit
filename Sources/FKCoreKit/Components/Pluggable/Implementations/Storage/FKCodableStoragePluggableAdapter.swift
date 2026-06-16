import Foundation

/// Bridges any ``FKCodableStorage`` backend to ``FKCodableStoring`` for Pluggable DI graphs.
///
/// String keys are namespaced with ``keyPrefix`` to avoid collisions with direct Storage usage.
/// TTL writes use ``defaultTTL`` when set; otherwise entries do not expire.
public final class FKCodableStoragePluggableAdapter: FKCodableStoring, @unchecked Sendable {
  private let storage: any FKCodableStorage
  private let keyPrefix: String
  private let defaultTTL: TimeInterval?

  /// Creates an adapter over a Storage-module backend.
  ///
  /// - Parameters:
  ///   - storage: Production or test ``FKCodableStorage`` instance.
  ///   - keyPrefix: Namespace segment prepended to every logical key (default `"pluggable"`).
  ///   - defaultTTL: Optional TTL applied on every write; pass `nil` for non-expiring entries.
  public init(
    storage: any FKCodableStorage,
    keyPrefix: String = "pluggable",
    defaultTTL: TimeInterval? = nil
  ) {
    self.storage = storage
    self.keyPrefix = keyPrefix
    self.defaultTTL = defaultTTL
  }

  /// Reads raw bytes for a namespaced key.
  public func data(forKey key: String) throws -> Data? {
    let storageKey = mappedKey(key)
    guard storage.exists(key: storageKey) else { return nil }
    return try storage.value(key: storageKey, as: Data.self)
  }

  /// Writes or deletes raw bytes for a namespaced key.
  public func set(_ data: Data?, forKey key: String) throws {
    let storageKey = mappedKey(key)
    if let data {
      try storage.set(data, key: storageKey, ttl: defaultTTL)
    } else {
      try storage.remove(key: storageKey)
    }
  }

  /// Removes the value for a namespaced key.
  public func remove(forKey key: String) throws {
    try storage.remove(key: mappedKey(key))
  }

  /// Whether a non-expired value exists for a namespaced key.
  public func contains(key: String) -> Bool {
    storage.exists(key: mappedKey(key))
  }

  private func mappedKey(_ key: String) -> String {
    FKStorageStringKey(namespace: keyPrefix, rawValue: key).fullKey
  }
}
