import Foundation

/// Non-fatal mapping issue collected in lenient mode.
public struct FKMappingWarning: Sendable, Equatable {
  /// Field path related to the warning.
  public let path: String
  /// Human-readable warning message.
  public let message: String

  /// Creates a mapping warning.
  ///
  /// - Parameters:
  ///   - path: Related field path.
  ///   - message: Warning description.
  public init(path: String, message: String) {
    self.path = path
    self.message = message
  }
}

/// Result wrapper for lenient decoding that preserves warnings.
public struct FKMappingResult<Value: Sendable>: Sendable {
  /// Successfully mapped value.
  public let value: Value
  /// Non-fatal warnings collected during mapping.
  public let warnings: [FKMappingWarning]

  /// Creates a mapping result.
  ///
  /// - Parameters:
  ///   - value: Mapped model value.
  ///   - warnings: Collected warnings.
  public init(value: Value, warnings: [FKMappingWarning] = []) {
    self.value = value
    self.warnings = warnings
  }
}
