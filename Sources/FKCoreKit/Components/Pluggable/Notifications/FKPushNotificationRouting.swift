import Foundation

#if canImport(UIKit)
import UIKit

/// Source context for a remote push notification delivery.
public enum FKPushNotificationSource: Sendable {
  /// App is in the foreground when the notification arrives.
  case foreground
  /// App received the notification in background.
  case background
  /// User interacted with the notification (tap or action).
  case userAction
}

/// Pluggable contract for routing remote push payloads into app navigation.
///
/// Host apps parse APNs `userInfo` and delegate deeplink-style navigation here.
/// Pair with ``FKDeeplinkRouting`` when payloads contain URLs.
public protocol FKPushNotificationRouting: Sendable {
  /// Handles a remote notification payload.
  ///
  /// - Parameters:
  ///   - userInfo: APNs payload dictionary.
  ///   - source: Delivery context (foreground, background, or user action).
  /// - Returns: Route handling outcome for UI feedback.
  func handleRemoteNotification(
    userInfo: [AnyHashable: Any],
    source: FKPushNotificationSource
  ) -> FKRouteHandlingResult
}

#endif
