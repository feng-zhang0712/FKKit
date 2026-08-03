import Foundation

/// Immutable, calendar-aware date-time value inspired by Moment.js-style workflows.
///
/// ``FKDateTime`` wraps a `Date` plus an ``FKDateTimeConfiguration`` so parse, format,
/// arithmetic, comparison, and relative display share one consistent context.
///
/// Typical usage:
/// ```swift
/// let stamp = FKDateTime.now()
/// stamp.relative(style: .chat)           // WeChat-like message time
/// stamp.adding(2, .day)?.format(.date)
/// FKDateTime.parse("2026-08-03 18:00:00", format: .dateTime)
/// ```
public struct FKDateTime: Sendable, Hashable, Comparable, Codable {
  /// Underlying absolute instant.
  public let date: Date

  /// Calendar / time zone / locale used by instance operations.
  public let configuration: FKDateTimeConfiguration

  // MARK: - Init

  /// Creates a value for `date` using `configuration`.
  public init(_ date: Date = Date(), configuration: FKDateTimeConfiguration = .default) {
    self.date = date
    self.configuration = configuration
  }

  /// Current instant with the given configuration.
  public static func now(configuration: FKDateTimeConfiguration = .default) -> FKDateTime {
    FKDateTime(Date(), configuration: configuration)
  }

  /// Instant from a Unix timestamp in seconds.
  public static func from(
    unixTimestamp: TimeInterval,
    configuration: FKDateTimeConfiguration = .default
  ) -> FKDateTime {
    FKDateTime(Date(timeIntervalSince1970: unixTimestamp), configuration: configuration)
  }

  /// Instant from a Unix timestamp in milliseconds.
  public static func from(
    unixMilliseconds: Int64,
    configuration: FKDateTimeConfiguration = .default
  ) -> FKDateTime {
    FKDateTime(
      Date(timeIntervalSince1970: TimeInterval(unixMilliseconds) / 1_000),
      configuration: configuration
    )
  }

  /// Builds a date from explicit calendar components.
  ///
  /// - Returns: `nil` when the calendar cannot compose a valid date.
  public static func from(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
    minute: Int = 0,
    second: Int = 0,
    configuration: FKDateTimeConfiguration = .default
  ) -> FKDateTime? {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    components.second = second
    guard let date = configuration.calendar.date(from: components) else { return nil }
    return FKDateTime(date, configuration: configuration)
  }

  // MARK: - Codable

  /// Decodes a single-value Unix timestamp (seconds), ISO-8601 string, or `Date`.
  ///
  /// - Note: Configuration is not persisted; decoded values use ``FKDateTimeConfiguration/default``.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let interval = try? container.decode(TimeInterval.self) {
      self.init(Date(timeIntervalSince1970: interval))
    } else if let string = try? container.decode(String.self),
              let parsed = FKDateTimeParsing.iso8601Date(from: string) {
      self.init(parsed)
    } else {
      self.init(try container.decode(Date.self))
    }
  }

  /// Encodes the absolute instant as a Unix timestamp in seconds (configuration is omitted).
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(date.timeIntervalSince1970)
  }

  // MARK: - Context

  /// Returns a copy that keeps the same instant but uses `configuration`.
  public func with(configuration: FKDateTimeConfiguration) -> FKDateTime {
    FKDateTime(date, configuration: configuration)
  }

  /// Returns a copy interpreted / formatted in `timeZone`.
  public func `in`(timeZone: TimeZone) -> FKDateTime {
    with(configuration: configuration.with(timeZone: timeZone))
  }

  /// Returns a copy that formats with `locale`.
  public func `in`(locale: Locale) -> FKDateTime {
    with(configuration: configuration.with(locale: locale))
  }

  // MARK: - Comparable / Hashable

  /// Equality compares absolute instants only (configuration is ignored).
  public static func == (lhs: FKDateTime, rhs: FKDateTime) -> Bool {
    lhs.date == rhs.date
  }

  public static func < (lhs: FKDateTime, rhs: FKDateTime) -> Bool {
    lhs.date < rhs.date
  }

  /// Hash combines the absolute instant only (configuration is ignored).
  public func hash(into hasher: inout Hasher) {
    hasher.combine(date)
  }
}

extension FKDateTime: CustomStringConvertible {
  /// Debug-friendly absolute timestamp in the configured time zone.
  public var description: String {
    format(FKDateTimeFormatPreset.dateTime)
  }
}

// MARK: - Date bridge

public extension Date {
  /// Wraps this instant as ``FKDateTime`` with the default configuration.
  var fk_dateTime: FKDateTime { FKDateTime(self) }

  /// Wraps this instant as ``FKDateTime`` with a custom configuration.
  func fk_dateTime(configuration: FKDateTimeConfiguration) -> FKDateTime {
    FKDateTime(self, configuration: configuration)
  }
}
