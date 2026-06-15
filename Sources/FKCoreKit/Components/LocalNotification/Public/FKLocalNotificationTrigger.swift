import Foundation

/// Calendar-based notification trigger with explicit timezone.
public struct FKLocalNotificationCalendarTrigger: Sendable, Hashable {
  /// Date components that define the fire time (at least one non-nil component required).
  public var dateComponents: DateComponents

  /// Timezone used when evaluating calendar components.
  public var timezone: TimeZone

  /// Creates a calendar trigger.
  public init(dateComponents: DateComponents, timezone: TimeZone = .current) {
    self.dateComponents = dateComponents
    self.timezone = timezone
  }
}

/// Typed local notification trigger.
public enum FKLocalNotificationTrigger: Sendable, Hashable {
  /// Fires after a time interval; supports repeating intervals ≥ 60 seconds.
  case timeInterval(TimeInterval, repeats: Bool)

  /// Fires on calendar components in the specified timezone.
  case calendar(FKLocalNotificationCalendarTrigger, repeats: Bool)

  /// Delivers immediately (`UNNotificationRequest` with `trigger: nil`).
  case immediate
}
