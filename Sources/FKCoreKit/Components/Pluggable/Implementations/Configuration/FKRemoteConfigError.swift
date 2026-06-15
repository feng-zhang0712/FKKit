import Foundation

/// Errors thrown by ``FKJSONRemoteConfigProvider``.
public enum FKRemoteConfigError: LocalizedError, Sendable {
  /// No bundle resource or remote URL was configured.
  case missingSource
  /// Network or I/O failure while fetching remote config.
  case fetchFailed(underlying: Error)
  /// Parsed JSON was not a string-keyed object.
  case invalidPayload

  /// Localized error description for UI and logging.
  public var errorDescription: String? {
    switch self {
    case .missingSource:
      return FKI18n.string("fkcore.pluggable.error.remote_config.missing_source")
    case let .fetchFailed(underlying):
      return FKI18n.format("fkcore.pluggable.error.remote_config.fetch_failed", underlying.localizedDescription)
    case .invalidPayload:
      return FKI18n.string("fkcore.pluggable.error.remote_config.invalid_payload")
    }
  }
}
