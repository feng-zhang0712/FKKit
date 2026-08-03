import Foundation

/// Thread-safe cached `DateFormatter` helpers for ``FKDateTime``.
///
/// Formatters are mutable and not `Sendable`; access is serialized by an internal lock
/// inside an `@unchecked Sendable` store (same pattern as ``FKDateFormattingProvider``).
enum FKDateTimeFormatting {
  private final class Store: @unchecked Sendable {
    let lock = NSLock()
    let patternCache = NSCache<NSString, DateFormatter>()
    let styleCache = NSCache<NSString, DateFormatter>()
    let templateCache = NSCache<NSString, DateFormatter>()
  }

  private static let store = Store()

  static func string(
    from date: Date,
    format: String,
    configuration: FKDateTimeConfiguration
  ) -> String {
    store.lock.lock()
    defer { store.lock.unlock() }
    return formatterLocked(format: format, configuration: configuration).string(from: date)
  }

  static func date(
    from string: String,
    format: String,
    configuration: FKDateTimeConfiguration
  ) -> Date? {
    store.lock.lock()
    defer { store.lock.unlock() }
    return formatterLocked(format: format, configuration: configuration).date(from: string)
  }

  static func string(
    from date: Date,
    dateStyle: DateFormatter.Style,
    timeStyle: DateFormatter.Style,
    configuration: FKDateTimeConfiguration
  ) -> String {
    store.lock.lock()
    defer { store.lock.unlock() }
    return styleFormatterLocked(
      dateStyle: dateStyle,
      timeStyle: timeStyle,
      configuration: configuration
    ).string(from: date)
  }

  static func string(
    from date: Date,
    template: String,
    configuration: FKDateTimeConfiguration
  ) -> String {
    store.lock.lock()
    defer { store.lock.unlock() }
    return templateFormatterLocked(template: template, configuration: configuration).string(from: date)
  }

  static func durationString(
    from start: Date,
    to end: Date,
    allowedUnits: NSCalendar.Unit,
    unitsStyle: DateComponentsFormatter.UnitsStyle,
    maximumUnitCount: Int,
    locale: Locale,
    calendar: Calendar
  ) -> String? {
    var alignedCalendar = calendar
    alignedCalendar.locale = locale
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = allowedUnits
    formatter.unitsStyle = unitsStyle
    formatter.maximumUnitCount = maximumUnitCount
    formatter.calendar = alignedCalendar
    // Absolute span length; order of endpoints does not matter.
    return formatter.string(from: abs(end.timeIntervalSince(start)))
  }

  /// Caller must hold `store.lock`.
  private static func formatterLocked(
    format: String,
    configuration: FKDateTimeConfiguration
  ) -> DateFormatter {
    let key = cacheKey(
      format,
      configuration.timeZone.identifier,
      configuration.locale.identifier,
      String(describing: configuration.calendar.identifier)
    )
    if let cached = store.patternCache.object(forKey: key) {
      return cached
    }
    let formatter = DateFormatter()
    formatter.locale = configuration.locale
    formatter.timeZone = configuration.timeZone
    formatter.calendar = configuration.calendar
    formatter.dateFormat = format
    store.patternCache.setObject(formatter, forKey: key)
    return formatter
  }

  /// Caller must hold `store.lock`.
  private static func styleFormatterLocked(
    dateStyle: DateFormatter.Style,
    timeStyle: DateFormatter.Style,
    configuration: FKDateTimeConfiguration
  ) -> DateFormatter {
    let key = cacheKey(
      "style:\(dateStyle.rawValue)-\(timeStyle.rawValue)",
      configuration.timeZone.identifier,
      configuration.locale.identifier,
      String(describing: configuration.calendar.identifier)
    )
    if let cached = store.styleCache.object(forKey: key) {
      return cached
    }
    let formatter = DateFormatter()
    formatter.locale = configuration.locale
    formatter.timeZone = configuration.timeZone
    formatter.calendar = configuration.calendar
    formatter.dateStyle = dateStyle
    formatter.timeStyle = timeStyle
    store.styleCache.setObject(formatter, forKey: key)
    return formatter
  }

  /// Caller must hold `store.lock`.
  private static func templateFormatterLocked(
    template: String,
    configuration: FKDateTimeConfiguration
  ) -> DateFormatter {
    let key = cacheKey(
      "template:\(template)",
      configuration.timeZone.identifier,
      configuration.locale.identifier,
      String(describing: configuration.calendar.identifier)
    )
    if let cached = store.templateCache.object(forKey: key) {
      return cached
    }
    let formatter = DateFormatter()
    formatter.locale = configuration.locale
    formatter.timeZone = configuration.timeZone
    formatter.calendar = configuration.calendar
    formatter.setLocalizedDateFormatFromTemplate(template)
    store.templateCache.setObject(formatter, forKey: key)
    return formatter
  }

  private static func cacheKey(_ parts: String...) -> NSString {
    parts.joined(separator: "|") as NSString
  }
}

/// ISO-8601 parse / format helpers tolerant of common wire variants.
enum FKDateTimeParsing {
  private final class Store: @unchecked Sendable {
    let lock = NSLock()
    let withFractional: ISO8601DateFormatter
    let withoutFractional: ISO8601DateFormatter

    init() {
      withFractional = Self.makeISOFormatter(fractional: true)
      withoutFractional = Self.makeISOFormatter(fractional: false)
    }

    private static func makeISOFormatter(fractional: Bool) -> ISO8601DateFormatter {
      let formatter = ISO8601DateFormatter()
      formatter.timeZone = TimeZone(secondsFromGMT: 0)
      formatter.formatOptions = [.withInternetDateTime]
      if fractional {
        formatter.formatOptions.insert(.withFractionalSeconds)
      }
      return formatter
    }
  }

  private static let store = Store()

  static func iso8601Date(from string: String) -> Date? {
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    let isoParsed: Date? = {
      store.lock.lock()
      defer { store.lock.unlock() }
      return store.withFractional.date(from: trimmed)
        ?? store.withoutFractional.date(from: trimmed)
    }()
    if let isoParsed { return isoParsed }

    let fallbacks = [
      "yyyy-MM-dd'T'HH:mm:ssXXXXX",
      "yyyy-MM-dd'T'HH:mm:ssZ",
      "yyyy-MM-dd'T'HH:mm:ss",
      "yyyy-MM-dd HH:mm:ss",
      "yyyy-MM-dd",
    ]
    let configuration = FKDateTimeConfiguration.utc
    for format in fallbacks {
      if let date = FKDateTimeFormatting.date(
        from: trimmed,
        format: format,
        configuration: configuration
      ) {
        return date
      }
    }
    return nil
  }

  static func iso8601String(from date: Date, fractionalSeconds: Bool) -> String {
    store.lock.lock()
    defer { store.lock.unlock() }
    return (fractionalSeconds ? store.withFractional : store.withoutFractional).string(from: date)
  }
}
