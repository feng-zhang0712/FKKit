import Foundation

/// Standard `userInfo` keys for local notification payloads.
public enum FKLocalNotificationUserInfoKey {
  /// Deeplink URL string routed on notification tap when a router is configured.
  public static let deeplinkURL = "fk.deeplink.url"

  /// Opaque route identifier for host-side routing.
  public static let routeID = "fk.route.id"

  /// Analytics event name fired on notification interaction.
  public static let analyticsEvent = "fk.analytics.event"
}
