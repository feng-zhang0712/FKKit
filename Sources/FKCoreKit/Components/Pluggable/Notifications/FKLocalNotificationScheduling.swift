import Foundation

/// Pluggable contract for local notification scheduling.
///
/// Types live in `LocalNotification/Public/`; this protocol is the DI surface for feature modules.
/// Request notification permission via ``FKPermissions`` before scheduling — this protocol never prompts.
public protocol FKLocalNotificationScheduling: Sendable {
  /// Schedules a single local notification request.
  func schedule(_ request: FKLocalNotificationRequest) async throws

  /// Schedules multiple requests; throws on the first failure.
  func schedule(_ requests: [FKLocalNotificationRequest]) async throws

  /// Cancels a pending notification by identifier.
  func cancelPending(withIdentifier identifier: String) async

  /// Cancels multiple pending notifications by identifier.
  func cancelPending(withIdentifiers identifiers: [String]) async

  /// Cancels all pending local notifications.
  func cancelAllPending() async

  /// Removes a delivered notification from Notification Center by identifier.
  func removeDelivered(withIdentifier identifier: String) async

  /// Removes multiple delivered notifications from Notification Center by identifier.
  func removeDelivered(withIdentifiers identifiers: [String]) async

  /// Removes all delivered notifications from Notification Center.
  func removeAllDelivered() async
}
