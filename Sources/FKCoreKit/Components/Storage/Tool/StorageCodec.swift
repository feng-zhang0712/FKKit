import Foundation

// MARK: - StorageCodec (internal)

/// JSON encode/decode helpers for all FKStorage backends (stable key ordering for debugging).
///
/// **Thread safety:** `JSONEncoder` and `JSONDecoder` are not thread-safe. Backends use different serial
/// queues and may call concurrently, so each operation uses a fresh encoder/decoder instance.
enum StorageCodec {
  /// Encodes a value to JSON `Data`.
  ///
  /// - Throws: Rethrows `EncodingError` from `JSONEncoder` (wrapped as ``FKStorageError/encodingFailed`` by callers).
  static func encode<Value: Encodable>(_ value: Value) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return try encoder.encode(value)
  }

  /// Decodes JSON `Data` into `type`.
  ///
  /// - Throws: Rethrows `DecodingError` (wrapped as ``FKStorageError/decodingFailed`` by callers).
  static func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
    try JSONDecoder().decode(type, from: data)
  }
}
