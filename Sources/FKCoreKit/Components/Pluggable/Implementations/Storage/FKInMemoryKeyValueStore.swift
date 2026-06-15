import Foundation

/// Thread-safe in-memory ``FKCodableStoring`` for tests, previews, and Examples.
public final class FKInMemoryKeyValueStore: FKCodableStoring, @unchecked Sendable {
  private var store: [String: Data] = [:]
  private let lock = NSLock()

  /// Creates an empty in-memory store.
  public init() {}

  /// Reads raw bytes for `key`.
  public func data(forKey key: String) throws -> Data? {
    lock.lock()
    defer { lock.unlock() }
    return store[key]
  }

  /// Writes or deletes raw bytes for `key`.
  public func set(_ data: Data?, forKey key: String) throws {
    lock.lock()
    defer { lock.unlock() }
    if let data {
      store[key] = data
    } else {
      store.removeValue(forKey: key)
    }
  }

  /// Removes the value for `key`.
  public func remove(forKey key: String) throws {
    try set(nil, forKey: key)
  }

  /// Whether `key` currently has a value.
  public func contains(key: String) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    return store[key] != nil
  }
}
