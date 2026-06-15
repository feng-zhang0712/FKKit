import Foundation

/// Session persistence and observation failures.
public enum FKPluggableSessionError: LocalizedError, Sendable {
  /// Underlying storage read/write failed.
  case storageFailure(underlying: Error)
  /// Operation requires an authenticated session.
  case notAuthenticated

  /// Localized error description for UI and logging.
  public var errorDescription: String? {
    switch self {
    case let .storageFailure(underlying):
      return FKI18n.format("fkcore.pluggable.error.session.storage_failure", underlying.localizedDescription)
    case .notAuthenticated:
      return FKI18n.string("fkcore.pluggable.error.session.not_authenticated")
    }
  }
}
