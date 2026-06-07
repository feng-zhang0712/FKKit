import Foundation

/// Binary key-value storage boundary (UserDefaults, Keychain, file, or memory).
///
/// Higher-level kits add Codable helpers via ``FKCodableStoring``.
public protocol FKKeyValueStoring: AnyObject, Sendable {
  /// Reads raw data for `key`.
  ///
  /// - Parameter key: Logical storage key.
  /// - Returns: Stored bytes or `nil` when missing.
  /// - Throws: Backend I/O errors.
  func data(forKey key: String) throws -> Data?

  /// Writes or deletes data for `key`. Pass `nil` to remove the entry.
  ///
  /// - Parameters:
  ///   - data: Encoded payload or `nil` to delete.
  ///   - key: Logical storage key.
  func set(_ data: Data?, forKey key: String) throws

  /// Removes the value for `key` if present.
  func remove(forKey key: String) throws

  /// Whether a non-expired value exists for `key`.
  func contains(key: String) -> Bool
}

/// Typed Codable storage built on ``FKKeyValueStoring``.
public protocol FKCodableStoring: FKKeyValueStoring {
  /// Decodes a value when present.
  func value<T: Decodable & Sendable>(forKey key: String, as type: T.Type) throws -> T?

  /// Encodes and stores a value.
  func set<T: Encodable & Sendable>(_ value: T, forKey key: String) throws
}

/// JSON helpers for ``FKCodableStoring`` (nonisolated for Swift 6 call-site flexibility).
public enum FKPluggableJSONCodec: Sendable {
  /// Encodes a value with a default `JSONEncoder`.
  public nonisolated static func encode<T: Encodable>(_ value: T) throws -> Data {
    try JSONEncoder().encode(value)
  }

  /// Decodes a value with a default `JSONDecoder`.
  public nonisolated static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    try JSONDecoder().decode(T.self, from: data)
  }
}

/// Default JSON encode/decode helpers for ``FKCodableStoring`` conformers.
public extension FKCodableStoring {
  /// Decodes using ``FKPluggableJSONCodec``.
  func value<T: Decodable & Sendable>(forKey key: String, as type: T.Type) throws -> T? {
    guard let data = try data(forKey: key) else { return nil }
    return try FKPluggableJSONCodec.decode(type, from: data)
  }

  /// Stores raw bytes without JSON-encoding ``Data`` again.
  ///
  /// Prefer this overload (or ``FKKeyValueStoring/set(_:forKey:)``) when persisting already-encoded payloads.
  func set(_ data: Data, forKey key: String) throws {
    try fk_setKeyValueData(self, data, forKey: key)
  }

  /// Encodes using ``FKPluggableJSONCodec`` and persists the result.
  func set<T: Encodable & Sendable>(_ value: T, forKey key: String) throws {
    if let raw = value as? Data {
      try fk_setKeyValueData(self, raw, forKey: key)
      return
    }
    let data = try FKPluggableJSONCodec.encode(value)
    try fk_setKeyValueData(self, data, forKey: key)
  }
}

// MARK: - Dispatch helpers

/// Calls ``FKKeyValueStoring/set(_:forKey:)`` without resolving to ``FKCodableStoring/set(_:forKey:)``.
///
/// `Data` is `Encodable`, so `set(encodedData, forKey:)` otherwise binds to the generic helper and recurses forever.
private func fk_setKeyValueData(_ storage: FKKeyValueStoring, _ data: Data?, forKey key: String) throws {
  try storage.set(data, forKey: key)
}
