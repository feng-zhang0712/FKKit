import Foundation

public extension Date {
  /// Formats the date with a custom format string.
  func fk_formatted(
    _ format: String,
    timeZone: TimeZone? = nil,
    locale: Locale? = nil,
    calendar: Calendar? = nil
  ) -> String {
    FKDateFormatting.string(from: self, format: format, timeZone: timeZone, locale: locale, calendar: calendar)
  }

  /// Unix timestamp in seconds.
  var fk_unixTimestamp: TimeInterval {
    timeIntervalSince1970
  }

  /// Localized relative time description against `reference`.
  func fk_relativeDescription(reference: Date = Date(), calendar: Calendar = .current) -> String {
    FKDateFormatting.relativeDescription(for: self, reference: reference, calendar: calendar)
  }

  /// Weekday component (1 = Sunday in Gregorian calendar by default).
  func fk_weekday(calendar: Calendar = .current) -> Int {
    calendar.component(.weekday, from: self)
  }

  /// Month component (1...12).
  func fk_month(calendar: Calendar = .current) -> Int {
    calendar.component(.month, from: self)
  }

  /// Compares two dates at the given calendar granularity.
  func fk_compare(
    to other: Date,
    granularity: Calendar.Component = .day,
    calendar: Calendar = .current
  ) -> ComparisonResult {
    calendar.compare(self, to: other, toGranularity: granularity)
  }

  /// Creates a date from a Unix timestamp in seconds.
  init(fk_unixTimestamp timestamp: TimeInterval) {
    self.init(timeIntervalSince1970: timestamp)
  }
}

public extension String {
  /// Parses a date string using the supplied format.
  func fk_toDate(
    format: String,
    timeZone: TimeZone? = nil,
    locale: Locale? = nil,
    calendar: Calendar? = nil
  ) -> Date? {
    FKDateFormatting.date(from: self, format: format, timeZone: timeZone, locale: locale, calendar: calendar)
  }

  /// Returns whether the string is a valid date for the given format (round-trip check).
  func fk_isValidDate(
    format: String,
    timeZone: TimeZone? = nil,
    locale: Locale? = nil,
    calendar: Calendar? = nil
  ) -> Bool {
    FKDateFormatting.isValid(self, format: format, timeZone: timeZone, locale: locale, calendar: calendar)
  }
}
