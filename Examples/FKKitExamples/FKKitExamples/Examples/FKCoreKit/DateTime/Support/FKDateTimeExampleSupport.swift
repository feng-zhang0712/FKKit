import Foundation
import FKCoreKit

/// Shared helpers for FKDateTime example scenarios.
enum FKDateTimeExampleSupport {
  /// Formats an optional ``FKDateTime`` for log lines.
  static func describe(_ value: FKDateTime?) -> String {
    guard let value else { return "nil" }
    return "\(value.format(.dateTime)) tz=\(value.configuration.timeZone.identifier)"
  }

  /// Formats ``FKDateTimeDiff`` fields for log lines.
  static func describe(_ diff: FKDateTimeDiff) -> String {
    """
    y=\(diff.years) mo=\(diff.months) d=\(diff.days) h=\(diff.hours) m=\(diff.minutes) s=\(diff.seconds) \
    totalSeconds=\(String(format: "%.3f", diff.totalSeconds)) \
    abs=\(String(format: "%.3f", diff.absoluteTotalSeconds)) \
    +=\(diff.isPositive) -=\(diff.isNegative)
    """
  }

  /// Builds a fixed wall-clock instant relative to `reference` by calendar units.
  static func offset(
    from reference: FKDateTime = .now(),
    years: Int = 0,
    months: Int = 0,
    days: Int = 0,
    hours: Int = 0,
    minutes: Int = 0,
    seconds: Int = 0
  ) -> FKDateTime {
    var components = DateComponents()
    components.year = years
    components.month = months
    components.day = days
    components.hour = hours
    components.minute = minutes
    components.second = seconds
    return reference.adding(components) ?? reference
  }
}
