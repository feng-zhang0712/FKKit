import Foundation

/// Protocol describing customizable date formatting behavior.
public protocol FKDateFormattingProviding: Sendable {
  /// Converts a date to a formatted string.
  func string(from date: Date, format: String, timeZone: TimeZone?, locale: Locale?, calendar: Calendar?) -> String
  /// Parses a string into a date using the supplied format.
  func date(from string: String, format: String, timeZone: TimeZone?, locale: Locale?, calendar: Calendar?) -> Date?
  /// Produces a localized relative description.
  func relativeDescription(for date: Date, reference: Date, calendar: Calendar) -> String
  /// Validates a date string against format.
  func isValid(_ text: String, format: String, timeZone: TimeZone?, locale: Locale?, calendar: Calendar?) -> Bool
}

/// Default cached date-formatting implementation.
public struct FKDateFormattingProvider: FKDateFormattingProviding, @unchecked Sendable {
  private let formatterCache = NSCache<NSString, DateFormatter>()

  public init() {}

  public func string(from date: Date, format: String, timeZone: TimeZone?, locale: Locale?, calendar: Calendar?) -> String {
    let formatter = formatter(for: format, timeZone: timeZone, locale: locale, calendar: calendar)
    return formatter.string(from: date)
  }

  public func date(from string: String, format: String, timeZone: TimeZone?, locale: Locale?, calendar: Calendar?) -> Date? {
    let formatter = formatter(for: format, timeZone: timeZone, locale: locale, calendar: calendar)
    return formatter.date(from: string)
  }

  public func relativeDescription(for date: Date, reference: Date, calendar: Calendar) -> String {
    let seconds = Int(reference.timeIntervalSince(date))
    if seconds < 0 {
      return string(from: date, format: "yyyy-MM-dd HH:mm", timeZone: nil, locale: nil, calendar: calendar)
    }
    if seconds < 30 { return FKI18n.string("fkcore.utils.time.just_now") }
    if seconds < 60 { return FKI18n.format("fkcore.utils.time.seconds_ago", seconds) }

    let minutes = seconds / 60
    if minutes < 60 { return FKI18n.format("fkcore.utils.time.minutes_ago", minutes) }

    let hours = minutes / 60
    if hours < 24 { return FKI18n.format("fkcore.utils.time.hours_ago", hours) }
    if calendar.isDateInYesterday(date) { return FKI18n.string("fkcore.utils.time.yesterday") }
    if let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: reference),
       calendar.isDate(date, inSameDayAs: twoDaysAgo) {
      return FKI18n.string("fkcore.utils.time.day_before_yesterday")
    }

    return string(from: date, format: "yyyy-MM-dd", timeZone: nil, locale: nil, calendar: calendar)
  }

  public func isValid(_ text: String, format: String, timeZone: TimeZone?, locale: Locale?, calendar: Calendar?) -> Bool {
    guard let parsed = date(from: text, format: format, timeZone: timeZone, locale: locale, calendar: calendar) else {
      return false
    }
    return string(from: parsed, format: format, timeZone: timeZone, locale: locale, calendar: calendar) == text
  }

  private func formatter(for format: String, timeZone: TimeZone?, locale: Locale?, calendar: Calendar?) -> DateFormatter {
    let calendarIdentifier = calendar.map { String(describing: $0.identifier) } ?? "system"
    let key = "\(format)|\(timeZone?.identifier ?? "system")|\(locale?.identifier ?? "system")|\(calendarIdentifier)" as NSString
    if let cached = formatterCache.object(forKey: key) { return cached }
    let formatter = DateFormatter()
    formatter.dateFormat = format
    formatter.timeZone = timeZone
    formatter.locale = locale
    formatter.calendar = calendar
    formatterCache.setObject(formatter, forKey: key)
    return formatter
  }
}

/// Thread-safe date formatting facade used by `Date` and `String` extensions.
public enum FKDateFormatting {
  private final class ProviderStore: @unchecked Sendable {
    private let lock = NSLock()
    private var provider: FKDateFormattingProviding = FKDateFormattingProvider()

    func set(_ provider: FKDateFormattingProviding) {
      lock.lock()
      defer { lock.unlock() }
      self.provider = provider
    }

    func get() -> FKDateFormattingProviding {
      lock.lock()
      defer { lock.unlock() }
      return provider
    }
  }

  private static let store = ProviderStore()

  /// Replaces the default provider for testing or customization.
  public static func register(provider newProvider: FKDateFormattingProviding) {
    store.set(newProvider)
  }

  static func string(
    from date: Date,
    format: String,
    timeZone: TimeZone? = nil,
    locale: Locale? = nil,
    calendar: Calendar? = nil
  ) -> String {
    store.get().string(from: date, format: format, timeZone: timeZone, locale: locale, calendar: calendar)
  }

  static func date(
    from string: String,
    format: String,
    timeZone: TimeZone? = nil,
    locale: Locale? = nil,
    calendar: Calendar? = nil
  ) -> Date? {
    store.get().date(from: string, format: format, timeZone: timeZone, locale: locale, calendar: calendar)
  }

  static func relativeDescription(for date: Date, reference: Date, calendar: Calendar) -> String {
    store.get().relativeDescription(for: date, reference: reference, calendar: calendar)
  }

  static func isValid(
    _ string: String,
    format: String,
    timeZone: TimeZone? = nil,
    locale: Locale? = nil,
    calendar: Calendar? = nil
  ) -> Bool {
    store.get().isValid(string, format: format, timeZone: timeZone, locale: locale, calendar: calendar)
  }
}
