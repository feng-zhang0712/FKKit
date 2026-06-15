import Foundation

/// Foreground presentation options when a notification arrives while the app is active.
public struct FKLocalNotificationPresentationOptions: OptionSet, Sendable, Hashable {
  /// Raw option bitmask.
  public let rawValue: UInt

  /// Creates options from a raw value.
  public init(rawValue: UInt) {
    self.rawValue = rawValue
  }

  /// Show a banner at the top of the screen.
  public static let banner = FKLocalNotificationPresentationOptions(rawValue: 1 << 0)

  /// Show the notification in Notification Center list.
  public static let list = FKLocalNotificationPresentationOptions(rawValue: 1 << 1)

  /// Play the notification sound.
  public static let sound = FKLocalNotificationPresentationOptions(rawValue: 1 << 2)

  /// Update the app icon badge.
  public static let badge = FKLocalNotificationPresentationOptions(rawValue: 1 << 3)

  /// Common foreground presentation: banner, list, and sound.
  public static let standard: FKLocalNotificationPresentationOptions = [.banner, .list, .sound]
}
