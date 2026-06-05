import Foundation
import Security

/// Unified error type for FKSecurity operations.
public enum FKSecurityError: Error, Sendable, Equatable {
  /// Input data is invalid for the requested operation.
  case invalidInput(String)
  /// A required key or IV is missing or has an invalid length.
  case invalidKey(String)
  /// Cryptographic operation failed with a platform status code.
  case cryptoFailed(status: Int32, message: String)
  /// Security framework operation failed with an OSStatus code.
  case securityFailed(status: OSStatus, message: String)
  /// Key material is not available in Keychain or memory.
  case keyNotFound(String)
  /// File operation failed.
  case fileFailed(String)
  /// Feature is unavailable on the current OS/runtime.
  case unavailable(String)
  /// Unknown wrapped error message.
  case unknown(String)
}

extension FKSecurityError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case let .invalidInput(message):
      return FKI18n.format("fkcore.security.error.invalid_input", message)
    case let .invalidKey(message):
      return FKI18n.format("fkcore.security.error.invalid_key", message)
    case let .cryptoFailed(status, message):
      return FKI18n.format("fkcore.security.error.crypto_failed", status, message)
    case let .securityFailed(status, message):
      return FKI18n.format("fkcore.security.error.security_failed", status, message)
    case let .keyNotFound(message):
      return FKI18n.format("fkcore.security.error.key_not_found", message)
    case let .fileFailed(message):
      return FKI18n.format("fkcore.security.error.file_failed", message)
    case let .unavailable(message):
      return FKI18n.format("fkcore.security.error.unavailable", message)
    case let .unknown(message):
      return FKI18n.format("fkcore.security.error.unknown", message)
    }
  }
}

