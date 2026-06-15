import Foundation

/// Stable error classification for local notification operations.
public enum FKLocalNotificationError: Error, Sendable, Equatable {
  /// Notification permission is not granted; request via ``FKPermissions`` first.
  case notAuthorized

  /// Trigger parameters are invalid (interval, calendar components, or repeat rules).
  case invalidTrigger(String)

  /// Content parameters are invalid (empty title and body, etc.).
  case invalidContent(String)

  /// Attachment is unavailable (reserved for v1.1 attachment support).
  case attachmentUnavailable(String)

  /// Underlying `UserNotifications` framework error.
  case systemError(String)

  /// App icon badge update failed.
  case badgeUpdateFailed
}

extension FKLocalNotificationError: LocalizedError {
  /// Human-readable description via FKI18n (not for programmatic branching).
  public var errorDescription: String? {
    switch self {
    case .notAuthorized:
      return FKI18n.string("fkcore.local_notification.error.not_authorized")
    case let .invalidTrigger(message):
      return FKI18n.format("fkcore.local_notification.error.invalid_trigger", message)
    case let .invalidContent(message):
      return FKI18n.format("fkcore.local_notification.error.invalid_content", message)
    case let .attachmentUnavailable(message):
      return FKI18n.format("fkcore.local_notification.error.attachment_unavailable", message)
    case let .systemError(message):
      return FKI18n.format("fkcore.local_notification.error.system", message)
    case .badgeUpdateFailed:
      return FKI18n.string("fkcore.local_notification.error.badge_update_failed")
    }
  }
}
