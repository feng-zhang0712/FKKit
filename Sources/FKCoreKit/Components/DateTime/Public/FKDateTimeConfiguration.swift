import Foundation

/// Calendar, time zone, and locale context applied by ``FKDateTime`` operations.
///
/// Create once (for example `.utc` or an app-default) and reuse so formatting, arithmetic,
/// and relative text stay consistent across call sites.
public struct FKDateTimeConfiguration: Sendable, Equatable, Hashable {
  /// Calendar used for component math and day/week boundaries.
  public var calendar: Calendar

  /// Time zone used for wall-clock interpretation and formatting.
  public var timeZone: TimeZone

  /// Locale used for localized formatters and weekday names.
  public var locale: Locale

  /// Creates a configuration, aligning `calendar.timeZone` / `calendar.locale` with the given values.
  ///
  /// - Parameters:
  ///   - calendar: Base calendar (default: `Calendar.current`).
  ///   - timeZone: Wall-clock time zone (default: `TimeZone.current`).
  ///   - locale: Formatting locale (default: `Locale.current`).
  public init(
    calendar: Calendar = .current,
    timeZone: TimeZone = .current,
    locale: Locale = .current
  ) {
    var aligned = calendar
    aligned.timeZone = timeZone
    aligned.locale = locale
    self.calendar = aligned
    self.timeZone = timeZone
    self.locale = locale
  }

  /// Device-current calendar, time zone, and locale.
  public static var `default`: FKDateTimeConfiguration { FKDateTimeConfiguration() }

  /// Gregorian calendar fixed to UTC with the `en_US_POSIX` locale (ideal for wire formats).
  public static var utc: FKDateTimeConfiguration {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .fk_utc
    calendar.locale = Locale(identifier: "en_US_POSIX")
    return FKDateTimeConfiguration(
      calendar: calendar,
      timeZone: .fk_utc,
      locale: Locale(identifier: "en_US_POSIX")
    )
  }

  /// Returns a copy that uses `timeZone` while preserving calendar identifier and locale.
  public func with(timeZone: TimeZone) -> FKDateTimeConfiguration {
    FKDateTimeConfiguration(calendar: calendar, timeZone: timeZone, locale: locale)
  }

  /// Returns a copy that uses `locale` while preserving calendar identifier and time zone.
  public func with(locale: Locale) -> FKDateTimeConfiguration {
    FKDateTimeConfiguration(calendar: calendar, timeZone: timeZone, locale: locale)
  }

  /// Returns a copy that uses `calendar` (time zone and locale are re-applied from this configuration).
  public func with(calendar: Calendar) -> FKDateTimeConfiguration {
    FKDateTimeConfiguration(calendar: calendar, timeZone: timeZone, locale: locale)
  }
}
