import Foundation

/// Input model for scheduling a local notification.
///
/// Use stable identifiers such as `{domain}.{feature}.{id}` (for example `order.reminder.12847`).
/// Scheduling with the same identifier replaces any existing pending request with that id.
public struct FKLocalNotificationRequest: Sendable, Hashable {
  /// Unique request identifier; re-scheduling with the same id replaces the pending request.
  public var identifier: String

  /// Notification content.
  public var content: FKLocalNotificationContent

  /// Delivery trigger.
  public var trigger: FKLocalNotificationTrigger

  /// Optional registered category identifier for custom action buttons.
  public var categoryIdentifier: String?

  /// Creates a local notification request.
  public init(
    identifier: String,
    content: FKLocalNotificationContent,
    trigger: FKLocalNotificationTrigger,
    categoryIdentifier: String? = nil
  ) {
    self.identifier = identifier
    self.content = content
    self.trigger = trigger
    self.categoryIdentifier = categoryIdentifier
  }
}

/// Summary of a pending local notification request.
public struct FKLocalNotificationPendingSummary: Sendable, Hashable, Identifiable {
  /// Same as ``identifier``.
  public var id: String { identifier }

  /// Request identifier.
  public let identifier: String

  /// Mapped notification content.
  public let content: FKLocalNotificationContent

  /// Human-readable trigger description.
  public let triggerDescription: String
}

/// Summary of a delivered local notification.
public struct FKLocalNotificationDeliveredSummary: Sendable, Hashable, Identifiable {
  /// Same as ``identifier``.
  public var id: String { identifier }

  /// Request identifier.
  public let identifier: String

  /// Mapped notification content.
  public let content: FKLocalNotificationContent

  /// Delivery date when available.
  public let deliveryDate: Date?
}
