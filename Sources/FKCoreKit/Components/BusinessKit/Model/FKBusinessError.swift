import Foundation

/// A unified error type for FKBusinessKit.
public enum FKBusinessError: LocalizedError, Equatable, Sendable {
  /// The input is invalid.
  case invalidArgument(String)

  /// A required configuration is missing.
  case missingConfiguration(String)

  /// The requested operation is not supported in current environment.
  case unsupported(String)

  /// A network request failed.
  case networkFailed(underlying: String)

  /// A persistence operation failed.
  case persistenceFailed(underlying: String)

  /// A task was cancelled.
  case cancelled

  /// An unknown error occurred.
  case unknown(String)

  /// Human-readable error description for logging and UI fallback usage.
  public var errorDescription: String? {
    switch self {
    case let .invalidArgument(reason):
      return FKI18n.format("fkcore.business.error.invalid_argument", reason)
    case let .missingConfiguration(reason):
      return FKI18n.format("fkcore.business.error.missing_configuration", reason)
    case let .unsupported(reason):
      return FKI18n.format("fkcore.business.error.unsupported", reason)
    case let .networkFailed(underlying):
      return FKI18n.format("fkcore.business.error.network_failed", underlying)
    case let .persistenceFailed(underlying):
      return FKI18n.format("fkcore.business.error.persistence_failed", underlying)
    case .cancelled:
      return FKI18n.string("fkcore.business.error.cancelled")
    case let .unknown(reason):
      return FKI18n.format("fkcore.business.error.unknown", reason)
    }
  }
}

