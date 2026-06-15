import Foundation

/// User interaction response for a delivered local notification.
public struct FKLocalNotificationResponse: Sendable, Equatable {
  /// Identifier of the notification request.
  public let requestIdentifier: String

  /// Selected action identifier (`UNNotificationDefaultActionIdentifier` for default tap).
  public let actionIdentifier: String

  /// String userInfo payload from the notification content.
  public let userInfo: [String: String]

  /// `true` when the user tapped the notification body (default action).
  public let isDefaultAction: Bool

  /// Creates a notification response snapshot.
  public init(
    requestIdentifier: String,
    actionIdentifier: String,
    userInfo: [String: String],
    isDefaultAction: Bool
  ) {
    self.requestIdentifier = requestIdentifier
    self.actionIdentifier = actionIdentifier
    self.userInfo = userInfo
    self.isDefaultAction = isDefaultAction
  }
}

/// Callback invoked when the user interacts with a local notification.
///
/// The manager invokes this handler on the main queue.
public typealias FKLocalNotificationResponseHandler = @Sendable (FKLocalNotificationResponse) -> Void
