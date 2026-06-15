#if os(iOS)
import Foundation
@preconcurrency import UserNotifications
import UIKit

enum FKLocalNotificationTriggerMapper {
  /// Minimum interval for repeating time-based triggers (system requirement).
  static let minimumRepeatingInterval: TimeInterval = 60

  static func validate(_ trigger: FKLocalNotificationTrigger) throws {
    switch trigger {
    case let .timeInterval(interval, repeats):
      guard interval > 0 else {
        throw FKLocalNotificationError.invalidTrigger("Time interval must be greater than zero.")
      }
      if repeats, interval < minimumRepeatingInterval {
        throw FKLocalNotificationError.invalidTrigger("Repeating time interval must be at least 60 seconds.")
      }
    case let .calendar(calendarTrigger, _):
      guard hasNonEmptyCalendarComponent(calendarTrigger.dateComponents) else {
        throw FKLocalNotificationError.invalidTrigger("Calendar trigger requires at least one date component.")
      }
    case .immediate:
      break
    }
  }

  static func makeUNTrigger(from trigger: FKLocalNotificationTrigger) throws -> UNNotificationTrigger? {
    switch trigger {
    case let .timeInterval(interval, repeats):
      return UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: repeats)
    case let .calendar(calendarTrigger, repeats):
      var components = calendarTrigger.dateComponents
      components.timeZone = calendarTrigger.timezone
      return UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
    case .immediate:
      return nil
    }
  }

  static func triggerDescription(for trigger: FKLocalNotificationTrigger) -> String {
    switch trigger {
    case let .timeInterval(interval, repeats):
      return "timeInterval(\(interval)s, repeats: \(repeats))"
    case let .calendar(calendarTrigger, repeats):
      return "calendar(\(calendarTrigger.dateComponents), timezone: \(calendarTrigger.timezone.identifier), repeats: \(repeats))"
    case .immediate:
      return "immediate"
    }
  }

  static func triggerDescription(for unTrigger: UNNotificationTrigger?) -> String {
    guard let unTrigger else { return "immediate" }
    if let intervalTrigger = unTrigger as? UNTimeIntervalNotificationTrigger {
      return "timeInterval(\(intervalTrigger.timeInterval)s, repeats: \(intervalTrigger.repeats))"
    }
    if let calendarTrigger = unTrigger as? UNCalendarNotificationTrigger {
      return "calendar(\(calendarTrigger.dateComponents), repeats: \(calendarTrigger.repeats))"
    }
    return String(describing: type(of: unTrigger))
  }

  private static func hasNonEmptyCalendarComponent(_ components: DateComponents) -> Bool {
    let fields: [Int?] = [
      components.era,
      components.year,
      components.month,
      components.day,
      components.hour,
      components.minute,
      components.second,
      components.nanosecond,
      components.weekday,
      components.weekdayOrdinal,
      components.quarter,
      components.weekOfMonth,
      components.weekOfYear,
      components.yearForWeekOfYear,
    ]
    return fields.contains { $0 != nil }
  }
}

#endif
