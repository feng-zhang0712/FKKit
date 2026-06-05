import Foundation

/// Default implementation of ``FKBusinessTimeFormatting``.
public final class FKBusinessTimeFormatter: FKBusinessTimeFormatting, @unchecked Sendable {
  /// Returns current language code used for localized relative text.
  private let languageCodeProvider: () -> String
  /// Cache for date formatters keyed by format and locale.
  private let formatterCache = NSCache<NSString, DateFormatter>()

  /// Creates time formatter helper.
  ///
  /// - Parameter languageCodeProvider: Closure providing current language code.
  public init(languageCodeProvider: @escaping () -> String) {
    self.languageCodeProvider = languageCodeProvider
  }

  /// Formats date using custom pattern and locale.
  ///
  /// - Parameters:
  ///   - date: Target date.
  ///   - format: Date format string.
  ///   - locale: Optional locale override.
  /// - Returns: Formatted date text.
  public func format(date: Date, format: String, locale: Locale? = nil) -> String {
    let key = "\(format)|\(locale?.identifier ?? languageCodeProvider())" as NSString
    let formatter: DateFormatter
    if let cached = formatterCache.object(forKey: key) {
      formatter = cached
    } else {
      let f = DateFormatter()
      f.dateFormat = format
      f.locale = locale ?? Locale(identifier: languageCodeProvider())
      formatterCache.setObject(f, forKey: key)
      formatter = f
    }
    return formatter.string(from: date)
  }

  /// Produces relative time description for business-facing UI.
  ///
  /// - Parameters:
  ///   - date: Source date.
  ///   - now: Reference date.
  /// - Returns: Relative time description.
  public func relativeDescription(from date: Date, now: Date = Date()) -> String {
    let seconds = Int(now.timeIntervalSince(date))
    if seconds < 0 { return format(date: date, format: "yyyy-MM-dd HH:mm", locale: nil) }
    if seconds < 30 { return FKI18n.string("fkcore.business.time.just_now") }
    if seconds < 60 { return FKI18n.format("fkcore.business.time.seconds_ago", seconds) }
    let minutes = seconds / 60
    if minutes < 60 { return FKI18n.format("fkcore.business.time.minutes_ago", minutes) }
    let hours = minutes / 60
    let calendar = Calendar.current
    if calendar.isDateInToday(date) {
      return FKI18n.format("fkcore.business.time.today_at", format(date: date, format: "HH:mm", locale: nil))
    }
    if calendar.isDateInYesterday(date) {
      return FKI18n.format("fkcore.business.time.yesterday_at", format(date: date, format: "HH:mm", locale: nil))
    }
    if hours < 24 * 7 {
      return format(date: date, format: "MM-dd HH:mm", locale: nil)
    }
    return format(date: date, format: "yyyy-MM-dd", locale: nil)
  }
}

