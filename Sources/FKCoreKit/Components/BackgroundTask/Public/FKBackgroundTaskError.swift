import Foundation

/// Stable error classification for background task operations.
public enum FKBackgroundTaskError: Error, Sendable, Equatable {
  /// Schedule attempted for an identifier that was not registered with this manager.
  case unregisteredIdentifier(String)

  /// The same identifier was registered more than once.
  case duplicateRegistration(String)

  /// The identifier is not listed in `BGTaskSchedulerPermittedIdentifiers` or registration failed.
  case identifierNotPermitted(String)

  /// `BGTaskScheduler.submit` failed (too many pending requests, etc.).
  case schedulingFailed(code: Int)

  /// `beginBackgroundTask` is unavailable (non-iOS or no `UIApplication`).
  case backgroundWorkUnavailable

  /// ``FKBackgroundTaskManager/installRegistrations(_:)`` was called more than once.
  case alreadyInstalled

  /// Schedule or cancel attempted before ``FKBackgroundTaskManager/installRegistrations(_:)`` completed.
  case notInstalled
}

extension FKBackgroundTaskError: LocalizedError {
  /// Human-readable description via FKI18n (not for programmatic branching).
  public var errorDescription: String? {
    switch self {
    case let .unregisteredIdentifier(identifier):
      return FKI18n.format("fkcore.background_task.error.unregistered", identifier)
    case let .duplicateRegistration(identifier):
      return FKI18n.format("fkcore.background_task.error.duplicate_registration", identifier)
    case let .identifierNotPermitted(identifier):
      return FKI18n.format("fkcore.background_task.error.not_permitted", identifier)
    case let .schedulingFailed(code):
      return FKI18n.format("fkcore.background_task.error.scheduling_failed", String(code))
    case .backgroundWorkUnavailable:
      return FKI18n.string("fkcore.background_task.error.work_unavailable")
    case .alreadyInstalled:
      return FKI18n.string("fkcore.background_task.error.already_installed")
    case .notInstalled:
      return FKI18n.string("fkcore.background_task.error.not_installed")
    }
  }
}
