import Foundation

/// Structured mapping failure with field paths and underlying causes.
public enum FKMappingError: Error, Sendable {
  /// JSON payload could not be parsed.
  case invalidJSON(underlying: Error?)
  /// A mapping path is syntactically invalid or cannot be traversed.
  case invalidPath(path: String, reason: String)
  /// Expected key or path segment was missing.
  case keyNotFound(path: String)
  /// Value type does not match expectation at the given path.
  case typeMismatch(path: String, expected: String, actual: String)
  /// Required value was null or empty after normalization.
  case valueNotFound(path: String)
  /// Envelope reported a non-success business code.
  case businessFailure(code: Int, message: String?, payload: Data?)
  /// Codable decoding failed.
  case decodingFailed(underlying: Error, codingPath: [String])
  /// Codable encoding failed.
  case encodingFailed(underlying: Error)
  /// Nested mapping error wrapper.
  indirect case nested(error: FKMappingError)
  /// Security guard rejected oversized or deeply nested payloads.
  case payloadLimitExceeded(reason: String)
}

public extension FKMappingError {
  /// Dot-separated field path when the error is associated with a JSON key or coding path.
  var fieldPath: String? {
    switch self {
    case let .invalidPath(path, _), let .keyNotFound(path), let .typeMismatch(path, _, _), let .valueNotFound(path):
      return path
    case let .decodingFailed(_, codingPath):
      let path = codingPath.joined(separator: ".")
      return path.isEmpty ? nil : path
    case let .nested(error):
      return error.fieldPath
    case .invalidJSON, .businessFailure, .encodingFailed, .payloadLimitExceeded:
      return nil
    }
  }
}

extension FKMappingError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case let .invalidJSON(underlying):
      if let underlying {
        return FKI18n.format("fkcore.mapping.error.invalid_json", underlying.localizedDescription)
      }
      return FKI18n.string("fkcore.mapping.error.invalid_json_generic")
    case let .invalidPath(path, reason):
      return FKI18n.format("fkcore.mapping.error.invalid_path", path, reason)
    case let .keyNotFound(path):
      return FKI18n.format("fkcore.mapping.error.key_not_found", path)
    case let .typeMismatch(path, expected, actual):
      return FKI18n.format("fkcore.mapping.error.type_mismatch", path, expected, actual)
    case let .valueNotFound(path):
      return FKI18n.format("fkcore.mapping.error.value_not_found", path)
    case let .businessFailure(code, message, _):
      return FKI18n.format(
        "fkcore.mapping.error.business_failure",
        code,
        message ?? FKI18n.string("fkcore.mapping.error.unknown_business_message")
      )
    case let .decodingFailed(underlying, codingPath):
      let path = codingPath.joined(separator: ".")
      return FKI18n.format(
        "fkcore.mapping.error.decoding_failed",
        path.isEmpty ? FKI18n.string("fkcore.mapping.error.root_path") : path,
        underlying.localizedDescription
      )
    case let .encodingFailed(underlying):
      return FKI18n.format("fkcore.mapping.error.encoding_failed", underlying.localizedDescription)
    case let .nested(error):
      return error.errorDescription
    case let .payloadLimitExceeded(reason):
      return FKI18n.format("fkcore.mapping.error.payload_limit", reason)
    }
  }
}
